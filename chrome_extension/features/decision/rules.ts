// Rules Engine v1 (handoff 9.4 / Build Plan 7.3): không AI; mỗi câu nêu được nguồn tính toán.
import type { BudgetLine, OwnedLine, SaleDay } from '../../types';
import { categoryLabel } from '../items/model';
import { amountOf, freshness, type ItemView } from '../items/price';
import { DAY, daysBetween, fmtVnd } from '../../lib/format';

export const BIEN_DO = 0.1;
export const WAIT_DAYS = 3;          // thời gian cân nhắc mặc định (Spec: 3 ngày)

// khaDung = (hạn mức − đã chi − dự phòng) × (1 − biên độ); dự phòng = TB ngày × số ngày còn lại (nếu đủ 30 ngày lịch sử)
export function khaDung(l: BudgetLine, now = new Date()) {
  const conLai = l.limitVnd - l.spentVnd;
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const daysLeft = Math.max(0, daysBetween(now.toISOString(), end.toISOString()));
  const duPhong = l.hasEnoughHistory ? (l.dailyAvgVnd ?? 0) * daysLeft : 0;
  return Math.floor(Math.max(0, conLai - duPhong) * (1 - BIEN_DO));
}

export interface BudgetInsight { kind: 'share' | 'over' | 'empty' | 'missing' | 'noprice' | 'nogroup' | 'unlinked'; text: string; }
export function budgetInsight(v: ItemView, budgets: BudgetLine[] | null, linked: boolean, now = new Date()): BudgetInsight {
  const g = v.item.budgetGroupId;
  if (!g) return { kind: 'nogroup', text: 'Chưa chọn nhóm ngân sách cho món này.' };
  const name = categoryLabel(g) ?? 'Nhóm này';
  if (!linked) return { kind: 'unlinked', text: `Ngân sách ${name}: thiết lập trên app.` };          // EX-08
  const line = budgets?.find((b) => b.groupId === g);
  if (!line) return { kind: 'missing', text: `Chưa thiết lập ngân sách ${name}. Bạn vẫn quyết định được.` }; // E08
  const price = freshness(v.latest, now) === 'fresh' ? amountOf(v.latest) : undefined;
  if (price == null) return { kind: 'noprice', text: `${name} · cần giá gần đây để so với ngân sách.` };
  const kd = khaDung(line, now);
  if (kd <= 0) return { kind: 'empty', text: `${name} · phần khả dụng tháng này đã hết.` };            // không chia cho 0
  if (price > kd) return { kind: 'over', text: `${name} · vượt phần khả dụng khoảng ${fmtVnd(price - kd)} (khả dụng ${fmtVnd(kd)}).` };
  return { kind: 'share', text: `${name} · chiếm khoảng ${Math.round((price / kd) * 100)}% phần khả dụng (${fmtVnd(kd)})` };
}

export function nextSale(calendar: SaleDay[], nowIso = new Date().toISOString()) {
  const up = calendar.map((s) => ({ ...s, days: daysBetween(nowIso, s.date) })).filter((s) => s.days >= 0).sort((a, b) => a.days - b.days);
  return up[0] ?? null;
}
export function saleText(calendar: SaleDay[], nowIso?: string) {
  const s = nextSale(calendar, nowIso);
  if (!s) return null;
  const tail = s.verified ? ' (đã xác nhận)' : '';
  return s.days === 0 ? `Hôm nay là đợt ${s.label}${tail}` : `Đợt ${s.label} còn ${s.days} ngày${tail}`;
}
export function sameGroupText(v: ItemView, views: ItemView[]) {
  const g = v.item.budgetGroupId;
  if (!g) return null;
  const n = views.filter((x) => x.item.id !== v.item.id && x.item.status === 'considering' && x.item.budgetGroupId === g).length;
  return n > 0 ? `Bạn đang cân nhắc thêm ${n} món cùng nhóm.` : null;
}
export function ownedText(v: ItemView, owned: OwnedLine[] | null) {
  const o = owned?.find((x) => x.budgetGroupId === v.item.budgetGroupId);
  return o ? `Bạn đã ghi có ${o.count} ${o.name} đang dùng. Bạn muốn thay hay mua thêm?` : null;
}
export function defaultSaleCalendar(year = new Date().getFullYear()): SaleDay[] {
  const out: SaleDay[] = [];
  for (const y of [year, year + 1]) for (let m = 1; m <= 12; m++) out.push({ date: `${y}-${String(m).padStart(2, '0')}-${String(m).padStart(2, '0')}T00:00:00`, label: `${m}.${m}`, verified: false });
  return out;
}

// Nhãn tóm tắt — kiểm tra theo thứ tự, dừng ở điều kiện đầu tiên khớp (handoff 9.4).
export type VerdictCode = 'needRecentPrice' | 'canWait' | 'overAvailable' | 'canConsiderSkip' | 'withinBudget' | 'notEnoughData';
export const VERDICT_LABEL: Record<VerdictCode, string> = {
  needRecentPrice: 'Cần giá gần đây', canWait: 'Có thể chờ', overAvailable: 'Vượt phần khả dụng',
  canConsiderSkip: 'Có thể cân nhắc bỏ', withinBudget: 'Trong ngân sách', notEnoughData: 'Chưa đủ dữ liệu',
};
export function verdict(v: ItemView, ctx: { budgets: BudgetLine[] | null; calendar: SaleDay[]; linked: boolean }, now = new Date()): { code: VerdictCode; label: string } {
  const r = (code: VerdictCode) => ({ code, label: VERDICT_LABEL[code] });
  if (freshness(v.latest, now) !== 'fresh' || amountOf(v.latest) == null) return r('needRecentPrice');
  const ageDays = (now.getTime() - new Date(v.item.createdAt).getTime()) / DAY;
  if (ageDays < WAIT_DAYS && v.item.motive !== 'nhu-cau') return r('canWait');
  const s = nextSale(ctx.calendar, now.toISOString());
  if (s && s.verified && s.days <= 7) return r('canWait');
  const b = budgetInsight(v, ctx.budgets, ctx.linked, now);
  if (b.kind === 'over' || b.kind === 'empty') return r('overAvailable');
  if (ageDays > 60 && v.item.priority <= 2) return r('canConsiderSkip');
  if (b.kind === 'share') return r('withinBudget');
  return r('notEnoughData');
}

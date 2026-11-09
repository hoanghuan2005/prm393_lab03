// Giá: độ mới (≤3 ngày mới · 4–7 ngày kèm ngày · >7 ngày cũ + "Xác nhận lại"), so được khi cùng loại giá và cùng phân loại.
import type { PriceSnapshot, WishlistItem } from '../../types';
import { DAY, fmtVnd } from '../../lib/format';

export type Freshness = 'fresh' | 'recent' | 'old' | 'none';
export function freshness(s: PriceSnapshot | undefined, now = new Date()): Freshness {
  if (!s) return 'none';
  const d = (now.getTime() - new Date(s.observedAt).getTime()) / DAY;
  return d <= 3 ? 'fresh' : d <= 7 ? 'recent' : 'old';
}
export const amountOf = (s?: PriceSnapshot) => (s ? s.amountVnd ?? s.minVnd : undefined);
export function fmtPrice(s?: PriceSnapshot) {
  if (!s) return '—';
  if (s.priceType === 'range' && s.minVnd != null && s.maxVnd != null) return `${s.minVnd.toLocaleString('vi-VN')} – ${fmtVnd(s.maxVnd)}`;
  return s.amountVnd != null ? fmtVnd(s.amountVnd) : '—';
}
const vKey = (v?: string) => (v ?? '').toLowerCase().replace(/\s+/g, ' ').trim();
export function comparable(a: PriceSnapshot, b: PriceSnapshot) {
  if (a.priceType !== b.priceType) return false;                // Flash Sale chỉ so với Flash Sale; đơn không so với khoảng
  if (a.priceType === 'range') return false;
  return (a.modelId ?? '') === (b.modelId ?? '') && vKey(a.variantLabel) === vKey(b.variantLabel);
}

export interface ItemView {
  item: WishlistItem; prices: PriceSnapshot[]; latest?: PriceSnapshot; first?: PriceSnapshot; afterVoucher?: PriceSnapshot;
  sale?: PriceSnapshot;        // giá đợt giảm gần nhất
  lowestSale?: PriceSnapshot;  // giá đợt giảm thấp nhất đã ghi (như "historical low" của SteamDB)
}
export function buildViews(items: WishlistItem[], prices: PriceSnapshot[]): ItemView[] {
  const by = new Map<string, PriceSnapshot[]>();
  for (const p of prices) by.set(p.itemId, [...(by.get(p.itemId) ?? []), p]);
  return items.map((item) => {
    const ps = (by.get(item.id) ?? []).sort((a, b) => a.observedAt.localeCompare(b.observedAt));
    // Giá sau voucher chỉ để tham khảo cá nhân: không dùng làm giá chính, không so với giá niêm yết.
    // Giá đợt giảm đi riêng; giá gốc là giá chính (chỉ có giá đợt giảm thì dùng nó).
    const listed = ps.filter((p) => p.priceType !== 'afterVoucher');
    const regular = listed.filter((p) => p.priceType !== 'sale');
    const main = regular.length ? regular : listed;
    const latest = main[main.length - 1];
    const first = latest ? main.find((p) => comparable(p, latest)) : undefined;
    const av = ps.filter((p) => p.priceType === 'afterVoucher');
    const sales = ps.filter((p) => p.priceType === 'sale' && p.amountVnd);
    const lowestSale = sales.reduce<PriceSnapshot | undefined>((m, p) => (!m || p.amountVnd! < m.amountVnd! ? p : m), undefined);
    return { item, prices: ps, latest, first, afterVoucher: av[av.length - 1], sale: sales[sales.length - 1], lowestSale };
  });
}

// "-30% · 11.11" cho một giá đợt giảm
export function discountText(s?: PriceSnapshot) {
  if (!s) return '';
  const pct = s.amountVnd && s.originalVnd && s.originalVnd > s.amountVnd ? Math.round(((s.originalVnd - s.amountVnd) / s.originalVnd) * 100) : 0;
  return [pct ? `-${pct}%` : '', s.saleLabel ?? ''].filter(Boolean).join(' · ') || 'Đang giảm';
}

export type PriceTagKind = 'lower' | 'higher' | 'stable' | 'need';
export interface PriceTagInfo { kind: PriceTagKind; label: string; }
export function priceTag(v: Pick<ItemView, 'latest' | 'first'>, now = new Date()): PriceTagInfo {
  const f = freshness(v.latest, now);
  if (f !== 'fresh' || !v.latest || amountOf(v.latest) == null) return { kind: 'need', label: 'Cần cập nhật giá' };
  const a = amountOf(v.latest)!, b = amountOf(v.first);
  if (!v.first || v.first.id === v.latest.id || b == null || a === b) return { kind: 'stable', label: 'Giá ổn định' };
  const pct = Math.round((Math.abs(a - b) / b) * 100);
  if (pct === 0) return { kind: 'stable', label: 'Giá ổn định' };
  return a < b ? { kind: 'lower', label: `Thấp hơn lúc lưu ${pct}%` } : { kind: 'higher', label: `Cao hơn lúc lưu ${pct}%` };
}
export function compareToSaved(firstVnd: number | undefined, nowVnd: number | null): PriceTagInfo | null {
  if (!firstVnd || nowVnd == null) return null;
  const pct = Math.round((Math.abs(nowVnd - firstVnd) / firstVnd) * 100);
  if (pct === 0) return { kind: 'stable', label: 'Giá ổn định' };
  return nowVnd < firstVnd ? { kind: 'lower', label: `Thấp hơn lúc lưu ${pct}%` } : { kind: 'higher', label: `Cao hơn lúc lưu ${pct}%` };
}

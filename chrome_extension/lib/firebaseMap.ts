// Chuyển dữ liệu extension ↔ Firestore của app Why I Buy? (docs/data-model.md trong repo prm393_lab03).
// Hàm thuần, không import Firebase, để test được trong Node. Thời gian ghi đi là Date (Firestore lưu thành timestamp).
import type { BudgetLine, Decision, OwnedLine, PriceSnapshot, SaleDay, WishlistItem } from '../types';
import { toRatingCount, toShopStar, toStar } from './format';

type Doc = Record<string, unknown>;

// Động cơ và nhóm ngân sách: extension dùng slug tiếng Việt, app dùng key tiếng Anh.
export const MOTIVE_TO_APP: Record<string, string> = {
  'nhu-cau': 'need', 'mong-muon': 'want', 'khuyen-mai': 'sale', 'cam-xuc': 'emotion',
  'anh-huong-mxh': 'social', 'tien-loi': 'convenience', 'quang-cao': 'ads', 'khac': 'other',
};
export const GROUP_TO_APP: Record<string, string> = {
  'an-uong': 'food', 'thoi-trang': 'fashion', 'cong-nghe': 'tech', 'lam-dep': 'beauty', 'hoc-tap': 'study', 'khac': 'other',
};
const invert = (m: Record<string, string>) => Object.fromEntries(Object.entries(m).map(([k, v]) => [v, k]));
const MOTIVE_FROM_APP = invert(MOTIVE_TO_APP);
const GROUP_FROM_APP = invert(GROUP_TO_APP);
export const motiveToApp = (m?: string) => (m ? MOTIVE_TO_APP[m] ?? 'other' : null);
export const motiveFromApp = (m: unknown) => (typeof m === 'string' ? MOTIVE_FROM_APP[m] : undefined);
export const groupToApp = (g?: string) => (g ? GROUP_TO_APP[g] ?? g : null);
export const groupFromApp = (g: unknown) => (typeof g === 'string' ? GROUP_FROM_APP[g] ?? g : undefined);

// Timestamp của Firestore, Date hoặc chuỗi ISO → ISO; không đọc được → undefined.
export function toIso(v: unknown): string | undefined {
  if (v == null) return undefined;
  if (typeof v === 'string') return Number.isNaN(Date.parse(v)) ? undefined : new Date(v).toISOString();
  if (v instanceof Date) return v.toISOString();
  if (typeof (v as any).toDate === 'function') return (v as any).toDate().toISOString();
  return undefined;
}
const toDate = (iso?: string) => (iso ? new Date(iso) : null);
const str = (v: unknown) => (typeof v === 'string' && v.trim() ? v : undefined);
const int = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? Math.round(v) : undefined);
// Đánh giá sản phẩm/shop: chỉ gửi trường đọc được thành số
function ratingDoc(r: { productRating?: unknown; productRatingCount?: unknown; shopRating?: unknown }): Doc {
  const star = toStar(r.productRating), count = toRatingCount(r.productRatingCount), shop = toShopStar(r.shopRating);
  return { ...(star != null ? { productRating: star } : {}), ...(count != null ? { productRatingCount: count } : {}), ...(shop != null ? { shopRating: shop } : {}) };
}
const ratingsFrom = (d: Doc) => ({ productRating: toStar(d.productRating) ?? undefined, productRatingCount: toRatingCount(d.productRatingCount) ?? undefined, shopRating: toShopStar(d.shopRating) ?? undefined });

// ---------- Món ----------
// Trường extension sở hữu khi ghi lên. Không gửi latestPrice* (tính riêng từ giá), purchaseId/decidedAt (chỉ app ghi).
export function itemToDoc(i: WishlistItem): Doc {
  return {
    title: i.title,
    status: i.status,
    motive: motiveToApp(i.motive),
    priority: Math.min(5, Math.max(1, Math.round(i.priority || 3))),
    url: i.originalUrl ?? i.url ?? null,
    budgetGroupId: groupToApp(i.budgetGroupId),
    reviewAt: toDate(i.reviewAt),
    saveChannel: i.saveChannel,
    productKey: i.productKey ?? null,
    modelId: i.modelId ?? null,
    variantLabel: i.variantLabel?.slice(0, 60) ?? null,
    shopName: i.shopName?.slice(0, 60) ?? null,
    vouchers: i.vouchers?.length ? i.vouchers.slice(0, 20).map((t) => t.slice(0, 240)) : null,
    vouchersAt: toDate(i.vouchersAt),
    imageUrl: i.imageUrl ?? null,
    buyIntentAt: toDate(i.buyIntentAt),
    createdAt: new Date(i.createdAt),
    ...ratingDoc(i),
  };
}

// Thời gian cân nhắc chỉ đặt khi tạo món, giống WishlistService.add của app (trừ động cơ Nhu cầu).
export function cooldownFor(i: WishlistItem, coolingOffDays: number): Date | null {
  if (i.motive === 'nhu-cau') return null;
  return new Date(new Date(i.createdAt).getTime() + coolingOffDays * 86_400_000);
}

// revision = mốc updatedAt (ms) của server: bản server sửa sau luôn có revision lớn hơn.
export function docToItem(id: string, d: Doc): WishlistItem {
  const createdAt = toIso(d.createdAt) ?? new Date().toISOString();
  const updatedAt = toIso(d.updatedAt) ?? createdAt;
  const status = d.status === 'purchased' || d.status === 'skipped' ? d.status : 'considering';
  const url = str(d.url);
  return {
    id,
    title: str(d.title) ?? 'Sản phẩm chưa đặt tên',
    url: url && /^https:\/\/shopee\.vn\/product\//.test(url) ? url : undefined,
    originalUrl: url,
    productKey: str(d.productKey),
    modelId: str(d.modelId),
    variantLabel: str(d.variantLabel),
    shopName: str(d.shopName),
    vouchers: Array.isArray(d.vouchers) && d.vouchers.some((t) => typeof t === 'string') ? d.vouchers.filter((t): t is string => typeof t === 'string') : undefined,
    vouchersAt: toIso(d.vouchersAt),
    motive: motiveFromApp(d.motive),
    budgetGroupId: groupFromApp(d.budgetGroupId),
    priority: Math.min(5, Math.max(1, int(d.priority) ?? 3)),
    status,
    reviewAt: toIso(d.reviewAt),
    saveChannel: d.saveChannel === 'extension' || d.saveChannel === 'share' ? d.saveChannel : 'manual',
    purchaseId: str(d.purchaseId),
    imageUrl: str(d.imageUrl),
    buyIntentAt: status === 'considering' ? toIso(d.buyIntentAt) : undefined,
    ...ratingsFrom(d),
    revision: Date.parse(updatedAt),
    createdAt,
    updatedAt,
    syncState: 'synced',
  };
}

// ---------- Giá ----------
// rules của app bắt buộc amountVnd > 0: khoảng giá ghi amountVnd = giá thấp nhất. Không có số hợp lệ → không gửi.
export function priceToDoc(p: PriceSnapshot): Doc | null {
  const amount = p.amountVnd ?? p.minVnd;
  if (!amount || amount <= 0) return null;
  return {
    amountVnd: Math.round(amount),
    observedAt: new Date(p.observedAt),
    source: p.source === 'extensionPage' ? 'extensionPage' : p.source === 'demo' ? 'demo' : 'manual',
    priceType: p.priceType,
    confirmation: p.confirmation,
    ...(p.minVnd ? { minVnd: Math.round(p.minVnd) } : {}),
    ...(p.maxVnd ? { maxVnd: Math.round(p.maxVnd) } : {}),
    ...(p.originalVnd ? { originalVnd: Math.round(p.originalVnd) } : {}),
    ...(p.variantLabel ? { variantLabel: p.variantLabel.slice(0, 60) } : {}),
    ...(p.saleLabel ? { saleLabel: p.saleLabel.slice(0, 40) } : {}),
    ...(p.shopName?.trim() ? { shopName: p.shopName.trim().slice(0, 60) } : {}),
    ...ratingDoc(p),
  };
}

// Giá cập nhật latestPriceVnd của món: bản mới nhất, trừ giá sau voucher (chỉ tham khảo, handoff 9.1)
// và giá đợt giảm (giá gốc là giá chính); chỉ có giá đợt giảm thì dùng nó.
export function latestPriceOf(ps: PriceSnapshot[]): { vnd: number; at: Date } | null {
  const priced = ps.filter((p) => p.priceType !== 'afterVoucher' && ((p.amountVnd ?? p.minVnd ?? 0) > 0));
  const regular = priced.filter((p) => p.priceType !== 'sale');
  const ok = (regular.length ? regular : priced).sort((a, b) => a.observedAt.localeCompare(b.observedAt));
  const last = ok[ok.length - 1];
  return last ? { vnd: Math.round((last.amountVnd ?? last.minVnd)!), at: new Date(last.observedAt) } : null;
}

export function docToPrice(id: string, itemId: string, d: Doc): PriceSnapshot | null {
  const amount = int(d.amountVnd);
  const observedAt = toIso(d.observedAt);
  if (!amount || amount <= 0 || !observedAt) return null;
  const priceType = d.priceType === 'range' || d.priceType === 'flash' || d.priceType === 'afterVoucher' || d.priceType === 'sale' ? d.priceType : 'single';
  const minVnd = int(d.minVnd), maxVnd = int(d.maxVnd);
  return {
    id, itemId, priceType,
    amountVnd: priceType === 'range' && minVnd && maxVnd ? undefined : amount,
    minVnd, maxVnd, originalVnd: int(d.originalVnd),
    variantLabel: str(d.variantLabel), saleLabel: str(d.saleLabel),
    shopName: str(d.shopName), ...ratingsFrom(d),
    source: d.source === 'extensionPage' ? 'extensionPage' : d.source === 'demo' ? 'demo' : 'manual',
    confirmation: d.confirmation === 'unconfirmed' ? 'unconfirmed' : 'userConfirmed',
    observedAt,
    syncState: 'synced',
  };
}

// ---------- Quyết định ----------
// "Mua" trên extension chỉ là ý định (buyIntentAt); decision buy do app ghi khi lưu khoản mua (khoá buy_{itemId}).
export function decisionToDoc(d: Decision): Doc | null {
  if (d.choice === 'buy') return null;
  return { choice: d.choice, itemId: d.itemId, at: new Date(d.at), ...(d.reviewAt ? { reviewAt: new Date(d.reviewAt) } : {}) };
}

export function docToDecision(id: string, d: Doc): Decision | null {
  const choice = d.choice;
  const at = toIso(d.at);
  if (typeof d.itemId !== 'string' || !at || !(choice === 'buy' || choice === 'wait' || choice === 'skip' || choice === 'undo')) return null;
  return { id, itemId: d.itemId, choice, at, reviewAt: toIso(d.reviewAt), syncState: 'synced' };
}

// ---------- Ngân sách, lịch sale, đồ đang có ----------
export interface PurchaseRow { amountVnd: number; budgetGroupId: string; occurredAt: string; fromWishlist: boolean; }

export function docToPurchase(d: Doc): PurchaseRow | null {
  const amount = int(d.amountVnd);
  const occurredAt = toIso(d.occurredAt);
  if (!amount || !occurredAt) return null;
  return { amountVnd: amount, budgetGroupId: str(d.budgetGroupId) ?? 'other', occurredAt, fromWishlist: !!str(d.wishlistItemId) };
}

// Giống AvailableBudget của app (data-model.md): dự phòng = chi trung bình/ngày trong tối đa 90 ngày
// (không tính khoản mua từ danh sách mong muốn); chỉ có khi đã có ít nhất 30 ngày dữ liệu.
// [purchases] chỉ cần 90 ngày gần nhất; [firstAt] là khoản mua đầu tiên của tài khoản (để biết đủ 30 ngày chưa).
export function budgetLines(limits: Record<string, unknown>, purchases: PurchaseRow[], now = new Date(), firstAt?: string): BudgetLine[] {
  const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
  const first = firstAt ? Date.parse(firstAt) : purchases.reduce((m, p) => Math.min(m, Date.parse(p.occurredAt)), Infinity);
  const historyDays = Number.isFinite(first) ? Math.floor((now.getTime() - first) / 86_400_000) : 0;
  const windowDays = Math.max(1, Math.min(90, historyDays));
  const windowStart = now.getTime() - windowDays * 86_400_000;
  return Object.entries(limits)
    .filter(([, v]) => typeof v === 'number' && v > 0)
    .map(([group, v]) => {
      const rows = purchases.filter((p) => p.budgetGroupId === group);
      const spentVnd = rows.filter((p) => Date.parse(p.occurredAt) >= monthStart).reduce((s, p) => s + p.amountVnd, 0);
      const habitual = rows.filter((p) => !p.fromWishlist && Date.parse(p.occurredAt) >= windowStart).reduce((s, p) => s + p.amountVnd, 0);
      return {
        groupId: groupFromApp(group) ?? group, month, limitVnd: v as number, spentVnd,
        dailyAvgVnd: Math.round(habitual / windowDays), hasEnoughHistory: historyDays >= 30,
      };
    });
}

// Remote Config `sale_calendar` của app: [{date:"2026-11-11", name:"11.11", type, confirmed}]
export function parseSaleCalendar(json: string): SaleDay[] {
  try {
    const rows = JSON.parse(json);
    if (!Array.isArray(rows)) return [];
    return rows
      .filter((r) => typeof r?.date === 'string' && /^\d{4}-\d{2}-\d{2}/.test(r.date))
      .map((r) => ({ date: `${r.date.slice(0, 10)}T00:00:00`, label: String(r.name ?? r.date.slice(5, 10)), verified: r.confirmed === true }));
  } catch { return []; }
}

// "Bạn đã ghi có N <tên> đang dùng": gom đồ đang có theo nhóm, lấy tên món ghi gần nhất.
export function ownedLines(docs: Doc[]): OwnedLine[] {
  const by = new Map<string, OwnedLine>();
  for (const d of docs) {
    const group = groupFromApp(d.budgetGroupId);
    const name = str(d.name);
    if (!group || !name) continue;
    const cur = by.get(group);
    by.set(group, cur ? { ...cur, count: cur.count + 1 } : { budgetGroupId: group, name: name.toLowerCase(), count: 1 });
  }
  return [...by.values()];
}

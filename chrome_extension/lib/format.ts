export const fmtVnd = (n: number) => `${Math.round(n).toLocaleString('vi-VN')} ₫`;
export const fmtDayMonth = (iso: string) => { const d = new Date(iso); return `${d.getDate()}/${d.getMonth() + 1}`; };
// Đánh giá đọc từ trang được chuẩn hoá thành số trước khi lưu/đồng bộ.
const STAR_RE = /^([0-5](?:[.,]\d{1,2})?)$/;
// Số sao 0–5 (làm tròn 1 chữ số); "4,9" → 4.9; không hợp lệ hoặc 0 → null
export function toStar(v: unknown): number | null {
  const n = typeof v === 'number' ? v : typeof v === 'string' && STAR_RE.test(v.trim()) ? parseFloat(v.trim().replace(',', '.')) : NaN;
  if (!Number.isFinite(n) || n > 5) return null;
  const r = Math.round(n * 10) / 10;
  return r > 0 ? r : null;
}
const COUNT_UNIT: Record<string, number> = { k: 1e3, nghìn: 1e3, ngàn: 1e3, tr: 1e6, triệu: 1e6, m: 1e6 };
// Số lượt đánh giá: "2,3k" → 2300, "1.234" → 1234, "999+" → 999; không đọc được → null
export function toRatingCount(v: unknown): number | null {
  if (typeof v === 'number') return Number.isInteger(v) && v >= 0 ? v : null;
  if (typeof v !== 'string') return null;
  const s = v.trim().toLowerCase().replace(/\+$/, '').trim();
  const m = s.match(/^(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngàn|tr|triệu|m)$/);
  if (m) return Math.round(parseFloat(m[1].replace(',', '.')) * COUNT_UNIT[m[2]]);
  if (/^\d+$/.test(s)) return parseInt(s, 10);
  if (/^\d{1,3}([.,]\d{3})+$/.test(s)) return parseInt(s.replace(/[.,]/g, ''), 10);
  return null;
}
// Đánh giá shop chỉ nhận số sao; chữ khác (vd "51,8k" lượt đánh giá) → null
export function toShopStar(v: unknown): number | null {
  return typeof v === 'number' || (typeof v === 'string' && STAR_RE.test(v.trim())) ? toStar(v) : null;
}
// 2300 → "2,3k", 1200000 → "1,2tr"
export function fmtCount(n: number) {
  const f = (x: number, unit: string) => `${(Math.round(x * 10) / 10).toString().replace('.', ',')}${unit}`;
  return n >= 1e6 ? f(n / 1e6, 'tr') : n >= 1e3 ? f(n / 1e3, 'k') : String(n);
}
// "★ 4.9 (2,3k đánh giá)" cho sản phẩm; shop chỉ hiện số sao
export const fmtProductRating = (r?: { productRating?: unknown; productRatingCount?: unknown }) => {
  const star = toStar(r?.productRating), count = toRatingCount(r?.productRatingCount);
  const cnt = count ? `${fmtCount(count)} đánh giá` : '';
  return star != null ? `★ ${star}${cnt ? ` (${cnt})` : ''}` : cnt;
};
export const fmtShopRating = (s?: unknown) => { const star = toShopStar(s); return star == null ? '' : `★ ${star}`; };
export const fmtTime =(iso: string) => { const d = new Date(iso); return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`; };
export function parseVnd(s: string): number | null {
  const digits = (s ?? '').replace(/[^\d]/g, '');
  if (!digits) return null;
  const n = parseInt(digits, 10);
  return n >= 0 ? n : null;
}
export const DAY = 86_400_000;
export function daysBetween(fromIso: string, toIso: string) {
  const a = new Date(fromIso); a.setHours(0, 0, 0, 0);
  const b = new Date(toIso); b.setHours(0, 0, 0, 0);
  return Math.round((b.getTime() - a.getTime()) / DAY);
}
export const uuid = () => (globalThis.crypto?.randomUUID?.() ?? `id-${Date.now()}-${Math.random().toString(16).slice(2)}`);
export function deviceLabel(ua = globalThis.navigator?.userAgent ?? '') {
  const os = /Windows/i.test(ua) ? 'Windows' : /Mac OS X|Macintosh/i.test(ua) ? 'macOS' : /CrOS/i.test(ua) ? 'ChromeOS' : /Linux/i.test(ua) ? 'Linux' : 'máy tính';
  const br = /Edg\//.test(ua) ? 'Edge' : /OPR\//.test(ua) ? 'Opera' : 'Chrome';
  return `${br} – ${os}`;
}
export const TITLE_MAX = 60;
// Cắt tên về tối đa 60 ký tự, ưu tiên cắt ở ranh giới từ (handoff 9.1).
export function clampTitle(t: string, max = TITLE_MAX) {
  const s = t.replace(/\s+/g, ' ').trim();
  if (s.length <= max) return s;
  const cut = s.slice(0, max + 1);
  const sp = cut.lastIndexOf(' ');
  return (sp > max * 0.6 ? cut.slice(0, sp) : s.slice(0, max)).replace(/[\s,.;:|–-]+$/, '');
}
// Băm ổn định (FNV-1a) để làm id = hash(uid, productKey, modelId ?? variant ?? url)
export function stableHash(s: string) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; }
  return h.toString(36).padStart(7, '0');
}

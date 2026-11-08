// Rút gọn tên Shopee thành từ khoá tìm kiếm, xác định "món cùng loại" và so giá giữa các món ĐÃ LƯU (Figma 23).
// Không gọi mạng, không đọc kết quả tìm kiếm của Shopee.
import { amountOf, freshness, type ItemView } from './price';
import { shopIdOf } from './url';
import { fmtDayMonth, fmtVnd } from '../../lib/format';

const PROMO = [
  'hàng có sẵn', 'có sẵn', 'giá rẻ', 'giá sỉ', 'giá tốt', 'chính hãng', 'hàng chính hãng', 'freeship', 'free ship', 'xả kho', 'xả hàng',
  'siêu rẻ', 'rẻ vô địch', 'rẻ nhất', 'cao cấp', 'loại 1', 'loại tốt', 'mẫu mới', 'hàng mới', 'mới nhất', 'hot trend', 'hot', 'sale', 'new',
  'yêu thích', 'mall', 'bảo hành', 'chất lượng cao', 'siêu đẹp', 'cực đẹp', 'đẹp', 'tặng kèm', 'quà tặng', 'combo', 'sỉ', 'lẻ',
];
const STOP = new Set(['dành', 'cho', 'và', 'của', 'với', 'các', 'những', 'loại', 'hàng', 'mẫu', 'size', 'màu', 'nhiều', 'giá', 'sp', 'sản', 'phẩm', 'chiếc', 'cái', 'bộ', 'set']);

const stripBrackets = (s: string) => s.replace(/[\[(【{][^\])】}]*[\])】}]/g, ' ');
const stripEmoji = (s: string) => s.replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{2B50}\u{2705}]/gu, ' ');
const squash = (s: string) => s.replace(/\s+/g, ' ').trim();

export function searchKeyword(title: string, maxWords = 7): string {
  let t = stripEmoji(stripBrackets(title.normalize('NFC')));
  t = t.split(/[,|/;–—]|\s-\s|\s\+\s/)[0] ?? t;           // phần đầu thường là tên thật, phía sau là từ khoá nhồi thêm
  t = ` ${t.toLowerCase()} `;
  for (const p of [...PROMO].sort((a, b) => b.length - a.length)) t = t.split(` ${p} `).join(' ');
  t = t.replace(/\b(19|20)\d{2}\b/g, ' ').replace(/[^\p{L}\p{N}\s]/gu, ' ');
  return squash(t).split(' ').slice(0, maxWords).join(' ');
}

export function shopeeSearchUrl(keyword: string) {
  return `https://shopee.vn/search?keyword=${encodeURIComponent(keyword)}&order=asc&page=0&sortBy=price`;
}

export function tokens(title: string): Set<string> {
  return new Set(searchKeyword(title, 12).split(' ').filter((w) => w.length > 1 && !STOP.has(w)));
}

// Cùng loại = cùng sản phẩm (khác phân loại), hoặc tên gần giống: chung ≥ 3 từ và Jaccard ≥ 0,6.
export function isSameType(a: ItemView, b: ItemView): boolean {
  if (a.item.id === b.item.id) return false;
  if (a.item.productKey && a.item.productKey === b.item.productKey) return true;
  const A = tokens(a.item.title), B = tokens(b.item.title);
  const shared = [...A].filter((w) => B.has(w)).length;
  const union = new Set([...A, ...B]).size;
  return shared >= 3 && union > 0 && shared / union >= 0.6;
}

export interface SimilarRow { view: ItemView; fresh: boolean; cheapest: boolean; sameShop: boolean; sameProduct: boolean; }
export interface SimilarResult { rows: SimilarRow[]; summary: string | null; }

// Chỉ so giá ghi trong 3 ngày, cùng loại giá; khoảng giá không đem so (handoff 9.1).
export function compareSimilar(me: ItemView, views: ItemView[], now = new Date()): SimilarResult {
  const others = views.filter((v) => !v.item.deleted && v.item.status === 'considering' && isSameType(me, v));
  if (!others.length) return { rows: [], summary: null };
  const ok = (v: ItemView) => freshness(v.latest, now) === 'fresh' && v.latest!.priceType !== 'range' && amountOf(v.latest) != null
    && (!me.latest || v.latest!.priceType === me.latest.priceType);
  const pool = [me, ...others].filter(ok);
  const min = pool.length ? Math.min(...pool.map((v) => amountOf(v.latest)!)) : null;
  const price = (v: ItemView) => amountOf(v.latest) ?? Infinity;
  const rows = others.map((v) => ({
    view: v, fresh: ok(v), cheapest: ok(v) && amountOf(v.latest) === min,
    sameShop: !!shopIdOf(v.item.productKey) && shopIdOf(v.item.productKey) === shopIdOf(me.item.productKey),
    sameProduct: !!v.item.productKey && v.item.productKey === me.item.productKey,
  })).sort((a, b) => (a.fresh === b.fresh ? price(a.view) - price(b.view) : a.fresh ? -1 : 1));
  const freshOthers = rows.filter((r) => r.fresh);
  let summary: string;
  if (!ok(me)) summary = `Cập nhật giá món này để so với ${others.length} món cùng loại bạn đã lưu.`;
  else if (!freshOthers.length) summary = 'Các món cùng loại bạn đã lưu chưa có giá ghi trong 3 ngày qua để so.';
  else if (amountOf(me.latest) === min) summary = `Món này đang có giá thấp nhất trong ${freshOthers.length + 1} món cùng loại bạn đã lưu (giá ghi trong 3 ngày).`;
  else {
    const c = freshOthers[0].view;
    summary = `Có món cùng loại rẻ hơn ${fmtVnd(amountOf(me.latest)! - amountOf(c.latest)!)}: ${c.item.title}${c.item.variantLabel ? ` · ${c.item.variantLabel}` : ''} (${fmtVnd(amountOf(c.latest)!)}, giá ghi ${fmtDayMonth(c.latest!.observedAt)}).`;
  }
  return { rows, summary };
}

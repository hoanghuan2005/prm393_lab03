// Cào voucher cho Admin/Nhân viên (bản Lab + Firebase): trên một trang Shopee, bấm 1 nút → đọc mọi voucher
// đang hiển thị → ghi vào shopeeVouchers/{id} trên Firestore (firestore.rules: chỉ máy đã liên kết QR với
// tài khoản có role 'staff' hoặc 'admin'). Không áp mã, không bấm "Lưu" trên trang.
import { parseShopeeLink, shopIdOf } from '../items/url';
import { parseVoucher } from '../ex10/voucher';
import { stableHash } from '../../lib/format';
import type { PageRead } from '../ex10/reader';

export const MAX_SCRAPE = 200;          // số voucher tối đa mỗi lần cào (1 batch Firestore tối đa 500 thao tác)
export type StaffRole = 'staff' | 'admin';

// Chèn vào trang bằng chrome.scripting.executeScript → PHẢI tự chứa (không import, không biến ngoài hàm).
// Rê chuột (không bấm) lên dải "Mã Giảm Giá Của Shop" để Shopee mở danh sách voucher đầy đủ, rồi chờ hiện ra.
export async function expandVoucherLists(): Promise<number> {
  const norm = (s: string | null) => (s || '').replace(/\s+/g, ' ').trim();
  const label = /^(mã giảm giá của shop|voucher của shop|mã giảm giá|voucher)$/i;
  const triggers = Array.from(document.body.querySelectorAll('*'))
    .filter((el) => el.children.length <= 2 && label.test(norm(el.textContent)) && !el.closest('header, footer, nav'))
    .slice(0, 4);
  for (const el of triggers) {
    const row = el.parentElement ?? el;
    for (const target of [row, ...Array.from(row.querySelectorAll('*')).slice(0, 12)]) {
      for (const type of ['pointerover', 'mouseover', 'mouseenter']) {
        target.dispatchEvent(new MouseEvent(type, { bubbles: type !== 'mouseenter', cancelable: true, view: window }));
      }
    }
  }
  if (triggers.length) await new Promise((r) => setTimeout(r, 900));
  return triggers.length;
}

export interface VoucherDoc { id: string; data: Record<string, unknown>; }

const int = (v: number | undefined, max: number) => (v != null && Number.isInteger(v) && v >= 0 && v <= max ? v : undefined);

// Trang đã đọc → các document shopeeVouchers (chưa có lastSeenAt; uploadVouchers thêm giờ máy chủ).
// Id ổn định theo shop + nội dung voucher → cào lại chỉ cập nhật, không tạo trùng.
export function voucherDocs(page: Pick<PageRead, 'url' | 'name' | 'shopName' | 'voucherTexts'>, capturedBy: string): VoucherDoc[] {
  let url: URL | null = null;
  try { url = new URL(page.url); } catch { /* bỏ qua */ }
  const link = parseShopeeLink(page.url);
  const shopId = shopIdOf(link?.productKey);
  const where = shopId ? `shop:${shopId}` : url ? `${url.hostname}${url.pathname}` : page.url;
  const sourceUrl = (link?.url ?? (url ? `${url.origin}${url.pathname}` : page.url)).slice(0, 500);
  const seen = new Set<string>();
  const out: VoucherDoc[] = [];
  for (const text of page.voucherTexts) {
    const v = parseVoucher(text);
    const raw = v.raw.slice(0, 300);
    if (!raw) continue;
    const key = `${where}|${raw.toLowerCase()}`;
    const id = `v_${stableHash(key)}${stableHash(`${key}#`)}`;
    if (seen.has(id)) continue;
    seen.add(id);
    const data: Record<string, unknown> = {
      raw, kind: v.kind, scope: v.scope, unavailable: !!v.unavailable,
      sourceUrl, capturedBy, source: 'extension',
      amountVnd: int(v.amount, 999_999_999), percent: int(v.percent, 100), capVnd: int(v.cap, 999_999_999),
      minSpendVnd: int(v.minSpend, 999_999_999), usedPct: int(v.usedPct, 100), minQty: int(v.minQty, 999),
      expiresText: v.expires?.slice(0, 40), expiresDate: v.expiresDate, startsText: v.starts?.slice(0, 40),
      saleLabel: v.sale?.slice(0, 40), appliesText: v.applies?.slice(0, 120),
      shopId, shopName: page.shopName?.slice(0, 100) || undefined,
      productKey: link?.productKey, productTitle: link?.productKey ? page.name?.slice(0, 120) || undefined : undefined,
    };
    for (const k of Object.keys(data)) if (data[k] === undefined) delete data[k];
    out.push({ id, data });
    if (out.length >= MAX_SCRAPE) break;
  }
  return out;
}

// Trang shop (shopee.vn/<tên-shop>) không có nút "Xem Shop" nên reader không thấy tên shop → lấy từ tiêu đề tab,
// ví dụ "Shop Mèo, Cửa hàng trực tuyến | Shopee Việt Nam". Trang khác (trang chủ, tìm kiếm, sản phẩm) → null.
export function shopNameFromTitle(title: string | undefined, pageUrl: string): string | null {
  let path = '';
  try { path = new URL(pageUrl).pathname; } catch { return null; }
  if (!/^\/[A-Za-z0-9._-]+\/?$/.test(path) || /-i\.\d+\.\d+/.test(path) || /^\/(m|search|cart|user|mall|daily_discover|flash_sale|product)\b/i.test(path)) return null;
  const name = (title || '').split('|')[0].replace(/,?\s*cửa hàng trực tuyến.*$/i, '').replace(/\s+/g, ' ').trim();
  return name && !/^shopee/i.test(name) ? name.slice(0, 100) : null;
}

// token liên kết ="<uid tài khoản>:<uid ẩn danh của extension>" (lib/firebaseApi.ts)
export function ownerOf(token?: string): { uid: string; sid: string } | null {
  const i = token?.indexOf(':') ?? -1;
  return token && i > 0 ? { uid: token.slice(0, i), sid: token.slice(i + 1) } : null;
}

// Tài khoản đã liên kết là staff/admin? null nếu không phải hoặc phiên không còn đúng.
export async function staffRoleOf(token?: string): Promise<StaffRole | null> {
  const ids = ownerOf(token);
  if (!ids) return null;
  const { currentUser, db } = await import('../../lib/firebase');
  const user = await currentUser();
  if (!user || user.uid !== ids.sid) return null;
  const { doc, getDoc } = await import('firebase/firestore');
  const role = (await getDoc(doc(db, 'users', ids.uid))).get('role');
  return role === 'staff' || role === 'admin' ? role : null;
}

export async function uploadVouchers(docs: VoucherDoc[]): Promise<number> {
  if (!docs.length) return 0;
  const { db } = await import('../../lib/firebase');
  const { doc, serverTimestamp, writeBatch } = await import('firebase/firestore');
  const batch = writeBatch(db);
  for (const d of docs) batch.set(doc(db, 'shopeeVouchers', d.id), { ...d.data, lastSeenAt: serverTimestamp() });
  await batch.commit();
  return docs.length;
}

// Cào voucher từ trang chủ (bản Lab + Firebase, chỉ staff/admin): người dùng đứng ở trang chủ Shopee, bấm 1 nút →
// gom link sản phẩm đang hiện → mỗi shop lấy 1 sản phẩm → background mở lần lượt từng sản phẩm ở tab nền,
// đọc voucher như nút cào thường, ghi shopeeVouchers, đóng tab. Một tab mỗi lần, nghỉ giữa các trang, gặp
// captcha / trang đăng nhập thì đưa tab lên và chờ người dùng xác minh rồi làm tiếp. Không bấm "Lưu" mã, không đặt hàng.

export const CRAWL_KEY = 'wib_voucher_crawl';
export const CRAWL_MAX_SHOPS = 20;
export const CRAWL_GAP_MS = 6_000;      // thời gian tối thiểu giữa hai lần mở trang

export interface CrawlState {
  running: boolean;
  total: number;
  done: number;
  pushed: number;
  failed?: number;          // số shop bị bỏ qua vì lỗi tải trang
  current?: string;
  error?: string;
  stopRequested?: boolean;
  finishedAt?: number;
}

export interface ProductLink { url: string; shopId: string; }

// Trang chủ: đường dẫn "/" (có thể kèm query).
export function isShopeeHome(url?: string): boolean {
  try { const u = new URL(url ?? ''); return /(^|\.)shopee\.vn$/i.test(u.hostname) && (u.pathname === '/' || u.pathname === ''); } catch { return false; }
}

// Trang Shopee chặn bot / bắt đăng nhập → chờ người dùng xác minh, không tự vượt.
export function isBlockedUrl(url?: string): boolean {
  return /shopee\.vn\/(verify\/|buyer\/login|captcha)/i.test(url ?? '');
}

// Chèn vào trang chủ bằng chrome.scripting.executeScript → PHẢI tự chứa (không import, không biến ngoài hàm).
// Cuộn xuống vài màn hình để Shopee tải thêm "Gợi ý hôm nay", rồi gom link sản phẩm (…-i.<shop>.<item>, /product/<shop>/<item>).
export async function collectProductLinks(): Promise<{ url: string; shopId: string }[]> {
  const startY = window.scrollY;
  for (let i = 0; i < 6; i++) { window.scrollBy(0, window.innerHeight); await new Promise((r) => setTimeout(r, 700)); }
  window.scrollTo(0, startY);
  const out: { url: string; shopId: string }[] = [];
  const seen = new Set<string>();
  for (const a of Array.from(document.querySelectorAll('a[href]'))) {
    let u: URL;
    try { u = new URL((a as HTMLAnchorElement).href, location.href); } catch { continue; }
    if (!/(^|\.)shopee\.vn$/i.test(u.hostname)) continue;
    const m = u.pathname.match(/-i\.(\d+)\.(\d+)\/?$/) || u.pathname.match(/^\/product\/(\d+)\/(\d+)\/?$/);
    if (!m) continue;
    const key = `${m[1]}.${m[2]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ url: `${u.origin}${u.pathname}`, shopId: m[1] });
  }
  return out;
}

// Mỗi shop một sản phẩm (mã của shop giống nhau ở mọi sản phẩm của shop), giữ thứ tự trên trang, tối đa `max`.
export function pickShops(links: ProductLink[], max = CRAWL_MAX_SHOPS): ProductLink[] {
  const seen = new Set<string>();
  const out: ProductLink[] = [];
  for (const l of links) {
    if (seen.has(l.shopId)) continue;
    seen.add(l.shopId);
    out.push(l);
    if (out.length >= max) break;
  }
  return out;
}


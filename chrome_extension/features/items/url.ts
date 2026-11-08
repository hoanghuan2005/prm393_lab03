// Chuẩn hoá link (Build Plan 7.2, handoff 9.1): chỉ HTTPS, đúng host Shopee; productKey = shopee:<shopId>:<itemId>.
const HOSTS = new Set(['shopee.vn', 'www.shopee.vn']);
const SHORT = new Set(['s.shopee.vn', 'shp.ee', 'vn.shp.ee']);

export interface ShopeeLink { originalUrl: string; url?: string; productKey?: string; isShortLink: boolean; }

export function parseShopeeLink(raw: string): ShopeeLink | null {
  let u: URL;
  try { u = new URL(raw.trim()); } catch { return null; }
  if (u.protocol !== 'https:') return null;
  if (SHORT.has(u.hostname)) return { originalUrl: u.href, isShortLink: true }; // không tự mở link rút gọn
  if (!HOSTS.has(u.hostname)) return null;
  const m = u.pathname.match(/-i\.(\d+)\.(\d+)\/?$/) ?? u.pathname.match(/\/product\/(\d+)\/(\d+)/);
  if (!m) return null;
  return { originalUrl: u.href, url: `https://shopee.vn/product/${m[1]}/${m[2]}`, productKey: `shopee:${m[1]}:${m[2]}`, isShortLink: false };
}

export function cleanTabTitle(t?: string) { return (t ?? '').replace(/\s*[|\-–—]\s*Shopee.*$/i, '').trim(); }
export const shopIdOf = (productKey?: string) => productKey?.split(':')[1];

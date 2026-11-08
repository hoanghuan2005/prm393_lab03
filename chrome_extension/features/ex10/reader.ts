// readPage() được chèn vào trang bằng chrome.scripting.executeScript({ func: readPage }) — CHỈ ở bản Lab EX-10,
// chỉ khi người dùng bấm icon. Hàm PHẢI tự chứa (không import, không biến ngoài hàm).
// Chỉ đọc những gì đang hiển thị: tên, ảnh, giá của loại đang chọn, loại đang chọn, (tùy chọn) chữ voucher.
// Không gọi mạng, không đọc cookie / giỏ hàng / kho voucher, không bấm gì trên trang.

export interface PriceCandidate {
  amount: number; amountMax?: number; text: string;
  source: 'dom' | 'json-ld' | 'meta';
  struck?: boolean; fontSize?: number;
}
export interface VariantPick { group: string | null; value: string; image?: string; }
export interface PageRead {
  url: string; host: string; title: string;
  name: string | null; nameSource: 'json-ld' | 'og:title' | 'h1' | 'title' | null;
  image: string | null; imageSource: 'variant' | 'json-ld' | 'og:image' | null;
  priceCandidates: PriceCandidate[];   // [0] = giá đang hiển thị lớn nhất (thường là giá của loại đang chọn)
  originalPrice: number | null;         // giá gạch ngang nếu có
  variants: VariantPick[];              // loại đang chọn, mỗi nhóm một giá trị
  variantText: string;                  // "Cá Trắm Cỏ" hoặc "Đen – M"
  variantMissing: string[];             // nhóm phân loại chưa chọn
  voucherTexts: string[];
  flashSale: FlashSaleRead | null;      // Flash Sale đang hiển thị trên trang
  shopName: string | null;              // tên shop bán (khung có nút "Xem Shop", dự phòng JSON-LD offers.seller)
  productRating: number | null;         // số sao sản phẩm (JSON-LD aggregateRating hoặc trên trang)
  productRatingCount: string | null;    // số lượt đánh giá sản phẩm, vd "2,3k"
  shopRating: string | null;            // đánh giá của shop trong khung "Xem Shop"
  notes: string[];
}
export interface FlashSaleRead { kind: 'upcoming' | 'ongoing'; startsAt?: string; endsAt?: string; text: string; isFlash: boolean; }

// maxVouchers: mặc định 40 (người dùng); công cụ cào voucher cho Admin đọc nhiều hơn.
export function readPage(opts: { vouchers?: boolean; maxVouchers?: number } = {}): PageRead {
  const out: PageRead = {
    url: location.href, host: location.hostname, title: document.title,
    name: null, nameSource: null, image: null, imageSource: null,
    priceCandidates: [], originalPrice: null, variants: [], variantText: '', variantMissing: [], voucherTexts: [], flashSale: null, shopName: null, productRating: null, productRatingCount: null, shopRating: null, notes: [],
  };
  const str = (v: unknown) => (typeof v === 'string' ? v.trim() : '');
  const norm = (s: string | null | undefined) => (s || '').replace(/\s+/g, ' ').trim();
  const toVnd = (v: unknown): number | null => {
    const n = typeof v === 'number' ? v : parseFloat(String(v ?? '').replace(/[^\d.]/g, ''));
    return isFinite(n) && n > 0 ? Math.round(n) : null;
  };
  const cleanTitle = (t: string) => t.replace(/\s*[|\-–—]\s*Shopee.*$/i, '').trim();
  const hidden = (el: Element | null): boolean => {
    for (let e = el; e; e = e.parentElement) {
      if ((e as HTMLElement).hidden) return true;
      const cs = getComputedStyle(e);
      if (cs.display === 'none' || cs.visibility === 'hidden') return true;
    }
    return false;
  };
  const skip = (el: Element) => /^(SCRIPT|STYLE|NOSCRIPT|SVG|PATH)$/i.test(el.tagName) || !!el.closest('header, footer, nav');
  const all = Array.from(document.body.querySelectorAll('*')).slice(0, 8000);

  // 1) JSON-LD / meta: chỉ dùng cho tên, ảnh, và làm giá DỰ PHÒNG (đây là giá chung của sản phẩm, có thể là giá thấp nhất)
  const products: any[] = [];
  const walk = (o: any): void => {
    if (!o || typeof o !== 'object') return;
    if (Array.isArray(o)) { o.forEach(walk); return; }
    const t = o['@type'];
    if (t === 'Product' || (Array.isArray(t) && t.includes('Product'))) products.push(o);
    if (o['@graph']) walk(o['@graph']);
  };
  document.querySelectorAll('script[type="application/ld+json"]').forEach((s) => { try { walk(JSON.parse(s.textContent || '')); } catch { /* bỏ qua */ } });
  const p = products[0];
  const fallback: PriceCandidate[] = [];
  if (p) {
    if (str(p.name)) { out.name = str(p.name); out.nameSource = 'json-ld'; }
    const img = Array.isArray(p.image) ? p.image[0] : p.image;
    const imgUrl = typeof img === 'object' && img ? str((img as any).url) : str(img);
    if (imgUrl) { out.image = imgUrl; out.imageSource = 'json-ld'; }
    const offers = Array.isArray(p.offers) ? p.offers[0] : p.offers;
    if (offers) {
      const low = toVnd(offers.lowPrice), high = toVnd(offers.highPrice), one = toVnd(offers.price);
      if (low && high && low !== high) fallback.push({ amount: low, amountMax: high, text: `${low} - ${high}`, source: 'json-ld' });
      else if (one ?? low) fallback.push({ amount: (one ?? low) as number, text: String(one ?? low), source: 'json-ld' });
    }
  }
  const meta = (n: string) => str(document.querySelector(`meta[property="${n}"], meta[name="${n}"]`)?.getAttribute('content'));
  if (!out.name && meta('og:title')) { out.name = cleanTitle(meta('og:title')); out.nameSource = 'og:title'; }
  if (!out.image && meta('og:image')) { out.image = meta('og:image'); out.imageSource = 'og:image'; }
  const mp = toVnd(meta('product:price:amount') || meta('og:price:amount'));
  if (mp) fallback.push({ amount: mp, text: String(mp), source: 'meta' });
  if (!out.name) { const h1 = norm(document.querySelector('h1')?.textContent); if (h1) { out.name = h1; out.nameSource = 'h1'; } }
  if (!out.name && out.title) { out.name = cleanTitle(out.title); out.nameSource = 'title'; }

  // 2) Giá ĐANG HIỂN THỊ (phản ánh loại đang chọn). Xét ở mức phần tử vì Shopee tách "20.000" và "đ" ra hai thẻ.
  const num = String.raw`\d{1,3}(?:[.,]\d{3})+|\d{4,}`;
  const one = String.raw`[₫đ]?\s*(?:${num})\s*[₫đ]?`;
  const priceOnly = new RegExp(String.raw`^(${one})(?:\s*[-–]\s*(${one}))?$`);
  const parseOne = (s: string) => toVnd((s.match(new RegExp(num)) || [''])[0].replace(/[.,]/g, ''));
  const matches: { el: Element; c: PriceCandidate }[] = [];
  for (const el of all) {
    if (skip(el)) continue;
    const t = norm(el.textContent);
    if (!t || t.length > 40 || !/[₫đ]/.test(t)) continue;
    const m = t.match(priceOnly);
    if (!m || hidden(el)) continue;
    const a = parseOne(m[1]); const b = m[2] ? parseOne(m[2]) : null;
    if (!a) continue;
    let fs = 0;
    for (const d of [el, ...Array.from(el.querySelectorAll('*'))]) fs = Math.max(fs, parseFloat(getComputedStyle(d).fontSize) || 0);
    let struck = false;
    for (let e: Element | null = el, k = 0; e && k < 4; e = e.parentElement, k++) {
      const cs = getComputedStyle(e);
      if ((cs.textDecorationLine || cs.textDecoration || '').includes('line-through') || /^(DEL|S|STRIKE)$/.test(e.tagName)) { struck = true; break; }
    }
    matches.push({ el, c: { amount: Math.min(a, b ?? a), amountMax: b && b !== a ? Math.max(a, b) : undefined, text: t, source: 'dom', struck, fontSize: fs } });
  }
  // giữ phần tử trong cùng: bỏ phần tử nào chứa một phần tử khớp khác
  const inner = matches.filter((x) => !matches.some((y) => y !== x && x.el.contains(y.el)));
  const live = inner.filter((x) => !x.c.struck).sort((a, b) => (b.c.fontSize ?? 0) - (a.c.fontSize ?? 0)).map((x) => x.c);
  const struckList = inner.filter((x) => x.c.struck).map((x) => x.c);
  out.originalPrice = struckList[0]?.amount ?? null;
  const seen = new Set<string>();
  for (const c of [...live.slice(0, 3), ...fallback, ...struckList.slice(0, 1)]) {
    const k = `${c.amount}-${c.amountMax ?? ''}-${c.struck ? 1 : 0}`;
    if (seen.has(k)) continue; seen.add(k); out.priceCandidates.push(c);
  }
  if (!live.length && fallback.length) out.notes.push('Không thấy giá đang hiển thị; đang dùng giá chung của sản phẩm (có thể là giá thấp nhất trong các loại).');
  if (!out.priceCandidates.length) out.notes.push('Không đọc được giá trên trang. Bạn có thể bỏ qua.');

  // 3) Loại (phân loại) đang chọn — không phụ thuộc tên class của Shopee:
  //    nút lựa chọn được nhóm theo khung cha; nút đang chọn có aria-checked/selected/pressed,
  //    class chứa "selected/active/checked", hoặc là nút duy nhất có kiểu viền/màu khác cả nhóm.
  const actionRe = /giỏ hàng|mua ngay|chia sẻ|tố cáo|theo dõi|chat|xem shop|đã thích|yêu thích|^\+$|^-$|^−$|^(giảm|tăng)( số lượng)?$|increase|decrease/i;
  const optEls = all.filter((el) => {
    if (skip(el)) return false;
    const isOpt = el.tagName === 'BUTTON' || ['radio', 'option'].includes(el.getAttribute('role') || '')
      || el.hasAttribute('aria-checked') || el.hasAttribute('aria-selected') || el.hasAttribute('aria-pressed');
    if (!isOpt) return false;
    const text = norm(el.textContent);                    // nút phân loại luôn có chữ; nút chỉ có icon (chia sẻ, ảnh) bị bỏ
    const label = norm(el.getAttribute('aria-label')) || text;
    return !!text && label.length <= 40 && !actionRe.test(label) && !actionRe.test(text) && !/^\d+$/.test(text) && !hidden(el);
  });
  const groups = new Map<Element, Element[]>();
  for (const el of optEls) { const g = el.parentElement; if (g) groups.set(g, [...(groups.get(g) || []), el]); }
  // Dấu hiệu "đang chọn", xét lần lượt; chỉ nhận khi đúng MỘT nút trong nhóm có dấu hiệu đó.
  const ariaOn = (el: Element) => ['aria-checked', 'aria-selected', 'aria-pressed'].some((a) => el.getAttribute(a) === 'true');
  // Xét TỪNG class: "selection-box-selected" là chọn; "selection-box-unselected" KHÔNG phải chọn.
  const classOn = (el: Element) => Array.from((el as HTMLElement).classList || []).some((c) =>
    /(^|[-_])(selected|active|checked|current|chosen)$/i.test(c) && !/(un|in|not)[-_]?(selected|active|checked)|disabled/i.test(c));
  const sig = (el: Element) => { const cs = getComputedStyle(el); return [cs.borderTopColor, cs.color, cs.backgroundColor, cs.outlineColor, cs.boxShadow].join('|'); };
  const shape = (el: Element) => String(el.querySelectorAll('*').length);   // nút đang chọn thường có thêm dấu tick ở góc
  const uniqueBy = (items: Element[], key: (e: Element) => string) => {
    const count = new Map<string, number>();
    items.forEach((i) => count.set(key(i), (count.get(key(i)) || 0) + 1));
    if (count.size < 2) return [];
    const odd = items.filter((i) => count.get(key(i)) === 1);
    return odd.length === 1 ? odd : [];
  };
  const pickSelected = (items: Element[]): Element | null => {
    for (const test of [ariaOn, classOn]) { const on = items.filter(test); if (on.length === 1) return on[0]; }
    if (items.length >= 3) {
      const bySig = uniqueBy(items, sig); if (bySig.length) return bySig[0];
      const byShape = uniqueBy(items, shape); if (byShape.length) return byShape[0];
    } else if (items.length === 2) {
      const bySig = uniqueBy(items, sig), byShape = uniqueBy(items, shape);
      // 2 nút: chỉ tin khi một nút có thêm phần tử (dấu tick) VÀ khác kiểu
      if (byShape.length && bySig.length) {
        const more = items.find((i) => i.querySelectorAll('*').length === Math.max(...items.map((x) => x.querySelectorAll('*').length)));
        return more ?? null;
      }
    }
    return null;
  };
  const labelOf = (g: Element): string | null => {
    for (let n: Element | null = g, k = 0; n && k < 3; n = n.parentElement, k++) {
      const prev = n.previousElementSibling;
      const t = norm(prev?.textContent);
      if (t && t.length <= 30 && !/\d{3}/.test(t)) return t;
    }
    return null;
  };
  for (const [g, items] of groups) {
    if (items.length < 2 && !labelOf(g)) continue;
    if (g.querySelector('input')) continue;                 // nhóm tăng/giảm số lượng
    const sel = pickSelected(items);
    const picked = sel ? [sel] : [];
    const group = labelOf(g);
    if (!picked.length) { if (group && items.length >= 2) out.variantMissing.push(group); continue; }
    const el = picked[0];
    const value = norm(el.getAttribute('aria-label')) || norm(el.textContent);
    const image = (el.querySelector('img') as HTMLImageElement | null)?.src || undefined;
    out.variants.push({ group, value, image });
  }
  out.variantText = out.variants.map((v) => v.value).join(' – ');
  const vImg = out.variants.find((v) => v.image)?.image;
  if (vImg) { out.image = vImg; out.imageSource = 'variant'; }
  if (out.variantMissing.length) out.notes.push(`Chưa chọn ${out.variantMissing.join(', ')} trên trang nên giá có thể chưa đúng loại. Chọn loại rồi bấm icon lại.`);

  // 4) Voucher đang hiển thị (CHỈ khi người dùng bật)
  if (opts.vouchers) {
    const unitSrc = 'giảm\\s*(?:₫|đ)?\\s*\\d|giảm\\s*\\d+\\s*%|miễn phí vận chuyển|freeship|free ship|hoàn\\s*[\\d.,]+\\s*(?:k)?\\s*%?\\s*xu';
    const unitRe = new RegExp(unitSrc, 'i'), countRe = new RegExp(unitSrc, 'gi');
    const textOf = (el: Element) => {
      const parts: string[] = []; const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT); let n: Node | null;
      while ((n = w.nextNode())) { const t = (n.textContent || '').trim(); if (t) parts.push(t); }
      return norm(parts.join(' '));
    };
    const units = all.filter((el) => {
      if (skip(el)) return false;
      const t = textOf(el);
      // thẻ voucher trong danh sách đã mở có thêm điều kiện, HSD, "Đã dùng x%", nút Lưu → cho phép dài hơn
      const maxLen = /tối thiểu|hsd|hạn|hiệu lực|áp dụng|đã dùng|lưu|tối đa/i.test(t) ? 240 : 110;
      return !!t && t.length <= maxLen && unitRe.test(t) && (t.match(countRe) || []).length <= 1 && !hidden(el);
    });
    const set = new Set(units);
    for (const el of units) {
      let nested = false;
      for (let a = el.parentElement; a; a = a.parentElement) if (set.has(a)) { nested = true; break; }
      if (nested) continue;
      const t = textOf(el);
      if (!out.voucherTexts.includes(t)) out.voucherTexts.push(t);
      if (out.voucherTexts.length >= (opts.maxVouchers ?? 40)) break;
    }
  }
  // 5) Flash Sale / đợt giảm giá đang hiển thị: "BẮT ĐẦU SAU 15:00, 26 Thg 10", "Kết thúc trong 01:23:45".
  //    Chỉ đọc giờ hiển thị; trước giờ mở bán Shopee thường không hiện giá Flash Sale.
  {
    const startRe = /bắt\s*đầu\s*(?:sau|lúc|vào|từ)?\s*(\d{1,2})\s*[:h]\s*(\d{2})(?:\s*,?\s*(?:ngày\s*)?(\d{1,2})\s*(?:thg|tháng|\/)\s*(\d{1,2}))?/i;
    const endRe = /kết\s*thúc\s*(?:trong|sau)\s*(\d{1,2})\s*:\s*(\d{2})\s*:\s*(\d{2})/i;
    const hits: { el: Element; t: string }[] = [];
    for (const el of all) {
      if (skip(el)) continue;
      const t = norm(el.textContent);
      if (!t || t.length > 90 || !(startRe.test(t) || endRe.test(t)) || hidden(el)) continue;
      hits.push({ el, t });
    }
    const innerHits = hits.filter((x) => !hits.some((y) => y !== x && x.el.contains(y.el)));
    const h = innerHits[0];
    if (h) {
      let isFlash = /flash\s*sale/i.test(h.t);
      for (let e: Element | null = h.el, k = 0; e && k < 4 && !isFlash; e = e.parentElement, k++) isFlash = /flash/i.test(e.outerHTML.slice(0, 3000));
      const now = new Date();
      const ms = h.t.match(startRe), me = h.t.match(endRe);
      if (ms) {
        const d = new Date(now);
        d.setSeconds(0, 0);
        d.setHours(parseInt(ms[1], 10), parseInt(ms[2], 10));
        if (ms[3] && ms[4]) {
          d.setMonth(parseInt(ms[4], 10) - 1, parseInt(ms[3], 10));
          if (d.getTime() < now.getTime() - 180 * 86_400_000) d.setFullYear(d.getFullYear() + 1); // tháng 1 khi đang tháng 12
        } else if (/ngày\s*mai/i.test(h.t)) d.setDate(d.getDate() + 1);
        else if (d.getTime() < now.getTime()) d.setDate(d.getDate() + 1);
        out.flashSale = { kind: 'upcoming', startsAt: d.toISOString(), text: h.t, isFlash };
      } else if (me) {
        const secs = parseInt(me[1], 10) * 3600 + parseInt(me[2], 10) * 60 + parseInt(me[3], 10);
        out.flashSale = { kind: 'ongoing', endsAt: new Date(now.getTime() + secs * 1000).toISOString(), text: h.t, isFlash };
      }
    }
  }
  // 6) Tên shop: khung shop trên trang sản phẩm có nút "Xem Shop"; tên shop là dòng chữ đầu tiên trong khung đó
  //    (bỏ trạng thái Online, nút Chat, nhãn và số liệu đánh giá). Dự phòng: offers.seller.name trong JSON-LD.
  {
    const offer = p ? (Array.isArray(p.offers) ? p.offers[0] : p.offers) : null;
    const seller = offer && typeof offer.seller === 'object' ? str(offer.seller?.name) : '';
    // Chữ trạng thái / nhãn / số liệu trong khung shop, không phải tên shop (vd. "Không có sẵn", "Online 5 phút trước")
    const noise = /^(xem shop|chat ngay|chat|mall|shopee mall|yêu thích\+?|shop yêu thích|preferred\+?|chính hãng)$|đánh giá|sản phẩm|phản hồi|tham gia|theo dõi|có sẵn|hết hàng|không khả dụng|tạm nghỉ|online|hoạt động|truy cập|trước$|^[\d.,%\s]+k?$/i;
    const btn = all.find((el) => !skip(el) && /^xem shop$/i.test(norm(el.textContent)) && !hidden(el));
    const pathOf = (a: Element | null | undefined) => {
      try { return a ? new URL((a as HTMLAnchorElement).href, location.href).pathname.replace(/\/+$/, '') : ''; } catch { return ''; }
    };
    // Nút "Xem Shop" là link tới shopee.vn/<tên-đăng-nhập-shop>
    const shopPath = pathOf(btn?.closest('a') ?? btn?.querySelector('a'));
    const handle = /^\/[A-Za-z0-9._-]{2,60}$/.test(shopPath) ? shopPath.slice(1) : '';
    const firstName = (root: Element) => {
      for (const el of Array.from(root.querySelectorAll('*'))) {
        if (el.children.length || skip(el)) continue;
        const t = norm(el.textContent);
        if (t.length >= 2 && t.length <= 60 && !noise.test(t) && !hidden(el)) return t;
      }
      return '';
    };
    let found = '';
    for (let box = btn?.parentElement ?? null, k = 0; box && k < 4 && !found; box = box.parentElement, k++) {
      if (norm(box.textContent).length > 600) break;   // đã ra khỏi khung shop
      // ưu tiên chữ nằm trong link tới cùng shop (ảnh đại diện + tên shop), rồi mới tới cả khung
      for (const a of Array.from(box.querySelectorAll('a[href]'))) {
        if (handle && pathOf(a) === shopPath && (found = firstName(a))) break;
      }
      // khung đã chứa tiêu đề sản phẩm (h1) / cả trang → không tìm cả khung nữa, dễ lấy nhầm chữ của sản phẩm
      if (!found && k < 3 && box !== document.body && !box.querySelector('h1')) found = firstName(box);
    }
    out.shopName = (seller || found || handle).slice(0, 60) || null;
  }
  // 7) Đánh giá: sản phẩm (số sao + số lượt) và shop. Shopee hiện cặp "giá trị" + nhãn "Đánh Giá" cạnh nhau;
  //    nhãn nằm trong khung có nút "Xem Shop" là của shop, nhãn còn lại là của sản phẩm.
  {
    const agg = p && typeof p.aggregateRating === 'object' ? p.aggregateRating : null;
    const starOf = (s: string) => { const m = s.match(/^([0-5](?:[.,]\d{1,2})?)$/); const n = m ? parseFloat(m[1].replace(',', '.')) : NaN; return n > 0 && n <= 5 ? Math.round(n * 10) / 10 : null; };
    if (agg) {
      out.productRating = starOf(String(agg.ratingValue ?? '').trim());
      const c = String(agg.ratingCount ?? agg.reviewCount ?? '').trim();
      if (c && c !== '0') out.productRatingCount = c.slice(0, 20);
    }
    const shopBtn = all.find((el) => !skip(el) && /^xem shop$/i.test(norm(el.textContent)) && !hidden(el));
    let shopBox: Element | null = null;
    for (let b = shopBtn?.parentElement ?? null, k = 0; b && k < 5; b = b.parentElement, k++) { shopBox = b; if (/đánh giá/i.test(b.textContent || '')) break; }
    const labels = all.filter((el) => !el.children.length && !skip(el) && /^đánh giá$/i.test(norm(el.textContent)) && !hidden(el));
    const valueOf = (lab: Element): string => {
      for (let n: Element | null = lab, k = 0; n && k < 2; n = n.parentElement, k++) {
        for (const sib of [n.previousElementSibling, n.nextElementSibling]) {
          const t = norm(sib?.textContent);
          if (t && t.length <= 12 && /\d/.test(t)) return t;
        }
      }
      return '';
    };
    for (const lab of labels) {
      const v = valueOf(lab);
      if (!v) continue;
      if (shopBox && shopBox.contains(lab)) { if (!out.shopRating) out.shopRating = v; continue; }
      if (!out.productRatingCount) out.productRatingCount = v;
      // số sao nằm ngay trước khối "số lượt + Đánh Giá" (vd "4.9 ★★★★★ | 2,3k Đánh Giá")
      for (let n: Element | null = lab, k = 0; n && k < 4 && out.productRating == null; n = n.parentElement, k++) {
        const leaves = Array.from(n.parentElement?.querySelectorAll('*') ?? []).filter((e) => !e.children.length && !hidden(e) && norm(e.textContent) !== v); // bỏ chính số lượt
        for (const e of leaves) { const s = starOf(norm(e.textContent)); if (s != null) { out.productRating = s; break; } }
      }
    }
    // Dự phòng: khung "ĐÁNH GIÁ SẢN PHẨM" ghi "4.9 trên 5"
    if (out.productRating == null) {
      for (const el of all) {
        if (el.children.length > 3 || skip(el)) continue;
        const m = norm(el.textContent).match(/^([0-5](?:[.,]\d)?)\s*trên\s*5$/i);
        if (m && !hidden(el)) { out.productRating = starOf(m[1]); break; }
      }
    }
  }
  return out;
}

// Phân tích chữ voucher ĐANG HIỂN THỊ trên trang (kể cả danh sách voucher người dùng tự bấm mở) và ước tính giá sau voucher.
// Chỉ là ƯỚC TÍNH để tham khảo cá nhân (handoff 9.1: PriceType.afterVoucher). Không bấm "Lưu", không áp mã,
// không đọc kho voucher hay trang thanh toán.

// bundle: "Combo khuyến mãi" – "Mua 2 & giảm 5%", chỉ áp dụng khi mua nhiều món, không tính cho 1 món
export type VoucherKind = 'amount' | 'percent' | 'shipping' | 'coin' | 'bundle' | 'unknown';
// payment: ưu đãi theo phương thức thanh toán (ShopeePay, SPayLater, thẻ / ngân hàng) – chỉ khi trả bằng cách đó
export type VoucherScope = 'shop' | 'platform' | 'payment' | 'unknown';

export interface ParsedVoucher {
  raw: string;
  kind: VoucherKind;
  scope: VoucherScope;
  amount?: number;        // giảm cố định (VND) — hoặc số xu hoàn
  percent?: number;       // giảm % — hoặc % hoàn xu
  cap?: number;           // giảm tối đa (VND)
  minSpend?: number;      // đơn tối thiểu (VND)
  saved?: boolean;        // true "Đã lưu", false "Lưu" (chưa lưu), undefined: không rõ
  expires?: string;       // "31/10" hoặc "còn 2 ngày"
  usedPct?: number;       // "Đã dùng 80%"
  unavailable?: boolean;  // hết lượt / hết hạn
  minQty?: number;        // combo: số món tối thiểu ("Mua 2")
  expiresDate?: string;   // "2026-10-31" – chỉ khi trang ghi đủ ngày/tháng/năm
  starts?: string;        // "00:00 11/11" hoặc "còn 2 giờ" – mã chưa tới giờ dùng
  sale?: string;          // đợt sale ghi trên mã: "11.11", "Sale Sinh Nhật", "Flash Sale"…
  applies?: string;       // "Áp dụng cho …" – shop / sản phẩm dùng được, nếu trang ghi
}

const SUFFIX: Record<string, number> = { k: 1_000, nghìn: 1_000, ngàn: 1_000, tr: 1_000_000, triệu: 1_000_000 };
export function parseMoneyToken(num: string, suffix?: string): number | null {
  if (!num) return null;
  const sfx = suffix?.toLowerCase();
  const v = sfx && SUFFIX[sfx] ? parseFloat(num.replace(',', '.')) * SUFFIX[sfx] : parseInt(num.replace(/[.,]/g, ''), 10);
  return isFinite(v) && v >= 0 ? Math.round(v) : null;
}

const MONEY = String.raw`(?:₫|đ)?\s*(\d[\d.,]*)\s*(k|tr|triệu|nghìn|ngàn)?\b`;
const reCap = new RegExp(String.raw`(?:tối đa|toi da)\s*${MONEY}`, 'i');
const reMin = new RegExp(String.raw`(?:đơn(?:\s*hàng)?\s*tối\s*thiểu|tối\s*thiểu|đơn(?:\s*hàng)?\s*từ)\s*${MONEY}`, 'i');
const reAmount = new RegExp(String.raw`giảm\s*${MONEY}`, 'i');
const rePercent = /giảm\s*(\d{1,2})\s*%/i;
const reShip = /vận chuyển|freeship|free ship|miễn phí ship/i;
const reCoinPct = /hoàn\s*(\d{1,2})\s*%\s*(?:xu|shopee xu)/i;
const reCoinAmt = new RegExp(String.raw`hoàn\s*${MONEY}\s*xu`, 'i');
const reExpDate = /(?:hsd|hạn sử dụng|có hiệu lực đến|hiệu lực đến)\s*:?\s*(\d{1,2})[./-](\d{1,2})/i;
const reExpLeft = /(?:sắp hết hạn|hết hạn)\s*:?\s*còn\s*(\d+)\s*(giờ|ngày|phút)/i;
const reExpFull = /(?:hsd|hạn sử dụng|có hiệu lực đến|hiệu lực đến|đến)\s*:?\s*(?:(\d{1,2}:\d{2})\s*,?\s*)?(\d{1,2})[./-](\d{1,2})[./-](20\d{2})/i;
const reStartAt = /(?:có hiệu lực từ|hiệu lực từ|bắt đầu từ|áp dụng từ|dùng từ)\s*:?\s*(?:(\d{1,2}:\d{2})\s*,?\s*)?(\d{1,2})[./-](\d{1,2})/i;
const reStartIn = /(?:có hiệu lực sau|hiệu lực sau|bắt đầu sau|dùng được sau)\s*:?\s*(\d+)\s*(giờ|ngày|phút)/i;
const reApplies = /((?:chỉ\s*)?áp dụng (?:cho|tại|với)\s*[^.;|]{3,100}?)(?=\s*(?:hsd|hạn|có hiệu lực|đã dùng|đơn tối thiểu|tối thiểu|lưu|điều kiện|$|[.;|]))/i;
// không nhận số tiền / phần trăm ("₫1.1tr", "2.2%") và ngày HSD / hiệu lực ("HSD: 12.12") là đợt sale
const reSaleDouble = /(?:^|[^\d.,₫đ:/-])(\d{1,2})[.](\d{1,2})(?![\d.,:/-]|\s*(?:k|tr|triệu|nghìn|ngàn|đ|₫|%)(?![a-zà-ỹ]))/gi;
const reDateLead = /(?:hsd|hạn(?: sử dụng)?|đến|từ|hiệu lực(?: đến| từ)?|sau)\s*:?\s*(?:\d{1,2}:\d{2}\s*,?\s*)?$/i;
const SALE_WORDS: [RegExp, string][] = [
  [/sale\s*sinh\s*nhật|sinh\s*nhật\s*shopee/i, 'Sale Sinh Nhật'], [/siêu\s*sale/i, 'Siêu Sale'], [/flash\s*sale/i, 'Flash Sale'],
  [/payday|ngày\s*lương|sale\s*giữa\s*tháng/i, 'Sale Giữa Tháng'], [/black\s*friday/i, 'Black Friday'],
  [/sale\s*tết|tết\s*sale/i, 'Sale Tết'], [/brand\s*day|super\s*brand/i, 'Brand Day'], [/mã\s*live|live\s*(?:sale|độc quyền)/i, 'Live'],
  [/mã\s*video|video\s*(?:sale|độc quyền)/i, 'Video'],
];
// Đợt sale ghi trên mã: "11.11", "12.12" (ngày trùng tháng) và tên đợt → nhãn ngắn, ví dụ "11.11 · Siêu Sale"
export function saleLabelOf(raw: string): string | undefined {
  const parts: string[] = [];
  for (const m of raw.matchAll(reSaleDouble)) {
    const d = parseInt(m[1], 10), mo = parseInt(m[2], 10);
    const at = (m.index ?? 0) + m[0].indexOf(`${m[1]}.${m[2]}`);
    if (reDateLead.test(raw.slice(Math.max(0, at - 30), at))) continue;
    if (d === mo && d >= 1 && d <= 12) { parts.push(`${d}.${mo}`); break; }
  }
  for (const [re, label] of SALE_WORDS) if (re.test(raw)) parts.push(label);
  return parts.length ? parts.slice(0, 3).join(' · ') : undefined;
}
const reUsed = /đã dùng\s*(\d{1,3})\s*%/i;
const reBundle = /(?:mua|chọn)\s*(\d+)\s*(?:sản phẩm|món|cái)?\s*(?:&|và|,|để|được|thì)?\s*giảm|combo\s*khuyến\s*mãi/i;
const rePayment = /shopeepay|shopee\s*pay|spaylater|s\s*pay\s*later|thẻ\s*tín\s*dụng|thẻ\s*ghi\s*nợ|ngân\s*hàng|thanh\s*toán\s*(?:bằng|qua|với)|ví\s*điện\s*tử|\bvisa\b|mastercard|\bjcb\b|napas/i;

export function parseVoucher(rawText: string): ParsedVoucher {
  const raw = rawText.replace(/\s+/g, ' ').trim();
  const lower = raw.toLowerCase();
  const scope: VoucherScope = rePayment.test(raw) ? 'payment'
    : /của\s*shop\b|shop\s*voucher|voucher\s*của\s*shop|mã\s*giảm\s*giá\s*của\s*shop/i.test(raw) ? 'shop'
    : /shopee|xtra|toàn sàn|mã\s*sàn/i.test(raw) ? 'platform' : 'unknown';
  const out: ParsedVoucher = { raw, kind: 'unknown', scope };

  const min = raw.match(reMin); if (min) { const v = parseMoneyToken(min[1], min[2]); if (v !== null) out.minSpend = v; }
  const ed = raw.match(reExpDate), el = raw.match(reExpLeft);
  if (ed) out.expires = `${parseInt(ed[1], 10)}/${parseInt(ed[2], 10)}`; else if (el) out.expires = `còn ${el[1]} ${el[2]}`;
  const ef = raw.match(reExpFull);
  if (ef) {
    const d = parseInt(ef[2], 10), mo = parseInt(ef[3], 10);
    if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) {
      out.expiresDate = `${ef[4]}-${String(mo).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      if (!out.expires) out.expires = `${d}/${mo}`;
    }
  }
  const sa = raw.match(reStartAt), si = raw.match(reStartIn);
  if (sa) out.starts = `${sa[1] ? `${sa[1]} ` : ''}${parseInt(sa[2], 10)}/${parseInt(sa[3], 10)}`;
  else if (si) out.starts = `còn ${si[1]} ${si[2]}`;
  const sale = saleLabelOf(raw); if (sale) out.sale = sale;
  const ap = raw.match(reApplies); if (ap) out.applies = ap[1].replace(/\s+/g, ' ').trim();
  const used = raw.match(reUsed); if (used) out.usedPct = Math.min(100, parseInt(used[1], 10));
  if (/đã\s*lưu/i.test(raw)) out.saved = true; else if (/(^|\s)lưu(\s|$)/i.test(lower)) out.saved = false;
  if (/hết lượt|đã hết|đã hết hạn|hết hạn sử dụng/i.test(raw) || out.usedPct === 100) out.unavailable = true;

  const bundle = raw.match(reBundle);
  if (bundle) {
    out.kind = 'bundle';
    const qty = raw.match(/(?:mua|chọn)\s*(\d+)/i); if (qty) out.minQty = parseInt(qty[1], 10);
    const pct = raw.match(rePercent); if (pct) out.percent = parseInt(pct[1], 10);
    else { const a = raw.match(reAmount); if (a) { const v = parseMoneyToken(a[1], a[2]); if (v) out.amount = v; } }
    return out;
  }
  const cp = raw.match(reCoinPct), ca = raw.match(reCoinAmt);
  if (cp || ca) { out.kind = 'coin'; if (cp) out.percent = parseInt(cp[1], 10); else out.amount = parseMoneyToken(ca![1], ca![2]) ?? undefined; return out; }
  if (reShip.test(raw)) {
    out.kind = 'shipping';
    const a = raw.match(reAmount); if (a) { const v = parseMoneyToken(a[1], a[2]); if (v) out.amount = v; }
    return out;
  }
  const pct = raw.match(rePercent);
  if (pct) {
    out.kind = 'percent'; out.percent = parseInt(pct[1], 10);
    const cap = raw.match(reCap); if (cap) { const v = parseMoneyToken(cap[1], cap[2]); if (v) out.cap = v; }
    return out;
  }
  const amt = raw.match(reAmount);
  if (amt) { const v = parseMoneyToken(amt[1], amt[2]); if (v) { out.kind = 'amount'; out.amount = v; } }
  return out;
}

export interface VoucherEval { voucher: ParsedVoucher; discount: number; eligible: boolean; minKnown: boolean; finalPrice: number; }

export function evaluateVoucher(v: ParsedVoucher, price: number): VoucherEval | null {
  if (v.kind !== 'amount' && v.kind !== 'percent') return null;
  const minKnown = v.minSpend !== undefined;
  const eligible = !v.unavailable && (!minKnown || price >= (v.minSpend as number));
  let discount = 0;
  if (eligible) {
    discount = v.kind === 'amount' ? v.amount ?? 0 : Math.floor((price * (v.percent ?? 0)) / 100);
    if (v.kind === 'percent' && v.cap !== undefined) discount = Math.min(discount, v.cap);
    discount = Math.min(discount, price);
  }
  return { voucher: v, discount, eligible, minKnown, finalPrice: price - discount };
}

export interface VoucherResult {
  all: ParsedVoucher[];
  best: VoucherEval | null;                 // một mã giảm nhiều nhất
  combo: { shop: VoucherEval; platform: VoucherEval; discount: number; finalPrice: number } | null; // 1 mã shop + 1 mã Shopee (nếu được dùng cùng lúc)
  ranked: VoucherEval[];
  ineligible: VoucherEval[];
  shipping: ParsedVoucher[];
  coin: ParsedVoucher[];
  bundle: ParsedVoucher[];   // combo mua nhiều món – không tính vào giá 1 món
  payment: VoucherEval[];    // ưu đãi theo cách thanh toán – tính riêng, không gộp vào ước tính chính
  unknownCount: number;
}

export function bestVoucher(texts: string[], price: number): VoucherResult {
  const seen = new Set<string>();
  const all = texts.map(parseVoucher).filter((v) => (seen.has(v.raw) ? false : (seen.add(v.raw), true)));
  const payment = all.filter((v) => v.scope === 'payment').map((v) => evaluateVoucher(v, price))
    .filter((e): e is VoucherEval => !!e && e.eligible && e.discount > 0).sort((a, b) => b.discount - a.discount);
  const evals = all.filter((v) => v.scope !== 'payment').map((v) => evaluateVoucher(v, price)).filter((e): e is VoucherEval => !!e);
  const ranked = evals.filter((e) => e.eligible && e.discount > 0).sort((a, b) => b.discount - a.discount);
  const best = ranked[0] ?? null;
  const bestShop = ranked.find((e) => e.voucher.scope !== 'platform');
  let combo: VoucherResult['combo'] = null;
  if (bestShop) {
    // mã Shopee tính trên phần còn lại sau mã của shop (ước tính)
    const after = price - bestShop.discount;
    const plat = all.filter((v) => v.scope === 'platform').map((v) => evaluateVoucher(v, after)).filter((e): e is VoucherEval => !!e && e.eligible && e.discount > 0)
      .sort((a, b) => b.discount - a.discount)[0];
    if (plat) combo = { shop: bestShop, platform: plat, discount: bestShop.discount + plat.discount, finalPrice: Math.max(0, after - plat.discount) };
  }
  return {
    all, best, combo, ranked,
    ineligible: evals.filter((e) => !e.eligible && !e.voucher.unavailable).sort((a, b) => (a.voucher.minSpend ?? 0) - (b.voucher.minSpend ?? 0)),
    shipping: all.filter((v) => v.kind === 'shipping'), coin: all.filter((v) => v.kind === 'coin'),
    bundle: all.filter((v) => v.kind === 'bundle'), payment,
    unknownCount: all.filter((v) => v.kind === 'unknown').length,
  };
}

// ---------- Gợi ý nên dùng mã nào
// Chỉ gợi ý trong số mã ĐÃ dùng được với giá hiện tại. Không bao giờ gợi ý mua thêm để đủ đơn tối thiểu
// (đi ngược mục tiêu của Why I Buy? là giúp cân nhắc trước khi mua).
export interface VoucherPick { eval: VoucherEval; role: 'shop' | 'platform' | 'single'; }
export interface VoucherAdvice {
  picks: VoucherPick[];          // rỗng = không có mã nào dùng được
  discount: number;
  finalPrice: number;
  combo: boolean;
  todo: string[];                // việc cần làm trên Shopee trước khi đặt (lưu mã…)
  cautions: string[];            // điều cần biết (sắp hết hạn, sắp hết lượt, có thể không dùng chung…)
  extras: string[];              // ưu đãi không tính vào giá: vận chuyển, hoàn xu, thanh toán, combo
}

const HOT_USED = 80;             // "Đã dùng ≥ 80%" → có thể hết lượt trước khi bạn đặt
const short = (v: ParsedVoucher) => {
  const main = v.kind === 'amount' ? `giảm ${fmtShort(v.amount ?? 0)}` : v.kind === 'percent' ? `giảm ${v.percent}%${v.cap ? ` (tối đa ${fmtShort(v.cap)})` : ''}` : v.raw;
  return `mã ${v.scope === 'platform' ? 'Shopee' : v.scope === 'shop' ? 'của shop' : ''} ${main}`.replace(/\s+/g, ' ');
};
function fmtShort(n: number) { return n >= 1_000_000 ? `${+(n / 1_000_000).toFixed(1)}tr` : n >= 1_000 ? `${Math.round(n / 1_000)}k` : `${n}đ`; }

export function adviseVoucher(r: VoucherResult, price: number): VoucherAdvice {
  const useCombo = !!r.combo && r.combo.discount > (r.best?.discount ?? 0);
  const picks: VoucherPick[] = useCombo
    ? [{ eval: r.combo!.shop, role: 'shop' }, { eval: r.combo!.platform, role: 'platform' }]
    : r.best ? [{ eval: r.best, role: 'single' }] : [];
  const discount = useCombo ? r.combo!.discount : r.best?.discount ?? 0;
  const todo: string[] = [], cautions: string[] = [], extras: string[] = [];
  for (const { eval: e } of picks) {
    const v = e.voucher;
    const name = short(v), Name = name[0].toUpperCase() + name.slice(1);
    if (v.saved === false) todo.push(`Bấm "Lưu" ${name} trên trang Shopee trước khi đặt.`);
    if (v.expires) cautions.push(`${Name} hết hạn ${/^còn/.test(v.expires) ? `sau ${v.expires.replace(/^còn\s*/, '')}` : `ngày ${v.expires}`}.`);
    if (v.usedPct != null && v.usedPct >= HOT_USED) cautions.push(`${Name} đã dùng ${v.usedPct}%, có thể hết lượt.`);
    if (!e.minKnown) cautions.push(`Không thấy điều kiện đơn tối thiểu của ${name}, hãy kiểm tra lại ở bước thanh toán.`);
  }
  if (useCombo) cautions.push('Shopee có thể không cho dùng chung hai mã này; khi đó mã giảm nhiều nhất vẫn là lựa chọn tốt.');
  const free = r.shipping.find((v) => !v.unavailable && (v.minSpend === undefined || price >= v.minSpend));
  if (free) extras.push(`Có mã vận chuyển${free.saved === false ? ' (chưa lưu)' : ''}: có thể chọn thêm ở bước thanh toán.`);
  if (r.coin.length) extras.push(`${r.coin.length} ưu đãi hoàn xu: nhận xu sau khi mua, không làm giảm giá trả.`);
  if (r.payment.length) extras.push(`Nếu thanh toán bằng phương thức ghi trên mã: có thể giảm thêm ${fmtShort(r.payment[0].discount)} (${r.payment[0].voucher.raw.slice(0, 60)}).`);
  if (r.bundle.length) extras.push('Combo mua nhiều món không tính ở đây vì bạn đang cân nhắc 1 món.');
  return { picks, discount, finalPrice: Math.max(0, price - discount), combo: useCombo, todo, cautions, extras };
}

// Local Repository theo handoff 9.1: WishlistItem, PriceSnapshot, Decision (chỉ thêm) lưu riêng trong chrome.storage.local.
import type { Decision, DecisionChoice, PriceSnapshot, PriceSource, PriceType, Confirmation, Settings, WishlistItem } from '../../types';
import { kv } from '../../lib/kv';
import { clampTitle, stableHash, toRatingCount, toShopStar, toStar, uuid } from '../../lib/format';

export const K = { items: 'wib_items', prices: 'wib_prices', decisions: 'wib_decisions', settings: 'wib_settings' } as const;
export const DEFAULT_SETTINGS: Settings = { syncOn: true, saveImages: false, hideLinkBanner: false, ex10AutoFill: true, ex10Vouchers: true };

// Bản trước mặc định tắt "Tự điền từ trang" / "Đọc voucher": bật một lần cho cài đặt đã lưu, sau đó tôn trọng lựa chọn của người dùng.
const EX10_ON = 'wib_ex10_default_on';
export async function getSettings(): Promise<Settings> {
  const k = await kv();
  const stored = await k.get<Partial<Settings>>(K.settings, {});
  if (!(await k.get<boolean>(EX10_ON, false))) {
    if ('ex10AutoFill' in stored || 'ex10Vouchers' in stored) await k.set(K.settings, { ...stored, ex10AutoFill: true, ex10Vouchers: true });
    await k.set(EX10_ON, true);
    return { ...DEFAULT_SETTINGS, ...stored, ex10AutoFill: true, ex10Vouchers: true };
  }
  return { ...DEFAULT_SETTINGS, ...stored };
}
export async function setSettings(patch: Partial<Settings>) { const s = { ...(await getSettings()), ...patch }; await (await kv()).set(K.settings, s); return s; }

// ---- Chuyển dữ liệu từ định dạng cũ (bản trước 26/10: giá nằm trong item.priceHistory) sang hợp đồng handoff 9.1
const SCHEMA = 'wib_schema';
const migrated = new WeakMap<object, Promise<void>>();
export async function migrateIfNeeded() {
  const k = await kv();
  if (!migrated.has(k)) migrated.set(k, (async () => {
    if ((await k.get<number>(SCHEMA, 1)) >= 2) return;
    const old = await k.get<any[]>(K.items, []);
    const prices: PriceSnapshot[] = await k.get<PriceSnapshot[]>(K.prices, []);
    const items: WishlistItem[] = old.map((o) => {
      if (o.saveChannel) return o as WishlistItem;                 // đã là định dạng mới
      const m = String(o.normalizedKey ?? '').match(/^(\d+)\.(\d+)$/);
      const productKey = m ? `shopee:${m[1]}:${m[2]}` : undefined;
      for (const h of (o.priceHistory ?? []) as any[]) {
        if (!(h.vnd > 0)) continue;
        prices.push({ id: uuid(), itemId: o.id, priceType: 'single', amountVnd: h.vnd, variantLabel: o.variant,
          source: h.source === 'page_read' || h.source === 'user_confirmed' ? 'extensionPage' : 'manual',
          confirmation: h.source === 'page_read' ? 'unconfirmed' : 'userConfirmed', observedAt: h.capturedAt, syncState: 'local' });
      }
      return {
        id: o.id, title: clampTitle(o.title ?? '') || 'Món trên Shopee', url: m ? `https://shopee.vn/product/${m[1]}/${m[2]}` : undefined, productKey,
        variantLabel: o.variant, motive: o.purchaseReason, budgetGroupId: o.categoryId, priority: 3,
        status: o.status === 'purchased' ? 'considering' : o.status ?? 'considering', // "Đã mua" cũ chưa có purchaseId → về Đang cân nhắc
        reviewAt: o.reviewAt, saveChannel: 'extension', revision: o.revision ?? 1, createdAt: o.createdAt, updatedAt: o.updatedAt ?? o.createdAt,
        originalUrl: o.originalUrl, imageUrl: o.imageUrl, saleEvent: o.saleEvent, syncState: 'local', deleted: o.deleted,
        buyIntentAt: o.status === 'purchased' ? o.decidedAt ?? o.updatedAt : undefined,
      } as WishlistItem;
    });
    await k.set(K.items, items);
    await k.set(K.prices, prices);
    await k.set(SCHEMA, 2);
  })());
  return migrated.get(k);
}

const get = async <T,>(k: string) => { await migrateIfNeeded(); return (await kv()).get<T[]>(k, []); };
const put = async <T,>(k: string, v: T[]) => (await kv()).set(k, v);

export const allItems = () => get<WishlistItem>(K.items);
export const allPrices = () => get<PriceSnapshot>(K.prices);
export const allDecisions = () => get<Decision>(K.decisions);
export async function listItems() { return (await allItems()).filter((i) => !i.deleted).sort((a, b) => b.createdAt.localeCompare(a.createdAt)); }
export async function getItem(id: string) { return (await allItems()).find((i) => i.id === id && !i.deleted) ?? null; }
export async function pricesFor(id: string) { return (await allPrices()).filter((p) => p.itemId === id).sort((a, b) => a.observedAt.localeCompare(b.observedAt)); }
export async function loadAll() {
  const [items, prices, decisions] = await Promise.all([listItems(), allPrices(), allDecisions()]);
  const live = new Set(items.map((i) => i.id));
  return { items, prices: prices.filter((p) => live.has(p.itemId)), decisions };
}

const vKey = (v?: string) => (v ?? '').toLowerCase().replace(/\s+/g, ' ').trim();
// id = hash(uid, productKey, modelId ?? variant ?? url). Extension chưa có uid khi chưa liên kết → dùng "local".
export function itemIdFor(productKey: string | undefined, modelId: string | undefined, variantLabel: string | undefined, url: string, uid = 'local') {
  return `w_${stableHash([uid, productKey ?? '', modelId ?? vKey(variantLabel) ?? '', productKey ? '' : url].join('|'))}`;
}

// Trùng = cùng sản phẩm VÀ cùng phân loại (handoff: "cùng sản phẩm, cùng phân loại").
export async function findDuplicate(productKey: string | undefined, url: string, variantLabel?: string) {
  const v = vKey(variantLabel);
  return (await listItems()).find((i) => ((productKey && i.productKey === productKey) || (!productKey && (i.originalUrl === url || i.url === url))) && vKey(i.variantLabel) === v) ?? null;
}

export interface PriceInput { priceType: PriceType; amountVnd?: number; minVnd?: number; maxVnd?: number; originalVnd?: number; saleLabel?: string; source: PriceSource; confirmation: Confirmation; }

export type PriceSaveMode = 'both' | 'original' | 'sale';
// Giá gốc + giá đang giảm (SteamDB): 'both' ghi 2 bản — giá gốc ('single') làm giá chính để so theo thời gian,
// và giá đợt giảm ('sale', kèm % và tên đợt/mã). Không có giảm giá → một bản 'single' (hoặc 'flash') như cũ.
export function salePrices(o: { nowVnd: number; originalVnd?: number | null; mode: PriceSaveMode; saleLabel?: string; flash?: boolean; source: PriceSource; confirmation: Confirmation }): PriceInput[] {
  const { nowVnd, mode, source, confirmation } = o;
  const label = o.saleLabel?.replace(/\s+/g, ' ').trim().slice(0, 40) || (o.flash ? 'Flash Sale' : undefined);
  const orig = o.originalVnd && o.originalVnd > nowVnd ? o.originalVnd : undefined;
  if (!orig) return [{ priceType: o.flash ? 'flash' : 'single', amountVnd: nowVnd, source, confirmation }];
  const regular: PriceInput = { priceType: 'single', amountVnd: orig, source, confirmation };
  const sale: PriceInput = { priceType: 'sale', amountVnd: nowVnd, originalVnd: orig, saleLabel: label, source, confirmation };
  return mode === 'original' ? [regular] : mode === 'sale' ? [sale] : [regular, sale];
}
export const discountPct = (nowVnd?: number | null, originalVnd?: number | null) =>
  nowVnd && originalVnd && originalVnd > nowVnd ? Math.round(((originalVnd - nowVnd) / originalVnd) * 100) : 0;
export interface NewItemInput {
  originalUrl: string; url?: string; productKey?: string; title: string; variantLabel?: string; shopName?: string; imageUrl?: string; vouchers?: string[];
  price?: PriceInput | null; budgetGroupId?: string; motive?: string; saleEvent?: WishlistItem['saleEvent'];
  productRating?: number; productRatingCount?: number; shopRating?: number;
}

// Voucher lưu kèm món: bỏ trùng, tối đa 20 mã, mỗi mã ≤240 ký tự; không có mã → undefined
export function cleanVouchers(texts?: string[]): string[] | undefined {
  const out = [...new Set((texts ?? []).map((t) => t.replace(/\s+/g, ' ').trim().slice(0, 240)).filter(Boolean))].slice(0, 20);
  return out.length ? out : undefined;
}

const touch = (i: WishlistItem, now: string): WishlistItem => ({ ...i, updatedAt: now, revision: i.revision + 1, syncState: i.syncState === 'local' ? 'local' : 'pending' });
const validPrice = (p?: PriceInput | null) => !!p && ((p.amountVnd ?? 0) > 0 || ((p.minVnd ?? 0) > 0 && (p.maxVnd ?? 0) > 0)); // không bao giờ lưu 0 ₫

function snapshot(itemId: string, p: PriceInput, item: Pick<WishlistItem, 'modelId' | 'variantLabel' | 'shopName' | 'productRating' | 'productRatingCount' | 'shopRating'>, now: string): PriceSnapshot {
  return { id: uuid(), itemId, ...p, modelId: item.modelId, variantLabel: item.variantLabel, observedAt: now, syncState: 'local',
    shopName: item.shopName, productRating: toStar(item.productRating) ?? undefined, productRatingCount: toRatingCount(item.productRatingCount) ?? undefined, shopRating: toShopStar(item.shopRating) ?? undefined };
}

export async function addItem(input: NewItemInput, now = new Date().toISOString()): Promise<{ item: WishlistItem; duplicate: boolean }> {
  const dup = await findDuplicate(input.productKey, input.url ?? input.originalUrl, input.variantLabel);
  if (dup) return { item: dup, duplicate: true }; // E03
  const title = clampTitle(input.title) || 'Món trên Shopee';
  const item: WishlistItem = {
    id: itemIdFor(input.productKey, undefined, input.variantLabel, input.url ?? input.originalUrl),
    title, url: input.url, productKey: input.productKey, variantLabel: input.variantLabel?.trim() || undefined, shopName: input.shopName?.trim().slice(0, 60) || undefined,
    ...(cleanVouchers(input.vouchers) ? { vouchers: cleanVouchers(input.vouchers), vouchersAt: now } : {}),
    motive: input.motive, budgetGroupId: input.budgetGroupId, priority: 3, status: 'considering', saveChannel: 'extension',
    revision: 1, createdAt: now, updatedAt: now, originalUrl: input.originalUrl, imageUrl: input.imageUrl, saleEvent: input.saleEvent, syncState: 'local',
    productRating: input.productRating, productRatingCount: input.productRatingCount, shopRating: input.shopRating,
  };
  const items = (await allItems()).filter((i) => i.id !== item.id); // id trùng với tombstone cũ → thay
  await put(K.items, [...items, item]);
  if (validPrice(input.price)) await put(K.prices, [...(await allPrices()), snapshot(item.id, input.price!, item, now)]);
  return { item, duplicate: false };
}

async function patchItem(id: string, fn: (i: WishlistItem) => WishlistItem) {
  const rows = await allItems();
  const idx = rows.findIndex((r) => r.id === id);
  if (idx < 0) return null;
  rows[idx] = fn(rows[idx]);
  await put(K.items, rows);
  return rows[idx];
}

export async function addPrice(itemId: string, p: PriceInput, now = new Date().toISOString()) {
  if (!validPrice(p)) return null;
  const it = await getItem(itemId);
  if (!it) return null;
  const s = snapshot(itemId, p, it, now);
  await put(K.prices, [...(await allPrices()), s]);
  await patchItem(itemId, (i) => touch(i, now));
  return s;
}

// "Xác nhận lại" giá cũ: ghi một bản giá mới cùng số tiền, nguồn manual, đã xác nhận.
export async function reconfirmPrice(itemId: string, now = new Date().toISOString()) {
  const ps = await pricesFor(itemId);
  const last = ps[ps.length - 1];
  if (!last) return null;
  const { priceType, amountVnd, minVnd, maxVnd, originalVnd, saleLabel } = last;
  return addPrice(itemId, { priceType, amountVnd, minVnd, maxVnd, originalVnd, saleLabel, source: 'manual', confirmation: 'userConfirmed' }, now);
}

export function updateFields(id: string, f: Partial<Pick<WishlistItem, 'title' | 'variantLabel' | 'shopName' | 'vouchers' | 'vouchersAt' | 'budgetGroupId' | 'motive' | 'priority' | 'saleEvent' | 'productRating' | 'productRatingCount' | 'shopRating'>>, now = new Date().toISOString()) {
  return patchItem(id, (i) => touch({ ...i, ...f, title: f.title != null ? clampTitle(f.title) || i.title : i.title, priority: f.priority != null ? Math.min(5, Math.max(1, Math.round(f.priority))) : i.priority }, now));
}

// Quyết định: luôn THÊM một bản ghi Decision, rồi áp tác động lên món.
//  wait → chỉ đặt reviewAt · skip → status skipped · buy → chỉ ghi ý định (status giữ nguyên, app sẽ ghi khoản mua)
//  undo → hoàn tác quyết định gần nhất (skip/buy/wait) về trạng thái trước đó.
export async function recordDecision(itemId: string, choice: DecisionChoice, opts: { reviewAt?: string } = {}, now = new Date().toISOString()) {
  const d: Decision = { id: uuid(), itemId, choice, at: now, reviewAt: opts.reviewAt, syncState: 'local' };
  await put(K.decisions, [...(await allDecisions()), d]);
  return patchItem(itemId, (i) => {
    if (choice === 'wait') return touch({ ...i, reviewAt: opts.reviewAt }, now);
    if (choice === 'skip') return touch({ ...i, status: 'skipped', buyIntentAt: undefined }, now);
    if (choice === 'buy') return touch({ ...i, buyIntentAt: now }, now);
    // undo: món đã purchased (app đã ghi khoản mua) thì không hoàn tác từ extension
    if (i.status === 'purchased') return i;
    return touch({ ...i, status: 'considering', buyIntentAt: undefined, reviewAt: i.status === 'skipped' ? i.reviewAt : undefined }, now);
  });
}

export async function lastDecision(itemId: string) {
  return (await allDecisions()).filter((d) => d.itemId === itemId).sort((a, b) => a.at.localeCompare(b.at)).pop() ?? null;
}

export async function removeItem(id: string, now = new Date().toISOString()) {
  const rows = await allItems();
  const it = rows.find((r) => r.id === id);
  if (!it) return;
  if (it.syncState === 'local') {
    await put(K.items, rows.filter((r) => r.id !== id));
    await put(K.prices, (await allPrices()).filter((p) => p.itemId !== id));
    await put(K.decisions, (await allDecisions()).filter((d) => d.itemId !== id));
  } else await put(K.items, rows.map((r) => (r.id === id ? { ...touch(r, now), deleted: true } : r)));
}

// ---- trạng thái đồng bộ
type Kind = 'items' | 'prices' | 'decisions';
export async function setSyncState(kind: Kind, ids: string[], state: WishlistItem['syncState']) {
  const set = new Set(ids);
  const rows = await get<{ id: string; syncState: string }>(K[kind]);
  await put(K[kind], rows.map((r) => (set.has(r.id) ? { ...r, syncState: state } : r)));
}
export async function markAll(state: 'pending' | 'local', onlyUnsynced = true) {
  for (const k of ['items', 'prices', 'decisions'] as Kind[]) {
    const rows = await get<{ id: string; syncState: string; deleted?: boolean }>(K[k]);
    const next = rows.filter((r) => !(state === 'local' && r.deleted)).map((r) => (onlyUnsynced && r.syncState === 'synced' && state === 'pending' ? r : { ...r, syncState: state }));
    await put(K[k], next);
  }
}
export async function replaceItem(item: WishlistItem) {
  const rows = await allItems();
  const i = rows.findIndex((r) => r.id === item.id);
  if (i >= 0) rows[i] = item; else rows.push(item);
  await put(K.items, rows);
}
export async function mergePrices(ps: PriceSnapshot[]) {
  const rows = await allPrices();
  const have = new Set(rows.map((r) => r.id));
  await put(K.prices, [...rows, ...ps.filter((p) => !have.has(p.id)).map((p) => ({ ...p, syncState: 'synced' as const }))]);
}
export async function mergeDecisions(ds: Decision[]) {
  const rows = await allDecisions();
  const have = new Set(rows.map((r) => r.id));
  await put(K.decisions, [...rows, ...ds.filter((d) => !have.has(d.id)).map((d) => ({ ...d, syncState: 'synced' as const }))]);
}
// Bỏ món đã đồng bộ mà server không còn (bị xoá ở app). Món chưa đồng bộ luôn được giữ.
export async function dropSyncedExcept(keep: Set<string>) {
  const rows = await allItems();
  const gone = new Set(rows.filter((r) => r.syncState === 'synced' && !keep.has(r.id)).map((r) => r.id));
  if (!gone.size) return;
  await put(K.items, rows.filter((r) => !gone.has(r.id)));
  await put(K.prices, (await allPrices()).filter((p) => !gone.has(p.itemId)));
}
export async function clearLocalData() { const k = await kv(); await k.remove(K.items); await k.remove(K.prices); await k.remove(K.decisions); }
export async function exportJson() { return JSON.stringify({ exportedAt: new Date().toISOString(), ...(await loadAll()) }, null, 2); }

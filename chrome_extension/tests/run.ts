import assert from 'node:assert/strict';
import { memoryKV, setKV } from '../lib/kv';
setKV(memoryKV());
import { parseShopeeLink, cleanTabTitle } from '../features/items/url';
import { buildViews, comparable, freshness, priceTag, compareToSaved, type ItemView } from '../features/items/price';
import { budgetInsight, khaDung, saleText, defaultSaleCalendar, verdict } from '../features/decision/rules';
import * as repo from '../features/items/repo';
import { startPairing, checkPairing, getPairing, unpair, setApi, clearRevokedNotice } from '../features/pairing/pairing';
import { syncNow, getSyncMeta, backoffMs } from '../features/sync/sync';
import { MockApi, DEMO_CODE } from '../lib/api';
import { clampTitle, deviceLabel, fmtVnd, stableHash } from '../lib/format';
import type { PriceSnapshot, WishlistItem } from '../types';

const t = async (name: string, fn: () => Promise<void> | void) => { await fn(); console.log('✓', name); };
const NOW = new Date('2026-10-26T10:00:00');
const iso = (s: string) => new Date(s).toISOString();
const snap = (over: Partial<PriceSnapshot>): PriceSnapshot => ({ id: Math.random().toString(36), itemId: 'x', priceType: 'single', source: 'manual', confirmation: 'userConfirmed', observedAt: iso('2026-10-26T09:00:00'), syncState: 'local', ...over });
const itm = (over: Partial<WishlistItem> = {}): WishlistItem => ({ id: 'x', title: 'Tai nghe Bluetooth', priority: 3, status: 'considering', saveChannel: 'extension', revision: 1, createdAt: iso('2026-10-10T10:00:00'), updatedAt: iso('2026-10-10T10:00:00'), syncState: 'local', ...over });
const view = (i: WishlistItem, ps: PriceSnapshot[]) => buildViews([i], ps.map((p) => ({ ...p, itemId: i.id })))[0];

await t('Link: productKey shopee:<shop>:<item>, url gọn, link rút gọn, từ chối host giả', () => {
  const l = parseShopeeLink('https://shopee.vn/Do-Choi-i.989111446.48004301544?extraParams=x')!;
  assert.equal(l.productKey, 'shopee:989111446:48004301544'); assert.equal(l.url, 'https://shopee.vn/product/989111446/48004301544');
  for (const s of ['https://s.shopee.vn/abc', 'https://shp.ee/xyz', 'https://vn.shp.ee/q']) assert.equal(parseShopeeLink(s)?.isShortLink, true, s);
  for (const bad of ['http://shopee.vn/x-i.1.2', 'https://shopee.vn.evil.com/x-i.1.2', 'https://shopee.vn/', 'javascript:alert(1)']) assert.equal(parseShopeeLink(bad), null, bad);
  assert.equal(cleanTabTitle('Tai nghe | Shopee Việt Nam'), 'Tai nghe');
});

await t('Tên tối đa 60 ký tự (cắt ở ranh giới từ); id ổn định', () => {
  const long = 'Đồ Chơi Cá Catnip dành cho Mèo, Đồ chơi Cá cho mèo con cắn Nhai cào xước, Đồ Dùng Cho Mèo.';
  const c = clampTitle(long);
  assert.ok(c.length <= 60 && long.startsWith(c) && !c.endsWith(','), c);
  assert.equal(stableHash('a|b'), stableHash('a|b')); assert.notEqual(stableHash('a|b'), stableHash('a|c'));
  assert.equal(repo.itemIdFor('shopee:1:2', undefined, 'Cá Chép', 'u'), repo.itemIdFor('shopee:1:2', undefined, ' cá  chép ', 'u2'));
});

await t('Độ mới giá 3 mốc + nhãn giá; chỉ so cùng loại giá, cùng phân loại', () => {
  assert.equal(freshness(snap({ observedAt: iso('2026-10-24T10:00:00') }), NOW), 'fresh');
  assert.equal(freshness(snap({ observedAt: iso('2026-10-21T10:00:00') }), NOW), 'recent');
  assert.equal(freshness(snap({ observedAt: iso('2026-10-15T10:00:00') }), NOW), 'old');
  const i = itm();
  const v = view(i, [snap({ amountVnd: 420000, observedAt: iso('2026-10-24T09:00:00') }), snap({ amountVnd: 378000 })]);
  assert.deepEqual(priceTag(v, NOW), { kind: 'lower', label: 'Thấp hơn lúc lưu 10%' });
  assert.equal(priceTag(view(i, [snap({ amountVnd: 420000, observedAt: iso('2026-10-21T09:00:00') })]), NOW).kind, 'need', '4–7 ngày: chưa đem so');
  assert.ok(!comparable(snap({ priceType: 'flash' }), snap({ priceType: 'single' })), 'Flash Sale chỉ so với Flash Sale');
  assert.ok(!comparable(snap({ priceType: 'range' }), snap({ priceType: 'range' })), 'không so khoảng giá');
  assert.ok(!comparable(snap({ variantLabel: 'Đen' }), snap({ variantLabel: 'Trắng' })));
  const vf = view(i, [snap({ amountVnd: 420000, observedAt: iso('2026-10-24T09:00:00') }), snap({ amountVnd: 300000, priceType: 'flash' })]);
  assert.equal(priceTag(vf, NOW).label, 'Giá ổn định', 'giá Flash không bị so với giá thường lúc lưu');
  assert.equal(compareToSaved(200000, 188000)?.label, 'Thấp hơn lúc lưu 6%');
});

const B = [{ groupId: 'cong-nghe', month: '2026-10', limitVnd: 1_000_000, spentVnd: 40_000, hasEnoughHistory: false }];
await t('khaDung = 864.000 (Figma 31c); ngân sách: EX-08 chưa ghép, E08, hết, vượt, 44%', () => {
  assert.equal(khaDung(B[0], NOW), 864_000);
  assert.equal(khaDung({ ...B[0], hasEnoughHistory: true, dailyAvgVnd: 10_000 }, NOW), Math.floor((960_000 - 10_000 * 5) * 0.9)); // còn 5 ngày đến 31/10
  const v = view(itm({ budgetGroupId: 'cong-nghe' }), [snap({ amountVnd: 378000 })]);
  assert.equal(budgetInsight(v, B, true, NOW).text, `Công nghệ · chiếm khoảng 44% phần khả dụng (${fmtVnd(864000)})`);
  assert.equal(budgetInsight(v, B, false, NOW).kind, 'unlinked');
  assert.equal(budgetInsight(v, [], true, NOW).kind, 'missing');
  assert.equal(budgetInsight(v, [{ ...B[0], spentVnd: 1_000_000 }], true, NOW).kind, 'empty');
  assert.equal(budgetInsight(view(itm({ budgetGroupId: 'cong-nghe' }), [snap({ amountVnd: 900000 })]), B, true, NOW).kind, 'over');
});

await t('Nhãn tóm tắt theo đúng thứ tự 9.4', () => {
  const ctx = { budgets: B, calendar: [] as any[], linked: true };
  const base = itm({ budgetGroupId: 'cong-nghe', motive: 'mong-muon' });
  assert.equal(verdict(view(base, []), ctx, NOW).code, 'needRecentPrice');
  assert.equal(verdict(view({ ...base, createdAt: iso('2026-10-25T10:00:00') }, [snap({ amountVnd: 100000 })]), ctx, NOW).code, 'canWait');
  assert.equal(verdict(view({ ...base, createdAt: iso('2026-10-25T10:00:00'), motive: 'nhu-cau' }, [snap({ amountVnd: 100000 })]), ctx, NOW).code, 'withinBudget', 'trừ động cơ Nhu cầu');
  assert.equal(verdict(view(base, [snap({ amountVnd: 100000 })]), { ...ctx, calendar: [{ date: '2026-10-30T00:00:00', label: '10.10', verified: true }] }, NOW).code, 'canWait');
  assert.equal(verdict(view(base, [snap({ amountVnd: 900000 })]), ctx, NOW).code, 'overAvailable');
  assert.equal(verdict(view({ ...base, createdAt: iso('2026-07-01T10:00:00'), priority: 2 }, [snap({ amountVnd: 100000 })]), ctx, NOW).code, 'canConsiderSkip');
  assert.equal(verdict(view(base, [snap({ amountVnd: 100000 })]), ctx, NOW).code, 'withinBudget');
  assert.equal(verdict(view(base, [snap({ amountVnd: 100000 })]), { ...ctx, linked: false }, NOW).code, 'notEnoughData');
});

await t('Lịch sale: chỉ ghi "đã xác nhận" khi nguồn xác nhận', () => {
  assert.equal(saleText(defaultSaleCalendar(2026), '2026-11-07T15:00:00'), 'Đợt 11.11 còn 4 ngày');
});

let fishId = '';
await t('Kho dữ liệu: lưu (không lưu 0 ₫), chống trùng theo phân loại, giá riêng, quyết định chỉ thêm', async () => {
  const a = await repo.addItem({ originalUrl: 'https://shopee.vn/ca-i.1.2', url: 'https://shopee.vn/product/1/2', productKey: 'shopee:1:2', title: 'Đồ chơi cá catnip', variantLabel: 'Cá Chép', budgetGroupId: 'khac', price: { priceType: 'single', amountVnd: 20000, source: 'manual', confirmation: 'userConfirmed' } });
  fishId = a.item.id;
  assert.equal(a.item.priority, 3); assert.equal(a.item.saveChannel, 'extension'); assert.equal((await repo.pricesFor(fishId)).length, 1);
  const b = await repo.addItem({ originalUrl: 'https://shopee.vn/ca-i.1.2', url: 'https://shopee.vn/product/1/2', productKey: 'shopee:1:2', title: 'Đồ chơi cá catnip', variantLabel: 'Cá Hề', price: { priceType: 'single', amountVnd: 0, source: 'manual', confirmation: 'userConfirmed' } });
  assert.equal(b.duplicate, false); assert.equal((await repo.pricesFor(b.item.id)).length, 0, 'không lưu 0 ₫');
  assert.equal((await repo.addItem({ originalUrl: 'https://shopee.vn/x-i.1.2?y', url: 'https://shopee.vn/product/1/2', productKey: 'shopee:1:2', title: 'x', variantLabel: ' cá chép' })).duplicate, true);
  await repo.addPrice(fishId, { priceType: 'single', amountVnd: 18000, source: 'manual', confirmation: 'userConfirmed' });
  assert.equal((await repo.pricesFor(fishId)).length, 2);
  // quyết định
  let it = await repo.recordDecision(fishId, 'wait', { reviewAt: iso('2026-10-29T10:00:00') });
  assert.equal(it?.status, 'considering'); assert.ok(it?.reviewAt, 'Chờ chỉ đặt reviewAt');
  it = await repo.recordDecision(fishId, 'buy');
  assert.equal(it?.status, 'considering', 'Mua chỉ là ý định'); assert.ok(it?.buyIntentAt);
  it = await repo.recordDecision(fishId, 'undo');
  assert.equal(it?.buyIntentAt, undefined);
  it = await repo.recordDecision(fishId, 'skip'); assert.equal(it?.status, 'skipped');
  it = await repo.recordDecision(fishId, 'undo'); assert.equal(it?.status, 'considering');
  const ds = (await repo.allDecisions()).filter((d) => d.itemId === fishId).map((d) => d.choice);
  assert.deepEqual(ds, ['wait', 'buy', 'undo', 'skip', 'undo'], 'Decision chỉ thêm, không sửa');
  await repo.removeItem(b.item.id);
  assert.equal(await repo.getItem(b.item.id), null);
});

const mock = new MockApi(); setApi(mock);
await t('Liên kết: sai giảm lượt → khoá; đúng → CHỜ DUYỆT trên điện thoại; từ chối / đồng ý', async () => {
  assert.deepEqual(await startPairing('482914'), { ok: false, reason: 'invalid', attemptsLeft: 4 });
  for (let i = 0; i < 3; i++) await startPairing('000000');
  const locked = await startPairing('111111'); assert.equal(locked.ok, false); assert.equal((locked as any).reason, 'locked');
  assert.equal((await startPairing(DEMO_CODE)).ok, false, 'đã khoá');
  await mock.resetLock();
  let s = await startPairing(DEMO_CODE); assert.ok(s.ok);
  const id1 = (s as any).pairingId;
  assert.equal((await checkPairing(id1)).state, 'pending'); assert.equal((await getPairing()).linked, false, 'chưa duyệt thì chưa liên kết');
  await mock.phone(id1, 'reject'); assert.equal((await checkPairing(id1)).state, 'rejected');
  s = await startPairing(DEMO_CODE); const id2 = (s as any).pairingId;
  await mock.phone(id2, 'approve');
  const ok = await checkPairing(id2);
  assert.equal(ok.state, 'approved'); assert.equal(ok.synced, 1);
  assert.equal((await getPairing()).linked, true);
  assert.ok((await repo.allPrices()).every((p) => p.syncState === 'synced'));
  // hết hạn
  s = await startPairing(DEMO_CODE); const st = await mock.st(); st.pairings[(s as any).pairingId].expiresAt = iso('2020-01-01'); await mock.put(st);
  assert.equal((await checkPairing((s as any).pairingId)).state, 'expired');
});

await t('Đồng bộ: E04 mất mạng; E07 lỗi 503 → thử lại giãn dần; gửi lại không ghi đôi', async () => {
  const c = await repo.addItem({ originalUrl: 'https://shopee.vn/b-i.3.4', url: 'https://shopee.vn/product/3/4', productKey: 'shopee:3:4', title: 'Áo Lovito', price: { priceType: 'single', amountVnd: 250000, source: 'manual', confirmation: 'userConfirmed' } });
  assert.equal((await syncNow({ online: false })).skipped, 'offline');
  assert.equal((await repo.getItem(c.item.id))?.syncState, 'pending');
  await mock.failNext([503, 503]);
  let r = await syncNow({ force: true });
  assert.ok(r.failed && r.nextRetryAt); assert.equal((await getSyncMeta()).attempt, 1);
  assert.equal((await syncNow()).skipped, 'backoff', 'chưa tới giờ thử lại');
  r = await syncNow({ force: true }); assert.equal((await getSyncMeta()).attempt, 2);
  assert.deepEqual([backoffMs(1), backoffMs(2), backoffMs(3), backoffMs(20)], [1000, 2000, 4000, 300000]);
  r = await syncNow({ force: true }); assert.equal(r.failed, false); assert.equal((await getSyncMeta()).attempt, 0);
  assert.equal((await repo.getItem(c.item.id))?.syncState, 'synced');
  const n = Object.keys((await mock.st()).items).length;
  await syncNow({ force: true }); assert.equal(Object.keys((await mock.st()).items).length, n);
});

await t('Mua: extension ghi ý định → app ghi khoản mua → đồng bộ về thành Đã mua (có purchaseId)', async () => {
  await repo.recordDecision(fishId, 'buy');
  await syncNow({ force: true });
  assert.equal((await repo.getItem(fishId))?.status, 'considering');
  await mock.appRecordsPurchase(fishId);
  const r = await syncNow({ force: true });
  assert.ok(r.pulled >= 1);
  const it = await repo.getItem(fishId);
  assert.equal(it?.status, 'purchased'); assert.ok(it?.purchaseId); assert.equal(it?.buyIntentAt, undefined);
  assert.equal(it?.originalUrl, 'https://shopee.vn/ca-i.1.2', 'giữ trường chỉ có ở máy');
  const after = await repo.recordDecision(fishId, 'undo'); assert.equal(after?.status, 'purchased', 'không hoàn tác khoản mua từ extension');
});

await t('E06: app huỷ liên kết → 401 → chưa liên kết, giữ dữ liệu, hiện EXT-8 một lần', async () => {
  await mock.revokeAll();
  await repo.addPrice(fishId, { priceType: 'single', amountVnd: 17000, source: 'manual', confirmation: 'userConfirmed' });
  const r = await syncNow({ force: true });
  assert.equal(r.revoked, true);
  const p = await getPairing(); assert.equal(p.linked, false); assert.equal(p.revokedNotice, true);
  assert.ok((await repo.listItems()).length > 0);
  await clearRevokedNotice(); assert.equal((await getPairing()).revokedNotice, false);
});

await t('Huỷ liên kết: giữ hoặc xoá dữ liệu', async () => {
  let s = await startPairing(DEMO_CODE); await mock.phone((s as any).pairingId, 'approve'); await checkPairing((s as any).pairingId);
  await unpair({ keepLocal: true }); assert.ok((await repo.listItems()).length > 0);
  s = await startPairing(DEMO_CODE); await mock.phone((s as any).pairingId, 'approve'); await checkPairing((s as any).pairingId);
  await unpair({ keepLocal: false }); assert.equal((await repo.listItems()).length, 0); assert.equal((await repo.allPrices()).length, 0);
});

await t('Chuyển dữ liệu định dạng cũ sang hợp đồng 9.1', async () => {
  const { memoryKV, setKV } = await import('../lib/kv');
  const k = memoryKV(); setKV(k);
  await k.set('wib_items', [{ id: 'old1', sourcePlatform: 'shopee', originalUrl: 'https://shopee.vn/ca-i.11.22', normalizedKey: '11.22', title: 'Đồ chơi cá', variant: 'Cá Chép',
    referencePriceVnd: 18000, priceHistory: [{ vnd: 20000, source: 'page_read', capturedAt: iso('2026-10-24T09:00:00') }, { vnd: 18000, source: 'user_input', capturedAt: iso('2026-10-25T09:00:00') }],
    categoryId: 'khac', purchaseReason: 'mong-muon', status: 'purchased', createdAt: iso('2026-10-24T09:00:00'), updatedAt: iso('2026-10-25T09:00:00'), syncState: 'local', revision: 2 }]);
  const mod = await import('../features/items/repo');
  const [it] = await mod.listItems();
  assert.equal(it.productKey, 'shopee:11:22'); assert.equal(it.variantLabel, 'Cá Chép'); assert.equal(it.budgetGroupId, 'khac'); assert.equal(it.motive, 'mong-muon');
  assert.equal(it.priority, 3); assert.equal(it.saveChannel, 'extension'); assert.equal(it.status, 'considering'); assert.ok(it.buyIntentAt);
  const ps = await mod.pricesFor('old1');
  assert.deepEqual(ps.map((p) => [p.amountVnd, p.source, p.confirmation]), [[20000, 'extensionPage', 'unconfirmed'], [18000, 'manual', 'userConfirmed']]);
  setKV(memoryKV());
});

await t('Nhãn thiết bị', () => { assert.equal(deviceLabel('Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130'), 'Chrome – Windows'); });

// ---------- Tìm món tương tự, so món cùng loại, giờ nhắc
const sim = await import('../features/items/similar');
const sch = await import('../features/reminders/schedule');
await t('Rút gọn tên Shopee thành từ khoá tìm kiếm', () => {
  assert.equal(sim.searchKeyword('Đồ Chơi Cá Catnip dành cho Mèo, Đồ chơi Cá cho mèo con cắn Nhai cào xước'), 'đồ chơi cá catnip dành cho mèo');
  assert.equal(sim.searchKeyword('[HÀNG CÓ SẴN] Tai nghe Bluetooth TWS chống ồn 2026 chính hãng 🔥 | Freeship'), 'tai nghe bluetooth tws chống ồn');
  const u = new URL(sim.shopeeSearchUrl('đồ chơi cá')); assert.equal(u.searchParams.get('sortBy'), 'price'); assert.equal(u.searchParams.get('order'), 'asc');
});
await t('So món cùng loại đã lưu (chỉ giá ghi trong 3 ngày, cùng loại giá)', () => {
  const mk = (id: string, title: string, amt: number | undefined, at: string, key?: string, variant?: string, pt: any = 'single'): ItemView =>
    view(itm({ id, title, productKey: key, variantLabel: variant }), amt ? [snap({ amountVnd: amt, observedAt: iso(at), priceType: pt })] : []);
  const me = mk('a', 'Đồ Chơi Cá Catnip dành cho Mèo', 20000, '2026-10-26T09:00:00', 'shopee:1:2', 'Cá Chép');
  const b = mk('b', 'Đồ chơi cá bông catnip cho mèo cưng', 15000, '2026-10-25T09:00:00', 'shopee:3:4');
  const c = mk('c', 'Đồ Chơi Cá Catnip dành cho Mèo', 18000, '2026-10-26T08:00:00', 'shopee:1:2', 'Cá Hề');
  const old = mk('d', 'Đồ chơi cá catnip cho mèo loại lớn', 9000, '2026-10-10T08:00:00', 'shopee:5:6');
  const fl = mk('f', 'Đồ chơi cá catnip cho mèo', 5000, '2026-10-26T08:00:00', 'shopee:7:8', undefined, 'flash');
  const other = mk('e', 'Đồ chơi chuột lông cho mèo', 5000, '2026-10-26T08:00:00', 'shopee:9:9');
  const r = sim.compareSimilar(me, [me, b, c, old, fl, other], NOW);
  assert.equal(r.rows.length, 4);
  assert.equal(r.rows[0].view.item.id, 'b'); assert.ok(r.rows[0].cheapest);
  assert.ok(!r.rows.find((x) => x.view.item.id === 'f')!.cheapest, 'giá Flash không so với giá thường');
  assert.ok(r.summary!.startsWith('Có món cùng loại rẻ hơn 5.000'), r.summary!);
});
await t('Giờ nhắc Flash Sale: trước 5 phút; tránh 22:00–08:00 và 0:00', () => {
  const now = new Date('2026-10-25T10:00:00');
  assert.equal(sch.whenText(sch.reminderTime(iso('2026-10-26T15:00:00'), now)!.fireAt), '14:55, 26/10');
  assert.equal(sch.whenText(sch.reminderTime(iso('2026-10-27T00:00:00'), now)!.fireAt), '21:00, 26/10');
  assert.equal(sch.reminderTime(iso('2026-10-25T09:00:00'), now), null);
});
// ---------- Bộ đọc trang (Lab EX-10): giá theo loại đang chọn
const { JSDOM } = await import('jsdom');
const { readPage } = await import('../features/ex10/reader');
const runPage = (html: string, opts = {}) => {
  const w = new JSDOM(html, { url: 'https://shopee.vn/Do-Choi-Ca-Catnip-i.111.222' }).window as any;
  Object.assign(globalThis, { document: w.document, location: w.location, getComputedStyle: w.getComputedStyle.bind(w), NodeFilter: w.NodeFilter, HTMLElement: w.HTMLElement });
  return readPage(opts);
};
const fishPage = (selected: string, how: 'class' | 'style' | 'none' | 'shopee' | 'tick') => `<html><head><title>Đồ Chơi Cá Catnip | Shopee Việt Nam</title>
<script type="application/ld+json">{"@type":"Product","name":"Đồ Chơi Cá Catnip dành cho Mèo","image":"https://cf.shopee.vn/main.jpg","offers":{"lowPrice":"15000","highPrice":"28000","priceCurrency":"VND"}}</script></head>
<body><nav><a>Shopee</a> &gt; <a>Đồ chơi</a></nav>
<h1>Đồ Chơi Cá Catnip dành cho Mèo</h1>
<div><div style="font-size:30px">20.000<span style="font-size:18px">đ</span></div><div style="font-size:14px;text-decoration:line-through">28.000<span>đ</span></div><div>-29%</div></div>
<section><div>Mã Giảm Giá Của Shop</div><div><span>Giảm 20kđ</span></div></section>
<section><h3>Loại</h3><div>${['Cá thu đao', 'Cá Hề', 'Cá Diếc', 'Cá Chép', 'Cá Rồng Vàng', 'Cá Trắm Cỏ'].map((v) => {
  const on = v === selected;
  const cls = how === 'shopee' ? `sApkZm SkhBL1 ${on ? 'selection-box-selected' : 'selection-box-unselected'}`
    : how === 'class' && on ? 'product-variation product-variation--selected' : 'product-variation';
  const tick = how === 'tick' && on ? '<div class="corner"><svg><path d="M0 0"></path></svg></div>' : '';
  const st = how === 'style' ? (on ? 'border:1px solid #ee4d2d;color:#ee4d2d' : 'border:1px solid #e5e7eb;color:#222222') : 'border:1px solid #e5e7eb';
  return `<button class="${cls}" aria-label="${v}" aria-disabled="false" style="${st}"><img src="https://cf.shopee.vn/${encodeURIComponent(v)}.jpg">${v}${tick}</button>`;
}).join('')}</div></section>
<section><h3>Số Lượng</h3><div><button aria-label="Giảm">−</button><input value="1"><button aria-label="Tăng">+</button></div></section>
<div><span>Chia sẻ:</span><div><button aria-label="Messenger"></button><button aria-label="Facebook"></button></div></div>
<div><button>Thêm Vào Giỏ Hàng</button><button>Mua Ngay</button></div></body></html>`;

await t('Trang cá catnip: lấy 20.000 của loại đang chọn (không lấy 15.000 giá chung), giá gạch 28.000, loại Cá Trắm Cỏ', async () => {
  const r = runPage(fishPage('Cá Trắm Cỏ', 'class'), { vouchers: true });
  assert.equal(r.priceCandidates[0].amount, 20000); assert.equal(r.priceCandidates[0].source, 'dom');
  assert.ok(r.priceCandidates.some((c) => c.source === 'json-ld' && c.amount === 15000 && c.amountMax === 28000), 'giữ giá chung làm dự phòng');
  assert.equal(r.originalPrice, 28000);
  assert.deepEqual(r.variants.map((v) => [v.group, v.value]), [['Loại', 'Cá Trắm Cỏ']]);
  assert.equal(r.variantText, 'Cá Trắm Cỏ');
  assert.equal(r.imageSource, 'variant'); assert.ok(r.image?.includes('Tr'));
  assert.deepEqual(r.variantMissing, [], 'không báo nhầm nhóm Số lượng / Chia sẻ / nút mua');
  assert.equal(r.voucherTexts.length, 1); assert.ok(r.voucherTexts[0].endsWith('Giảm 20kđ'));
  const { parseVoucher } = await import('../features/ex10/voucher');
  assert.deepEqual([parseVoucher(r.voucherTexts[0]).kind, parseVoucher(r.voucherTexts[0]).amount], ['amount', 20000]);
});
await t('Loại được chọn chỉ nhận biết qua kiểu viền/màu (không có class)', () => {
  const r = runPage(fishPage('Cá Chép', 'style'));
  assert.equal(r.variantText, 'Cá Chép');
});
await t('Kiểu class của Shopee: "selection-box-unselected" KHÔNG bị tính là đang chọn (lỗi Cá thu đao)', () => {
  const r = runPage(fishPage('Cá Chép', 'shopee'));
  assert.equal(r.variantText, 'Cá Chép'); assert.ok(r.image?.includes('Ch'), 'ảnh theo loại đang chọn');
});
await t('Chỉ có dấu tick ở góc nút đang chọn', () => {
  assert.equal(runPage(fishPage('Cá Rồng Vàng', 'tick')).variantText, 'Cá Rồng Vàng');
});
await t('Chưa chọn loại: báo để người dùng chọn rồi bấm lại', () => {
  const r = runPage(fishPage('', 'none'));
  assert.equal(r.variantText, ''); assert.deepEqual(r.variantMissing, ['Loại']);
  assert.ok(r.notes.some((n) => n.includes('Chưa chọn Loại')));
});
await t('Hai nhóm phân loại (Màu + Size) qua aria-checked', () => {
  const r = runPage(`<html><body><div style="font-size:28px">₫250.000</div>
    <div><div>Màu sắc</div><div><button role="radio" aria-checked="true">Đen</button><button role="radio" aria-checked="false">Trắng</button></div></div>
    <div><div>Size</div><div><button role="radio" aria-checked="false">S</button><button role="radio" aria-checked="true">M</button><button role="radio" aria-checked="false">L</button></div></div></body></html>`);
  assert.equal(r.variantText, 'Đen – M'); assert.equal(r.priceCandidates[0].amount, 250000);
});
await t('Đọc Flash Sale trên trang: sắp diễn ra và đang diễn ra', () => {
  let r = runPage(`<html><body><div style="font-size:30px">20.000<span>đ</span></div>
    <div class="flash-sale-bar"><img alt="flash sale" src="x.png"><span>BẮT ĐẦU SAU 15:00, 26 Thg 10</span></div></body></html>`);
  assert.equal(r.flashSale?.kind, 'upcoming'); assert.equal(r.flashSale?.isFlash, true);
  const d = new Date(r.flashSale!.startsAt!);
  assert.deepEqual([d.getHours(), d.getMinutes(), d.getDate(), d.getMonth() + 1], [15, 0, 26, 10]);
  const before = Date.now();
  r = runPage(`<html><body><div><span>FLASH SALE</span><span>Kết thúc trong 01 : 30 : 00</span></div></body></html>`);
  assert.equal(r.flashSale?.kind, 'ongoing');
  const left = new Date(r.flashSale!.endsAt!).getTime() - before;
  assert.ok(left > 5390_000 && left < 5410_000);
  assert.equal(runPage('<html><body><div style="font-size:30px">20.000đ</div></body></html>').flashSale, null);
});

// ---------- Voucher (bản Lab)
const vc = await import('../features/ex10/voucher');
await t('Voucher: phân loại shop / Shopee / vận chuyển / hoàn xu; chưa lưu, HSD, đã dùng, hết lượt', () => {
  let v = vc.parseVoucher('Mã Giảm Giá Của Shop Giảm 20kđ');
  assert.deepEqual([v.kind, v.scope, v.amount], ['amount', 'shop', 20000]);
  v = vc.parseVoucher('Voucher Xtra Giảm 10% Giảm tối đa ₫30k Đơn Tối Thiểu ₫99k HSD: 31.10.2026 Đã dùng 85% Lưu');
  assert.deepEqual([v.kind, v.scope, v.percent, v.cap, v.minSpend, v.expires, v.usedPct, v.saved], ['percent', 'platform', 10, 30000, 99000, '31/10', 85, false]);
  v = vc.parseVoucher('Giảm ₫15k Đơn Tối Thiểu ₫0 Sắp hết hạn: Còn 2 ngày Đã lưu');
  assert.deepEqual([v.expires, v.saved], ['còn 2 ngày', true]);
  assert.equal(vc.parseVoucher('Hoàn 10% xu Đơn tối thiểu 50k').kind, 'coin');
  assert.equal(vc.parseVoucher('Miễn phí vận chuyển đơn từ 0đ').kind, 'shipping');
  assert.equal(vc.parseVoucher('Giảm ₫50k Đơn tối thiểu ₫200k Đã hết lượt').unavailable, true);
});
await t('Voucher: tốt nhất một mã, và ước tính dùng chung 1 mã shop + 1 mã Shopee', () => {
  const texts = ['Mã Giảm Giá Của Shop Giảm 20kđ Đơn tối thiểu 150k', 'Voucher của Shop Giảm 5% Giảm tối đa 30k',
    'Shopee Giảm 15% Giảm tối đa ₫50k Đơn Tối Thiểu ₫300k', 'Shopee Giảm ₫30k Đơn tối thiểu ₫200k', 'Giảm ₫100k Đơn tối thiểu ₫500k Đã hết lượt', 'Hoàn 5% xu', 'Miễn phí vận chuyển'];
  const r = vc.bestVoucher(texts, 378000);
  // 378k: Shopee 15% = 56,7k → chặn tối đa 50k (đơn ≥ 300k) là mã một mình tốt nhất
  assert.equal(r.best?.discount, 50000); assert.equal(r.best?.voucher.scope, 'platform');
  // Dùng chung: mã shop tốt nhất 20k (5% chỉ 18,9k) → còn 358k → Shopee 15% = 53,7k, chặn 50k → tổng 70k
  assert.ok(r.combo); assert.equal(r.combo!.shop.discount, 20000); assert.equal(r.combo!.platform.discount, 50000);
  assert.equal(r.combo!.discount, 70000); assert.equal(r.combo!.finalPrice, 308000);
  assert.ok(!r.ranked.some((e) => e.voucher.unavailable), 'bỏ mã hết lượt');
  assert.equal(r.coin.length, 1); assert.equal(r.shipping.length, 1);
});
await t('Voucher: combo mua nhiều món và ưu đãi thanh toán không tính vào giá 1 món', () => {
  const b = vc.parseVoucher('Combo khuyến mãi Mua 2 & giảm 5%');
  assert.deepEqual([b.kind, b.minQty, b.percent], ['bundle', 2, 5]);
  const p = vc.parseVoucher('Giảm ₫30k khi thanh toán bằng ShopeePay Đơn tối thiểu ₫100k');
  assert.deepEqual([p.scope, p.kind, p.amount], ['payment', 'amount', 30000]);
  const r = vc.bestVoucher(['Mua 2 & giảm 10%', 'Giảm ₫40k Thẻ tín dụng VIB Đơn tối thiểu ₫200k', 'Mã Giảm Giá Của Shop Giảm 15k'], 300000);
  assert.equal(r.best?.discount, 15000, 'combo và thanh toán không thành mã tốt nhất');
  assert.equal(r.bundle.length, 1); assert.equal(r.payment[0].discount, 40000);
});
await t('Voucher: gợi ý nên dùng mã nào, việc cần làm và lưu ý; không gợi ý mua thêm', () => {
  const texts = ['Mã Giảm Giá Của Shop Giảm 20kđ Đơn tối thiểu 150k Lưu', 'Shopee Giảm 15% Giảm tối đa ₫50k Đơn Tối Thiểu ₫300k HSD: 31.10.2026 Đã dùng 90% Đã lưu',
    'Shopee Giảm ₫100k Đơn tối thiểu ₫1tr', 'Miễn phí vận chuyển Đơn tối thiểu 0đ', 'Hoàn 5% xu'];
  const r = vc.bestVoucher(texts, 378000);
  const a = vc.adviseVoucher(r, 378000);
  assert.equal(a.combo, true); assert.equal(a.picks.length, 2);
  assert.deepEqual(a.picks.map((p) => p.role), ['shop', 'platform']);
  assert.equal(a.discount, 70000); assert.equal(a.finalPrice, 308000);
  assert.equal(a.todo.length, 1); assert.match(a.todo[0], /Lưu.*của shop/);
  assert.ok(a.cautions.some((c) => /31\/10/.test(c)) && a.cautions.some((c) => /90%/.test(c)) && a.cautions.some((c) => /dùng chung/.test(c)));
  assert.ok(a.extras.some((e) => /vận chuyển/.test(e)) && a.extras.some((e) => /hoàn xu/.test(e)));
  assert.ok(![...a.todo, ...a.cautions, ...a.extras].some((s) => /mua thêm|thêm .* để đủ/i.test(s)), 'không khuyến khích mua thêm');
  // chỉ có mã chưa đủ đơn → không có gợi ý
  const none = vc.adviseVoucher(vc.bestVoucher(['Shopee Giảm ₫100k Đơn tối thiểu ₫1tr'], 378000), 378000);
  assert.equal(none.picks.length, 0); assert.equal(none.finalPrice, 378000);
});
await t('Đọc danh sách voucher người dùng tự mở trên trang (thẻ dài có điều kiện, HSD, nút Lưu)', () => {
  const r = runPage(`<html><body><div style="font-size:30px">378.000<span>đ</span></div>
    <div role="dialog"><h3>Mã Giảm Giá Của Shop</h3>
      <div class="v"><div><span>Giảm 10%</span><span>Giảm tối đa ₫30k</span><span>Đơn Tối Thiểu ₫99k</span></div><div><span>HSD: 31.10.2026</span><span>Đã dùng 85%</span></div><button>Lưu</button></div>
      <div class="v"><div><span>Giảm ₫15k</span><span>Đơn Tối Thiểu ₫0</span></div><div><span>Sắp hết hạn: Còn 2 ngày</span></div><button>Đã lưu</button></div>
    </div></body></html>`, { vouchers: true });
  assert.equal(r.voucherTexts.length, 2, JSON.stringify(r.voucherTexts));
  const p = r.voucherTexts.map(vc.parseVoucher);
  assert.deepEqual(p.map((x) => [x.kind, x.saved, x.expires]), [['percent', false, '31/10'], ['amount', true, 'còn 2 ngày']]);
});
await t('Giá sau voucher lưu riêng (afterVoucher), không làm đổi giá chính hay nhãn so giá', async () => {
  const { memoryKV, setKV } = await import('../lib/kv'); setKV(memoryKV());
  const mod = await import('../features/items/repo');
  const a = await mod.addItem({ originalUrl: 'https://shopee.vn/t-i.7.7', url: 'https://shopee.vn/product/7/7', productKey: 'shopee:7:7', title: 'Tai nghe', price: { priceType: 'single', amountVnd: 378000, source: 'manual', confirmation: 'userConfirmed' } });
  await mod.addPrice(a.item.id, { priceType: 'afterVoucher', amountVnd: 318000, source: 'extensionPage', confirmation: 'userConfirmed' });
  const { items, prices } = await mod.loadAll();
  const v = buildViews(items, prices)[0];
  assert.equal(v.latest?.amountVnd, 378000); assert.equal(v.afterVoucher?.amountVnd, 318000);
  assert.equal(priceTag(v).label, 'Giá ổn định');
});

// ---------- Nối với app qua Firebase (lib/firebaseMap.ts)
const fm = await import('../lib/firebaseMap');
await t('Firebase: đổi động cơ / nhóm sang key của app và ngược lại; món ghi lên đúng trường', () => {
  assert.equal(fm.motiveToApp('khuyen-mai'), 'sale'); assert.equal(fm.motiveFromApp('social'), 'anh-huong-mxh');
  assert.equal(fm.groupToApp('cong-nghe'), 'tech'); assert.equal(fm.groupFromApp('beauty'), 'lam-dep');
  assert.equal(fm.groupFromApp('custom-group'), 'custom-group'); // nhóm người dùng tự tạo giữ nguyên
  const it = itm({ id: 'w_1', motive: 'nhu-cau', budgetGroupId: 'thoi-trang', originalUrl: 'https://shopee.vn/x-i.1.2', url: 'https://shopee.vn/product/1/2', productKey: 'shopee:1:2', variantLabel: 'Đen', buyIntentAt: iso('2026-10-26T09:00:00') });
  const d = fm.itemToDoc(it);
  assert.equal(d.motive, 'need'); assert.equal(d.budgetGroupId, 'fashion'); assert.equal(d.url, 'https://shopee.vn/x-i.1.2');
  assert.ok(d.createdAt instanceof Date && d.buyIntentAt instanceof Date); assert.equal(d.saveChannel, 'extension');
  assert.ok(!('latestPriceVnd' in d) && !('purchaseId' in d), 'chỉ app ghi giá mới nhất và purchaseId');
  assert.equal(fm.cooldownFor(it, 3), null); // Nhu cầu: không chờ
  assert.equal(fm.cooldownFor({ ...it, motive: 'cam-xuc' }, 3)?.toISOString(), iso('2026-10-13T10:00:00'));
});
await t('Firebase: đọc món từ app (Timestamp, món nhập tay, đã mua thì bỏ ý định mua)', () => {
  const ts = (s: string) => ({ toDate: () => new Date(s) });
  const a = fm.docToItem('abc', { title: 'Áo khoác', status: 'considering', motive: 'emotion', budgetGroupId: 'fashion', priority: 9, url: 'https://tiki.vn/ao', saveChannel: 'manual', createdAt: ts('2026-10-01T08:00:00Z'), updatedAt: ts('2026-10-05T08:00:00Z') });
  assert.deepEqual([a.motive, a.budgetGroupId, a.priority, a.url, a.originalUrl, a.syncState], ['cam-xuc', 'thoi-trang', 5, undefined, 'https://tiki.vn/ao', 'synced']);
  assert.equal(a.revision, Date.parse('2026-10-05T08:00:00Z'));
  const b = fm.docToItem('b', { title: 'X', status: 'purchased', purchaseId: 'p1', buyIntentAt: ts('2026-10-02T00:00:00Z'), createdAt: ts('2026-10-01T00:00:00Z') });
  assert.equal(b.buyIntentAt, undefined); assert.equal(b.purchaseId, 'p1'); assert.equal(b.revision, Date.parse('2026-10-01T00:00:00Z'));
});
await t('Firebase: giá theo rules của app (luôn có amountVnd > 0), giá sau voucher không làm giá mới nhất', () => {
  assert.equal(fm.priceToDoc(snap({ priceType: 'range', minVnd: 100000, maxVnd: 150000 }))?.amountVnd, 100000);
  assert.equal(fm.priceToDoc(snap({ amountVnd: 0 })), null);
  assert.equal(fm.priceToDoc(snap({ amountVnd: 50000, source: 'extensionPage', confirmation: 'unconfirmed' }))?.confirmation, 'unconfirmed');
  const latest = fm.latestPriceOf([snap({ amountVnd: 200000, observedAt: iso('2026-10-20T00:00:00') }), snap({ priceType: 'afterVoucher', amountVnd: 150000, observedAt: iso('2026-10-25T00:00:00') })]);
  assert.equal(latest?.vnd, 200000);
  const back = fm.docToPrice('s1', 'w', { amountVnd: 100000, minVnd: 100000, maxVnd: 150000, priceType: 'range', observedAt: new Date('2026-10-20T00:00:00Z') });
  assert.deepEqual([back?.amountVnd, back?.minVnd, back?.maxVnd, back?.confirmation, back?.source], [undefined, 100000, 150000, 'userConfirmed', 'manual']);
  assert.equal(fm.docToPrice('s2', 'w', { amountVnd: 0, observedAt: new Date() }), null);
});
await t('Firebase: "Mua" chỉ là ý định (không ghi decision buy); đọc decision của app', () => {
  assert.equal(fm.decisionToDoc({ id: 'd', itemId: 'w', choice: 'buy', at: iso('2026-10-26T09:00:00'), syncState: 'local' }), null);
  assert.equal(fm.decisionToDoc({ id: 'd', itemId: 'w', choice: 'wait', at: iso('2026-10-26T09:00:00'), reviewAt: iso('2026-11-02T09:00:00'), syncState: 'local' })?.choice, 'wait');
  assert.equal(fm.docToDecision('buy_w', { itemId: 'w', choice: 'buy', at: new Date('2026-10-26T00:00:00Z') })?.choice, 'buy');
  assert.equal(fm.docToDecision('x', { itemId: 'w', choice: 'nope', at: new Date() }), null);
});
await t('Firebase: ngân sách khả dụng như app (dự phòng chỉ khi đủ 30 ngày, bỏ khoản mua từ wishlist)', () => {
  const now = new Date('2026-10-26T10:00:00');
  const p = (amount: number, at: string, fromWishlist = false) => ({ amountVnd: amount, budgetGroupId: 'tech', occurredAt: iso(at), fromWishlist });
  const rows = [p(40000, '2026-10-05T10:00:00'), p(500000, '2026-10-10T10:00:00', true), p(90000, '2026-09-01T10:00:00')];
  const [l] = fm.budgetLines({ tech: 1_000_000, food: 0 }, rows, now, iso('2026-08-01T10:00:00'));
  assert.deepEqual([l.groupId, l.month, l.limitVnd, l.spentVnd, l.hasEnoughHistory], ['cong-nghe', '2026-10', 1_000_000, 540000, true]);
  assert.equal(l.dailyAvgVnd, Math.round(130000 / 86)); // 86 ngày dữ liệu, không tính 500k mua từ wishlist
  assert.equal(fm.budgetLines({ tech: 1_000_000 }, [p(40000, '2026-10-20T10:00:00')], now)[0].hasEnoughHistory, false);
});
await t('Firebase: lịch sale từ Remote Config; đồ đang có gom theo nhóm', () => {
  assert.deepEqual(fm.parseSaleCalendar('[{"date":"2026-11-11","name":"11.11","type":"double_day","confirmed":true}]'), [{ date: '2026-11-11T00:00:00', label: '11.11', verified: true }]);
  assert.deepEqual(fm.parseSaleCalendar('not json'), []);
  assert.deepEqual(fm.ownedLines([{ name: 'Tai nghe', budgetGroupId: 'tech' }, { name: 'Loa', budgetGroupId: 'tech' }, { name: 'Không nhóm' }]), [{ budgetGroupId: 'cong-nghe', name: 'tai nghe', count: 2 }]);
});
await t('Đồng bộ: món đã xoá trên app (không còn trong allIds) bị bỏ khỏi máy, món chưa đồng bộ giữ lại', async () => {
  const { memoryKV, setKV } = await import('../lib/kv'); setKV(memoryKV());
  const mod = await import('../features/items/repo');
  const kept = await mod.addItem({ originalUrl: 'https://shopee.vn/a-i.1.1', productKey: 'shopee:1:1', title: 'Giữ' });
  const gone = await mod.addItem({ originalUrl: 'https://shopee.vn/b-i.2.2', productKey: 'shopee:2:2', title: 'Đã xoá trên app' });
  await mod.addItem({ originalUrl: 'https://shopee.vn/c-i.3.3', productKey: 'shopee:3:3', title: 'Chưa đồng bộ' });
  await mod.setSyncState('items', [kept.item.id, gone.item.id], 'synced');
  await mod.dropSyncedExcept(new Set([kept.item.id]));
  assert.deepEqual((await mod.listItems()).map((i) => i.title).sort(), ['Chưa đồng bộ', 'Giữ']);
});
await t('Giá gốc + giá giảm (SteamDB): chọn cách lưu, giá gốc là giá chính, giá giảm kèm % và tên đợt', async () => {
  const base = { source: 'extensionPage' as const, confirmation: 'userConfirmed' as const };
  // Không giảm giá → một giá như cũ
  assert.deepEqual(repo.salePrices({ ...base, nowVnd: 200_000, originalVnd: null, mode: 'both' }).map((p) => p.priceType), ['single']);
  assert.deepEqual(repo.salePrices({ ...base, nowVnd: 200_000, originalVnd: 150_000, mode: 'both' }).map((p) => p.amountVnd), [200_000]); // "giá gốc" thấp hơn → bỏ
  // Có giảm: cả hai / chỉ gốc / chỉ giảm
  const both = repo.salePrices({ ...base, nowVnd: 140_000, originalVnd: 200_000, mode: 'both', saleLabel: '  11.11 ' });
  assert.deepEqual(both.map((p) => [p.priceType, p.amountVnd]), [['single', 200_000], ['sale', 140_000]]);
  assert.equal(both[1].originalVnd, 200_000); assert.equal(both[1].saleLabel, '11.11');
  assert.deepEqual(repo.salePrices({ ...base, nowVnd: 140_000, originalVnd: 200_000, mode: 'original' }).map((p) => [p.priceType, p.amountVnd]), [['single', 200_000]]);
  assert.deepEqual(repo.salePrices({ ...base, nowVnd: 140_000, originalVnd: 200_000, mode: 'sale' }).map((p) => p.priceType), ['sale']);
  assert.equal(repo.salePrices({ ...base, nowVnd: 140_000, originalVnd: 200_000, mode: 'sale', flash: true })[0].saleLabel, 'Flash Sale');
  assert.equal(repo.discountPct(140_000, 200_000), 30);

  const { memoryKV, setKV } = await import('../lib/kv'); setKV(memoryKV());
  const mod = await import('../features/items/repo');
  const { item } = await mod.addItem({ originalUrl: 'https://shopee.vn/x-i.9.9', productKey: 'shopee:9:9', title: 'Tai nghe', price: both[0] }, '2026-11-01T10:00:00.000Z');
  await mod.addPrice(item.id, both[1], '2026-11-01T10:00:00.000Z');
  await mod.addPrice(item.id, { ...both[1], amountVnd: 120_000, saleLabel: 'Flash Sale' }, '2026-11-11T10:00:00.000Z');
  const [v] = buildViews([item], await mod.pricesFor(item.id));
  assert.equal(v.latest?.amountVnd, 200_000);            // giá chính vẫn là giá gốc
  assert.equal(v.sale?.amountVnd, 120_000);              // giá giảm gần nhất
  assert.equal(v.lowestSale?.saleLabel, 'Flash Sale');   // giảm thấp nhất đã ghi
  const fm = await import('../lib/firebaseMap');
  assert.equal(fm.latestPriceOf(await mod.pricesFor(item.id))?.vnd, 200_000);
  const doc = fm.priceToDoc(v.sale!)!;
  assert.equal(doc.priceType, 'sale'); assert.equal(doc.saleLabel, 'Flash Sale'); assert.equal(doc.originalVnd, 200_000);
  assert.equal(fm.docToPrice('s', item.id, { ...doc, observedAt: new Date() })?.saleLabel, 'Flash Sale');
});

// ---------- Cào voucher cho Admin (shopeeVouchers)
const av = await import('../features/admin/vouchers');
await t('Admin cào voucher: id ổn định theo shop, bỏ trùng, đủ trường cho firestore.rules', () => {
  const page = { url: 'https://shopee.vn/Do-Choi-i.111.222?sp_atk=x', name: 'Đồ chơi', shopName: 'Shop Mèo',
    voucherTexts: ['Mã Giảm Giá Của Shop Giảm 20kđ', 'Voucher Xtra Giảm 10% Giảm tối đa ₫30k Đơn Tối Thiểu ₫99k HSD: 31.10.2026 Đã dùng 85% Lưu', 'Mã Giảm Giá Của Shop Giảm 20kđ'] };
  const docs = av.voucherDocs(page, 'owner-1');
  assert.equal(docs.length, 2, 'bỏ voucher trùng');
  assert.deepEqual(docs[0].data, { raw: 'Mã Giảm Giá Của Shop Giảm 20kđ', kind: 'amount', scope: 'shop', unavailable: false,
    sourceUrl: 'https://shopee.vn/product/111/222', capturedBy: 'owner-1', source: 'extension', amountVnd: 20000,
    shopId: '111', shopName: 'Shop Mèo', productKey: 'shopee:111:222', productTitle: 'Đồ chơi' });
  assert.deepEqual([docs[1].data.percent, docs[1].data.capVnd, docs[1].data.minSpendVnd, docs[1].data.usedPct, docs[1].data.expiresText], [10, 30000, 99000, 85, '31/10']);
  assert.ok(Object.values(docs[1].data).every((v) => v !== undefined), 'không gửi undefined lên Firestore');
  // cùng shop, sản phẩm khác → cùng id (voucher của shop); trang shop không có id → tách theo đường dẫn
  assert.equal(av.voucherDocs({ ...page, url: 'https://shopee.vn/x-i.111.999' }, 'o')[0].id, docs[0].id);
  const shopPage = av.voucherDocs({ ...page, url: 'https://shopee.vn/shopmeo?tab=1' }, 'o')[0];
  assert.notEqual(shopPage.id, docs[0].id); assert.equal(shopPage.data.sourceUrl, 'https://shopee.vn/shopmeo');
  assert.equal(shopPage.data.productKey, undefined); assert.equal(shopPage.data.productTitle, undefined);
  assert.match(docs[0].id, /^v_[0-9a-z]+$/);
  // hạn sử dụng đủ năm, giờ bắt đầu, đợt sale, phạm vi áp dụng; tên shop lấy từ tiêu đề trang shop
  const sale = av.voucherDocs({ ...page, voucherTexts: ['Mã 11.11 Siêu Sale Giảm 15% Đơn tối thiểu ₫0 Có hiệu lực từ: 00:00 11.11.2026 Có hiệu lực đến: 23:59 11.11.2026 Áp dụng cho một số shop nhất định Lưu'] }, 'o')[0].data;
  assert.deepEqual([sale.expiresText, sale.expiresDate, sale.startsText, sale.saleLabel, sale.appliesText], ['11/11', '2026-11-11', '00:00 11/11', '11.11 · Siêu Sale', 'Áp dụng cho một số shop nhất định']);
  assert.equal(docs[1].data.expiresDate, '2026-10-31'); assert.ok(!('saleLabel' in docs[0].data), 'mã không ghi đợt sale');
  assert.equal(vc.parseVoucher('Giảm ₫15k Có hiệu lực sau: 2 giờ Sale Sinh Nhật').starts, 'còn 2 giờ');
  assert.equal(vc.parseVoucher('Giảm ₫10k HSD: 31.10.2026').sale, undefined, 'ngày HSD không phải đợt sale');
  for (const s of ['Giảm ₫100k Đơn tối thiểu ₫1.1tr', 'Giảm 2.2% tối đa 50k', 'Giảm ₫20k HSD: 12.12', 'Giảm ₫20k Có hiệu lực từ: 00:00 11.11.2026'])
    assert.equal(vc.parseVoucher(s).sale, undefined, `không phải đợt sale: ${s}`);
  assert.equal(vc.parseVoucher('Voucher 12.12 Giảm ₫50k').sale, '12.12');
  assert.equal(av.shopNameFromTitle('Shop Mèo, Cửa hàng trực tuyến | Shopee Việt Nam', 'https://shopee.vn/shopmeo?x=1'), 'Shop Mèo');
  assert.equal(av.shopNameFromTitle('Shopee Việt Nam | Mua và Bán', 'https://shopee.vn/'), null);
  assert.equal(av.shopNameFromTitle('Đồ chơi | Shopee', 'https://shopee.vn/Do-Choi-i.111.222'), null);
  assert.deepEqual(av.ownerOf('uidA:anonB'), { uid: 'uidA', sid: 'anonB' }); assert.equal(av.ownerOf('bad'), null);
});
await t('Tên shop: không lấy chữ trạng thái ("Không có sẵn", "Online…") làm tên; ưu tiên chữ trong link tới shop', () => {
  const shopBox = (name: string) => `<html><body><h1>Đồ chơi</h1><div class="shop">
    <div><span>Không có sẵn</span><span>Online 5 Phút Trước</span></div>
    <a href="/shopmeo"><img src="a.jpg"><div>${name}</div></a>
    <div><button>Chat Ngay</button><a href="/shopmeo"><span>Xem Shop</span></a></div>
    <div><span>Đánh Giá</span><span>12,3k</span><span>Sản Phẩm</span><span>120</span></div></div></body></html>`;
  assert.equal(runPage(shopBox('Shop Mèo Con')).shopName, 'Shop Mèo Con');
  // không có chữ tên shop nào → dùng tên đăng nhập trong link, không dùng "Không có sẵn"
  assert.equal(runPage(shopBox('')).shopName, 'shopmeo');
});
await t('Cào voucher từ trang chủ: nhận trang chủ, mỗi shop 1 sản phẩm, dừng khi gặp captcha / đăng nhập', async () => {
  const hc = await import('../features/admin/homeCrawl');
  assert.equal(hc.isShopeeHome('https://shopee.vn/'), true); assert.equal(hc.isShopeeHome('https://shopee.vn/?is_from_login=true'), true);
  assert.equal(hc.isShopeeHome('https://shopee.vn/shopmeo'), false); assert.equal(hc.isShopeeHome('https://notshopee.vn/'), false);
  const links = [{ url: 'a', shopId: '1' }, { url: 'b', shopId: '1' }, { url: 'c', shopId: '2' }, { url: 'd', shopId: '3' }];
  assert.deepEqual(hc.pickShops(links).map((l) => l.url), ['a', 'c', 'd']);
  assert.deepEqual(hc.pickShops(links, 2).map((l) => l.url), ['a', 'c']);
  assert.equal(hc.isBlockedUrl('https://shopee.vn/verify/traffic?x=1'), true);
  assert.equal(hc.isBlockedUrl('https://shopee.vn/buyer/login?next=x'), true);
  assert.equal(hc.isBlockedUrl('https://shopee.vn/Do-Choi-i.1.2'), false);
});
console.log('\nTất cả test đạt');

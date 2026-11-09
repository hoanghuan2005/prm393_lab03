// Phần chạy trong background (service worker) của lượt cào voucher từ trang chủ – xem homeCrawl.ts.
import { browser } from 'wxt/browser';
import { readPage, type PageRead } from '../ex10/reader';
import { expandVoucherLists, shopNameFromTitle, voucherDocs, type VoucherDoc } from './vouchers';
import { CRAWL_GAP_MS, CRAWL_KEY, collectProductLinks, isBlockedUrl, pickShops, type CrawlState, type ProductLink } from './homeCrawl';

const LOAD_TIMEOUT_MS = 25_000;
const RENDER_WAIT_MS = 2_500;           // Shopee dựng trang bằng JS sau khi tải xong
const MAX_FAILS_IN_ROW = 3;             // 3 trang lỗi liên tiếp → có vấn đề chung (mạng, đăng nhập…), dừng hẳn
const KEEPALIVE_MS = 20_000;            // service worker MV3 bị tắt sau ~30 giây không gọi API extension

let active = false;                     // chặn bấm 2 lần trước khi trạng thái kịp ghi vào storage

class FatalError extends Error {}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function getState(): Promise<CrawlState | null> {
  return ((await browser.storage.local.get(CRAWL_KEY))[CRAWL_KEY] as CrawlState | undefined) ?? null;
}
async function patchState(p: Partial<CrawlState>): Promise<CrawlState> {
  const next = { ...((await getState()) ?? { running: false, total: 0, done: 0, pushed: 0 }), ...p } as CrawlState;
  await browser.storage.local.set({ [CRAWL_KEY]: next });
  return next;
}

export async function requestStop(): Promise<void> {
  const s = await getState();
  if (!s?.running) return;
  // không có lượt nào thật sự chạy trong worker này → trạng thái cũ, đóng luôn để popup không kẹt ở "Đang dừng…"
  await patchState(active ? { stopRequested: true } : { running: false, current: undefined, finishedAt: Date.now() });
}

function waitForLoad(tabId: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { done(); reject(new Error('Trang tải quá lâu.')); }, LOAD_TIMEOUT_MS);
    const onUpdated = (id: number, info: { status?: string }) => { if (id === tabId && info.status === 'complete') { done(); resolve(); } };
    const onRemoved = (id: number) => { if (id === tabId) { done(); reject(new Error('Tab đã bị đóng.')); } };
    function done() { clearTimeout(timer); browser.tabs.onUpdated.removeListener(onUpdated); browser.tabs.onRemoved.removeListener(onRemoved); }
    browser.tabs.onUpdated.addListener(onUpdated);
    browser.tabs.onRemoved.addListener(onRemoved);
    browser.tabs.get(tabId).then((t) => { if (t.status === 'complete') { done(); resolve(); } }).catch(() => {});
  });
}

// Service worker không có XMLHttpRequest → dùng Firestore Lite (REST/fetch). Phiên ẩn danh đã liên kết QR
// được khôi phục từ IndexedDB chung của extension (lib/firebase.ts).
async function uploadFromWorker(docs: VoucherDoc[]): Promise<number> {
  if (!docs.length) return 0;
  const { app, currentUser } = await import('../../lib/firebase');
  if (!(await currentUser())) throw new FatalError('Extension chưa đăng nhập Firebase. Mở popup để liên kết lại.');
  const { getFirestore, doc, serverTimestamp, writeBatch } = await import('firebase/firestore/lite');
  const db = getFirestore(app);
  const batch = writeBatch(db);
  for (const d of docs) batch.set(doc(db, 'shopeeVouchers', d.id), { ...d.data, lastSeenAt: serverTimestamp() });
  await batch.commit();
  return docs.length;
}

async function scrapeOne(link: ProductLink, ownerUid: string): Promise<number> {
  const tab = await browser.tabs.create({ url: link.url, active: false });
  if (tab.id == null) throw new Error('Không mở được tab.');
  try {
    await waitForLoad(tab.id);
    await sleep(RENDER_WAIT_MS);
    const t = await browser.tabs.get(tab.id);
    if (isBlockedUrl(t.url)) throw new BlockedError();
    await browser.scripting.executeScript({ target: { tabId: tab.id }, func: expandVoucherLists });
    const res = await browser.scripting.executeScript({ target: { tabId: tab.id }, func: readPage, args: [{ vouchers: true, maxVouchers: 200 }] });
    const page = res[0]?.result as PageRead | undefined;
    if (!page) return 0;
    if (!page.shopName) page.shopName = shopNameFromTitle(t.title, page.url);
    return await uploadFromWorker(voucherDocs(page, ownerUid));
  } finally {
    await browser.tabs.remove(tab.id).catch(() => {});
  }
}

class BlockedError extends FatalError {
  constructor() { super('Shopee yêu cầu xác minh (captcha) hoặc đăng nhập. Đã dừng; hãy xác minh trên Shopee rồi chạy lại sau ít phút.'); }
}

// Bắt đầu từ tab trang chủ đang mở. Trả về ngay; tiến độ ghi vào storage (CRAWL_KEY) để popup hiển thị.
export async function startCrawl(homeTabId: number, ownerUid: string): Promise<void> {
  // Chỉ có một service worker: `active` = false nghĩa là không có lượt nào đang chạy (running cũ trong storage là
  // của worker đã bị tắt) → bắt đầu lượt mới.
  if (active) return;
  active = true;
  const keepAlive = setInterval(() => { browser.runtime.getPlatformInfo().catch(() => {}); }, KEEPALIVE_MS);
  await browser.storage.local.set({ [CRAWL_KEY]: { running: true, total: 0, done: 0, pushed: 0, current: 'Đang gom sản phẩm trên trang chủ…' } satisfies CrawlState });
  try {
    const res = await browser.scripting.executeScript({ target: { tabId: homeTabId }, func: collectProductLinks });
    const links = pickShops((res[0]?.result as ProductLink[] | undefined) ?? []);
    if (!links.length) { await patchState({ running: false, error: 'Không thấy sản phẩm nào trên trang chủ. Cuộn xuống mục "Gợi ý hôm nay" rồi bấm lại.', current: undefined, finishedAt: Date.now() }); return; }
    await patchState({ total: links.length });
    let pushed = 0, failed = 0, failsInRow = 0;
    for (let i = 0; i < links.length; i++) {
      if ((await getState())?.stopRequested) break;
      const started = Date.now();
      await patchState({ current: `Shop ${i + 1}/${links.length}` });
      try {
        pushed += await scrapeOne(links[i], ownerUid);
        failsInRow = 0;
      } catch (e) {
        if (e instanceof FatalError) throw e;
        const code = String((e as any)?.code ?? '');
        if (code === 'permission-denied') throw new Error('Firebase từ chối ghi (permission-denied). Kiểm tra role tài khoản và firestore.rules.');
        // lỗi một trang (tải lâu, tab bị đóng…) → bỏ qua, sang shop tiếp theo; lỗi liên tiếp → dừng
        failed++;
        if (++failsInRow >= MAX_FAILS_IN_ROW) throw new Error(`${MAX_FAILS_IN_ROW} shop liên tiếp bị lỗi (${code || (e as Error)?.message || e}). Đã dừng; kiểm tra mạng / Shopee rồi chạy lại.`);
      }
      await patchState({ done: i + 1, pushed, failed });
      if (i < links.length - 1) await sleep(Math.max(0, CRAWL_GAP_MS - (Date.now() - started)) + Math.floor(Math.random() * 2_000));
    }
    await patchState({ running: false, current: undefined, finishedAt: Date.now() });
  } catch (e) {
    await patchState({ running: false, current: undefined, error: (e as Error)?.message ?? String(e), finishedAt: Date.now() });
  } finally {
    clearInterval(keepAlive);
    active = false;
  }
}

// Service worker bị tắt giữa chừng (trình duyệt đóng…) → trạng thái "đang chạy" cũ không còn đúng.
export async function resetStaleCrawl(): Promise<void> {
  const s = await getState();
  if (s?.running && !active) await patchState({ running: false, current: undefined, error: 'Lượt cào trước bị gián đoạn.', finishedAt: Date.now() });
}

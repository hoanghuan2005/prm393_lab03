// Nút "Cào voucher" cho Admin/Nhân viên: chỉ hiện ở bản Lab + Firebase, khi tài khoản đã liên kết có role
// staff/admin và tab đang mở là shopee.vn. Một lần bấm: mở danh sách voucher → đọc trang → ghi lên Firestore.
import { useEffect, useState } from 'react';
import { browser } from 'wxt/browser';
import { readPage, type PageRead } from '../features/ex10/reader';
import { MAX_SCRAPE, expandVoucherLists, ownerOf, shopNameFromTitle, staffRoleOf, uploadVouchers, voucherDocs, type StaffRole } from '../features/admin/vouchers';
import { CRAWL_KEY, CRAWL_MAX_SHOPS, isShopeeHome, type CrawlState } from '../features/admin/homeCrawl';

const RESULT_SHOW_MS = 60 * 60_000; // kết quả lượt cào trang chủ chỉ hiện trong 1 giờ sau khi xong

type State = { kind: 'idle' } | { kind: 'busy' } | { kind: 'done'; count: number; shop?: string } | { kind: 'error'; message: string };

export function AdminVoucherBar({ token }: { token?: string }) {
  const [role, setRole] = useState<StaffRole | null>(null);
  const [tab, setTab] = useState<{ id: number; url: string } | null>(null);
  const [state, setState] = useState<State>({ kind: 'idle' });
  const [crawl, setCrawl] = useState<CrawlState | null>(null);

  // Tiến độ lượt cào trang chủ do background ghi vào storage
  useEffect(() => {
    browser.storage.local.get(CRAWL_KEY).then((r) => setCrawl((r[CRAWL_KEY] as CrawlState | undefined) ?? null));
    const onChanged = (ch: Record<string, { newValue?: unknown }>, area: string) => {
      if (area === 'local' && ch[CRAWL_KEY]) setCrawl((ch[CRAWL_KEY].newValue as CrawlState | undefined) ?? null);
    };
    browser.storage.onChanged.addListener(onChanged);
    return () => browser.storage.onChanged.removeListener(onChanged);
  }, []);

  useEffect(() => { (async () => {
    const [t] = await browser.tabs.query({ active: true, currentWindow: true });
    if (t?.id == null || !t.url || !/^https:\/\/([a-z0-9-]+\.)?shopee\.vn\//i.test(t.url)) return;
    setTab({ id: t.id, url: t.url });
    setRole(await staffRoleOf(token).catch(() => null));
  })(); }, [token]);

  if (!role || !tab) return null;

  async function scrape() {
    const owner = ownerOf(token);
    if (!owner || !tab) return;
    setState({ kind: 'busy' });
    try {
      await browser.scripting.executeScript({ target: { tabId: tab.id }, func: expandVoucherLists });
      const res = await browser.scripting.executeScript({ target: { tabId: tab.id }, func: readPage, args: [{ vouchers: true, maxVouchers: MAX_SCRAPE }] });
      const page = res[0]?.result as PageRead | undefined;
      if (!page) throw new Error('Không đọc được trang.');
      if (!page.shopName) page.shopName = shopNameFromTitle((await browser.tabs.get(tab.id)).title, page.url);
      const docs = voucherDocs(page, owner.uid);
      if (!docs.length) { setState({ kind: 'error', message: 'Không thấy voucher nào trên trang. Mở danh sách voucher của shop rồi bấm lại.' }); return; }
      const count = await uploadVouchers(docs);
      setState({ kind: 'done', count, shop: page.shopName ?? undefined });
    } catch (e) {
      const code = String((e as any)?.code ?? '');
      setState({ kind: 'error', message: code === 'permission-denied'
        ? 'Firebase từ chối ghi (permission-denied). Kiểm tra role của tài khoản và đã deploy firestore.rules.'
        : `Chưa đẩy được voucher: ${code || (e as Error)?.message || e}` });
    }
  }

  function startCrawl() {
    const owner = ownerOf(token);
    if (!owner || !tab) return;
    browser.runtime.sendMessage({ type: 'voucherCrawl:start', tabId: tab.id, ownerUid: owner.uid }).catch(() => {}); // background không trả lời
  }

  const home = isShopeeHome(tab.url);
  return (
    <section className="card admin-bar" aria-label="Công cụ Admin">
      <p className="card-title"><span className="t-label">Công cụ {role === 'admin' ? 'Admin' : 'Nhân viên'}</span><span className="t-caption muted">shopeeVouchers</span></p>
      {crawl?.running ? (
        <>
          <p className="t-caption" role="status">
            Đang tự cào voucher: {crawl.current ?? '…'}{crawl.total ? ` · xong ${crawl.done}/${crawl.total} shop` : ''} · đã đẩy {crawl.pushed} voucher. Có thể đóng popup, việc vẫn chạy.
          </p>
          <button className="btn block" disabled={crawl.stopRequested} onClick={() => browser.runtime.sendMessage({ type: 'voucherCrawl:stop' }).catch(() => {})}>
            {crawl.stopRequested ? 'Đang dừng sau shop hiện tại…' : 'Dừng'}
          </button>
        </>
      ) : home ? (
        <>
          <button className="btn tonal block" onClick={startCrawl}>Tự cào voucher từ trang chủ</button>
          <p className="t-caption muted">Mở lần lượt tối đa {CRAWL_MAX_SHOPS} shop ở tab nền, đọc voucher rồi đóng tab.</p>
        </>
      ) : (
        <button className="btn tonal block" disabled={state.kind === 'busy'} onClick={scrape}>
          {state.kind === 'busy' ? 'Đang cào voucher…' : 'Cào toàn bộ voucher lên Firebase'}
        </button>
      )}
      {!crawl?.running && crawl?.finishedAt && Date.now() - crawl.finishedAt < RESULT_SHOW_MS && (
        crawl.error
          ? <p className="error-text" role="alert">{crawl.error}{crawl.done ? ` (đã xong ${crawl.done}/${crawl.total} shop, đẩy ${crawl.pushed} voucher)` : ''}</p>
          : <p className="t-caption" role="status">Lượt cào trang chủ xong: {crawl.done}/{crawl.total} shop, đẩy {crawl.pushed} voucher lên Firebase{crawl.failed ? ` (bỏ qua ${crawl.failed} shop lỗi)` : ''}.</p>
      )}
      {state.kind === 'done' && <p className="t-caption" role="status">Đã đẩy {state.count} voucher{state.shop ? ` của ${state.shop}` : ''} lên Firebase.</p>}
      {state.kind === 'error' && <p className="error-text" role="alert">{state.message}</p>}
    </section>
  );
}

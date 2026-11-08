// Trang extension X2 / X3 / X4 / X4a / X5 (handoff "X2 – X5 Trang extension").
import { useCallback, useEffect, useRef, useState } from 'react';
import { browser } from 'wxt/browser';
import type { PairingState, Settings } from '../../types';
import { AppIcon, PriceTag, Switch, Thumb, VerdictTag } from '../../components/ui';
import { IconAlert, IconBookmark, IconClose, IconDownload, IconHelp, IconLink, IconSearch, IconShieldCheck } from '../../components/Icons';
import { DecisionCard } from '../../components/DecisionCard';
import { PairForm } from '../../components/PairForm';
import { clearLocalData, exportJson, getSettings, loadAll, removeItem, setSettings } from '../../features/items/repo';
import { cancelReminders } from '../../features/reminders/reminders';
import { buildViews, fmtPrice, freshness, priceTag, type ItemView } from '../../features/items/price';
import { verdict } from '../../features/decision/rules';
import { getPairing, mockApi, unpair } from '../../features/pairing/pairing';
import { getSyncMeta, syncNow, type SyncMeta } from '../../features/sync/sync';
import { loadDecisionContext, type DecisionContext } from '../../features/decision/context';
import { fmtDayMonth, fmtProductRating, fmtShopRating, fmtTime } from '../../lib/format';
import { IS_DEMO, IS_FIREBASE, IS_LAB } from '../../lib/env';

type Route = 'wishlist' | 'pair' | 'settings';
const routeFromHash = (): Route => (['wishlist', 'pair', 'settings'].includes(location.hash.slice(1)) ? (location.hash.slice(1) as Route) : 'wishlist');

export default function App() {
  const [route, setRoute] = useState<Route>(routeFromHash());
  const [views, setViews] = useState<ItemView[]>([]);
  const [pairing, setPairing] = useState<PairingState>({ linked: false });
  const [settings, setS] = useState<Settings | null>(null);
  const [ctx, setCtx] = useState<DecisionContext | null>(null);
  const [meta, setMeta] = useState<SyncMeta>({ attempt: 0 });
  const [selected, setSelected] = useState<string | null>(null);
  const retry = useRef<number | undefined>(undefined);

  const reload = useCallback(async () => {
    const [{ items, prices }, p, s, c, m] = await Promise.all([loadAll(), getPairing(), getSettings(), loadDecisionContext(), getSyncMeta()]);
    setViews(buildViews(items, prices)); setPairing(c.revoked ? await getPairing() : p); setS(s); setCtx(c); setMeta(m);
    // E07: hẹn lần thử lại theo lịch giãn dần trong lúc trang đang mở
    window.clearTimeout(retry.current);
    if (m.nextRetryAt) retry.current = window.setTimeout(() => syncNow().finally(reload), Math.max(1000, new Date(m.nextRetryAt).getTime() - Date.now()));
  }, []);

  useEffect(() => {
    const onHash = () => setRoute(routeFromHash());
    const onStore = (ch: Record<string, unknown>, area: string) => {
      if (area === 'local' && ['wib_items', 'wib_prices', 'wib_decisions', 'wib_pairing', 'wib_settings', 'wib_sync_state'].some((k) => k in ch)) reload();
    };
    const onVisible = () => { if (document.visibilityState === 'visible') syncNow().catch(() => {}).finally(reload); };
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') setSelected(null); }; // TC-19
    window.addEventListener('hashchange', onHash);
    window.addEventListener('keydown', onKey);
    document.addEventListener('visibilitychange', onVisible);
    browser.storage.onChanged.addListener(onStore);
    syncNow().catch(() => {}).finally(reload);
    return () => {
      window.removeEventListener('hashchange', onHash); window.removeEventListener('keydown', onKey);
      document.removeEventListener('visibilitychange', onVisible); browser.storage.onChanged.removeListener(onStore);
      window.clearTimeout(retry.current);
    };
  }, [reload]);

  const go = (r: Route) => { location.hash = r; setRoute(r); };
  const sel = views.find((v) => v.item.id === selected) ?? null;
  useEffect(() => { if (selected && !views.some((v) => v.item.id === selected)) setSelected(null); }, [views, selected]);

  return (
    <div className="shell">
      <nav className="side" aria-label="Điều hướng">
        <div className="logo"><AppIcon size={32} /><span className="t-label">Why I Buy? · Extension</span></div>
        <button className="nav" aria-current={route === 'wishlist' ? 'page' : undefined} onClick={() => go('wishlist')}><IconBookmark /><span>Danh sách mong muốn</span></button>
        <button className="nav" aria-current={route === 'pair' ? 'page' : undefined} onClick={() => go('pair')}><IconShieldCheck /><span>Liên kết thiết bị</span></button>
        <button className="nav" aria-current={route === 'settings' ? 'page' : undefined} onClick={() => go('settings')}><IconHelp /><span>Cài đặt &amp; quyền riêng tư</span></button>
      </nav>
      <main className={`content${route === 'wishlist' ? '' : ' single'}`}>
        <div className="col">
          {pairing.revokedNotice && (
            <div className="note-banner err" role="alert">
              <span className="ic"><IconAlert /></span>
              <p className="t-body-sm tx">{IS_FIREBASE ? 'Liên kết đã bị huỷ, vui lòng liên kết lại.' : 'Liên kết đã bị huỷ, vui lòng nhập mã mới.'} Các món chưa đồng bộ vẫn được giữ trên máy này.</p>
              <button className="btn primary" style={{ height: 40 }} onClick={() => go('pair')}>{IS_FIREBASE ? 'Liên kết lại' : 'Nhập mã mới'}</button>
            </div>
          )}
          {meta.conflict && route === 'wishlist' && <div className="note-banner"><span className="ic"><IconHelp /></span><p className="t-body-sm tx">{meta.conflict} Đang hiện bản mới nhất.</p></div>}
          {route === 'wishlist' && ctx && <Wishlist views={views} ctx={ctx} pairing={pairing} settings={settings} meta={meta} selected={selected} onSelect={setSelected} onLink={() => go('pair')} onRetry={() => syncNow({ force: true }).finally(reload)} />}
          {route === 'pair' && <Pair pairing={pairing} onChanged={reload} onOpenList={() => go('wishlist')} />}
          {route === 'settings' && settings && <SettingsPage settings={settings} pairing={pairing} onChanged={reload} setS={setS} />}
        </div>
        {route === 'wishlist' && (sel && ctx ? (
          <aside className="detail" aria-label="Decision Card">
            <button className="close" aria-label="Đóng (Esc)" onClick={() => setSelected(null)}><IconClose size={20} /></button>
            <DecisionCard view={sel} views={views} ctx={ctx} onChanged={() => { syncNow().finally(reload); }} onRemoved={() => { setSelected(null); syncNow().finally(reload); }} onOpenItem={setSelected} />
          </aside>
        ) : views.length > 0 ? (
          <aside className="detail-empty">
            <span className="ic"><IconBookmark /></span>
            <p className="t-label" style={{ color: 'var(--on-surface)' }}>Chọn một món để cân nhắc</p>
            <p className="t-caption">Decision Card cho thấy giá, ngân sách và thời điểm, rồi để bạn chọn Mua, Chờ hoặc Bỏ qua.</p>
          </aside>
        ) : null)}
      </main>
    </div>
  );
}

// ---------- X2 / X2a
function Wishlist({ views, ctx, pairing, settings, meta, selected, onSelect, onLink, onRetry }: {
  views: ItemView[]; ctx: DecisionContext; pairing: PairingState; settings: Settings | null; meta: SyncMeta; selected: string | null;
  onSelect: (id: string) => void; onLink: () => void; onRetry: () => void;
}) {
  const [filter, setFilter] = useState<'considering' | 'purchased' | 'skipped' | 'all'>('considering');
  const [q, setQ] = useState('');
  const unsynced = views.filter((v) => v.item.syncState !== 'synced').length;
  const errors = views.filter((v) => v.item.syncState === 'error').length;
  const chip = !pairing.linked ? 'Chỉ trên máy' : !settings?.syncOn ? 'Chỉ trên máy · đồng bộ đang tắt' : errors ? 'Lỗi đồng bộ' : unsynced ? 'Chờ đồng bộ' : 'Đã đồng bộ';
  const shown = views.filter((v) => (filter === 'all' || v.item.status === filter) && (!q || v.item.title.toLowerCase().includes(q.toLowerCase())));
  const [removing, setRemoving] = useState(false);
  // Xoá tất cả món đang hiển thị (theo bộ lọc + ô tìm); món đã đồng bộ được đánh dấu xoá rồi đẩy lên app
  const removeShown = async () => {
    if (!shown.length || !confirm(`Xoá ${shown.length} món đang hiển thị khỏi danh sách? Không thể hoàn tác.`)) return;
    setRemoving(true);
    try {
      for (const v of shown) { await removeItem(v.item.id); await cancelReminders(v.item.id); }
      onSelect('');
      await syncNow().catch(() => {});
    } finally { setRemoving(false); }
  };
  const sub = (v: ItemView) => {
    const f = freshness(v.latest);
    const parts = [`Lưu ${fmtDayMonth(v.item.createdAt)}`, !v.latest ? 'chưa có giá' : f === 'old' ? `giá cũ ${fmtDayMonth(v.latest.observedAt)}` : `giá ghi ${fmtDayMonth(v.latest.observedAt)}`];
    if (v.item.status === 'considering' && v.item.buyIntentAt) parts.push('chờ app ghi khoản mua');
    else if (v.item.status === 'considering' && v.item.reviewAt) parts.push(`xem lại ${fmtDayMonth(v.item.reviewAt)}`);
    if (pairing.linked && v.item.syncState !== 'synced') parts.push('Chờ đồng bộ');
    return parts.join(' · ');
  };
  const tone = !pairing.linked ? '' : errors ? ' err' : unsynced ? ' warn' : ' ok';
  return (
    <>
      <div className="pagehead">
        <p className="t-title">Danh sách mong muốn</p>
        <span className={`badge${tone}`}><span className="dot" />{pairing.linked ? `${chip} · ${pairing.deviceLabel}` : 'Chỉ trên máy này'}</span>
        <button className="ghost" onClick={async () => download(`why-i-buy-${new Date().toISOString().slice(0, 10)}.json`, await exportJson())}><IconDownload />Xuất dữ liệu</button>
      </div>
      {!pairing.linked && (
        <div className="note-banner">
          <span className="ic"><IconLink /></span>
          <div className="tx"><p className="t-label">Chưa liên kết với app Android</p><p className="t-caption muted">Món lưu trên máy này sẽ được đồng bộ sau khi bạn liên kết.</p></div>
          <button className="btn primary" style={{ height: 40 }} onClick={onLink}>Liên kết</button>
        </div>
      )}
      {pairing.linked && settings?.syncOn && (errors > 0 || (unsynced > 0 && meta.nextRetryAt)) && (
        <div className="note-banner">
          <span className="ic"><IconAlert /></span>
          <p className="t-body-sm tx">Chưa đồng bộ được {unsynced} món vì mất kết nối. Món vẫn được giữ trên máy này.{meta.nextRetryAt ? ` Tự thử lại lúc ${fmtTime(meta.nextRetryAt)}.` : ''}</p>
          <button className="btn primary" style={{ height: 40 }} onClick={onRetry}>Thử lại</button>
        </div>
      )}
      <div className="toolbar">
        <div className="seg" role="group" aria-label="Lọc theo trạng thái">
          {([['considering', 'Đang cân nhắc'], ['purchased', 'Đã mua'], ['skipped', 'Đã bỏ qua'], ['all', 'Tất cả']] as const).map(([v, l]) => {
            const n = v === 'all' ? views.length : views.filter((x) => x.item.status === v).length;
            return <button key={v} aria-pressed={filter === v} onClick={() => setFilter(v)}>{l}<span className="n"> {n}</span></button>;
          })}
        </div>
        <label className="search"><IconSearch /><input placeholder="Tìm món" aria-label="Tìm món" value={q} onChange={(e) => setQ(e.target.value)} /></label>
        {shown.length > 0 && <button className="ghost" style={{ color: 'var(--error)' }} disabled={removing} onClick={removeShown}>{removing ? 'Đang xoá…' : `Xoá tất cả (${shown.length})`}</button>}
      </div>
      {shown.length === 0 && <div className="empty">{views.length === 0 ? 'Chưa có món nào. Mở một trang sản phẩm Shopee và bấm icon Why I Buy? để lưu.' : 'Không có món nào trong mục này.'}</div>}
      <div className="list">
        {shown.map((v) => (
          <button key={v.item.id} className="item" aria-selected={selected === v.item.id} onClick={() => onSelect(v.item.id)}>
            <Thumb src={v.item.imageUrl} size={56} radius={12} />
            <div className="info">
              <p className="ttl">{v.item.title}{v.item.variantLabel ? <span className="muted" style={{ fontWeight: 500 }}> · {v.item.variantLabel}</span> : ''}</p>
              <p className="t-caption muted">{sub(v)}</p>
              <span className="tags">
                {v.item.status === 'considering' && <VerdictTag label={verdict(v, ctx).label} />}
                {fmtProductRating(v.item) && <span className="t-caption" title="Đánh giá của người mua trên Shopee">Đánh giá trên Shopee: <b>{fmtProductRating(v.item)}</b></span>}
                {v.item.shopRating && <span className="t-caption muted" title="Đánh giá của shop trên Shopee">· Shop: {fmtShopRating(v.item.shopRating)}</span>}
              </span>
            </div>
            <div className="price"><p className="amt">{fmtPrice(v.latest)}</p>{v.item.status === 'considering' && <PriceTag info={priceTag(v)} />}</div>
          </button>
        ))}
      </div>
      {IS_DEMO && pairing.linked && <p className="t-caption muted">Dữ liệu mô phỏng</p>}
    </>
  );
}

// ---------- X4 / X4a
function Pair({ pairing, onChanged, onOpenList }: { pairing: PairingState; onChanged: () => void; onOpenList: () => void }) {
  const [justSynced, setJustSynced] = useState<number | null>(null);
  const [ask, setAsk] = useState(false);
  if (pairing.linked) return (
    <section className="formcard">
      <p className="t-title">Đã liên kết</p>
      <p className="t-body-sm muted">Extension đã liên kết với tài khoản {pairing.accountName} trên app Android.{justSynced != null ? ` ${justSynced} món đang chờ đã được đồng bộ.` : ''}</p>
      <p className="t-label">Thiết bị này: {pairing.deviceLabel}{pairing.linkedAt ? ` · liên kết lúc ${fmtTime(pairing.linkedAt)}` : ''}</p>
      {!ask ? <div className="row-actions"><button className="btn primary" onClick={onOpenList}>Mở danh sách</button><button className="btn tonal" onClick={() => setAsk(true)}>Huỷ liên kết</button></div> : (
        <div className="dialog">
          <p className="t-subtitle">Huỷ liên kết {pairing.deviceLabel}?</p>
          <p className="t-body-sm muted">Extension sẽ ngừng đồng bộ. Bạn muốn giữ các món trên máy này không?</p>
          <div className="row-actions">
            <button className="btn primary" onClick={async () => { await unpair({ keepLocal: true }); onChanged(); }}>Huỷ liên kết, giữ dữ liệu</button>
            <button className="btn danger" onClick={async () => { await unpair({ keepLocal: false }); onChanged(); }}>Huỷ liên kết và xoá dữ liệu</button>
            <button className="btn" onClick={() => setAsk(false)}>Không</button>
          </div>
        </div>
      )}
      {IS_DEMO && <p className="t-caption muted">Dữ liệu mô phỏng: chưa có backend thật.</p>}
    </section>
  );
  return (
    <section className="formcard">
      <p className="t-title">Liên kết với app Android</p>
      <p className="t-body-sm muted">{IS_FIREBASE ? 'Tạo mã QR, rồi trên điện thoại mở app Why I Buy? → Cá nhân → Thiết bị đã liên kết → Quét mã QR và chọn Đồng ý.' : 'Mở app Why I Buy? → Cá nhân → Liên kết extension để lấy mã 6 số. Sau khi nhập mã, xác nhận trên điện thoại.'}</p>
      <div style={{ maxWidth: 420 }}><PairForm large onLinked={(n) => { setJustSynced(n); onChanged(); }} /></div>
    </section>
  );
}

// ---------- X5
function SettingsPage({ settings, pairing, onChanged, setS }: { settings: Settings; pairing: PairingState; onChanged: () => void; setS: (s: Settings) => void }) {
  const upd = async (p: Partial<Settings>) => { setS(await setSettings(p)); if (p.syncOn) await syncNow({ force: true }); onChanged(); };
  const [ask, setAsk] = useState(false);
  const mock = mockApi();
  return (
    <>
      <p className="t-title">Cài đặt &amp; quyền riêng tư</p>
      <div className="setting" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 6, padding: 16 }}>
        <p className="t-subtitle">Extension đọc gì?</p>
        <p className="t-body-sm muted">
          {IS_LAB && settings.ex10AutoFill
            ? 'Chỉ đọc trang sản phẩm Shopee đang mở, và chỉ khi bạn bấm icon Why I Buy?: link, tên, ảnh, giá và phân loại đang hiển thị'
              + (settings.ex10Vouchers ? ', chữ voucher đang hiện trên trang' : '') + ', dòng Flash Sale. Không đọc giỏ hàng, đơn mua, kho voucher hay cookie đăng nhập.'
            : 'Chỉ đọc trang sản phẩm Shopee đang mở, và chỉ khi bạn bấm icon Why I Buy?. Không đọc giỏ hàng, đơn mua, kho voucher hay cookie đăng nhập.'}
        </p>
      </div>
      <div className="setting">
        <div className="t"><p className="t-label">Đồng bộ với app Android</p><p className="t-caption muted">{pairing.linked ? 'Tắt thì món chỉ lưu trên máy này' : 'Liên kết với app để bật đồng bộ'}</p></div>
        <Switch label="Đồng bộ với app Android" checked={pairing.linked && settings.syncOn} disabled={!pairing.linked} onChange={(v) => upd({ syncOn: v })} />
      </div>
      <div className="setting">
        <div className="t"><p className="t-label">Lưu ảnh sản phẩm</p><p className="t-caption muted">Tắt để chỉ lưu tên, link và giá{!IS_LAB ? '. Bản hiện tại chưa lấy ảnh từ trang.' : ''}</p></div>
        <Switch label="Lưu ảnh sản phẩm" checked={settings.saveImages} onChange={(v) => upd({ saveImages: v })} />
      </div>
      {IS_LAB && (
        <>
          <p className="t-subtitle" style={{ marginTop: 8 }}>Thử nghiệm EX-10 (chưa qua cổng 6.3)</p>
          <div className="setting">
            <div className="t"><p className="t-label">Tự điền tên, ảnh, giá từ trang đang mở</p><p className="t-caption muted">Đọc khi bạn bấm icon. Giá ở trạng thái chưa xác nhận cho đến khi bạn xác nhận.</p></div>
            <Switch label="Tự điền từ trang" checked={settings.ex10AutoFill} onChange={(v) => upd({ ex10AutoFill: v, ...(v ? {} : { ex10Vouchers: false }) })} />
          </div>
          <div className="setting">
            <div className="t"><p className="t-label">Đọc voucher hiển thị trên trang</p><p className="t-caption muted">Đọc voucher đang hiển thị, kể cả danh sách bạn tự mở; ước tính giá sau voucher để tham khảo (handoff 9.1: afterVoucher). Lệch quyết định N5, nhóm cần xác nhận. Không bấm lưu, không áp mã, không đọc kho voucher.</p></div>
            <Switch label="Đọc voucher" checked={settings.ex10Vouchers} disabled={!settings.ex10AutoFill} onChange={(v) => upd({ ex10Vouchers: v })} />
          </div>
        </>
      )}
      <div className="row-actions">
        <button className="btn tonal" onClick={async () => download(`why-i-buy-${new Date().toISOString().slice(0, 10)}.json`, await exportJson())}>Xuất dữ liệu (JSON)</button>
        <button className="btn danger" onClick={() => setAsk(true)}>Xoá dữ liệu trên máy này</button>
      </div>
      {ask && (
        <div className="dialog">
          <p className="t-subtitle">Xoá toàn bộ món đã lưu trên máy này?</p>
          <p className="t-body-sm muted">{pairing.linked ? 'Món đã đồng bộ vẫn còn trong tài khoản trên app. Món chưa đồng bộ sẽ mất.' : 'Thao tác này không hoàn tác được. Nên xuất dữ liệu trước.'}</p>
          <div className="row-actions">
            <button className="btn danger" onClick={async () => { await clearLocalData(); setAsk(false); onChanged(); }}>Xoá</button>
            <button className="btn" onClick={() => setAsk(false)}>Huỷ</button>
          </div>
        </div>
      )}
      {IS_DEMO && mock && (
        <div className="demo" style={{ marginTop: 12 }}>
          <strong style={{ color: 'var(--on-surface)' }}>Công cụ demo (máy chủ giả)</strong>
          Dùng khi trình bày các tình huống lỗi trong đặc tả.
          <div className="demo-row">
            <button className="btn" disabled={!pairing.linked} onClick={async () => { await mock.revokeAll(); await syncNow({ force: true }); onChanged(); }}>Giả lập app huỷ liên kết (E06)</button>
            <button className="btn" disabled={!pairing.linked} onClick={async () => { await mock.failNext([503]); onChanged(); }}>Giả lập lỗi server lần đồng bộ tới (E07)</button>
            <button className="btn" onClick={async () => { await mock.resetLock(); onChanged(); }}>Mở khoá mã liên kết</button>
          </div>
        </div>
      )}
    </>
  );
}

function download(name: string, body: string) {
  const url = URL.createObjectURL(new Blob([body], { type: 'application/json' }));
  const a = document.createElement('a'); a.href = url; a.download = name; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// Popup 360 px (handoff "EXT Popup extension", Figma EXT-1…EXT-8).
import { useEffect, useState } from 'react';
import { browser } from 'wxt/browser';
import type { PairingState, PriceType, Settings, WishlistItem } from '../../types';
import { AppIcon, CategorySelect, MotiveChips, PriceTag, Thumb } from '../../components/ui';
import { IconAlert, IconBookmark, IconCheckCircle, IconClose, IconExternal, IconHelp, MotiveIcons } from '../../components/Icons';
import { PairForm } from '../../components/PairForm';
import { cleanTabTitle, parseShopeeLink, type ShopeeLink } from '../../features/items/url';
import { addItem, addPrice, cleanVouchers, discountPct, findDuplicate, getSettings, pricesFor, recordDecision, salePrices, setSettings, updateFields, type PriceSaveMode } from '../../features/items/repo';
import { amountOf, compareToSaved, fmtPrice } from '../../features/items/price';
import { categoryLabel } from '../../features/items/model';
import { searchKeyword, shopeeSearchUrl } from '../../features/items/similar';
import { clearRevokedNotice, getPairing, unpair } from '../../features/pairing/pairing';
import { syncNow } from '../../features/sync/sync';
import { defaultSaleCalendar, nextSale } from '../../features/decision/rules';
import { loadDecisionContext } from '../../features/decision/context';
import { scheduleFlashReminder } from '../../features/reminders/reminders';
import { hhmm, reminderTime, whenText } from '../../features/reminders/schedule';
import { TITLE_MAX, clampTitle, fmtDayMonth, fmtProductRating, fmtShopRating, fmtVnd, parseVnd, toRatingCount, toShopStar, toStar } from '../../lib/format';
import { kv } from '../../lib/kv';
import { IS_FIREBASE, IS_LAB } from '../../lib/env';
import { copyImageToCloudinary } from '../../lib/cloudinary';
import { readPage, type PageRead } from '../../features/ex10/reader';
import { VoucherPanel } from '../../components/VoucherPanel';
import { AdminVoucherBar } from '../../components/AdminVoucherBar';

type Screen = 'loading' | 'ext2' | 'ext8' | 'link' | 'ext4' | 'ext6' | 'ext7';
interface Draft { link: ShopeeLink; title: string; variant: string; price: string; priceType: PriceType; maxPrice?: number; fromPage: boolean; confirmed: boolean; motive?: string; group?: string; imageUrl?: string; shopName?: string;
  productRating?: number; productRatingCount?: number; shopRating?: number;
  original: string; saleLabel: string; mode: PriceSaveMode; } // giá gốc (gạch ngang), tên đợt giảm / mã giảm giá, cách lưu

function AutoText({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  const fit = (el: HTMLTextAreaElement | null) => { if (el) { el.style.height = 'auto'; el.style.height = `${Math.min(el.scrollHeight, 60)}px`; } };
  return <textarea ref={fit} className="title-input" rows={2} aria-label="Tên sản phẩm" placeholder="Tên sản phẩm" value={value} maxLength={TITLE_MAX}
    onChange={(e) => { onChange(e.target.value); fit(e.target); }} />;
}
function PriceInput({ digits, onChange, label, placeholder = 'Thêm giá' }: { digits: string; onChange: (d: string) => void; label: string; placeholder?: string }) {
  return (
    <span className="price-box">
      <input inputMode="numeric" aria-label={label} placeholder={placeholder}
        value={digits ? Number(digits).toLocaleString('vi-VN') : ''} onChange={(e) => onChange(e.target.value.replace(/[^\d]/g, '').slice(0, 10))} />
      {digits && <span className="cur">₫</span>}
    </span>
  );
}

const MODES: { v: PriceSaveMode; label: string }[] = [
  { v: 'both', label: 'Giá gốc + giá giảm' }, { v: 'original', label: 'Chỉ giá gốc' }, { v: 'sale', label: 'Chỉ giá đang giảm' },
];
// Giá gốc + đợt giảm (như SteamDB): giá gốc là giá chính để so theo thời gian, giá giảm ghi riêng kèm % và tên đợt / mã.
function SaleFields({ nowVnd, original, onOriginal, label, onLabel, mode, onMode, forceLabel }: {
  nowVnd: number | null; original: string; onOriginal: (d: string) => void; label: string; onLabel: (v: string) => void;
  mode: PriceSaveMode; onMode: (m: PriceSaveMode) => void; forceLabel?: boolean;
}) {
  const pct = discountPct(nowVnd, parseVnd(original));
  return (
    <>
      <div className="price-row">
        <span className="t-label muted">Giá gốc</span>
        <PriceInput label="Giá gốc" digits={original} onChange={onOriginal} placeholder="Giá gạch ngang (nếu có)" />
      </div>
      {pct > 0 && (
        <>
          <div className="meta"><span className="pill sale">Đang giảm {pct}%</span></div>
          <div className="chips" role="group" aria-label="Lưu giá theo">
            {MODES.map((m) => <button key={m.v} type="button" className="chip" aria-pressed={mode === m.v} onClick={() => onMode(m.v)}>{m.label}</button>)}
          </div>
        </>
      )}
      {((pct > 0 && mode !== 'original') || forceLabel) && (
        <input className="field" maxLength={40} aria-label="Đợt giảm hoặc mã giảm giá" placeholder="Đợt giảm / mã giảm giá (vd 11.11, Flash Sale, SALE50)"
          value={label} onChange={(e) => onLabel(e.target.value)} />
      )}
      {pct > 0 && <p className="t-caption muted">{mode === 'both' ? 'Lưu giá gốc để so giá theo thời gian, và ghi thêm giá đang giảm của đợt này.' : mode === 'original' ? 'Chỉ lưu giá gốc, bỏ qua giá đang giảm.' : 'Chỉ lưu giá đang giảm, kèm giá gốc để biết giảm bao nhiêu.'}</p>}
    </>
  );
}

export default function App() {
  const [screen, setScreen] = useState<Screen>('loading');
  const [pairing, setPairing] = useState<PairingState>({ linked: false });
  const [settings, setS] = useState<Settings | null>(null);
  const [tabId, setTabId] = useState<number | undefined>();
  const [draft, setDraft] = useState<Draft | null>(null);
  const [existing, setExisting] = useState<WishlistItem | null>(null);
  const [existingFirst, setExistingFirst] = useState<number | undefined>();
  const [existingFirstAt, setExistingFirstAt] = useState<string | undefined>();
  const [saved, setSaved] = useState<WishlistItem | null>(null);
  const [savedTitle, setSavedTitle] = useState('Đã lưu trên máy');
  const [savedNote, setSavedNote] = useState('');
  const [nowPrice, setNowPrice] = useState('');
  const [nowOriginal, setNowOriginal] = useState('');
  const [nowLabel, setNowLabel] = useState('');
  const [nowMode, setNowMode] = useState<PriceSaveMode>('both');
  const [manualUrl, setManualUrl] = useState('');
  const [manualErr, setManualErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [saleLabel, setSaleLabel] = useState<string | null>(null);
  const [page, setPage] = useState<PageRead | null>(null);
  const [triedRead, setTriedRead] = useState(false);
  const [confirmUnlink, setConfirmUnlink] = useState(false);
  const [waitFlash, setWaitFlash] = useState(false);
  const [back, setBack] = useState<Screen>('ext4');
  const [afterVoucher, setAfterVoucher] = useState<number | null>(null);
  const [keepVouchers, setKeepVouchers] = useState(true);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') window.close(); }; // TC-19: Esc đóng popup
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, []);

  useEffect(() => { (async () => {
    const [p, s] = await Promise.all([getPairing(), getSettings()]);
    setPairing(p); setS(s);
    syncNow().catch(() => {});
    const ns = nextSale(p.linked ? (await loadDecisionContext()).calendar : defaultSaleCalendar());
    setSaleLabel(ns ? fmtDayMonth(ns.date) : null);
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    setTabId(tab?.id);
    const link = tab?.url ? parseShopeeLink(tab.url) : null;
    if (p.revokedNotice) { setBack(link ? 'ext4' : 'ext2'); }
    if (!link) { setScreen(p.revokedNotice ? 'ext8' : 'ext2'); return; }
    await openLink(link, cleanTabTitle(tab?.title), s, tab?.id, p.revokedNotice);
  })(); }, []);

  async function openLink(link: ShopeeLink, title: string, s: Settings, tId?: number, revoked?: boolean) {
    let d: Draft = { link, title: clampTitle(title), variant: '', price: '', priceType: 'single', fromPage: false, confirmed: false, original: '', saleLabel: '', mode: 'both' };
    if (IS_LAB && s.ex10AutoFill && tId != null) {
      setTriedRead(true);
      try {
        const res = await browser.scripting.executeScript({ target: { tabId: tId }, func: readPage, args: [{ vouchers: s.ex10Vouchers }] });
        const r = res[0]?.result as PageRead | undefined;
        if (r) {
          setPage(r);
          const pc = r.priceCandidates.find((c) => !c.struck);
          d = { ...d, title: clampTitle(r.name || title), variant: r.variantText, shopName: r.shopName ?? undefined,
            productRating: toStar(r.productRating) ?? undefined, productRatingCount: toRatingCount(r.productRatingCount) ?? undefined, shopRating: toShopStar(r.shopRating) ?? undefined,
            imageUrl: s.saveImages ? r.image ?? undefined : undefined,
            price: pc ? String(pc.amount) : '', maxPrice: pc?.amountMax, fromPage: !!pc, confirmed: false,
            priceType: pc?.amountMax ? 'range' : r.flashSale?.kind === 'ongoing' ? 'flash' : 'single',
            original: pc && r.originalPrice && r.originalPrice > pc.amount ? String(r.originalPrice) : '',
            saleLabel: r.flashSale?.kind === 'ongoing' ? (r.flashSale.isFlash ? 'Flash Sale' : 'Đợt giảm giá') : '' };
        }
      } catch { /* đọc lỗi không chặn lưu */ }
    }
    setDraft(d);
    let dup = await findDuplicate(link.productKey, link.url ?? link.originalUrl, d.variant);
    // Món lưu trước khi có tên shop: điền tên shop vừa đọc được từ trang
    if (dup && !dup.shopName && d.shopName) dup = (await updateFields(dup.id, { shopName: d.shopName })) ?? dup;
    // Cập nhật đánh giá mới nhất đọc được từ trang
    if (dup && (d.productRating != null || d.productRatingCount || d.shopRating)
      && (dup.productRating !== d.productRating || dup.productRatingCount !== d.productRatingCount || dup.shopRating !== d.shopRating))
      dup = (await updateFields(dup.id, { productRating: d.productRating ?? dup.productRating, productRatingCount: d.productRatingCount ?? dup.productRatingCount, shopRating: d.shopRating ?? dup.shopRating })) ?? dup;
    if (dup) {
      const ps = await pricesFor(dup.id);
      // "Lúc lưu" = giá gốc đầu tiên (giá đợt giảm và sau voucher đi riêng)
      const first = ps.find((p) => p.priceType !== 'sale' && p.priceType !== 'afterVoucher') ?? ps[0];
      setExisting(dup); setExistingFirst(amountOf(first)); setExistingFirstAt(first?.observedAt);
      setNowPrice(d.fromPage ? d.price : ''); setNowOriginal(d.fromPage ? d.original : ''); setNowLabel(d.saleLabel);
      setBack('ext6'); setScreen(revoked ? 'ext8' : 'ext6'); return;
    }
    setBack('ext4'); setScreen(revoked ? 'ext8' : 'ext4');
  }

  const fs = page?.flashSale ?? null;
  const flashLabel = fs?.isFlash ? 'Flash Sale' : 'Đợt giảm giá';
  const flashEvent = () => (fs?.kind === 'upcoming' && fs.startsAt ? { label: flashLabel, startsAt: fs.startsAt, capturedAt: new Date().toISOString() } : undefined);
  const remind = fs?.kind === 'upcoming' && fs.startsAt ? reminderTime(fs.startsAt) : null;

  async function finishSave(item: WishlistItem, note = '') {
    const r = await syncNow({ force: true });
    if (r.revoked) { setPairing({ linked: false, revokedNotice: true }); }
    // EXT-7: "Đã đồng bộ lên điện thoại" chỉ khi server xác nhận
    setSavedTitle(r.skipped === null && !r.failed ? 'Đã đồng bộ lên điện thoại' : 'Đã lưu trên máy');
    setSavedNote([note, r.skipped === 'offline' ? 'Đã lưu trên máy; sẽ đồng bộ khi có mạng.' : r.failed && !r.revoked ? 'Chưa đồng bộ được, sẽ tự thử lại.' : r.revoked ? 'Liên kết đã bị huỷ. Món vẫn được giữ trên máy này.' : ''].filter(Boolean).join(' '));
    setSaved(item); setScreen('ext7');
  }

  async function onSave() {
    if (!draft) return;
    setBusy(true);
    const amt = parseVnd(draft.price);
    const orig = parseVnd(draft.original);
    const source = draft.fromPage ? 'extensionPage' as const : 'manual' as const;
    const confirmation = draft.fromPage && !draft.confirmed ? 'unconfirmed' as const : 'userConfirmed' as const;
    const prices = draft.priceType === 'range' && draft.maxPrice && draft.fromPage && amt
      ? [{ priceType: 'range' as const, minVnd: amt, maxVnd: draft.maxPrice, originalVnd: orig ?? undefined, source: 'extensionPage' as const, confirmation: draft.confirmed ? 'userConfirmed' as const : 'unconfirmed' as const }]
      : amt ? salePrices({ nowVnd: amt, originalVnd: orig, mode: draft.mode, saleLabel: draft.saleLabel, flash: draft.priceType === 'flash', source, confirmation })
      : orig ? [{ priceType: 'single' as const, amountVnd: orig, source, confirmation }] // chỉ nhập giá gốc
      : [];
    const { item, duplicate } = await addItem({
      originalUrl: draft.link.originalUrl, url: draft.link.url, productKey: draft.link.productKey, title: draft.title, variantLabel: draft.variant, shopName: draft.shopName,
      productRating: draft.productRating, productRatingCount: draft.productRatingCount, shopRating: draft.shopRating,
      vouchers: keepVouchers && showVouchers ? page!.voucherTexts : undefined,
      // Ảnh lưu bản sao trên Cloudinary (chỉ với dữ liệu thật) để không mất khi Shopee đổi link
      imageUrl: draft.imageUrl && IS_FIREBASE ? await copyImageToCloudinary(draft.imageUrl) : draft.imageUrl,
      budgetGroupId: draft.group, motive: draft.motive, saleEvent: flashEvent(),
      price: prices[0] ?? null,
    });
    if (duplicate) { setExisting(item); setBusy(false); setScreen('ext6'); return; }
    for (const p of prices.slice(1)) await addPrice(item.id, p);
    if (afterVoucher) await addPrice(item.id, { priceType: 'afterVoucher', amountVnd: afterVoucher, saleLabel: draft.saleLabel.trim().slice(0, 40) || undefined, source: 'extensionPage', confirmation: 'userConfirmed' });
    let note = '';
    if (waitFlash && fs?.kind === 'upcoming' && fs.startsAt) {
      await recordDecision(item.id, 'wait', { reviewAt: fs.startsAt });
      const r = await scheduleFlashReminder(item, fs.startsAt);
      note = r ? `Đang chờ đến lúc Flash Sale, sẽ nhắc lúc ${whenText(new Date(r.fireAt))}.` : '';
    }
    await finishSave(item, note);
    setBusy(false);
  }

  async function onUpdatePrice() {
    const v = parseVnd(nowPrice);
    if (!existing || !v) return;
    setBusy(true);
    const prices = salePrices({ nowVnd: v, originalVnd: parseVnd(nowOriginal), mode: nowMode, saleLabel: nowLabel,
      source: draft?.fromPage && nowPrice === draft.price ? 'extensionPage' : 'manual', confirmation: 'userConfirmed' });
    for (const p of prices) await addPrice(existing.id, p);
    const pct = discountPct(v, parseVnd(nowOriginal));
    await finishSave(existing, pct && nowMode !== 'original' ? `Đã ghi giá ${fmtVnd(v)} (giảm ${pct}%${nowLabel.trim() ? ` · ${nowLabel.trim()}` : ''}).` : `Đã cập nhật giá ${fmtVnd(prices[0]?.amountVnd ?? v)}.`);
    setBusy(false);
  }

  const openList = async () => { try { await browser.runtime.openOptionsPage(); } finally { window.close(); } };
  const openPanel = () => { // sidePanel.open() phải gọi ngay trong lúc bấm
    const it = saved ?? existing;
    const opening = tabId != null ? (browser as any).sidePanel?.open?.({ tabId }) : undefined;
    const remember = it ? kv().then((k) => k.set('wib_last_item', it.id)) : Promise.resolve();
    Promise.all([opening, remember]).then(() => window.close()).catch(() => openList());
  };
  const openSearch = (title: string) => { browser.tabs.create({ url: shopeeSearchUrl(searchKeyword(title)) }); window.close(); };

  const Header = () => <header><AppIcon /><span className="name">Why I Buy?</span><span className="t-caption muted">shopee.vn</span></header>;
  const Footer = () => (
    <footer className="t-caption">
      {confirmUnlink ? (
        <>
          <span className="muted" style={{ flex: 1 }}>Huỷ liên kết? Món trên máy vẫn được giữ.</span>
          <button className="linklike" onClick={async () => { await unpair({ keepLocal: true }); setPairing({ linked: false }); setConfirmUnlink(false); }}>Huỷ liên kết</button>
          <button className="linklike" style={{ marginLeft: 8 }} onClick={() => setConfirmUnlink(false)}>Không</button>
        </>
      ) : pairing.linked ? (
        <><span className="muted">Đang lưu vào tài khoản: {pairing.accountName} ·</span><button className="linklike" onClick={() => setConfirmUnlink(true)}>Huỷ liên kết</button></>
      ) : <span className="muted">Chưa liên kết tài khoản</span>}
    </footer>
  );
  const LinkBanner = () => !pairing.linked && settings && !settings.hideLinkBanner ? (
    <div className="hint" style={{ alignItems: 'center' }}>
      <span style={{ flex: 1 }}>Chưa liên kết với app. Món vẫn được lưu trên máy này.</span>
      <button className="linklike" onClick={() => { setBack(screen); setScreen('link'); }}>Liên kết</button>
      <button className="linklike" aria-label="Ẩn" style={{ textDecoration: 'none', display: 'inline-flex' }} onClick={async () => setS(await setSettings({ hideLinkBanner: true }))}><IconClose size={16} /></button>
    </div>
  ) : null;
  const FlashBox = ({ withToggle }: { withToggle: boolean }) => !fs ? null : (
    <div className="flash">
      <div className="flash-head">{MotiveIcons.zap({ size: 16 })}
        {fs.kind === 'upcoming' && fs.startsAt ? <span>{flashLabel} lúc {whenText(new Date(fs.startsAt))}</span>
          : <span>{flashLabel} đang diễn ra{fs.endsAt ? ` · kết thúc lúc ${hhmm(new Date(fs.endsAt))}` : ''}</span>}
      </div>
      {fs.kind === 'upcoming' && <p className="flash-sub">Giá Flash Sale thường chỉ hiện khi mở bán.</p>}
      {withToggle && remind && (
        <label className="check-row">
          <input type="checkbox" checked={waitFlash} onChange={(e) => setWaitFlash(e.target.checked)} />
          <span>Chờ đến lúc Flash Sale và nhắc tôi<small>Nhắc lúc {whenText(remind.fireAt)}{remind.shifted ? ' (không gửi thông báo từ 22:00 đến 8:00)' : ''}</small></span>
        </label>
      )}
    </div>
  );
  const SearchLink = ({ title }: { title: string }) => <button className="linklike search-link" onClick={() => openSearch(title)}>Tìm món tương tự trên Shopee <IconExternal size={14} /></button>;
  const showVouchers = IS_LAB && !!settings?.ex10Vouchers && !!page;
  // Cào voucher cho Admin/Nhân viên (tự ẩn nếu tài khoản không phải staff/admin)
  const adminBar = IS_LAB && IS_FIREBASE && pairing.linked ? <AdminVoucherBar token={pairing.token} /> : null;

  if (screen === 'loading' || !settings) return <div className="pop"><Header /><main className="center"><p className="t-body-sm muted" role="status">Đang đọc trang…</p></main></div>; // EXT-3

  // EXT-8 — Liên kết bị huỷ (401)
  if (screen === 'ext8') return (
    <div className="pop"><Header />
      <main>
        <section className="card" role="alert">
          <p className="t-subtitle">{IS_FIREBASE ? 'Liên kết đã bị huỷ, vui lòng liên kết lại.' : 'Liên kết đã bị huỷ, vui lòng nhập mã mới.'}</p>
          <p className="t-body-sm muted">Các món chưa đồng bộ vẫn được giữ trên máy này.</p>
        </section>
        <button className="btn primary lg block" onClick={async () => { await clearRevokedNotice(); setScreen('link'); }}>{IS_FIREBASE ? 'Liên kết lại' : 'Nhập mã mới từ app'}</button>
        <button className="btn block" onClick={async () => { await clearRevokedNotice(); setPairing({ linked: false }); setScreen(back); }}>Để sau</button>
      </main>
      <Footer />
    </div>
  );

  // EXT-1 / X4 — Liên kết (không chặn việc lưu)
  if (screen === 'link') return (
    <div className="pop"><Header />
      <main>
        <section className="card">
          <p className="t-title">Liên kết với app</p>
          <p className="t-body-sm muted">{IS_FIREBASE ? 'Quét mã QR bằng app Why I Buy? để lưu món vào đúng tài khoản của bạn.' : 'Nhập mã 6 số từ app Why I Buy? để lưu món vào đúng tài khoản của bạn.'}</p>
          <PairForm onLinked={async (n) => { setPairing(await getPairing()); setSavedNote(n ? `${n} món đang chờ đã được đồng bộ.` : ''); setScreen(back === 'link' ? 'ext4' : back); }} />
        </section>
        <button className="btn block" onClick={() => setScreen(back === 'link' ? 'ext2' : back)}>Để sau, lưu trên máy này</button>
      </main>
      <Footer />
    </div>
  );

  // EXT-2 — Không phải trang sản phẩm (E01)
  if (screen === 'ext2') return (
    <div className="pop"><Header />
      <main>
        <section className="card">
          <p className="t-subtitle">Mở một sản phẩm trên shopee.vn để lưu</p>
          <p className="t-body-sm muted">Hoặc dán link sản phẩm vào đây.</p>
          <input className="field" placeholder="https://shopee.vn/…" value={manualUrl} onChange={(e) => { setManualUrl(e.target.value); setManualErr(''); }} />
          {manualErr && <div className="error-text" role="alert"><IconAlert />{manualErr}</div>}
        </section>
        <button className="btn primary lg block" disabled={!manualUrl.trim()} onClick={async () => {
          const l = parseShopeeLink(manualUrl);
          if (!l) { setManualErr('Hiện chỉ hỗ trợ link một món trên shopee.vn (https).'); return; } // E14
          await openLink(l, '', settings);
        }}>Tiếp tục</button>
        <button className="btn block" onClick={openList}>Mở app</button>
        {adminBar}
      </main>
      <Footer />
    </div>
  );

  // EXT-4 / EXT-5 — Đủ thông tin / thiếu giá
  if (screen === 'ext4' && draft) return (
    <div className="pop"><Header />
      <main>
        <LinkBanner />
        <section className="card" aria-label="Món đang xem">
          <div className="product">
            <Thumb src={draft.imageUrl} size={56} />
            <div className="info">
              <AutoText value={draft.title} onChange={(v) => setDraft({ ...draft, title: v })} />
              <span className="counter">{draft.title.length}/{TITLE_MAX} ký tự</span>
              <label className="variant-row">Phân loại:
                <input placeholder="không bắt buộc" value={draft.variant} onChange={(e) => setDraft({ ...draft, variant: e.target.value })} />
              </label>
              <label className="variant-row">Shop:
                <input placeholder="không bắt buộc" maxLength={60} value={draft.shopName ?? ''} onChange={(e) => setDraft({ ...draft, shopName: e.target.value })} />
              </label>
              {(fmtProductRating(draft) || draft.shopRating) && <p className="t-caption muted">{[fmtProductRating(draft) && `Sản phẩm: ${fmtProductRating(draft)}`, draft.shopRating && `Shop: ${fmtShopRating(draft.shopRating)}`].filter(Boolean).join(' · ')}</p>}
            </div>
          </div>
          <div className="price-row">
            <span className="t-label muted">{draft.priceType === 'range' && draft.maxPrice ? 'Khoảng giá' : draft.priceType === 'flash' ? 'Giá Flash Sale' : discountPct(parseVnd(draft.price), parseVnd(draft.original)) ? 'Giá đang giảm' : 'Giá đang thấy'}</span>
            {draft.priceType === 'range' && draft.maxPrice && draft.fromPage
              ? <span className="t-subtitle">{fmtPrice({ priceType: 'range', minVnd: parseVnd(draft.price) ?? 0, maxVnd: draft.maxPrice } as any)}</span>
              : <PriceInput label="Giá đang thấy" digits={draft.price} onChange={(d) => setDraft({ ...draft, price: d, fromPage: false, confirmed: true, priceType: draft.priceType === 'range' ? 'single' : draft.priceType })} placeholder="Thêm giá (không bắt buộc)" />}
          </div>
          {draft.fromPage && (
            <div className="meta">
              {draft.confirmed ? <span className="pill src">Giá đã xác nhận</span> : (
                <><span className="pill src">Đọc từ trang</span>
                  <button className="confirm" onClick={() => setDraft({ ...draft, confirmed: true })}>Đúng giá này</button></>
              )}
            </div>
          )}
          {!(draft.priceType === 'range' && draft.maxPrice && draft.fromPage) && (
            <SaleFields nowVnd={parseVnd(draft.price)} original={draft.original} onOriginal={(o) => setDraft({ ...draft, original: o })}
              label={draft.saleLabel} onLabel={(l) => setDraft({ ...draft, saleLabel: l })} mode={draft.mode} onMode={(m) => setDraft({ ...draft, mode: m })}
              forceLabel={afterVoucher != null} />
          )}
          {!draft.price && <p className="t-caption muted">{triedRead ? 'Không đọc được giá trên trang. Bạn có thể bỏ qua.' : 'Giá không bắt buộc. Bạn có thể bỏ qua.'}</p>}
          {page && page.variantMissing.length > 0 && <div className="hint warn"><IconHelp />Chưa chọn {page.variantMissing.join(', ')} trên trang. Chọn loại trên Shopee rồi bấm icon lại để lấy đúng giá.</div>}
          {page && page.priceCandidates.length > 0 && !page.priceCandidates.some((c) => c.source === 'dom') && <div className="hint warn"><IconHelp />Đây là giá chung của sản phẩm, có thể chưa đúng loại bạn chọn.</div>}
          {showVouchers && <VoucherPanel texts={page!.voucherTexts} price={parseVnd(draft.price)} saveLabel="Lưu kèm giá sau voucher"
            onSaveAfter={(v) => setAfterVoucher(afterVoucher === v ? null : v)} />}
          {showVouchers && page!.voucherTexts.length > 0 && (
            <label className="check-row av"><input type="checkbox" checked={keepVouchers} onChange={(e) => setKeepVouchers(e.target.checked)} />
              <span>Lưu kèm {page!.voucherTexts.length} ưu đãi đang thấy (mã giảm giá, combo, vận chuyển…)<small>Xem lại trong Decision Card để ước tính giá sau voucher.</small></span></label>
          )}
          {afterVoucher != null && <label className="check-row av"><input type="checkbox" checked onChange={() => setAfterVoucher(null)} /><span>Lưu kèm giá sau voucher {fmtVnd(afterVoucher)}<small>Chỉ để tham khảo cá nhân, không so với giá niêm yết.</small></span></label>}
          <FlashBox withToggle />
        </section>
        <section className="card" aria-label="Thông tin thêm">
          <p className="card-title"><span className="t-label">Vì sao muốn mua?</span><span className="t-caption muted">không bắt buộc</span></p>
          <MotiveChips value={draft.motive} onChange={(m) => setDraft({ ...draft, motive: m })} />
          <CategorySelect value={draft.group} onChange={(c) => setDraft({ ...draft, group: c })} />
        </section>
        <div className="cta">
          <button className="btn primary lg block" disabled={busy || !draft.title.trim()} onClick={onSave}>{busy ? 'Đang lưu…' : waitFlash ? 'Lưu và chờ Flash Sale' : 'Lưu vào danh sách'}</button>
          {draft.title && <SearchLink title={draft.title} />}
        </div>
        {adminBar}
      </main>
      <Footer />
    </div>
  );

  // EXT-6 — Món đã lưu trước đó (E03)
  if (screen === 'ext6' && existing) {
    // So giá gốc với giá gốc lúc lưu; giá đang giảm hiện riêng bằng % giảm
    const nowRegular = discountPct(parseVnd(nowPrice), parseVnd(nowOriginal)) ? parseVnd(nowOriginal) : parseVnd(nowPrice);
    const tag = compareToSaved(existingFirst, nowRegular);
    return (
      <div className="pop"><Header />
        <main>
          <div className="banner"><IconBookmark />Đã có trong danh sách</div>
          <section className="card">
            <div className="product">
              <Thumb src={existing.imageUrl} />
              <div className="info">
                <p className="t-label">{existing.title}</p>
                {existing.variantLabel && <p className="t-caption muted">Phân loại: {existing.variantLabel}</p>}
                {existing.shopName && <p className="t-caption muted">Shop: {existing.shopName}{existing.shopRating ? ` · ${fmtShopRating(existing.shopRating)}` : ''}</p>}
                {fmtProductRating(existing) && <p className="t-caption muted">Sản phẩm: {fmtProductRating(existing)}</p>}
              </div>
            </div>
            <div className="compare">
              <div className="row"><span className="k">Lúc lưu ({fmtDayMonth(existingFirstAt ?? existing.createdAt)})</span><span className="v">{existingFirst ? fmtVnd(existingFirst) : '—'}</span></div>
              <div className="row"><span className="k">Trên trang bây giờ</span><PriceInput label="Giá trên trang bây giờ" digits={nowPrice} onChange={setNowPrice} placeholder="Nhập giá" /></div>
              {tag && <div><PriceTag info={tag} /></div>}
            </div>
            <SaleFields nowVnd={parseVnd(nowPrice)} original={nowOriginal} onOriginal={setNowOriginal}
              label={nowLabel} onLabel={setNowLabel} mode={nowMode} onMode={setNowMode} />
            {showVouchers && <VoucherPanel texts={page!.voucherTexts} price={parseVnd(nowPrice) ?? existingFirst ?? null} saveLabel="Ghi giá sau voucher"
              onSaveAfter={async (v) => { setBusy(true); await addPrice(existing.id, { priceType: 'afterVoucher', amountVnd: v, saleLabel: nowLabel.trim().slice(0, 40) || undefined, source: 'extensionPage', confirmation: 'userConfirmed' }); await finishSave(existing, `Đã ghi giá sau voucher ${fmtVnd(v)} (tham khảo).`); setBusy(false); }} />}
            <FlashBox withToggle={false} />
          </section>
          <div className="actions">
            <button className="btn primary lg block" disabled={busy || !parseVnd(nowPrice)} onClick={onUpdatePrice}>Cập nhật giá</button>
            {remind && fs?.startsAt && (
              <button className="btn tonal block" disabled={busy} onClick={async () => {
                setBusy(true);
                await updateFields(existing.id, { saleEvent: flashEvent() });
                await recordDecision(existing.id, 'wait', { reviewAt: fs.startsAt });
                const r = await scheduleFlashReminder(existing, fs.startsAt!);
                await finishSave(existing, r ? `Đang chờ đến lúc Flash Sale, sẽ nhắc lúc ${whenText(new Date(r.fireAt))}.` : '');
                setBusy(false);
              }}>Chờ đến lúc Flash Sale</button>
            )}
            {showVouchers && page!.voucherTexts.length > 0 && (
              <button className="btn tonal block" disabled={busy} onClick={async () => {
                setBusy(true);
                const saved = await updateFields(existing.id, { vouchers: cleanVouchers(page!.voucherTexts), vouchersAt: new Date().toISOString() });
                await finishSave(saved ?? existing, `Đã lưu ${page!.voucherTexts.length} ưu đãi cho món này.`);
                setBusy(false);
              }}>Lưu {page!.voucherTexts.length} ưu đãi đang thấy</button>
            )}
            <button className="btn block" onClick={openList}>Mở app</button>
            <button className="linklike" style={{ alignSelf: 'center', marginTop: 4 }} onClick={openPanel}>Xem Decision Card</button>
            <SearchLink title={existing.title} />
          </div>
          {adminBar}
        </main>
        <Footer />
      </div>
    );
  }

  // EXT-7 — Đã lưu
  if (screen === 'ext7' && saved) {
    const cat = categoryLabel(saved.budgetGroupId);
    return (
      <div className="pop"><Header />
        <main className="center">
          <div className="circle"><IconCheckCircle /></div>
          <p className="t-title">{savedTitle}</p>
          <p className="t-body-sm muted">{saved.title}{cat ? ` · nhóm ${cat}` : ''}.{saleLabel ? ` Đợt sale Shopee tiếp theo: ${saleLabel}.` : ''}</p>
          {savedNote && <p className="t-label">{savedNote}</p>}
          <button className="btn primary lg block" onClick={openList}>Mở app</button>
          <button className="btn block" onClick={() => window.close()}>Đóng</button>
          <button className="linklike" onClick={openPanel}>Cân nhắc sau trong Decision Card</button>
        </main>
        <Footer />
      </div>
    );
  }
  return null;
}

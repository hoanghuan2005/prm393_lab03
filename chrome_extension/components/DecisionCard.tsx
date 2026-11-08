// Decision Card (Figma X3 / app 28, handoff 9.3–9.4). Ba nút cùng kiểu và kích thước; "Mua" chỉ ghi ý định —
// khoản mua được ghi trên app Android, món chỉ thành Đã mua khi app lưu khoản mua (đồng bộ về).
import { useEffect, useState } from 'react';
import type { DecisionContext } from '../features/decision/context';
import { budgetInsight, nextSale, ownedText, sameGroupText, saleText, verdict } from '../features/decision/rules';
import { amountOf, discountText, fmtPrice, freshness, priceTag, type ItemView } from '../features/items/price';
import { VoucherPanel } from './VoucherPanel';
import { categoryLabel, motiveLabel } from '../features/items/model';
import { addPrice, reconfirmPrice, recordDecision, removeItem, updateFields } from '../features/items/repo';
import { compareSimilar, searchKeyword, shopeeSearchUrl } from '../features/items/similar';
import { cancelReminders, reminderFor, scheduleFlashReminder, type Reminder } from '../features/reminders/reminders';
import { reminderTime, whenText } from '../features/reminders/schedule';
import { mockApi } from '../features/pairing/pairing';
import { syncNow } from '../features/sync/sync';
import { DAY, fmtDayMonth, fmtProductRating, fmtShopRating, fmtVnd, parseVnd } from '../lib/format';
import { IS_DEMO, IS_LAB } from '../lib/env';
import { Card, PriceTag, Stars, VerdictTag } from './ui';
import { IconExternal, MotiveIcons } from './Icons';

type Mode = 'idle' | 'buy' | 'wait' | 'skip' | 'price';

export function DecisionCard({ view, views, ctx, onChanged, onRemoved, onOpenItem }: {
  view: ItemView; views: ItemView[]; ctx: DecisionContext; onChanged: () => void; onRemoved?: () => void; onOpenItem?: (id: string) => void;
}) {
  const { item, latest, first } = view;
  const [mode, setMode] = useState<Mode>('idle');
  const [newPrice, setNewPrice] = useState('');
  const [waitChoice, setWaitChoice] = useState<'3d' | 'sale' | 'flash' | 'custom'>('3d');
  const [customDate, setCustomDate] = useState('');
  const [keyword, setKeyword] = useState(searchKeyword(item.title));
  const [rem, setRem] = useState<Reminder | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  useEffect(() => { setKeyword(searchKeyword(item.title)); setMode('idle'); setToast(null); }, [item.id]);
  useEffect(() => { let on = true; reminderFor(item.id).then((r) => { if (on) setRem(r); }); return () => { on = false; }; }, [item.id, item.updatedAt]);

  const fr = freshness(latest);
  const tag = priceTag(view);
  const vd = verdict(view, ctx);
  const budget = budgetInsight(view, ctx.budgets, ctx.linked);
  const sale = saleText(ctx.calendar);
  const ns = nextSale(ctx.calendar);
  const same = sameGroupText(view, views);
  const owned = ownedText(view, ctx.owned);
  const sim = compareSimilar(view, views);
  const flash = item.saleEvent && new Date(item.saleEvent.startsAt).getTime() > Date.now() ? item.saleEvent : null;
  const done = async (p: Promise<unknown>, msg?: string) => { await p; setMode('idle'); if (msg) setToast(msg); onChanged(); };

  const priceCaption = !latest ? 'Chưa có giá'
    : fr === 'fresh' ? `Bạn ghi ${fmtDayMonth(latest.observedAt)}${first && first.id !== latest.id ? ` · lúc lưu ${fmtPrice(first)}` : ''}`
    : fr === 'recent' ? `Giá ghi ${fmtDayMonth(latest.observedAt)}, đã hơn 3 ngày nên chưa đem so`
    : `Giá cũ, ghi ${fmtDayMonth(latest.observedAt)}`;

  const status = item.status === 'purchased' ? 'Đã mua · khoản mua đã được ghi trên app'
    : item.status === 'skipped' ? 'Đã bỏ qua · không tạo khoản chi'
    : item.buyIntentAt ? 'Đã ghi ý định mua · mở app trên điện thoại để ghi khoản mua'
    : item.reviewAt ? `Đang chờ · xem lại ${fmtDayMonth(item.reviewAt)}` : null;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <p className="t-caption muted" style={{ textTransform: 'uppercase', letterSpacing: '.4px', fontWeight: 600, paddingRight: 32 }}>Cân nhắc trước khi mua</p>
      <p className="t-title" style={{ paddingRight: 24, marginTop: -6 }}>{item.title}{item.variantLabel ? <span className="muted" style={{ fontWeight: 500 }}> · {item.variantLabel}</span> : ''}</p>
      <div><VerdictTag label={vd.label} /></div>
      {/* Thông tin món: nhãn bên trái, giá trị bên phải, mỗi dòng cách nhau rõ ràng */}
      <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', columnGap: 16, rowGap: 10, alignItems: 'center', padding: '12px 14px', borderRadius: 12, background: 'var(--surface-container)' }}>
        {item.shopName && <>
          <span className="t-caption muted">Shop</span>
          <span className="t-label">{item.shopName}{item.shopRating && <span className="muted" style={{ fontWeight: 500 }}> · {fmtShopRating(item.shopRating)}</span>}</span>
        </>}
        {fmtProductRating(item) && <>
          <span className="t-caption muted">Đánh giá trên Shopee</span>
          <span className="t-label">{fmtProductRating(item)}</span>
        </>}
        <span className="t-caption muted">Ưu tiên của bạn</span>
        <span><Stars value={item.priority} onChange={(n) => done(updateFields(item.id, { priority: n }))} /></span>
      </div>

      {/* Giá */}
      <div className="dsec">
        <p className="dsec-title">Giá</p>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <p className="dc-price" style={{ flex: 1 }}>{fmtPrice(latest)}{latest?.priceType === 'flash' ? <span className="t-label muted"> · Flash Sale</span> : ''}</p>
          <PriceTag info={tag} />
        </div>
        <p className="t-caption muted" style={{ marginTop: 4 }}>{priceCaption}{latest?.confirmation === 'unconfirmed' ? ' · chưa xác nhận' : ''}</p>
        {view.sale && view.sale !== latest && (
          <p className="t-caption" style={{ marginTop: 4 }}>Giá giảm gần nhất: <strong>{fmtPrice(view.sale)}</strong>
            <span className="muted"> · {discountText(view.sale)} · ghi {fmtDayMonth(view.sale.observedAt)}</span></p>
        )}
        {view.lowestSale && view.lowestSale !== view.sale && (
          <p className="t-caption" style={{ marginTop: 4 }}>Giảm thấp nhất đã ghi: <strong>{fmtPrice(view.lowestSale)}</strong>
            <span className="muted"> · {discountText(view.lowestSale)} · {fmtDayMonth(view.lowestSale.observedAt)}</span></p>
        )}
        {view.afterVoucher && (
          <p className="t-caption" style={{ marginTop: 4 }}>Sau voucher (ước tính): <strong>{fmtPrice(view.afterVoucher)}</strong>
            <span className="muted">{view.afterVoucher.saleLabel ? ` · ${view.afterVoucher.saleLabel}` : ''} · ghi {fmtDayMonth(view.afterVoucher.observedAt)} · chỉ để tham khảo</span></p>
        )}
        {mode === 'price' ? (
          <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
            <input className="field" inputMode="numeric" placeholder="Giá bạn đang thấy (₫)" value={newPrice ? Number(newPrice).toLocaleString('vi-VN') : ''} onChange={(e) => setNewPrice(e.target.value.replace(/[^\d]/g, '').slice(0, 10))} autoFocus />
            <button className="btn tonal" disabled={!parseVnd(newPrice)} onClick={() => done(addPrice(item.id, { priceType: 'single', amountVnd: parseVnd(newPrice)!, source: 'manual', confirmation: 'userConfirmed' }), 'Đã cập nhật giá.')}>Lưu giá</button>
          </div>
        ) : (
          <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' }}>
            <button className="chipbtn" onClick={() => { setNewPrice(''); setMode('price'); }}>Cập nhật giá</button>
            {latest && (fr === 'old' || latest.confirmation === 'unconfirmed') && (
              <button className="chipbtn" onClick={() => done(reconfirmPrice(item.id), 'Đã xác nhận lại giá.')}>{fr === 'old' ? 'Xác nhận lại' : 'Xác nhận giá này'}</button>
            )}
          </div>
        )}
      </div>

      {/* Voucher đã lưu kèm món (đọc từ trang lúc lưu) */}
      {item.vouchers?.length ? (
        <div className="dsec">
          <p className="dsec-title">Voucher đã lưu{item.vouchersAt ? ` · ${fmtDayMonth(item.vouchersAt)}` : ''}</p>
          <VoucherPanel texts={item.vouchers} price={amountOf(latest) ?? null} saveLabel="Ghi giá sau voucher"
            onSaveAfter={(v) => done(addPrice(item.id, { priceType: 'afterVoucher', amountVnd: v, source: 'extensionPage', confirmation: 'userConfirmed' }), `Đã ghi giá sau voucher ${fmtVnd(v)} (tham khảo).`)} />
          <p className="t-caption muted" style={{ marginTop: 4 }}>Voucher có thể đã hết hạn hoặc hết lượt; mở trang Shopee để kiểm tra trước khi đặt.</p>
        </div>
      ) : null}

      {/* Ngân sách */}
      <div className="dsec"><p className="dsec-title">Ngân sách</p><p className="t-body-sm">{budget.text}</p></div>

      {/* Thời điểm (ẩn nếu không có dữ liệu) */}
      {(sale || flash) && (
        <div className={`dsec${flash ? ' accent' : ''}`}>
          <p className="dsec-title">Thời điểm</p>
          {flash && (
            <div className="flashline">
              <p className="t-label" style={{ display: 'flex', gap: 6, alignItems: 'center' }}>{MotiveIcons.zap({ size: 16 })}{flash.label} lúc {whenText(new Date(flash.startsAt))}</p>
              <p className="t-caption muted">Đọc từ trang ngày {fmtDayMonth(flash.capturedAt)}.{rem ? ` Sẽ nhắc lúc ${whenText(new Date(rem.fireAt))}.` : ''}</p>
            </div>
          )}
          {sale && <p className="t-body-sm">{sale}</p>}
        </div>
      )}
      {(same || owned) && <div className="dsec"><p className="dsec-title">Đồ đang có · món cùng nhóm</p><p className="t-body-sm">{[owned, same].filter(Boolean).join(' ')}</p></div>}

      {/* So món cùng loại đã lưu (Figma 23) */}
      {sim.rows.length > 0 && (
        <div className="dsec">
          <p className="dsec-title">So với {sim.rows.length} món cùng loại đã lưu</p>
          {sim.summary && <p className="t-body-sm" style={{ margin: '0 0 8px' }}>{sim.summary}</p>}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {sim.rows.map((r) => (
              <button key={r.view.item.id} className="sim-row" onClick={() => onOpenItem?.(r.view.item.id)} disabled={!onOpenItem}>
                <span className="sim-info">
                  <span className="t-label sim-name">{r.view.item.title}{r.view.item.variantLabel ? ` · ${r.view.item.variantLabel}` : ''}</span>
                  <span className="t-caption muted">{r.sameProduct ? 'Cùng sản phẩm, loại khác' : r.sameShop ? 'Cùng shop' : 'Shop khác'}
                    {' · '}{r.view.latest ? `${r.fresh ? 'giá ghi' : 'giá cũ'} ${fmtDayMonth(r.view.latest.observedAt)}` : 'chưa có giá'}</span>
                </span>
                <span className="sim-price">
                  <span className="t-label">{fmtPrice(r.view.latest)}</span>
                  {r.cheapest && <span className="ptag lower" style={{ padding: '0 8px', fontSize: 12 }}>Thấp nhất</span>}
                </span>
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="dsec">
        <p className="dsec-title">Tìm món tương tự trên Shopee</p>
        <p className="t-caption muted" style={{ margin: '0 0 8px' }}>Mở trang tìm kiếm Shopee, sắp theo giá thấp đến cao. Bạn tự xem và lưu món muốn so.</p>
        <div style={{ display: 'flex', gap: 8 }}>
          <input className="field" aria-label="Từ khoá tìm kiếm" value={keyword} onChange={(e) => setKeyword(e.target.value)} />
          <button className="chipbtn" style={{ height: 40 }} disabled={!keyword.trim()} onClick={() => window.open(shopeeSearchUrl(keyword.trim()), '_blank', 'noopener')}>Tìm <IconExternal /></button>
        </div>
      </div>

      {item.motive && <p className="t-caption muted">Lý do khi lưu: {motiveLabel(item.motive)}{item.budgetGroupId ? ` · nhóm ${categoryLabel(item.budgetGroupId)}` : ''}</p>}
      {status && <p className="t-label">{status}</p>}

      {mode === 'buy' && (
        <Card bg="var(--background)">
          <p className="t-label">Ghi ý định mua?</p>
          <p className="t-caption muted" style={{ margin: '4px 0 10px' }}>
            Khoản mua được ghi trên app Android (giá thực trả, có dùng mã giảm giá hay không). Món chuyển sang Đã mua khi app lưu khoản mua.
            {!ctx.linked ? ' Liên kết với app để ghi khoản mua trên điện thoại.' : ''}
          </p>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="btn primary" onClick={() => done(Promise.all([recordDecision(item.id, 'buy'), cancelReminders(item.id)]), 'Đã ghi ý định mua. Mở app trên điện thoại để ghi khoản mua.')}>Ghi ý định mua</button>
            <button className="btn" onClick={() => setMode('idle')}>Huỷ</button>
          </div>
        </Card>
      )}

      {item.buyIntentAt && item.status === 'considering' && (
        <div className="note-card">
          Đang chờ app ghi khoản mua.{' '}
          <button className="linklike" onClick={() => done(recordDecision(item.id, 'undo'), 'Đã huỷ ý định mua.')}>Huỷ ý định mua</button>
          {IS_DEMO && ctx.linked && (
            <div className="demo" style={{ marginTop: 8 }}>Bản demo · giả lập app Android:
              <div className="demo-row"><button className="btn tonal" onClick={async () => { await syncNow({ force: true }); await mockApi()?.appRecordsPurchase(item.id); await syncNow({ force: true }); onChanged(); }}>App đã ghi khoản mua</button></div>
            </div>
          )}
        </div>
      )}

      {mode === 'wait' && (
        <Card bg="var(--background)">
          <p className="t-label" style={{ marginBottom: 8 }}>Bạn muốn xem lại khi nào?</p>
          {([...(flash && IS_LAB ? [['flash', `Đến lúc ${flash.label} (${whenText(new Date(flash.startsAt))}) và nhắc tôi`]] : []), ['3d', 'Sau 3 ngày'], ...(ns ? [['sale', `Đến đợt ${ns.label} (${fmtDayMonth(ns.date)})`]] : []), ['custom', 'Tự chọn ngày']] as [typeof waitChoice, string][]).map(([v, l]) => (
            <label key={v} className="t-body-sm" style={{ display: 'flex', gap: 8, alignItems: 'center', padding: '6px 0', cursor: 'pointer' }}>
              <input type="radio" name="wait" checked={waitChoice === v} onChange={() => setWaitChoice(v)} />{l}
            </label>
          ))}
          {waitChoice === 'custom' && <input className="field" type="date" value={customDate} onChange={(e) => setCustomDate(e.target.value)} style={{ marginTop: 6 }} />}
          <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
            <button className="btn primary" disabled={waitChoice === 'custom' && !customDate} onClick={() => {
              const at = waitChoice === 'flash' && flash ? flash.startsAt : waitChoice === '3d' ? new Date(Date.now() + 3 * DAY).toISOString()
                : waitChoice === 'sale' && ns ? new Date(ns.date).toISOString() : new Date(customDate).toISOString();
              done((async () => {
                await recordDecision(item.id, 'wait', { reviewAt: at });
                if (waitChoice === 'flash' && flash) setRem(await scheduleFlashReminder(item, flash.startsAt));
              })(), `Đang chờ · xem lại ${fmtDayMonth(at)}.`);
            }}>Đặt ngày xem lại</button>
            <button className="btn" onClick={() => setMode('idle')}>Huỷ</button>
          </div>
          <p className="t-caption muted" style={{ marginTop: 8 }}>
            Không tạo khoản chi.{' '}
            {waitChoice === 'flash' && flash ? (() => { const r = reminderTime(flash.startsAt); return r ? `Thông báo trên máy tính lúc ${whenText(r.fireAt)}${r.shifted ? ' (không gửi từ 22:00 đến 8:00)' : ''}.` : ''; })() : 'Nhắc nhở được gửi từ app Android khi đã liên kết.'}
          </p>
        </Card>
      )}

      {mode === 'skip' && (
        <Card bg="var(--background)">
          <p className="t-label">Không mua món này nữa?</p>
          <p className="t-caption muted" style={{ margin: '2px 0 10px' }}>Món chuyển sang Đã bỏ qua, không tạo khoản chi. Có thể hoàn tác.</p>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="btn primary" onClick={() => done(Promise.all([recordDecision(item.id, 'skip'), cancelReminders(item.id)]), 'skip')}>Bỏ qua</button>
            <button className="btn" onClick={() => setMode('idle')}>Huỷ</button>
          </div>
        </Card>
      )}

      {toast && (
        <div role="status" style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--on-surface)', color: '#fff', borderRadius: 12, padding: '8px 12px' }}>
          <span className="t-body-sm" style={{ flex: 1 }}>{toast === 'skip' ? 'Đã bỏ qua món này' : toast}</span>
          {toast === 'skip' && item.status === 'skipped' && <button className="btn" style={{ color: 'var(--primary)', height: 36 }} onClick={() => done(recordDecision(item.id, 'undo'), 'Đã hoàn tác.')}>Hoàn tác</button>}
        </div>
      )}
      {item.status === 'skipped' && !toast && <button className="linklike" style={{ alignSelf: 'flex-start' }} onClick={() => done(recordDecision(item.id, 'undo'), 'Đã hoàn tác.')}>Hoàn tác bỏ qua</button>}

      <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
        <a className="chipbtn" href={item.originalUrl ?? item.url} target="_blank" rel="noreferrer">Mở trên Shopee <IconExternal /></a>
        {onRemoved && <button className="chipbtn danger" onClick={async () => { if (confirm('Xoá món này khỏi danh sách?')) { await removeItem(item.id); await cancelReminders(item.id); onRemoved(); } }}>Xoá khỏi danh sách</button>}
        <span className="t-caption muted" style={{ marginLeft: 'auto' }}>Bạn luôn là người quyết định.{IS_DEMO && ctx.linked ? ' Dữ liệu mô phỏng.' : ''}</span>
      </div>
      {/* Quyết định */}
      {item.status === 'considering' && !item.buyIntentAt && mode === 'idle' && (
        <div className="decide">
          {/* handoff 9.3: ba nút cùng kiểu và kích thước, bằng nhau về độ nổi bật */}
          <button className="btn tonal" onClick={() => setMode('buy')}>Mua<small>ghi trên điện thoại</small></button>
          <button className="btn tonal" onClick={() => setMode('wait')}>Chờ<small>đặt ngày xem lại</small></button>
          <button className="btn tonal" onClick={() => setMode('skip')}>Bỏ qua<small>không tạo chi tiêu</small></button>
        </div>
      )}

    </div>
  );
}

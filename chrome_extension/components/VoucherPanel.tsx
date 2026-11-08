// Khối voucher (bản Lab): mặc định thu gọn thành một dòng tóm tắt; mở ra để xem từng mã.
import { useState } from 'react';
import { adviseVoucher, bestVoucher, type ParsedVoucher, type VoucherEval } from '../features/ex10/voucher';
import { fmtVnd } from '../lib/format';
import { IconChevronDown } from './Icons';

const scopeLabel = (v: ParsedVoucher) => (v.kind === 'shipping' ? 'Vận chuyển' : v.kind === 'coin' ? 'Hoàn xu' : v.kind === 'bundle' ? 'Combo' : v.scope === 'payment' ? 'Thanh toán' : v.scope === 'platform' ? 'Shopee' : v.scope === 'shop' ? 'Shop' : 'Mã');
// Mô tả gọn từ các trường đã phân tích, thay cho chữ thô trên trang
export function describe(v: ParsedVoucher) {
  const main = v.kind === 'amount' ? `Giảm ${fmtVnd(v.amount ?? 0)}` : v.kind === 'percent' ? `Giảm ${v.percent}%${v.cap ? `, tối đa ${fmtVnd(v.cap)}` : ''}` : v.raw;
  const cond = v.minSpend === undefined ? '' : v.minSpend === 0 ? ' · mọi đơn' : ` · đơn từ ${fmtVnd(v.minSpend)}`;
  return main + cond;
}
function Tags({ v }: { v: ParsedVoucher }) {
  return (
    <span className="vtags">
      <span className="vtag-s">{scopeLabel(v)}</span>
      {v.saved === false && <span className="vtag-s warn">Chưa lưu</span>}
      {v.expires && <span className="vtag-s">HSD {v.expires}</span>}
      {v.usedPct != null && <span className="vtag-s">Đã dùng {v.usedPct}%</span>}
    </span>
  );
}

export function VoucherPanel({ texts, price, onSaveAfter, saveLabel }: { texts: string[]; price: number | null; onSaveAfter?: (final: number) => void; saveLabel?: string }) {
  const [open, setOpen] = useState(false);
  const r = price ? bestVoucher(texts, price) : null;
  const adv = r && price ? adviseVoucher(r, price) : null;
  const est = adv && adv.picks.length ? { final: adv.finalPrice, d: adv.discount, combo: adv.combo } : null;
  const picked = new Set(adv?.picks.map((p) => p.eval.voucher.raw) ?? []);
  const rows: VoucherEval[] = r ? [...r.ranked, ...r.ineligible] : [];
  const n = r ? r.ranked.length + r.ineligible.length + r.payment.length : texts.length;
  // Ưu đãi không phải mã giảm giá (combo, vận chuyển, hoàn xu…): vẫn được lưu kèm nên nêu rõ để khớp số "Lưu kèm"
  const others = r ? Math.max(0, r.all.length - n) : 0;
  return (
    <div className="vpanel" aria-label="Voucher trên trang">
      <button className="vsum" aria-expanded={open} onClick={() => setOpen((o) => !o)}>
        <span className="grow">
          <span className="t-label">{est ? `Nên dùng ${adv!.picks.length} mã · còn khoảng ${fmtVnd(est.final)}` : texts.length ? 'Voucher trên trang' : 'Không thấy voucher trên trang'}</span>
          <span className="t-caption muted">{est ? `Giảm ${fmtVnd(est.d)} · ` : ''}{r ? `${n} mã giảm giá` : `${n} ưu đãi`}{others ? ` · ${others} ưu đãi khác (combo, vận chuyển, hoàn xu)` : ''}{!price && texts.length ? ' · cần giá để ước tính' : ''}{adv?.todo.length ? ' · có mã chưa lưu' : ''} · ước tính</span>
        </span>
        <IconChevronDown />
      </button>
      {open && (
        <div className="vlist">
          {adv && (
            <div className="vbest" role="note" aria-label="Gợi ý voucher">
              {adv.picks.length ? (
                <>
                  <p className="t-label">Nên dùng</p>
                  {adv.picks.map((p, i) => (
                    <div key={p.eval.voucher.raw} className="vrow2">
                      <div className="vinfo"><span className="t-caption">{adv.picks.length > 1 ? `${i + 1}. ` : ''}{describe(p.eval.voucher)}</span><Tags v={p.eval.voucher} /></div>
                      <span className="t-caption vamt2">−{fmtVnd(p.eval.discount)}</span>
                    </div>
                  ))}
                  <p className="t-caption">Còn khoảng <strong>{fmtVnd(adv.finalPrice)}</strong> (giảm {fmtVnd(adv.discount)}).</p>
                </>
              ) : (
                <p className="t-caption">Chưa có mã nào dùng được với giá này. Giá hiện tại là giá bạn sẽ trả.</p>
              )}
              {adv.todo.map((s) => <p key={s} className="t-caption"><strong>Cần làm:</strong> {s}</p>)}
              {adv.cautions.map((s) => <p key={s} className="t-caption muted">• {s}</p>)}
            </div>
          )}
          {rows.length > 0 && <p className="t-caption muted">Tất cả mã đọc được:</p>}
          {rows.map((e) => (
            <div key={e.voucher.raw} className="vrow2" title={e.voucher.raw} style={picked.has(e.voucher.raw) ? { fontWeight: 600 } : undefined}>
              <div className="vinfo"><span className="t-caption">{describe(e.voucher)}</span><Tags v={e.voucher} /></div>
              <span className="t-caption vamt2">{e.eligible ? `−${fmtVnd(e.discount)}` : e.voucher.minSpend ? 'chưa đủ đơn' : '—'}</span>
            </div>
          ))}
          {adv && adv.extras.map((s) => <p key={s} className="t-caption muted">{s}</p>)}
          {est && onSaveAfter && <button className="linklike" style={{ alignSelf: 'flex-start' }} onClick={() => onSaveAfter(est.final)}>{saveLabel ?? 'Ghi giá sau voucher'}: {fmtVnd(est.final)}</button>}
          <p className="t-caption muted">Muốn đọc thêm mã: mở "Mã Giảm Giá Của Shop" trên trang rồi bấm icon lại. Extension không tự lưu hay áp mã.</p>
        </div>
      )}
    </div>
  );
}

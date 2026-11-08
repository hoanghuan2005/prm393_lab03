// X4 / EXT-1: nhập mã 6 số (bản Firebase: hiện mã QR để app quét) → chờ duyệt trên điện thoại (25f) → liên kết. Dùng chung cho popup và trang extension.
import { useEffect, useRef, useState } from 'react';
import { CodeInput } from './ui';
import { IconAlert, IconHelp } from './Icons';
import { QrCode } from './QrCode';
import { checkPairing, mockApi, startPairing } from '../features/pairing/pairing';
import { IS_DEMO, IS_FIREBASE } from '../lib/env';
import { deviceLabel } from '../lib/format';

// Nội dung QR; app Why I Buy? (ExtensionQrScanScreen) chỉ nhận mã có tiền tố này
export const QR_PREFIX = 'whyibuy-link:';

export function PairForm({ large, onLinked }: { large?: boolean; onLinked: (synced: number) => void }) {
  const [code, setCode] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [help, setHelp] = useState(false);
  const [wait, setWait] = useState<{ id: string; expiresAt: string } | null>(null);
  const [left, setLeft] = useState(0);
  const timer = useRef<number | undefined>(undefined);

  useEffect(() => {
    if (!wait) return;
    const tick = async () => {
      setLeft(Math.max(0, Math.round((new Date(wait.expiresAt).getTime() - Date.now()) / 1000)));
      const st = await checkPairing(wait.id);
      if (st.state === 'approved') { setWait(null); onLinked(st.synced ?? 0); return; }
      if (st.state === 'rejected') { setWait(null); setErr(IS_FIREBASE ? 'Bạn đã từ chối trên điện thoại. Bấm tạo mã QR mới nếu muốn thử lần nữa.' : 'Bạn đã từ chối trên điện thoại. Mã này đã bị huỷ, hãy tạo mã mới trên app.'); return; }
      if (st.state === 'expired') { setWait(null); setErr(IS_FIREBASE ? 'Mã QR đã hết hạn. Bấm tạo mã QR mới rồi quét lại.' : 'Mã đã hết hạn. Hãy tạo mã mới trên app.'); return; }
      timer.current = window.setTimeout(tick, 1500);
    };
    tick();
    return () => window.clearTimeout(timer.current);
  }, [wait]);

  const submit = async () => {
    setBusy(true); setErr('');
    const r = await startPairing(code);
    setBusy(false);
    if (!r.ok) {
      setErr(r.reason === 'locked' ? 'Mã đã bị khoá vì nhập sai quá 5 lần. Hãy tạo mã mới trên app.'
        : r.reason === 'network' ? 'Không kết nối được. Kiểm tra mạng rồi thử lại.'
        : r.reason === 'signin' ? (IS_FIREBASE ? `Không tạo được mã QR.${r.message ? ` (${r.message})` : ''} Hãy thử lại.` : `Chưa đăng nhập được Google.${r.message && r.message !== 'cancelled' ? ` (${r.message})` : ''} Hãy thử lại.`)
        : `Mã không đúng hoặc đã hết hạn.${r.attemptsLeft != null ? ` Bạn còn ${r.attemptsLeft} lần thử.` : ''} Có thể tạo mã mới trên app.`);
      return;
    }
    setWait({ id: r.pairingId, expiresAt: r.expiresAt });
  };

  if (wait && IS_FIREBASE) return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'flex-start' }} role="status" aria-live="polite">
      <p className="t-subtitle">Quét mã QR bằng app Why I Buy?</p>
      <QrCode value={`${QR_PREFIX}${wait.id}`} size={large ? 220 : 180} />
      <p className="t-body-sm muted">Trên điện thoại: Cá nhân → Thiết bị đã liên kết → Quét mã QR, rồi chọn Đồng ý cho “{deviceLabel()}”. Mã hết hạn sau {Math.floor(left / 60)}:{String(left % 60).padStart(2, '0')}.</p>
      <div style={{ display: 'flex', gap: 8 }}><button className="btn" onClick={() => setWait(null)}>Huỷ</button></div>
    </div>
  );

  if (wait) return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }} role="status" aria-live="polite">
      <p className="t-subtitle">Đang chờ xác nhận trên điện thoại</p>
      <p className="t-body-sm muted">Mở app Why I Buy? và chọn Đồng ý cho thiết bị “{deviceLabel()}”. {IS_FIREBASE ? 'Yêu cầu' : 'Mã'} hết hạn sau {Math.floor(left / 60)}:{String(left % 60).padStart(2, '0')}.</p>
      <div style={{ display: 'flex', gap: 8 }}><button className="btn" onClick={() => setWait(null)}>Huỷ</button></div>
      {IS_DEMO && (
        <div className="demo">Bản demo · giả lập điện thoại (màn 25f):
          <div className="demo-row">
            <button className="btn tonal" onClick={() => mockApi()?.phone(wait.id, 'approve')}>Đồng ý</button>
            <button className="btn" onClick={() => mockApi()?.phone(wait.id, 'reject')}>Từ chối</button>
          </div>
        </div>
      )}
    </div>
  );

  if (IS_FIREBASE) return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {err ? <div className="error-text" role="alert"><IconAlert />{err}</div> : (
        <div className="hint"><IconHelp />Tạo mã QR rồi quét bằng app Why I Buy? trên điện thoại đã đăng nhập tài khoản của bạn. Không cần đăng nhập Google trên trình duyệt.</div>
      )}
      <button className={`btn primary${large ? '' : ' lg block'}`} disabled={busy} onClick={submit}>{busy ? 'Đang tạo mã…' : 'Tạo mã QR để liên kết'}</button>
    </div>
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <CodeInput large={large} value={code} onChange={(v) => { setCode(v); setErr(''); }} error={!!err} autoFocus />
      {err ? <div className="error-text" role="alert"><IconAlert />{err}</div> : (
        <div className="hint"><IconHelp />Lấy mã trong app: Cá nhân → Liên kết extension. Mã dùng một lần, hết hạn sau 5 phút.</div>
      )}
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button className={`btn primary${large ? '' : ' lg block'}`} disabled={code.length !== 6 || busy} onClick={submit}>{busy ? 'Đang gửi mã…' : 'Liên kết'}</button>
        <button className={`btn${large ? '' : ' block'}`} onClick={() => setHelp((h) => !h)}>Tôi chưa có mã</button>
      </div>
      {help && <div className="hint"><IconHelp /><span>Cần app Why I Buy? trên Android và đã đăng nhập. Chưa liên kết thì món vẫn được lưu trên máy này.{IS_DEMO ? ' Bản demo: dùng mã 482913.' : ''}</span></div>}
    </div>
  );
}

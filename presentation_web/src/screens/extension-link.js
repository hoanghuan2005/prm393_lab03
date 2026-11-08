// Liên kết tiện ích Chrome/Edge: Cá nhân → "Thiết bị đã liên kết" → Quét mã QR
// (ExtensionQrScanScreen) → ConfirmDialog → approved session (one Firestore batch).
import { html, icon, appBar, headerActions, bottomNav, section, button } from './kit.js'

// decorative QR-like pattern (encodes nothing)
function qrSvg() {
  const n = 21
  let seed = 7
  const rnd = () => ((seed = (seed * 9301 + 49297) % 233280) / 233280)
  const finder = (x, y) => `<rect x="${x}" y="${y}" width="7" height="7" fill="#0F172A"/><rect x="${x + 1}" y="${y + 1}" width="5" height="5" fill="#fff"/><rect x="${x + 2}" y="${y + 2}" width="3" height="3" fill="#0F172A"/>`
  let cells = ''
  for (let y = 0; y < n; y++)
    for (let x = 0; x < n; x++) {
      const inFinder = (x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12)
      if (!inFinder && rnd() > 0.52) cells += `<rect x="${x}" y="${y}" width="1" height="1" fill="#0F172A"/>`
    }
  return `<svg viewBox="-1 -1 23 23" width="132" height="132" shape-rendering="crispEdges"><rect x="-1" y="-1" width="23" height="23" fill="#fff"/>${cells}${finder(0, 0)}${finder(14, 0)}${finder(0, 14)}</svg>`
}

const deviceCard = (linked) =>
  section({
    title: 'Thiết bị đã liên kết',
    icon: icon('computer_rounded', 20),
    body: html`
      ${button('Quét mã QR', { icon: icon('qr_code_scanner_rounded', 20), variant: 'secondary', cls: 'b-scan' })}
      ${linked
        ? `<div class="wib-row" data-k="device" style="gap:16px;padding:12px 0 0">
            <span style="color:var(--text-2)">${icon('laptop_chromebook_rounded')}</span>
            <div class="wib-col" style="flex:1"><span style="font-size:16px">Edge – Windows</span><span class="t-caption">Liên kết ngày 07/11/2026</span></div>
            <span class="wib-textbtn">Huỷ liên kết</span></div>`
        : `<div class="t-body-m" style="margin-top:12px">Chưa có máy tính nào. Cài extension Why I Buy? trên Chrome hoặc Edge, chọn Tạo mã QR rồi quét bằng nút ở trên.</div>`}`,
  })

export default {
  id: 'extension-link',
  render() {
    return html`
      <div class="wib-screen scr-ext">
        <style>
          .scr-ext .pg{position:absolute;inset:28px 0 0 0;display:flex;flex-direction:column;background:var(--bg)}
          .scr-ext .cam{flex:1;position:relative;overflow:hidden;background:radial-gradient(90% 70% at 50% 45%,#3a3f4a,#15171c)}
          .scr-ext .laptop{position:absolute;left:50%;top:50%;width:250px;height:170px;margin:-100px 0 0 -125px;border-radius:10px;background:#0b0d12;box-shadow:0 0 0 6px #2a2d34}
          .scr-ext .laptop-screen{position:absolute;inset:8px;border-radius:4px;background:#f8fafc;display:grid;place-items:center}
          .scr-ext .scanline{position:absolute;left:18%;right:18%;height:2px;background:#FFDE02;box-shadow:0 0 12px #FFDE02;top:30%}
        </style>
        <div class="pg" data-k="profile">
          ${appBar({ back: 'chevron', title: 'Cá nhân', logoSize: 26, strong: true, actions: headerActions({ bell: 0, bookmark: 4 }) })}
          <div class="wib-body"><div class="wib-scroll">
            <div class="wib-card wib-row" style="gap:12px">
              <span class="wib-avatar" style="margin:0;width:48px;height:48px">${icon('person', 26)}</span>
              <div class="wib-col"><span class="t-title-m">Linh Nguyễn</span><span class="t-body-m">linh.nguyen@example.com</span></div>
            </div>
            <div style="height:16px"></div>
            <div data-k="card-a">${deviceCard(false)}</div>
            <div data-k="card-b" style="display:none">${deviceCard(true)}</div>
          </div></div>
          ${bottomNav('profile')}
        </div>
        <div class="pg" data-k="scan" style="display:none">
          ${appBar({ title: 'Quét mã QR liên kết' })}
          <div class="cam">
            <div class="laptop" data-k="laptop"><div class="laptop-screen">${qrSvg()}</div></div>
            <div class="scanline" data-k="scanline"></div>
          </div>
          <div class="t-body-m" style="padding:20px;text-align:center;background:#fff">Trên máy tính: mở extension Why I Buy? → Liên kết thiết bị → Tạo mã QR, rồi hướng camera vào mã.</div>
        </div>
        <div class="wib-scrim" data-k="scrim"></div>
        <div class="wib-dialog" data-k="dialog">
          <div class="wib-dialog__title">Cho phép Edge – Windows liên kết?</div>
          <div style="font-size:14px;line-height:1.4;color:var(--text-2)">Extension trên máy này sẽ xem và đồng bộ danh sách mong muốn, giá và ngân sách của bạn. Chỉ đồng ý nếu đây là máy tính của bạn.</div>
          <div class="wib-dialog__actions">
            <span class="wib-textbtn">Huỷ</span>
            <span class="wib-btn" data-k="agree" style="width:auto;padding:8px 24px">Đồng ý</span>
          </div>
        </div>
        <div class="wib-snackbar" data-k="snack" style="left:0;right:0;bottom:78px;border-radius:0">Đã liên kết Edge – Windows.</div>
      </div>`
  },

  demo(tl, root, k) {
    k.reveal(tl, '[data-k="card-a"]')
    k.tap(tl, '.b-scan', { pos: '+=0.5' })
    k.lift(tl, '+=0.05')
    k.page(tl, '[data-k="profile"]', '[data-k="scan"]', { pos: '+=0.1' })
    tl.fromTo(k.q('[data-k="laptop"]'), { scale: 0.7, rotation: -8, x: 40, opacity: 0.6 }, { scale: 1, rotation: 0, x: 0, opacity: 1, duration: 1.1, ease: 'power3.out' }, '>')
    tl.fromTo(k.q('[data-k="scanline"]'), { top: '25%' }, { top: '70%', duration: 0.6, repeat: 2, yoyo: true, ease: 'sine.inOut' }, '<')
    k.callout(tl, '[data-k="laptop"]', 'Mã QR chỉ sống 5 phút', { pos: '<+=0.3' })
    k.page(tl, '[data-k="scan"]', '[data-k="profile"]', { pos: '+=0.3', dir: -1 })
    k.dialog(tl, '[data-k="dialog"]', { scrim: '[data-k="scrim"]', pos: '+=0.1' })
    k.tap(tl, '[data-k="agree"]', { pos: '+=0.6' })
    k.dialog(tl, '[data-k="dialog"]', { scrim: '[data-k="scrim"]', open: false, pos: '+=0.05' })
    tl.set(k.q('[data-k="card-a"]'), { display: 'none' })
    tl.set(k.q('[data-k="card-b"]'), { display: '' })
    k.reveal(tl, '[data-k="device"]', { pos: '<' })
    k.snack(tl, '[data-k="snack"]', { pos: '<' })
    k.callout(tl, '[data-k="device"]', 'Một batch Firestore', { pos: '+=0.2' })
    k.wait(tl, 1)
  },
}

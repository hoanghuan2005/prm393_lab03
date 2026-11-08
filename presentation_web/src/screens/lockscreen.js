// Illustration of the problem (not an app screen): a lock screen flooded with
// generic shopping notifications late in the evening. No real brand is shown.
import { html, icon } from './kit.js'

const NOTES = [
  { app: 'Sàn mua sắm', color: '#F97316', ic: icon('local_offer_rounded', 16), time: 'bây giờ', title: 'Flash sale 11.11: giảm đến 50%', body: 'Chỉ còn 2 giờ! Món bạn xem hôm qua đang rẻ hơn.' },
  { app: 'Ví voucher', color: '#EF4444', ic: icon('confirmation_number_rounded', 16), time: '2 phút', title: 'Voucher 100K sắp hết hạn', body: 'Dùng ngay trước 23:59 để không bỏ lỡ.' },
  { app: 'Mạng xã hội', color: '#0EA5E9', ic: icon('trending_up', 16), time: '5 phút', title: 'Người bạn theo dõi vừa đăng bài', body: '“Món đáng mua nhất năm, mua ngay kẻo hết!”' },
  { app: 'Sàn mua sắm', color: '#F97316', ic: icon('shopping_cart_rounded', 16), time: '12 phút', title: 'Giỏ hàng của bạn đang giảm giá', body: '3 món trong giỏ vừa giảm thêm 15%.' },
  { app: 'Quảng cáo', color: '#2563EB', ic: icon('campaign_rounded', 16), time: '20 phút', title: 'Freeship 0đ cho mọi đơn', body: 'Chỉ áp dụng hôm nay.' },
]

export default {
  id: 'lockscreen',
  statusBar: 'light',
  render() {
    return html`
      <div class="wib-screen" style="background:radial-gradient(120% 80% at 30% 0%,#2a2340 0%,#141022 45%,#07060c 100%);color:#fff">
        <div class="wib-col" style="align-items:center;padding-top:34px">
          <div style="font-size:15px;font-weight:500;opacity:.85">Thứ Bảy, 7 tháng 11</div>
          <div data-k="clock" style="font-size:84px;font-weight:300;letter-spacing:-3px;line-height:1.05;margin-top:2px">22:47</div>
        </div>
        <div class="wib-col" data-k="stack" style="gap:8px;padding:22px 12px 0">
          ${NOTES.map(
            (n) => html`<div data-k="note" style="padding:12px 14px;border-radius:22px;background:rgba(255,255,255,.14);backdrop-filter:blur(18px);-webkit-backdrop-filter:blur(18px);box-shadow:inset 0 0 0 1px rgba(255,255,255,.08)">
              <div class="wib-row" style="gap:8px;font-size:11.5px;opacity:.8">
                <span style="width:20px;height:20px;border-radius:6px;display:grid;place-items:center;background:${n.color}">${n.ic}</span>
                <span style="flex:1">${n.app}</span><span>${n.time}</span>
              </div>
              <div style="margin-top:6px;font-size:14px;font-weight:600">${n.title}</div>
              <div style="margin-top:1px;font-size:13px;opacity:.82;line-height:1.35">${n.body}</div>
            </div>`,
          )}
        </div>
        <div class="wib-row" style="position:absolute;left:0;right:0;bottom:36px;justify-content:space-between;padding:0 44px;opacity:.85">
          <span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.14);display:grid;place-items:center">${icon('flashlight_on_rounded', 22)}</span>
          <span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.14);display:grid;place-items:center">${icon('photo_camera_rounded', 22)}</span>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const notes = k.qa('[data-k="note"]')
    tl.set(notes, { opacity: 0, y: -26, scale: 0.96 })
    notes
      .slice()
      .reverse()
      .forEach((n, i) => {
        tl.to(n, { opacity: 1, y: 0, scale: 1, duration: 0.5, ease: 'back.out(1.4)' }, i === 0 ? '+=0.3' : '+=0.45')
        tl.fromTo(k.q('[data-k="stack"]'), { x: -2 }, { x: 0, duration: 0.25, ease: 'elastic.out(1.2, 0.3)' }, '<')
      })
    k.callout(tl, notes[0], 'Khuyến mãi tạo cảm giác gấp gáp', { pos: '+=0.2' })
    k.callout(tl, notes[2], 'Ảnh hưởng mạng xã hội', { pos: '+=0.4' })
  },
}

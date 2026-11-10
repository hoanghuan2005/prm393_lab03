// Bong bóng trợ lý mua sắm (Android): FloatingBubbleService vẽ một bong bóng 54dp đè lên
// app mua sắm; ShoppingAccessibilityService thấy người dùng xem một món > 30 s thì bong bóng
// "thở", rung nhẹ và mở thẻ nhắc (chữ lấy nguyên từ handleLingeringAlert). Bấm "Lưu" gửi
// ACTION_SEND về MainActivity, tức là đi lại đúng đường Share Intent của màn Thêm món.
// Trang sản phẩm phía sau là minh hoạ chung chung, không dựng lại giao diện của sàn nào.
import { html, icon, logo } from './kit.js'

export default {
  id: 'bubble',
  render() {
    return html`
      <div class="wib-screen scr-bub" style="background:#F5F5F5">
        <style>
          .scr-bub .pg-top{display:flex;align-items:center;gap:10px;padding:8px 12px;background:#fff;box-shadow:0 1px 0 #E5E7EB}
          .scr-bub .pg-search{flex:1;height:34px;border-radius:8px;background:#F3F4F6;display:flex;align-items:center;gap:6px;padding:0 10px;font-size:13px;color:#9CA3AF}
          .scr-bub .pg-img{height:300px;display:grid;place-items:center;color:#fff;background:linear-gradient(150deg,#374151,#6B7280 55%,#D1D5DB)}
          .scr-bub .pg-card{background:#fff;padding:14px 16px;margin-bottom:8px}
          .scr-bub .pg-price{font-size:22px;font-weight:700;color:#DC2626}
          .scr-bub .pg-cta{position:absolute;left:0;right:0;bottom:0;display:flex;height:56px;background:#fff;box-shadow:0 -1px 0 #E5E7EB}
          .scr-bub .pg-cta span{flex:1;display:grid;place-items:center;font-size:14px;font-weight:600}
          .scr-bub .bb{position:absolute;right:10px;top:250px;width:54px;height:54px;border-radius:50%;background:#fff;display:grid;place-items:center;box-shadow:0 4px 14px rgba(0,0,0,.18);z-index:5}
          .scr-bub .bb-dot{position:absolute;top:2px;right:2px;width:12px;height:12px;border-radius:50%;background:#FF3B30;border:1.5px solid #fff;opacity:0}
          .scr-bub .bb-ring{position:absolute;inset:0;border-radius:50%;box-shadow:0 0 0 0 rgba(255,222,2,.7);opacity:0}
          .scr-bub .bb-card{position:absolute;right:72px;top:190px;width:250px;padding:12px;border-radius:16px;background:#1C2026;border:1.5px solid #FFDE02;color:#E0E0E0;z-index:5;opacity:0;transform-origin:100% 40%}
          .scr-bub .bb-title{font-size:14px;font-weight:700;color:#FFDE02}
          .scr-bub .bb-body{margin-top:6px;font-size:12px;line-height:1.4}
          .scr-bub .bb-info{margin-top:6px;font-size:11.5px;color:#FFDE02}
          .scr-bub .bb-btn{margin-top:10px;display:flex;align-items:center;justify-content:center;gap:6px;padding:8px;border-radius:8px;background:#FFDE02;color:#111;font-size:12.5px;font-weight:700}
          .scr-bub .bb-timer{position:absolute;left:12px;top:250px;padding:4px 10px;border-radius:999px;background:rgba(15,23,42,.78);color:#fff;font-size:12px;font-weight:600;z-index:4;opacity:0}
        </style>
        <div class="pg-top">${icon('arrow_back', 22)}<span class="pg-search">${icon('search', 18)}Tìm trong sàn mua sắm</span>${icon('shopping_cart_rounded', 22)}</div>
        <div data-k="page">
          <div class="pg-img">${icon('photo_camera_rounded', 72)}</div>
          <div class="pg-card">
            <div class="pg-price">450.000 ₫</div>
            <div style="margin-top:6px;font-size:15px;font-weight:500;color:#111827">Máy ảnh film mini, chụp ảnh lấy liền</div>
            <div style="margin-top:6px;font-size:12px;color:#6B7280">Đã bán 2,1k · Flash sale kết thúc sau 01:59:12</div>
          </div>
          <div class="pg-card" style="font-size:13px;color:#374151">Voucher shop giảm 30K · Freeship</div>
        </div>
        <div class="pg-cta"><span style="color:#DC2626">Thêm vào giỏ</span><span style="background:#DC2626;color:#fff">Mua ngay</span></div>

        <div class="bb-timer" data-k="timer">Đang xem · <b data-k="sec">0</b> s</div>
        <div class="bb" data-k="bubble"><span class="bb-ring" data-k="ring"></span>${logo(34)}<span class="bb-dot" data-k="dot"></span></div>
        <div class="bb-card" data-k="card">
          <div class="bb-title">🛑 Dừng lại 1 chút! Đừng mua vội</div>
          <div class="bb-body">Bạn đã dừng xem món này hơn 30 giây. Bạn đang thực sự CẦN hay chỉ là cảm xúc nhất thời? Hãy lưu lại để cân nhắc thêm nhé!</div>
          <div class="bb-info">Máy ảnh film mini • 450.000 ₫</div>
          <div class="bb-btn" data-k="save">${icon('shopping_cart_rounded', 16)}Lưu vào Wishlist Why I Buy</div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const sec = k.q('[data-k="sec"]')
    k.callout(tl, '[data-k="bubble"]', 'Bong bóng nổi trên app mua sắm', { pos: 0.4 })
    // người dùng xem trang sản phẩm, đồng hồ đếm thời gian xem (30 s, tua nhanh)
    tl.to(k.q('[data-k="timer"]'), { opacity: 1, duration: 0.3 }, '+=0.3')
    k.count(tl, sec, 30, { duration: 2.2, format: (v) => String(Math.round(v)), pos: '<' })
    // bong bóng "thở", chấm đỏ, mở thẻ nhắc
    tl.to(k.q('[data-k="timer"]'), { opacity: 0, duration: 0.25 }, '+=0.3')
    tl.to(k.q('[data-k="dot"]'), { opacity: 1, duration: 0.2 }, '<')
    tl.fromTo(k.q('[data-k="ring"]'), { opacity: 1, boxShadow: '0 0 0 0 rgba(255,222,2,.7)' }, { boxShadow: '0 0 0 18px rgba(255,222,2,0)', duration: 0.9, repeat: 1, ease: 'power2.out' }, '<')
    tl.fromTo(k.q('[data-k="bubble"]'), { scale: 1 }, { scale: 1.12, duration: 0.45, yoyo: true, repeat: 3, ease: 'sine.inOut' }, '<')
    tl.fromTo(k.q('[data-k="card"]'), { opacity: 0, scale: 0.85 }, { opacity: 1, scale: 1, duration: 0.45, ease: 'back.out(1.4)' }, '<+=0.3')
    k.callout(tl, '[data-k="card"]', 'Xem một món > 30 s → nhắc dừng lại', { pos: '+=0.2' })
    k.tap(tl, '[data-k="save"]', { pos: '+=1.4' })
    k.callout(tl, '[data-k="save"]', 'Mở form Thêm món (đường Share Intent)', { pos: '+=0.1' })
    k.wait(tl, 1.2)
  },
}

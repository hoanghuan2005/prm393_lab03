// Đăng nhập (lib/screens/login_screen.dart)
import { html, icon, button, field } from './kit.js'

export default {
  id: 'login',
  render() {
    return html`
      <div class="wib-screen">
        <div class="wib-body">
          <div class="wib-col" data-k="col" style="padding:20px 24px 24px">
            <span class="wib-textbtn" style="align-self:flex-start;padding:0">${icon('chevron_left_rounded', 24)}Quay lại</span>
            <div class="wib-row" data-k="brand" style="gap:10px;margin-top:14px">
              <span style="width:40px;height:40px;border-radius:13px;display:grid;place-items:center;background:linear-gradient(90deg,#FFD166,#FFDE02)">${icon('psychology_alt_rounded', 24)}</span>
              <span style="font-size:18px;font-weight:800">Why I Buy?</span>
            </div>
            <div data-k="title" style="margin-top:22px;font-size:24px;font-weight:800;line-height:1.3">Chào bạn trở lại</div>
            <div data-k="sub" style="margin-top:6px;font-size:14px;color:var(--text-2);line-height:1.45">Tiếp tục hiểu mình qua những khoản mua, từng chút một.</div>
            <div data-k="form" style="margin-top:20px">
              ${field({ float: 'Email', hint: 'Nhập email của bạn', prefix: icon('mail_outline_rounded', 20), cls: 'f-email' })}
              <div style="height:14px"></div>
              ${field({ float: 'Mật khẩu', hint: 'Nhập mật khẩu', prefix: icon('lock_outline_rounded', 20), cls: 'f-pass', trailing: `<span style="color:var(--text-2)">${icon('visibility_outlined', 22)}</span>` })}
            </div>
            <div style="align-self:flex-end;margin-top:4px"><span class="wib-textbtn">Quên mật khẩu?</span></div>
            <div data-k="actions">
              ${button('Đăng nhập', { icon: icon('login_rounded', 20), cls: 'b-login' })}
              <div class="wib-row" style="justify-content:center;margin-top:8px;font-size:14px">
                <span class="t-2">Chưa có tài khoản?</span><span class="wib-textbtn">Đăng ký</span>
              </div>
              <div class="wib-row" style="gap:12px;margin:12px 0 14px;font-size:14px;color:var(--text-2)">
                <span class="wib-divider" style="flex:1"></span>hoặc<span class="wib-divider" style="flex:1"></span>
              </div>
              ${button('Đăng nhập với Google', { icon: icon('g_mobiledata', 20), cls: 'b-google' })}
              <div style="height:10px"></div>
              ${button('Đăng nhập với GitHub', { icon: icon('code_rounded', 20), variant: 'secondary' })}
              <div style="height:10px"></div>
              ${button('Dùng thử chế độ Khách', { icon: icon('person_outline_rounded', 20), variant: 'secondary' })}
            </div>
            <div class="wib-banner" data-k="note" style="margin-top:22px">
              ${icon('lightbulb_outline', 20)}
              <div>Hiểu mình, không phán xét<br />Mỗi khoản mua là một dịp để lắng nghe chính bạn.</div>
            </div>
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    k.reveal(tl, '[data-k="brand"], [data-k="title"], [data-k="sub"], [data-k="form"], [data-k="actions"], [data-k="note"]', { stagger: 0.06 })
    const email = k.q('.f-email .wib-input')
    const pass = k.q('.f-pass .wib-input')
    k.tap(tl, email, { pos: '+=0.3', then: () => email.classList.add('is-focused') })
    k.type(tl, email.querySelector('.wib-input__value'), 'linh.nguyen@example.com', { cps: 26 })
    k.tap(tl, pass, {
      pos: '+=0.2',
      then: () => {
        email.classList.remove('is-focused')
        pass.classList.add('is-focused')
      },
    })
    k.type(tl, pass.querySelector('.wib-input__value'), '••••••••', { cps: 14 })
    k.callout(tl, '.b-google', 'Google Sign-In: 1 chạm', { pos: '+=0.3' })
    k.callout(tl, '.f-email', 'Firebase Authentication', { pos: '<' })
    k.tap(tl, '.b-google', { pos: '+=0.5', then: (el) => el.classList.add('is-loading') })
    k.wait(tl, 1.2)
  },
}

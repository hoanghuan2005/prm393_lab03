// Onboarding (lib/screens/onboarding_screen.dart): only slide 1 is reachable in the app.
import { html, icon, logo } from './kit.js'

const BENEFITS = [
  { icon: icon('schedule_rounded', 19), title: 'Ghi lại lý do mua', desc: 'Ghi lại món đồ và lý do khiến bạn mua.' },
  { icon: icon('insights_outlined', 19), title: 'Nhận ra mô hình chi tiêu', desc: 'Nhìn lại động cơ và thời điểm ghi khoản mua.' },
  { icon: icon('psychology_alt_outlined', 19), title: 'Hiểu mình, không phán xét', desc: 'Nhận diện cảm xúc, hiểu trước khi thay đổi.' },
]

export default {
  id: 'onboarding',
  render() {
    return html`
      <div class="wib-screen">
        <div class="wib-row" style="justify-content:space-between;padding:12px 20px">
          <span class="wib-row" style="gap:8px">${logo(36)}<span style="font-size:16px;font-weight:800;letter-spacing:-.3px">Why I Buy?</span></span>
          <span style="font-size:13px;font-weight:600;color:var(--text-2);padding:6px 14px">Bỏ qua</span>
        </div>
        <div class="wib-body">
          <div class="wib-col" style="align-items:center;padding:8px 24px 0">
            <div data-k="art" style="position:relative;width:100%;height:220px;border-radius:24px;background:linear-gradient(135deg,#FFF3B0,#F1F6F2);box-shadow:0 7px 18px rgba(0,0,0,.08),inset 0 0 0 1px rgba(226,232,240,.55);display:grid;place-items:center">
              <div data-k="circle" style="position:relative;width:136px;height:136px;border-radius:50%;background:#fff;box-shadow:0 5px 10px rgba(0,0,0,.1);display:grid;place-items:center">
                <div style="width:96px;height:96px;border-radius:50%;background:#E8F1ED;display:grid;place-items:center">${icon('spa_rounded', 52)}</div>
                <div data-k="badge" style="position:absolute;right:-8px;bottom:-2px;width:44px;height:44px;border-radius:50%;background:#263B1E;box-shadow:0 0 0 3px #E6F1EC;display:grid;place-items:center;color:#fff">${icon('self_improvement_rounded', 20)}</div>
              </div>
            </div>
            <span class="wib-overline" data-k="tag" style="margin-top:18px">DÀNH RIÊNG CHO BẠN</span>
            <div data-k="title" style="margin-top:12px;font-size:26px;font-weight:800;letter-spacing:-.5px">Why I Buy?</div>
            <div data-k="desc" style="margin-top:10px;font-size:14px;line-height:1.45;color:var(--text-2);text-align:center">Tiền bạc không chỉ là những con số. Quan sát động cơ tiêu dùng của chính mình để thay đổi nhẹ nhàng hơn.</div>
            <div class="wib-col" style="gap:8px;width:100%;margin-top:18px">
              ${BENEFITS.map(
                (b) => html`<div class="wib-row" data-k="benefit" style="gap:11px;padding:16px 12px;border-radius:13px;background:#fff;box-shadow:0 3px 8px rgba(0,0,0,.035),inset 0 0 0 1px #E8EDF2">
                  <span style="flex:none;width:38px;height:38px;border-radius:50%;background:var(--primary-container);display:grid;place-items:center">${b.icon}</span>
                  <span class="wib-col"><span style="font-size:13px;font-weight:700">${b.title}</span><span style="margin-top:2px;font-size:11.5px;line-height:1.3;color:var(--text-2)">${b.desc}</span></span>
                </div>`,
              )}
            </div>
          </div>
        </div>
        <div style="padding:8px 24px 26px">
          <span class="wib-btn wib-btn--lg" data-k="start" style="min-height:52px"><span class="wib-btn__label wib-row" style="gap:8px">Bắt đầu trải nghiệm ${icon('arrow_forward_rounded', 20)}</span><span class="wib-btn__spinner"></span></span>
          <div class="wib-row" style="justify-content:center;gap:6px;margin-top:14px;font-size:12px;color:var(--text-2);opacity:.7">${icon('shield_outlined', 14)}Dữ liệu an toàn • Không phán xét chi tiêu</div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    tl.fromTo(k.q('[data-k="art"]'), { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.6, ease: 'power3.out' })
    tl.fromTo(k.q('[data-k="circle"]'), { scale: 0.6, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.7, ease: 'back.out(1.6)' }, '-=0.3')
    tl.fromTo(k.q('[data-k="badge"]'), { scale: 0 }, { scale: 1, duration: 0.45, ease: 'back.out(2)' }, '-=0.2')
    k.reveal(tl, '[data-k="tag"], [data-k="title"], [data-k="desc"]', { pos: '-=0.3' })
    k.reveal(tl, '[data-k="benefit"]', { pos: '-=0.2', stagger: 0.12 })
    k.callout(tl, '[data-k="benefit"]:nth-child(3)', 'Giọng điệu: không phán xét', { pos: '+=0.2' })
    k.tap(tl, '[data-k="start"]', { pos: '+=0.9' })
  },

  demos: {
    idle(tl, root, k) {
      k.reveal(tl, '[data-k="art"], [data-k="tag"], [data-k="title"], [data-k="desc"], [data-k="benefit"]', { stagger: 0.07 })
    },
  },
}

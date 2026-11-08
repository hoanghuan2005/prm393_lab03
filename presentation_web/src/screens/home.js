// Trang chủ (lib/screens/home_screen.dart) with demo data from DemoDataService.
import { html, icon, appBar, headerActions, bottomNav, motiveTag, motiveSquare, money } from './kit.js'

const SEGMENTS = [
  ['need', 273],
  ['sale', 182],
  ['other', 91],
  ['social', 91],
  ['ads', 91],
  ['emotion', 91],
  ['want', 91],
  ['convenience', 91],
]
const RECENT = [
  { title: 'Bút và sổ tay', motive: 'need', when: 'Hôm nay 10:40', amount: 68000 },
  { title: 'Ốp lưng điện thoại', motive: 'other', when: 'Hôm qua 14:25', amount: 99000 },
  { title: 'Vé xem phim cùng bạn', motive: 'social', when: '04/11 18:05', amount: 120000 },
]

export default {
  id: 'home',
  render() {
    return html`
      <div class="wib-screen">
        ${appBar({ back: 'chevron', title: 'Trang chủ', logoSize: 26, strong: true, actions: headerActions({ bell: 0, bookmark: 4 }) })}
        <div class="wib-body">
          <div class="wib-scroll" data-k="scroll" style="padding-bottom:140px">
            <div class="t-title-m" data-k="hello">Chào bạn,</div>
            <div class="wib-card" data-k="overview" style="margin-top:12px;box-shadow:0 2px 8px rgba(0,0,0,.02)">
              <div class="wib-row" style="justify-content:space-between">
                <span class="wib-row" style="gap:6px;color:var(--text-2)">${icon('calendar_today_outlined', 14)}
                  <span style="font-size:11px;font-weight:700;letter-spacing:.6px">TỔNG QUAN THÁNG</span></span>
                <span class="wib-pill">Tháng 11/2026 ${icon('arrow_drop_down_rounded', 16)}</span>
              </div>
              <div data-k="total" style="margin-top:12px;font-size:32px;font-weight:800;letter-spacing:-.5px;color:var(--neutral);line-height:1.2">${money(1589000)}</div>
              <div style="margin-top:4px;font-size:13px;color:var(--text-2)">11 khoản trong tháng · Tuần này: 9 khoản (1.160.000 ₫)</div>
              <div style="margin-top:4px;font-size:13px;color:var(--text-2)">Nhiều nhất: <b style="color:var(--text);font-weight:700">Nhu cầu (3/11)</b></div>
              <div class="wib-row" style="justify-content:space-between;margin-top:14px;font-size:12px">
                <span class="t-2">Động cơ chính</span><b style="font-weight:700">27% do Nhu cầu</b>
              </div>
              <div class="wib-segbar" data-k="segbar" style="margin-top:8px;transform-origin:left center">
                ${SEGMENTS.map(([k, f]) => `<span data-motive="${k}" style="flex:${f} 1 0"></span>`)}
              </div>
              <div class="wib-divider" style="margin:10px 0"></div>
              <div class="wib-row" data-k="budget" style="gap:6px;font-size:12px">
                <span style="color:var(--neutral)">${icon('account_balance_wallet_outlined', 15)}</span>
                <span class="t-2">Ngân sách tháng: <b style="color:var(--text);font-weight:700">808.000 ₫ / 3.100.000 ₫</b></span>
                <span class="wib-spacer"></span>
                <span data-k="pct" style="padding:1.5px 6px;border-radius:4px;background:var(--success-c);color:var(--on-success-c);font-size:11px;font-weight:800">26%</span>
                <span class="t-2">${icon('chevron_right_rounded', 16)}</span>
              </div>
            </div>

            <div class="wib-card wib-row" data-k="wish" style="margin-top:16px;padding:14px 16px;gap:14px">
              ${icon('bookmark_border_rounded', 22)}
              <div style="flex:1">
                <div style="font-size:15px;font-weight:700">Danh sách mong muốn</div>
                <div style="margin-top:2px;font-size:12.5px;color:var(--text-2)">4 món đang cân nhắc</div>
              </div>
              <span class="t-2">${icon('chevron_right_rounded', 22)}</span>
            </div>

            <div data-k="before" style="margin-top:24px">
              <div style="font-size:16px;font-weight:700">Trước khi mua</div>
              <div style="margin-top:6px;font-size:13px;color:var(--text-2)">Dừng lại một chút. Vài câu hỏi nhanh giúp bạn hiểu điều gì đang thu hút mình.</div>
              <div style="margin-top:2px;font-size:13px;color:var(--text-2)">Hiểu trước khi thay đổi.</div>
              <div class="wib-row" style="gap:8px;margin-top:10px;flex-wrap:wrap">
                <span class="wib-action-chip" data-k="chip-before">${icon('lightbulb_outline', 18)}Trước khi mua</span>
                <span class="wib-action-chip">${icon('photo_camera_outlined', 18)}Chụp để tìm</span>
              </div>
            </div>

            <div data-k="recent" style="margin-top:24px">
              <div class="wib-row" style="gap:8px">
                <div style="flex:1;font-size:16px;font-weight:700">Khoản mua gần đây</div>
                <span style="padding:2px 8px;border-radius:999px;background:var(--surface-variant);font-size:12px;font-weight:700;color:var(--text-2)">3</span>
                <span class="wib-row" style="font-size:13px;font-weight:600;color:var(--neutral)">Xem tất cả ${icon('chevron_right_rounded', 18)}</span>
              </div>
              <div class="wib-card" style="margin-top:12px;padding:0">
                ${RECENT.map(
                  (r, i) => html`${i ? '<div class="wib-divider"></div>' : ''}
                  <div class="wib-row" data-k="row" style="gap:12px;padding:14px 16px">
                    ${motiveSquare(r.motive)}
                    <div style="flex:1;min-width:0">
                      <div style="font-size:15px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${r.title}</div>
                      <div class="wib-row" style="gap:8px;margin-top:4px">${motiveTag(r.motive)}<span style="font-size:12px;color:var(--text-2);opacity:.7">${r.when}</span></div>
                    </div>
                    <div style="font-size:15px;font-weight:700;color:var(--neutral)">${money(r.amount)}</div>
                  </div>`,
                )}
              </div>
            </div>
          </div>
          <div class="wib-fab" data-k="fab" style="bottom:12px">${icon('add_circle_outline_rounded', 20)}Ghi khoản mua</div>
        </div>
        ${bottomNav('home')}
      </div>`
  },

  demo(tl, root, k) {
    k.reveal(tl, '[data-k="hello"], [data-k="overview"], [data-k="wish"], [data-k="before"], [data-k="recent"]', { stagger: 0.08 })
    k.count(tl, '[data-k="total"]', 1589000, { pos: 0.15, duration: 1.3 })
    tl.fromTo(k.q('[data-k="segbar"]'), { scaleX: 0 }, { scaleX: 1, duration: 1.1, ease: 'power3.out' }, 0.45)
    k.callout(tl, '[data-k="segbar"]', '8 động cơ mua, mỗi động cơ một màu', { pos: 1.1 })
    k.callout(tl, '[data-k="pct"]', 'Ngân sách: 26%, chưa chạm mốc', { pos: 1.6 })
    k.scroll(tl, '[data-k="scroll"]', 300, { pos: '+=1.6', duration: 1.1 })
    k.tap(tl, '[data-k="chip-before"]', { pos: '+=0.2' })
    k.scroll(tl, '[data-k="scroll"]', 0, { pos: '+=0.6', duration: 1 })
  },

  demos: {
    idle(tl, root, k) {
      k.reveal(tl, '[data-k="hello"], [data-k="overview"], [data-k="wish"], [data-k="before"], [data-k="recent"]', { stagger: 0.08, pos: 1.4 })
      k.count(tl, '[data-k="total"]', 1589000, { pos: 1.5, duration: 1.4 })
      tl.fromTo(k.q('[data-k="segbar"]'), { scaleX: 0 }, { scaleX: 1, duration: 1.2, ease: 'power3.out' }, 1.8)
    },
  },
}

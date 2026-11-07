// Góc nhìn (lib/screens/insights_screen.dart + services/ai_insight_service.dart).
// Code computes every number; Gemini only rewrites the wording. Template sentences
// render first ('Câu mẫu'), validated AI sentences swap in card by card ('AI').
// A card whose AI text fails isAcceptable() (unknown number, too long, banned
// phrase) silently keeps its template sentence.
import { html, icon, appBar, headerActions, bottomNav } from './kit.js'

// Demo month 11/2026 from DemoDataService (11 purchases, 1.589.000 ₫; Oct 3.281.000 ₫).
// AI wording only reuses numbers in MonthlySpendingStats.allowedNumbers.
const CARDS = [
  {
    icon: icon('pie_chart_outline_rounded', 20),
    color: '#F59E0B',
    tpl: ['Động cơ ghi nhiều nhất: Nhu cầu', '3/11 khoản mua tháng này bạn ghi là Nhu cầu (27%), tổng 288.000 ₫.'],
    ai: ['Nhu cầu dẫn đầu tháng này', '3 trong 11 khoản mua bạn ghi là Nhu cầu, chiếm 27%, tổng 288.000 ₫. Điều gì khiến những món này trở nên cần thiết với bạn?'],
  },
  {
    icon: icon('nightlight_round', 20),
    color: '#3B82F6',
    tpl: ['Mua trong khung 22:00 - 05:00', 'Có 2 khoản mua trong khung giờ này, tổng 434.000 ₫. Bạn còn nhớ lúc đó mình mua vì sao không?'],
    ai: ['Những lần mua lúc khuya', '2 khoản mua rơi vào khung 22:00 - 05:00, tổng 434.000 ₫. Lúc ấy bạn đang làm gì và cảm thấy thế nào?'],
  },
  {
    // AI sentence rejected by the validator -> stays on the template
    icon: icon('compare_arrows_rounded', 20),
    color: '#0EA5E9',
    tpl: ['So với tháng trước', 'Tổng đã chi bạn ghi tháng này là 1.589.000 ₫, thấp hơn tháng 10/2026 khoảng 52% (3.281.000 ₫).'],
    ai: null,
  },
  {
    icon: icon('receipt_long_outlined', 20),
    color: '#A855F7',
    tpl: ['Khoản lớn nhất tháng', 'Tai nghe Bluetooth: 389.000 ₫, bạn ghi động cơ Khuyến mãi, lúc 23:40.'],
    ai: ['Tai nghe Bluetooth là khoản lớn nhất', 'Bạn mua Tai nghe Bluetooth 389.000 ₫ lúc 23:40 và ghi động cơ Khuyến mãi. Đến giờ món này được bạn dùng thế nào?'],
  },
  {
    icon: icon('do_not_disturb_on_outlined', 20),
    color: '#14B8A6',
    tpl: ['Món đã quyết định không mua', 'Tháng này bạn đã cân nhắc và không mua 1 món, tổng giá đã ghi 799.000 ₫.'],
    ai: ['Một món bạn đã chọn không mua', 'Bạn đã cân nhắc và quyết định không mua 1 món, tổng giá đã ghi 799.000 ₫. Điều gì giúp bạn đi đến quyết định đó?'],
  },
]

const STATUS_TPL = 'Đang viết nhận xét từ số liệu của bạn...'
const STATUS_AI = 'Lời nhận xét do AI viết lại từ số liệu app đã tính. AI không tạo ra con số mới.'

// final translateY of the list = content 1119 - body 618 (measured): bottom of the list
const SCROLL_END = 501

const STYLE = `
.scr-ins .scr-ins__month{display:flex;align-items:center;justify-content:space-between;padding:2px 8px;border-radius:14px;background:var(--surface);border:1px solid var(--divider)}
.scr-ins .scr-ins__month .wib-iconbtn{width:48px;height:48px;color:var(--text-2)}
.scr-ins .scr-ins__ai{margin-top:12px;padding:12px 8px 12px 16px;border-radius:16px;background:var(--primary-container);border:1px solid rgba(255,222,2,.5)}
.scr-ins .scr-ins__prog{position:relative;height:3px;margin-bottom:8px;background:var(--surface-variant);overflow:hidden}
.scr-ins .scr-ins__prog>span{position:absolute;left:0;top:0;bottom:0;width:38%;background:var(--text)}
.scr-ins .scr-ins__card{margin-bottom:16px;padding:16px;border-radius:16px;background:var(--surface);border:1px solid var(--divider)}
.scr-ins .scr-ins__tile{flex:none;width:36px;height:36px;display:grid;place-items:center;border-radius:10px}
.scr-ins .scr-ins__title{font-size:15px;font-weight:700;line-height:1.35;color:var(--text)}
.scr-ins .scr-ins__text{font-size:14px;line-height:1.45;color:var(--text-2)}
.scr-ins .scr-ins__swap{position:relative}
.scr-ins .scr-ins__swap>.v-ai{position:absolute;left:0;right:0;top:0;opacity:0}
.scr-ins .scr-ins__chip{flex:none;line-height:1.35;transform-origin:right center}
.scr-ins .scr-ins__chip .c-ai{display:none}
.scr-ins .scr-ins__chip .c-tpl{display:contents}
.scr-ins .scr-ins__chip.is-ai .c-tpl{display:none}
.scr-ins .scr-ins__chip.is-ai .c-ai{display:contents}
.scr-ins .scr-ins__more{display:flex;align-items:center;justify-content:center;gap:8px;height:48px;border-radius:999px;border:1px solid var(--divider);font-size:14px;font-weight:600;color:var(--text)}
`

/** InsightSourceChip: renders both looks, .is-ai + wib-ai-chip flips it */
const sourceChip = () =>
  `<span class="wib-tpl-chip scr-ins__chip" data-k="chip"><span class="c-tpl">${icon('notes_rounded', 12)}<span>Câu mẫu</span></span><span class="c-ai">${icon('auto_awesome', 12)}<span>AI</span></span></span>`

const swap = (cls, tpl, ai, attrs = '') =>
  `<div class="scr-ins__swap ${cls}" ${attrs}><div class="v-tpl">${tpl}</div>${ai ? `<div class="v-ai">${ai}</div>` : ''}</div>`

export default {
  id: 'insights',
  render() {
    return html`
      <div class="wib-screen scr-ins">
        <style>${STYLE}</style>
        ${appBar({ back: 'chevron', title: 'Góc nhìn', logoSize: 26, strong: true, actions: headerActions({ bell: 0, bookmark: 4 }) })}
        <div class="wib-body" data-k="body">
          <div class="wib-scroll" data-k="scroll">
            <div class="scr-ins__month" data-k="month">
              <span class="wib-iconbtn">${icon('chevron_left_rounded')}</span>
              <span class="wib-row" style="gap:8px;padding:12px 8px">${icon('calendar_month_outlined', 16)}<span style="font-size:14px;font-weight:700">Tháng 11/2026</span></span>
              <span class="wib-iconbtn">${icon('chevron_right_rounded')}</span>
            </div>

            <div class="scr-ins__ai" data-k="ai">
              <div class="wib-row" style="min-height:48px">
                <span style="color:var(--ai-accent);display:flex">${icon('auto_awesome', 24)}</span>
                <span style="flex:1;margin-left:12px;font-size:15px;font-weight:700">Dùng AI</span>
                <span class="wib-switch is-on" style="margin-right:4px"></span>
              </div>
              <div style="padding:0 8px 0 36px">
                <div class="scr-ins__prog" data-k="prog"><span></span></div>
                ${swap('', STATUS_TPL, STATUS_AI, 'data-k="status" style="font-size:13px;line-height:1.4;color:var(--text-body)"')}
                <div style="margin-top:4px;font-size:12px;line-height:1.35;color:var(--neutral)">Chỉ gửi số liệu đã tổng hợp, động cơ và tên khoản lớn nhất. Không gửi ghi chú hay link.</div>
              </div>
            </div>

            <div style="height:20px"></div>
            ${CARDS.map(
              (c, i) => html`<div class="scr-ins__card" data-k="card" data-i="${i}">
                <div class="wib-row" style="align-items:flex-start">
                  <span class="scr-ins__tile" style="background:${c.color}1a;color:${c.color}">${c.icon}</span>
                  ${swap('scr-ins__title', c.tpl[0], c.ai && c.ai[0], 'style="flex:1;min-width:0;margin:0 8px 0 10px"')}
                  ${sourceChip()}
                </div>
                ${swap('scr-ins__text', c.tpl[1], c.ai && c.ai[1], 'style="margin-top:12px"')}
              </div>`,
            )}
            <div class="scr-ins__more" data-k="more">${icon('auto_stories_outlined', 18)}Xem chiêm nghiệm tháng</div>
          </div>
        </div>
        ${bottomNav('insights')}
      </div>`
  },

  demo(tl, root, k) {
    const cards = k.qa('[data-k="card"]')
    const chips = cards.map((c) => c.querySelector('[data-k="chip"]'))

    // 1. template sentences render first, AI request in flight
    k.reveal(tl, '[data-k="month"], [data-k="ai"], [data-k="card"], [data-k="more"]', { stagger: 0.06, pos: 0 })
    tl.fromTo(k.q('[data-k="prog"] > span'), { xPercent: -100 }, { xPercent: 265, duration: 0.85, ease: 'power1.inOut', repeat: 1 }, 0.2)

    // 2. Gemini reply validated: status line + progress bar
    const T = 2.0
    tl.to(k.q('[data-k="prog"]'), { height: 0, marginBottom: 0, opacity: 0, duration: 0.3, ease: 'power2.out' }, T)
    swapText(tl, k.q('[data-k="status"]'), T)

    // 3. card by card: chip flips to 'AI', text cross-fades (card 3 is rejected and stays)
    const at = { 0: T + 0.2, 1: T + 0.5, 3: T + 1.15, 4: T + 1.45 }
    CARDS.forEach((c, i) => {
      if (!c.ai) return
      const p = at[i]
      k.cls(tl, chips[i], 'wib-tpl-chip', false, p - 0.02)
      k.cls(tl, chips[i], 'wib-ai-chip', true, p - 0.02)
      k.cls(tl, chips[i], 'is-ai', true, p - 0.02)
      tl.fromTo(chips[i], { scale: 0.55 }, { scale: 1, duration: 0.4, ease: 'back.out(2.6)', immediateRender: false }, p)
      cards[i].querySelectorAll('.scr-ins__swap').forEach((box) => swapText(tl, box, p))
    })

    // 4. scroll down so the rejected card and the last AI cards are in view
    tl.to(k.q('[data-k="scroll"]'), { y: -SCROLL_END, duration: 1.0, ease: 'power2.inOut' }, T + 0.55)
    k.callout(tl, chips[3], 'Gemini viết lại câu', { pos: T + 1.9 })
    k.callout(tl, chips[2], 'Câu AI sai bị loại', { pos: T + 2.5 })
    tl.to({}, { duration: 2.3 }, T + 2.5)
  },
}

/** cross-fade .v-tpl -> .v-ai inside `box`, animating the box height between the two */
function swapText(tl, box, pos) {
  const tpl = box.querySelector('.v-tpl')
  const ai = box.querySelector('.v-ai')
  if (!ai) return
  tl.fromTo(box, { height: () => tpl.offsetHeight }, { height: () => ai.offsetHeight, duration: 0.45, ease: 'power2.inOut', immediateRender: false }, pos)
  tl.to(tpl, { opacity: 0, duration: 0.28, ease: 'power1.inOut' }, pos)
  tl.to(ai, { opacity: 1, duration: 0.32, ease: 'power1.inOut' }, pos + 0.06)
}

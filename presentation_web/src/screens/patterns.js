// Mô hình tab (lib/screens/patterns_screen.dart). No chart library in the app:
// every chart is a LinearProgressIndicator, rebuilt here as track + fill.
// Data: PurchaseViewModel.weekStats / monthStats on the demo seed (today Sat 07/11/2026).
import { html, icon, appBar, headerActions, bottomNav, money, MOTIVES } from './kit.js'

const WEEK = {
  label: '02/11 – 08/11/2026',
  title: 'Tổng chi tiêu trong tuần',
  total: 1160000,
  count: 9,
  motives: [
    ['need', 288000, 3],
    ['ads', 265000, 1],
    ['sale', 200000, 1],
    ['want', 143000, 1],
    ['social', 120000, 1],
    ['other', 99000, 1],
    ['emotion', 45000, 1],
  ],
  slots: [
    [3, 246000],
    [0, 0],
    [2, 284000],
    [4, 630000],
  ],
}
const MONTH = {
  label: 'Tháng 11/2026',
  title: 'Tổng chi tiêu trong tháng',
  total: 1589000,
  count: 11,
  motives: [
    ['sale', 589000, 2],
    ['need', 288000, 3],
    ['ads', 265000, 1],
    ['want', 143000, 1],
    ['social', 120000, 1],
    ['other', 99000, 1],
    ['emotion', 45000, 1],
    ['convenience', 40000, 1],
  ],
  slots: [
    [3, 246000],
    [1, 40000],
    [2, 284000],
    [5, 1019000],
  ],
}
// TimeSlot enum order, _slotIcons, _slotColors (AppColors.slot*)
const SLOTS = [
  { key: 'morning', title: 'Sáng (05:00 - 11:00)', ic: icon('wb_sunny_outlined', 18), color: '#3B82F6' },
  { key: 'noon', title: 'Trưa (11:00 - 14:00)', ic: icon('wb_sunny_rounded', 18), color: '#10B981' },
  { key: 'afternoon', title: 'Chiều (14:00 - 18:00)', ic: icon('wb_twilight_rounded', 18), color: '#F59E0B' },
  { key: 'evening', title: 'Tối (18:00 - 05:00)', ic: icon('nightlight_round', 18), color: '#6366F1' },
]

const STYLE = `
.scr-patterns .pat-card{background:#fff;border:1px solid var(--divider);border-radius:16px}
.scr-patterns .pat-seg{position:relative;display:flex;padding:4px;border-radius:12px;background:#E2E8F0}
.scr-patterns .pat-seg__thumb{position:absolute;left:4px;top:4px;bottom:4px;width:calc(50% - 4px);border-radius:10px;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.06)}
.scr-patterns .pat-seg__opt{position:relative;flex:1;padding:8px 0;text-align:center;font-size:13px;line-height:1.35;font-weight:500;color:var(--text-2);border-radius:10px}
.scr-patterns .pat-seg__opt.is-on{font-weight:700;color:var(--text)}
.scr-patterns .pat-h{font-size:16px;font-weight:700;line-height:1.35}
.scr-patterns .pat-track{position:relative;border-radius:4px;background:#F1F5F9;overflow:hidden}
.scr-patterns .pat-fill{position:absolute;inset:0 auto 0 0;display:block}
.scr-patterns .pat-tile{flex:none;width:32px;height:32px;border-radius:8px;background:var(--mb);color:var(--m);display:grid;place-items:center}
.scr-patterns .pat-muted{font-size:12px;line-height:1.35;color:rgba(100,116,139,.7)}
`

const pctOf = (sum, total) => (total > 0 ? (sum / total) * 100 : 0)

function motiveRows(period) {
  return period.motives
    .map(([key, sum, count]) => {
      const pct = pctOf(sum, period.total)
      const fill = key === 'sale' ? '#FFDE02' : 'var(--m)'
      return html`<div data-k="motive-row" data-motive="${key}" style="padding:12px 16px">
        <div class="wib-row">
          <span class="pat-tile">${icon(MOTIVES[key].icon, 16)}</span>
          <div style="flex:1;min-width:0;margin-left:10px">
            <div class="wib-row" style="justify-content:space-between;font-size:14px;font-weight:700;line-height:1.35">
              <span>${MOTIVES[key].label}</span><span style="color:var(--neutral)">${money(sum)}</span>
            </div>
            <div class="wib-row" style="justify-content:space-between;margin-top:4px">
              <span class="pat-muted">${count} khoản chi</span>
              <span style="font-size:12px;font-weight:700;line-height:1.35;color:var(--text-2)">${pct.toFixed(0)}%</span>
            </div>
          </div>
        </div>
        <div class="pat-track" style="height:6px;margin-top:8px">
          <span class="pat-fill" data-pct="${pct.toFixed(2)}" style="width:${pct.toFixed(2)}%;background:${fill}"></span>
        </div>
      </div>`
    })
    .join('')
}

function slotRows(period) {
  return SLOTS.map((s, i) => {
    const [count, sum] = period.slots[i]
    const pct = pctOf(sum, period.total)
    return html`${i ? '<div style="height:1px;margin:9.5px 0;background:var(--divider)"></div>' : ''}
      <div data-k="slot-${s.key}">
        <div class="wib-row" style="min-height:20px">
          <span style="display:flex;color:${s.color}">${s.ic}</span>
          <span style="margin-left:8px;font-size:13px;font-weight:600;line-height:1.35">${s.title}</span>
          <span class="wib-spacer"></span>
          <span data-k="slot-sub" style="font-size:12px;line-height:1.35;color:var(--text-2)">${count} khoản (${money(sum)})</span>
        </div>
        <div class="pat-track" style="height:5px;margin-top:6px">
          <span class="pat-fill" data-k="slot-fill" data-pct="${pct.toFixed(2)}" style="width:${pct.toFixed(2)}%;background:${s.color}"></span>
        </div>
      </div>`
  }).join('')
}

export default {
  id: 'patterns',
  render() {
    return html`
      <div class="wib-screen scr-patterns">
        <style>${STYLE}</style>
        ${appBar({ back: 'chevron', title: 'Mô hình', logoSize: 26, strong: true, actions: headerActions({ bell: 0, bookmark: 4 }) })}
        <div class="wib-body">
          <div class="wib-scroll" data-k="scroll">
            <div class="pat-seg" data-k="seg">
              <span class="pat-seg__thumb" data-k="thumb"></span>
              <span class="pat-seg__opt is-on" data-k="opt-week">Tuần</span>
              <span class="pat-seg__opt" data-k="opt-month">Tháng</span>
            </div>

            <div class="pat-card wib-row" data-k="period" style="margin-top:12px;padding:4px 16px;border-radius:14px;justify-content:space-between">
              <span class="wib-iconbtn" style="width:48px;height:48px;color:var(--text-2)">${icon('chevron_left_rounded')}</span>
              <span class="wib-row" style="padding:6px 8px">
                <span style="display:flex">${icon('calendar_month_outlined', 16)}</span>
                <span data-k="plabel" style="margin-left:8px;font-size:14px;font-weight:700;line-height:1.35;white-space:nowrap">${WEEK.label}</span>
                <span style="display:flex;margin-left:4px;color:var(--text-2)">${icon('arrow_drop_down_rounded', 20)}</span>
              </span>
              <span class="wib-iconbtn" style="width:48px;height:48px;color:var(--text-2)">${icon('chevron_right_rounded')}</span>
            </div>

            <div class="pat-card wib-row" data-k="total" style="margin-top:16px;padding:16px;justify-content:space-between">
              <div>
                <div data-k="ttitle" style="font-size:12px;line-height:1.35;color:var(--text-2)">${WEEK.title}</div>
                <div data-k="tamount" style="margin-top:4px;font-size:26px;font-weight:800;line-height:1.25;color:var(--neutral)">${money(WEEK.total)}</div>
                <div class="pat-muted" data-k="tcount" style="margin-top:2px">${WEEK.count} khoản đã ghi nhận</div>
              </div>
              <span style="flex:none;width:48px;height:48px;border-radius:50%;background:var(--primary-container);display:grid;place-items:center">${icon('pie_chart_rounded', 24)}</span>
            </div>

            <div class="pat-h" data-k="h-motive" style="margin-top:24px">Theo động cơ</div>
            <div class="pat-card" data-k="motives" style="margin-top:12px">
              <div data-k="m-week">${motiveRows(WEEK)}</div>
              <div data-k="m-month" style="display:none">${motiveRows(MONTH)}</div>
            </div>

            <div class="pat-h" data-k="h-slot" style="margin-top:24px">Khung giờ mua sắm</div>
            <div class="pat-card" data-k="slots" style="margin-top:12px;padding:16px">${slotRows(WEEK)}</div>
          </div>
        </div>
        ${bottomNav('patterns')}
      </div>`
  },

  demo(tl, root, k) {
    const scroll = k.q('[data-k="scroll"]')
    k.reveal(tl, '[data-k="seg"], [data-k="period"], [data-k="total"], [data-k="h-motive"], [data-k="motives"]', { stagger: 0.06 })
    k.fill(tl, '[data-k="m-week"] .pat-fill', { pos: 0.3, duration: 0.7, stagger: 0.05 })

    // tap "Tháng": one period drives every number on the tab
    const TAP = 1.2
    const PRESS = TAP + 0.59 // k.tap: 0.5 s travel + 0.09 s press
    k.tap(tl, '[data-k="opt-month"]', { pos: TAP })
    tl.to(k.q('[data-k="thumb"]'), { xPercent: 100, duration: 0.25, ease: 'power2.out' }, PRESS)
    k.cls(tl, '[data-k="opt-week"]', 'is-on', false, PRESS)
    k.cls(tl, '[data-k="opt-month"]', 'is-on', true, PRESS)
    k.text(tl, '[data-k="plabel"]', MONTH.label, PRESS)
    k.text(tl, '[data-k="ttitle"]', MONTH.title, PRESS)
    k.text(tl, '[data-k="tcount"]', `${MONTH.count} khoản đã ghi nhận`, PRESS)
    k.count(tl, '[data-k="tamount"]', MONTH.total, { from: WEEK.total, pos: PRESS, duration: 0.5 })
    tl.set(k.q('[data-k="m-week"]'), { display: 'none' }, PRESS)
    tl.set(k.q('[data-k="m-month"]'), { display: '' }, PRESS)
    k.fill(tl, '[data-k="m-month"] .pat-fill', { pos: PRESS, duration: 0.6, stagger: 0.04 })
    k.qa('[data-k="slot-sub"]').forEach((el, i) => {
      const [count, sum] = MONTH.slots[i]
      k.text(tl, el, `${count} khoản (${money(sum)})`, PRESS)
    })
    k.qa('[data-k="slot-fill"]').forEach((el, i) => {
      el.dataset.pct = pctOf(MONTH.slots[i][1], MONTH.total).toFixed(2)
    })
    k.lift(tl, PRESS + 0.5)

    // scroll down to the time-of-day slots
    k.scroll(tl, scroll, 610, { pos: PRESS + 1.3, duration: 1.1 })
    k.fill(tl, '[data-k="slot-fill"]', { pos: '-=0.45', duration: 0.8, stagger: 0.12 })
    k.callout(tl, '[data-k="slot-evening"]', 'Hay mua buổi tối?', { pos: '-=0.2' })
    k.callout(tl, '[data-k="m-month"] [data-motive="emotion"]', '8 màu động cơ, khớp web admin', { pos: '+=0.5' })
    k.wait(tl, 1.4)
  },
}

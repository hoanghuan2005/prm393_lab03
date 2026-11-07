// Ngân sách theo nhóm (lib/screens/budget_screen.dart). Pushed route, no bottom nav.
// Numbers follow BudgetViewModel / AvailableBudget.compute on the demo seed
// (07/11/2026, 23 days left, 36-day history). To show the over-limit state the
// limits are re-split inside the same 3.100.000 ₫ total: Ăn uống 2.000.000,
// Thời trang 100.000, Công nghệ 1.000.000 (seed: 1.500.000 / 600.000 / 1.000.000).
// Spent, total and remaining stay identical to the seed and to the Home card.
import { html, icon, money } from './kit.js'

const LIMITED = [
  {
    key: 'food',
    name: 'Ăn uống',
    icon: icon('restaurant_rounded', 18),
    spent: 120000,
    limit: 2000000,
    // remaining 1.880.000 − buffer 12.083 × 23 = 277.909 → 1.602.091 × 90% = 1.441.881
    available: 1441881,
  },
  { key: 'fashion', name: 'Thời trang', icon: icon('checkroom_rounded', 18), spent: 200000, limit: 100000, available: 0 },
  // remaining 512.000 − buffer 29.638 × 23 = 681.674 → 0
  { key: 'tech', name: 'Công nghệ', icon: icon('devices_rounded', 18), spent: 488000, limit: 1000000, available: 0 },
]
const UNLIMITED = [
  { name: 'Làm đẹp', icon: icon('face_retouching_natural_rounded', 18), spent: 265000 },
  { name: 'Học tập', icon: icon('school_rounded', 18), spent: 211000 },
  { name: 'Khác', icon: icon('more_horiz_rounded', 18), spent: 305000 },
]
const TOTAL_LIMIT = LIMITED.reduce((s, g) => s + g.limit, 0) // 3.100.000
const TOTAL_SPENT = LIMITED.reduce((s, g) => s + g.spent, 0) // 808.000

// "Vì sao con số này? · Ăn uống" (_showAvailableExplanation), lines joined by \n
const WHY_FOOD = [
  'Hạn mức nhóm: 2.000.000 ₫',
  '− Đã chi tháng này: 120.000 ₫',
  '= Còn lại: 1.880.000 ₫',
  '',
  '− Dự phòng chi thường ngày: 12.083 ₫/ngày × 23 ngày còn lại = 277.909 ₫',
  '  (trung bình 36 ngày gần nhất của nhóm, không tính khoản mua từ danh sách mong muốn)',
  '× 90% (chừa 10% biên độ an toàn)',
  '',
  '= Khả dụng cho danh sách mong muốn: 1.441.881 ₫',
].join('\n')

const STYLE = `
.scr-budget .bud-card{background:#fff;border:1px solid var(--divider);border-radius:16px}
.scr-budget .bud-track{position:relative;border-radius:4px;background:#E2E8F0;overflow:hidden}
.scr-budget .bud-fill{position:absolute;inset:0 auto 0 0;display:block}
.scr-budget .bud-tile{flex:none;width:34px;height:34px;border-radius:8px;background:var(--surface-variant);color:var(--neutral);display:grid;place-items:center}
.scr-budget .bud-gname{flex:1;min-width:0;margin-left:10px;font-size:14.5px;font-weight:700;line-height:1.3}
.scr-budget .bud-gamt{flex:none;font-size:13px;font-weight:600;color:var(--neutral);line-height:1.3}
.scr-budget .bud-gcap{margin-top:6px;font-size:11.5px;line-height:1.3;color:var(--text-2)}
.scr-budget .bud-why{display:inline-flex;align-items:center;gap:8px;height:48px;font-size:14px;font-weight:600;color:var(--neutral)}
.scr-budget .bud-dialog{position:absolute;left:40px;right:40px;top:50%;z-index:16;padding:24px 24px 18px;border-radius:20px;background:#fff;box-shadow:0 8px 28px rgba(0,0,0,.2);opacity:0;transform:translateY(-50%)}
`

function groupCard(g) {
  const over = g.spent > g.limit
  const pct = Math.min(100, (g.spent / g.limit) * 100)
  return html`<div class="bud-card" data-k="group" data-group="${g.key}" style="margin-bottom:12px;padding:16px">
    <div class="wib-row">
      <span class="bud-tile">${g.icon}</span>
      <span class="bud-gname">Nhóm ${g.name}</span>
      <span class="bud-gamt">${money(g.spent)} / ${money(g.limit)}</span>
    </div>
    <div class="bud-track" ${over ? 'data-k="over-bar"' : ''} style="height:6px;margin-top:10px">
      <span class="bud-fill" data-pct="${pct.toFixed(2)}" style="width:${pct.toFixed(2)}%;background:${over ? '#47667B' : '#94A3B8'}"></span>
    </div>
    <div class="bud-gcap" ${over ? 'data-k="over-cap"' : ''}>${
      over
        ? `Đã vượt ${money(g.spent - g.limit)} so với mốc nhóm. App không chặn mua.`
        : `Còn lại ${money(g.limit - g.spent)} · khả dụng cho danh sách mong muốn ${money(g.available)}.`
    }</div>
    <span class="bud-why" data-k="why-${g.key}">${icon('help_outline_rounded', 16)}Vì sao con số này?</span>
  </div>`
}

function unlimitedCard(g) {
  return html`<div class="bud-card wib-row" data-k="group" style="margin-bottom:12px;padding:16px">
    <span class="bud-tile">${g.icon}</span>
    <span class="wib-col" style="flex:1;min-width:0;margin-left:10px">
      <span style="font-size:14.5px;font-weight:700;line-height:1.3">Nhóm ${g.name}</span>
      <span style="margin-top:2px;font-size:11.5px;line-height:1.3;color:var(--text-2)">Chưa đặt hạn mức tháng này</span>
    </span>
    <span class="bud-gamt">Đã chi ${money(g.spent)}</span>
  </div>`
}

export default {
  id: 'budget',
  render() {
    const pct = ((TOTAL_SPENT / TOTAL_LIMIT) * 100).toFixed(2)
    return html`
      <div class="wib-screen scr-budget">
        <style>${STYLE}</style>
        <div class="wib-appbar">
          <span class="wib-iconbtn" style="width:48px;height:48px">${icon('chevron_left_rounded')}</span>
          <div class="wib-appbar__title" style="padding-left:16px;font-weight:700">Ngân sách theo nhóm</div>
          <span class="wib-iconbtn" style="width:48px;height:48px;color:var(--text-2)">${icon('help_outline_rounded')}</span>
        </div>
        <div class="wib-body">
          <div class="wib-scroll" data-k="scroll" style="padding-bottom:24px">
            <div class="bud-card wib-row" data-k="month" style="justify-content:space-between;padding:8px 12px;border-radius:14px">
              <span class="wib-iconbtn" style="width:48px;height:48px">${icon('chevron_left_rounded')}</span>
              <span class="wib-row" style="padding:4px 12px">
                <span style="color:var(--neutral);display:flex">${icon('calendar_today_rounded', 16)}</span>
                <span style="margin-left:8px;font-size:15px;font-weight:700">Tháng 11/2026</span>
                <span style="margin-left:4px;color:var(--text-2);display:flex">${icon('arrow_drop_down_rounded')}</span>
              </span>
              <span class="wib-iconbtn" style="width:48px;height:48px">${icon('chevron_right_rounded')}</span>
            </div>

            <div class="bud-card" data-k="overall" style="margin-top:16px;padding:18px;box-shadow:0 2px 8px rgba(0,0,0,.02)">
              <div class="wib-row" style="justify-content:space-between">
                <span style="font-size:15px;font-weight:700;line-height:1.3">Tổng ngân sách tháng</span>
                <span data-k="badge" style="padding:2.5px 8px;border-radius:6px;background:var(--success-c);color:var(--on-success-c);font-size:11.5px;font-weight:700;line-height:1.3">Trong hạn mức</span>
              </div>
              <div class="wib-row" style="justify-content:space-between;margin-top:12px">
                <span data-k="spent" style="font-size:24px;font-weight:800;line-height:1.25;color:var(--neutral)">${money(TOTAL_SPENT)}</span>
                <span style="font-size:16px;font-weight:600;color:var(--text-2)">/ ${money(TOTAL_LIMIT)}</span>
              </div>
              <div class="bud-track" data-k="overall-bar" style="height:8px;margin-top:10px">
                <span class="bud-fill" data-pct="${pct}" style="width:${pct}%;background:#FFDE02"></span>
              </div>
              <div style="margin-top:8px;font-size:12px;line-height:1.35;color:var(--text-2)">Còn lại ${money(TOTAL_LIMIT - TOTAL_SPENT)} trong ngân sách dự kiến tháng này.</div>
            </div>
            <div data-k="extra" style="padding-top:8px;font-size:12px;line-height:1.35;color:var(--text-2)">Ngoài ra bạn đã chi ${money(UNLIMITED.reduce((s, g) => s + g.spent, 0))} ở nhóm chưa đặt hạn mức (không tính vào tổng trên).</div>

            <div data-k="label" style="margin-top:24px;font-size:12px;font-weight:700;letter-spacing:.6px;line-height:1.3;color:var(--text-2)">CÁC NHÓM NGÂN SÁCH</div>
            <div style="margin-top:12px">
              ${LIMITED.map(groupCard)}
              ${UNLIMITED.map(unlimitedCard)}
            </div>

            <div data-k="note" style="margin-top:4px;text-align:center;font-size:12px;line-height:1.35;color:var(--hint)">Bỏ qua cũng được: Decision Card vẫn hoạt động, chỉ không tính phần trăm.</div>
            <span class="wib-btn" data-k="setup" style="margin-top:24px;min-height:50px;font-size:15px;font-weight:700">
              <span class="wib-btn__label wib-row" style="gap:8px">${icon('tune_rounded', 20)}<span>Cài đặt mức ngân sách</span></span>
              <span class="wib-btn__spinner"></span>
            </span>
          </div>
        </div>

        <div class="wib-scrim" data-k="scrim"></div>
        <div class="bud-dialog" data-k="dialog">
          <div style="font-size:24px;font-weight:400;line-height:1.33">Vì sao con số này? · Ăn uống</div>
          <div style="margin-top:16px;font-size:13.5px;line-height:1.5;color:var(--text-2);white-space:pre-wrap">${WHY_FOOD}</div>
          <div class="wib-row" style="justify-content:flex-end;margin-top:20px">
            <span class="wib-textbtn" data-k="ok" style="padding:0 12px;font-weight:700">Đã hiểu</span>
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const scroll = k.q('[data-k="scroll"]')
    k.reveal(tl, '[data-k="month"], [data-k="overall"], [data-k="extra"], [data-k="label"], [data-k="group"]', { stagger: 0.06 })
    k.count(tl, '[data-k="spent"]', TOTAL_SPENT, { pos: 0.1, duration: 1.1 })
    k.fill(tl, '[data-k="overall-bar"] .bud-fill', { pos: 0.25, duration: 1 })
    k.fill(tl, '[data-k="group"] .bud-fill', { pos: 0.55, duration: 0.9, stagger: 0.12 })

    // bring the three limited groups (and the first unlimited one) into view
    k.scroll(tl, scroll, 312, { pos: 1.6, duration: 1 })
    k.callout(tl, '[data-k="over-bar"]', 'Vượt mốc: xám, không đỏ', { pos: 2.5 })

    // "Vì sao con số này?" under Ăn uống opens the step-by-step dialog
    k.callout(tl, '[data-k="why-food"]', 'Vì sao con số này?', { pos: 3.3 })
    k.tap(tl, '[data-k="why-food"]', { pos: 3.3 })
    tl.to(k.q('[data-k="scrim"]'), { opacity: 1, duration: 0.25, ease: 'power2.out' }, '-=0.2')
    tl.to(k.q('[data-k="dialog"]'), { opacity: 1, duration: 0.25, ease: 'power2.out' }, '<')
    k.wait(tl, 2.2)
    k.tap(tl, '[data-k="ok"]', { pos: '+=0' })
    tl.to(k.q('[data-k="dialog"]'), { opacity: 0, duration: 0.2, ease: 'power2.in' }, '-=0.2')
    tl.to(k.q('[data-k="scrim"]'), { opacity: 0, duration: 0.2 }, '<')
    k.wait(tl, 0.5)
  },
}

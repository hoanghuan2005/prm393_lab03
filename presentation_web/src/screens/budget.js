// Ngân sách theo nhóm (lib/screens/budget_screen.dart). Pushed route, no bottom nav.
// Numbers: BudgetViewModel / AvailableBudget.compute on the shared demo seed
// (07/11/2026, 23 days left, 36-day history): limits Ăn uống 1.500.000, Thời trang
// 600.000, Công nghệ 1.000.000 (= 3.100.000 ₫, 808.000 ₫ spent, same as Home).
// The seed has no group over its limit, so the demo makes one with the real flow:
// "Cài đặt mức ngân sách" -> BudgetSettingSheet (lib/widgets/budget_setting_sheet.dart),
// the user lowers Thời trang from 600.000 to 150.000 ₫ (already spent 200.000 ₫) and
// saves; the card then turns #47667B with the exceeded caption. Everything shown
// before that edit is the shared snapshot.
import { html, icon, money, grouped, field, button, snackbar } from './kit.js'

const GROUPS = [
  { key: 'food', name: 'Ăn uống', icon: icon('restaurant_rounded', 18), spent: 120000, limit: 1500000, daily: 12083 },
  { key: 'fashion', name: 'Thời trang', icon: icon('checkroom_rounded', 18), spent: 200000, limit: 600000, daily: 10527 },
  { key: 'tech', name: 'Công nghệ', icon: icon('devices_rounded', 18), spent: 488000, limit: 1000000, daily: 29638 },
  { key: 'beauty', name: 'Làm đẹp', icon: icon('face_retouching_natural_rounded', 18), spent: 265000, limit: null },
  { key: 'study', name: 'Học tập', icon: icon('school_rounded', 18), spent: 211000, limit: null },
  { key: 'other', name: 'Khác', icon: icon('more_horiz_rounded', 18), spent: 305000, limit: null },
]
const DAYS_LEFT = 23
const WINDOW_DAYS = 36

// AvailableBudget: max(0, remaining − daily × daysLeft) × 90 % (floored)
function breakdown(g) {
  const remaining = g.limit - g.spent
  const buffer = g.daily * DAYS_LEFT
  const left = remaining - buffer
  return { remaining, buffer, available: left <= 0 ? 0 : Math.floor((left * 90) / 100) }
}
// food 991.881 ₫, fashion 142.091 ₫, tech 0 ₫
GROUPS.forEach((g) => g.limit && Object.assign(g, breakdown(g)))

const LIMITED = GROUPS.filter((g) => g.limit)
const UNLIMITED = GROUPS.filter((g) => !g.limit)
const TOTAL_LIMIT = LIMITED.reduce((s, g) => s + g.limit, 0) // 3.100.000
const TOTAL_SPENT = LIMITED.reduce((s, g) => s + g.spent, 0) // 808.000
const UNLIMITED_SPENT = UNLIMITED.reduce((s, g) => s + g.spent, 0) // 781.000
const FASHION = GROUPS[1]

// The edit made in the sheet during the demo
const NEW_FASHION_LIMIT = 150000
const NEW_TOTAL_LIMIT = TOTAL_LIMIT - FASHION.limit + NEW_FASHION_LIMIT // 2.650.000
// AmountField while the user deletes 600.000 and types 150000 (dots regrouped per key)
const KEYS = ['60.000', '6.000', '600', '60', '6', '', '1', '15', '150', '1.500', '15.000', '150.000']

// "Vì sao con số này? · Thời trang" (_showAvailableExplanation), lines joined by \n
const WHY_FASHION = [
  `Hạn mức nhóm: ${money(FASHION.limit)}`,
  `− Đã chi tháng này: ${money(FASHION.spent)}`,
  `= Còn lại: ${money(FASHION.remaining)}`,
  '',
  `− Dự phòng chi thường ngày: ${money(FASHION.daily)}/ngày × ${DAYS_LEFT} ngày còn lại = ${money(FASHION.buffer)}`,
  `  (trung bình ${WINDOW_DAYS} ngày gần nhất của nhóm, không tính khoản mua từ danh sách mong muốn)`,
  '× 90% (chừa 10% biên độ an toàn)',
  '',
  `= Khả dụng cho danh sách mong muốn: ${money(FASHION.available)}`,
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
.scr-budget .bud-sheet{top:28px;display:flex;flex-direction:column;padding-bottom:0}
.scr-budget .bud-sheet-body{position:relative;flex:1;min-height:0;overflow:hidden}
.scr-budget .bud-sheet-scroll{padding:8px 16px 24px;will-change:transform}
.scr-budget .bud-x{display:grid;place-items:center;margin-right:-2px}
.scr-budget .bud-spent{padding:4px 0 12px;font-size:12px;font-weight:500;line-height:1.35;color:var(--text-2)}
.scr-budget .bud-sum{padding:16px;border-radius:12px;background:var(--surface-variant)}
`

function groupCard(g) {
  const pct = Math.min(100, (g.spent / g.limit) * 100)
  return html`<div class="bud-card" data-k="group" style="margin-bottom:12px;padding:16px">
    <div class="wib-row">
      <span class="bud-tile">${g.icon}</span>
      <span class="bud-gname">Nhóm ${g.name}</span>
      <span class="bud-gamt" data-k="amt-${g.key}">${money(g.spent)} / ${money(g.limit)}</span>
    </div>
    <div class="bud-track" data-k="bar-${g.key}" style="height:6px;margin-top:10px">
      <span class="bud-fill" data-pct="${pct.toFixed(2)}" style="width:${pct.toFixed(2)}%;background:#94A3B8"></span>
    </div>
    <div class="bud-gcap" data-k="cap-${g.key}">Còn lại ${money(g.remaining)} · khả dụng cho danh sách mong muốn ${money(g.available)}.</div>
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

// AmountField per group in BudgetSettingSheet ('₫' suffix only once the field has text)
function limitField(g) {
  const x = `<span class="bud-x" data-k="x-${g.key}">${icon('close_rounded', 20)}</span>`
  return html`${field({
    label: g.name,
    value: g.limit ? grouped(g.limit) : '',
    hint: 'Không đặt hạn mức',
    suffix: g.limit ? '₫' : '',
    trailing: g.limit ? x : '',
    valueAttrs: `data-k="lim-${g.key}"`,
  })}
    <div class="bud-spent">Đã chi tháng này: ${money(g.spent)}</div>`
}

const overallCaption = (limit) => `Còn lại ${money(limit - TOTAL_SPENT)} trong ngân sách dự kiến tháng này.`
const sheetSummary = (limit) => `Bằng tổng hạn mức các nhóm. Các nhóm này đã chi ${money(TOTAL_SPENT)}; còn ${money(limit - TOTAL_SPENT)}.`

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
          <div class="wib-scroll" data-k="scroll" style="padding-bottom:34px">
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
                <span style="padding:2.5px 8px;border-radius:6px;background:var(--success-c);color:var(--on-success-c);font-size:11.5px;font-weight:700;line-height:1.3">Trong hạn mức</span>
              </div>
              <div class="wib-row" style="justify-content:space-between;margin-top:12px">
                <span data-k="spent" style="font-size:24px;font-weight:800;line-height:1.25;color:var(--neutral)">${money(TOTAL_SPENT)}</span>
                <span data-k="total" style="font-size:16px;font-weight:600;color:var(--text-2)">/ ${money(TOTAL_LIMIT)}</span>
              </div>
              <div class="bud-track" data-k="overall-bar" style="height:8px;margin-top:10px">
                <span class="bud-fill" data-pct="${pct}" style="width:${pct}%;background:#FFDE02"></span>
              </div>
              <div data-k="overall-cap" style="margin-top:8px;font-size:12px;line-height:1.35;color:var(--text-2)">${overallCaption(TOTAL_LIMIT)}</div>
            </div>
            <div data-k="extra" style="padding-top:8px;font-size:12px;line-height:1.35;color:var(--text-2)">Ngoài ra bạn đã chi ${money(UNLIMITED_SPENT)} ở nhóm chưa đặt hạn mức (không tính vào tổng trên).</div>

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
          <div style="font-size:24px;font-weight:400;line-height:1.33">Vì sao con số này? · ${FASHION.name}</div>
          <div style="margin-top:16px;font-size:13.5px;line-height:1.5;color:var(--text-2);white-space:pre-wrap">${WHY_FASHION}</div>
          <div class="wib-row" style="justify-content:flex-end;margin-top:20px">
            <span class="wib-textbtn" data-k="ok" style="padding:0 12px;font-weight:700">Đã hiểu</span>
          </div>
        </div>

        <div data-k="sheet-scope">
          <div class="wib-scrim"></div>
          <div class="wib-sheet bud-sheet">
            <div class="wib-sheet__handle"></div>
            <div class="wib-sheet__title">Hạn mức tháng 11/2026</div>
            <div class="bud-sheet-body">
              <div class="bud-sheet-scroll" data-k="sheet-scroll">
                <div class="t-body-m">Đặt mốc tham chiếu cho từng nhóm hàng. Để trống nếu không muốn đặt hạn mức. App không chặn mua sắm.</div>
                <div style="height:16px"></div>
                ${GROUPS.map(limitField)}
                <div class="bud-sum">
                  <div class="t-title-m" data-k="sum-total">Tổng ngân sách tháng: ${money(TOTAL_LIMIT)}</div>
                  <div class="t-body-m" data-k="sum-text" style="margin-top:4px">${sheetSummary(TOTAL_LIMIT)}</div>
                </div>
                <div style="height:16px"></div>
                ${button('Lưu hạn mức', { icon: icon('check_rounded', 20), attrs: 'data-k="save"' })}
              </div>
            </div>
          </div>
        </div>
        ${snackbar('Đã lưu hạn mức tháng 11/2026.').replace('class="wib-snackbar"', 'class="wib-snackbar" style="left:15px;right:15px;bottom:28px"')}
      </div>`
  },

  demo(tl, root, k) {
    const scroll = k.q('[data-k="scroll"]')
    const body = scroll.parentElement
    const sheetScope = k.q('[data-k="sheet-scope"]')
    const sheetScroll = k.q('[data-k="sheet-scroll"]')
    const limV = k.q('[data-k="lim-fashion"]')
    const limInput = limV.closest('.wib-input')
    const limX = k.q('[data-k="x-fashion"]')
    const save = k.q('[data-k="save"]')
    // scroll ends, measured when the tween starts (no overscroll past the content)
    const endOf = (el) => () => -Math.max(0, el.offsetHeight - el.parentElement.offsetHeight)

    // 1. seed snapshot: 808.000 ₫ / 3.100.000 ₫, every group under its limit
    k.reveal(tl, '[data-k="month"], [data-k="overall"], [data-k="extra"], [data-k="label"], [data-k="group"], [data-k="note"], [data-k="setup"]', { stagger: 0.05 })
    k.count(tl, '[data-k="spent"]', TOTAL_SPENT, { pos: 0.1, duration: 0.9 })
    k.fill(tl, '[data-k="overall-bar"] .bud-fill', { pos: 0.25, duration: 0.9 })
    k.fill(tl, '[data-k="group"] .bud-fill', { pos: 0.45, duration: 0.8, stagger: 0.1 })

    // 2. to the bottom: Thời trang card on top, "Cài đặt mức ngân sách" below
    tl.to(scroll, { y: endOf(scroll), duration: 0.8, ease: 'power3.inOut' }, 1.0)

    // 3. "Vì sao con số này?" of Thời trang: the calculation with the user's numbers
    const tWhy = 1.85
    k.callout(tl, '[data-k="why-fashion"]', 'Vì sao con số này?', { pos: tWhy })
    k.tap(tl, '[data-k="why-fashion"]', { pos: tWhy })
    tl.to(k.qa('[data-k="scrim"], [data-k="dialog"]'), { opacity: 1, duration: 0.25, ease: 'power2.out' }, tWhy + 0.55)
    const tOk = tWhy + 2.05
    k.tap(tl, '[data-k="ok"]', { pos: tOk })
    tl.to(k.qa('[data-k="dialog"], [data-k="scrim"]'), { opacity: 0, duration: 0.2, ease: 'power2.in' }, tOk + 0.55)

    // 4. BudgetSettingSheet: lower Thời trang 600.000 -> 150.000 ₫ (already spent 200.000 ₫)
    const tSetup = tOk + 0.8
    k.tap(tl, '[data-k="setup"]', { pos: tSetup })
    k.sheet(tl, sheetScope, { pos: tSetup + 0.55 })
    const tField = tSetup + 1.05
    k.tap(tl, limInput, {
      pos: tField,
      anchor: [0.35, 0.5],
      then: () => {
        limInput.classList.add('is-focused')
        limV.classList.add('is-typing')
      },
    })
    const tKeys = tField + 0.62
    KEYS.forEach((v, i) => {
      k.text(tl, limV, v, tKeys + i * 0.04)
      // the clear button exists only while the field has text
      if (v === '' || i === 6) tl.set(limX, { display: v === '' ? 'none' : '' }, tKeys + i * 0.04)
    })
    const tTyped = tKeys + KEYS.length * 0.04
    // the summary below the fields follows the edit
    k.text(tl, '[data-k="sum-total"]', `Tổng ngân sách tháng: ${money(NEW_TOTAL_LIMIT)}`, tTyped)
    k.text(tl, '[data-k="sum-text"]', sheetSummary(NEW_TOTAL_LIMIT), tTyped)
    tl.to(sheetScroll, { y: endOf(sheetScroll), duration: 0.45, ease: 'power3.inOut' }, tTyped + 0.05)

    // 5. "Lưu hạn mức": one Firestore write, sheet closes, SnackBar; the card turns neutral grey
    const tSave = tTyped + 0.5
    k.tap(tl, save, {
      pos: tSave,
      then: () => {
        limV.classList.remove('is-typing')
        save.classList.add('is-loading')
      },
    })
    k.lift(tl, tSave + 0.75)
    const tSaved = tSave + 0.85
    k.sheet(tl, sheetScope, { open: false, pos: tSaved })
    k.text(tl, '[data-k="amt-fashion"]', `${money(FASHION.spent)} / ${money(NEW_FASHION_LIMIT)}`, tSaved)
    tl.set(k.q('[data-k="bar-fashion"] .bud-fill'), { width: '100%', background: '#47667B' }, tSaved)
    k.text(tl, '[data-k="cap-fashion"]', `Đã vượt ${money(FASHION.spent - NEW_FASHION_LIMIT)} so với mốc nhóm. App không chặn mua.`, tSaved)
    // overall card (off screen) stays consistent: 808.000 ₫ / 2.650.000 ₫
    k.text(tl, '[data-k="total"]', `/ ${money(NEW_TOTAL_LIMIT)}`, tSaved)
    tl.set(k.q('[data-k="overall-bar"] .bud-fill'), { width: `${((TOTAL_SPENT / NEW_TOTAL_LIMIT) * 100).toFixed(2)}%` }, tSaved)
    k.text(tl, '[data-k="overall-cap"]', overallCaption(NEW_TOTAL_LIMIT), tSaved)
    k.snack(tl, '.wib-snackbar', { pos: tSaved + 0.3 })
    k.callout(tl, '[data-k="cap-fashion"]', 'Vượt mốc: xám, không đỏ', { pos: tSaved + 0.35 })
  },
}

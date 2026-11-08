// Lịch sử tab (lib/screens/history_screen.dart), calm backdrop for chapter 'bang-chung'.
// Data: DemoDataService seeded on Sat 07/11/2026 ~15:20. The 10 this-month templates
// are spread by _spreadInMonth (day = 1 + i*6 ~/ 9), plus the purchase bought from
// Wishlist ('Bình giữ nhiệt 500ml', seed time − 3 days → 04/11 15:20, group 'other').
// 11 purchases = 1.589.000 ₫. Budget meter = limitedSpent / totalLimit (tech 488.000 +
// fashion 200.000 + food 120.000 = 808.000 ₫ of 3.100.000 ₫). Newest first, as
// PurchaseService orders by occurredAt descending.
import { html, icon, appBar, headerActions, bottomNav, money } from './kit.js'

// 'Tất cả' | 'Mua từ Wishlist' | BuyingMotive.values (label + icon)
const CHIPS = [
  { label: 'Tất cả', selected: true },
  { label: 'Mua từ Wishlist', icon: 'bookmark_border_rounded' },
  { label: 'Nhu cầu', icon: 'inventory_2_outlined' },
  { label: 'Mong muốn', icon: 'favorite_outline' },
  { label: 'Khuyến mãi', icon: 'local_offer_outlined' },
  { label: 'Cảm xúc', icon: 'sentiment_very_satisfied_outlined' },
  { label: 'Ảnh hưởng MXH', icon: 'trending_up' },
  { label: 'Tiện lợi', icon: 'bolt_outlined' },
  { label: 'Quảng cáo', icon: 'campaign_outlined' },
  { label: 'Khác', icon: 'more_horiz' },
]

// BuyingMotive.label + icon (buying_motive.dart), colours via [data-motive] in app.css
const MOTIVE = {
  need: { label: 'Nhu cầu', ic: icon('inventory_2_outlined', 20) },
  want: { label: 'Mong muốn', ic: icon('favorite_outline', 20) },
  sale: { label: 'Khuyến mãi', ic: icon('local_offer_outlined', 20) },
  emotion: { label: 'Cảm xúc', ic: icon('sentiment_very_satisfied_outlined', 20) },
  social: { label: 'Ảnh hưởng MXH', ic: icon('trending_up', 20) },
  convenience: { label: 'Tiện lợi', ic: icon('bolt_outlined', 20) },
  ads: { label: 'Quảng cáo', ic: icon('campaign_outlined', 20) },
  other: { label: 'Khác', ic: icon('more_horiz', 20) },
}

const DAYS = [
  { key: '07', header: 'Hôm nay · 07/11/2026', items: [['Bút và sổ tay', 'need', '10:40', 68000]] },
  { key: '06', header: 'Hôm qua · 06/11/2026', items: [['Ốp lưng điện thoại', 'other', '14:25', 99000]] },
  {
    key: '05',
    header: '05/11/2026',
    items: [
      ['Vé xem phim cùng bạn', 'social', '18:05', 120000],
      ['Cà phê sáng', 'need', '07:50', 35000],
    ],
  },
  {
    key: '04',
    header: '04/11/2026',
    items: [
      ['Kem chống nắng', 'ads', '21:10', 265000],
      ['Bình giữ nhiệt 500ml', 'need', '15:20', 185000],
    ],
  },
  {
    key: '03',
    header: '03/11/2026',
    items: [
      ['Áo khoác gió', 'sale', '19:45', 200000],
      ['Sách Tâm lý học về tiền', 'want', '09:20', 143000],
    ],
  },
  { key: '02', header: '02/11/2026', items: [['Trà sữa nướng', 'emotion', '22:30', 45000]] },
  {
    key: '01',
    header: '01/11/2026',
    items: [
      ['Tai nghe Bluetooth', 'sale', '23:40', 389000],
      ['Cơm tấm', 'convenience', '12:15', 40000],
    ],
  },
]

const SPENT = 808000
const LIMIT = 3100000
const PCT = ((SPENT / LIMIT) * 100).toFixed(2) // 26.06

const STYLE = `
.scr-history,.scr-history *{box-sizing:border-box}
.scr-history .wib-appbar__title{gap:4px}
.scr-history .his-month{flex:none;display:flex;align-items:center;justify-content:space-between;padding:5px 16px 0;background:var(--bg)}
.scr-history .his-month .wib-iconbtn{width:48px;height:48px;color:var(--text-2)}
.scr-history .his-month__pick{display:flex;align-items:center;padding:3px 12px;border-radius:10px}
.scr-history .his-chips{flex:none;height:42px;display:flex;align-items:stretch;gap:8px;padding:3px 16px;overflow:hidden;background:var(--bg)}
.scr-history .his-chip{flex:none;display:flex;align-items:center;gap:4px;padding:0 12px;border-radius:20px;background:var(--surface-variant);color:var(--neutral);font-size:12px;font-weight:500;line-height:1.3;white-space:nowrap}
.scr-history .his-chip .mi{font-size:14px;color:var(--text-2)}
.scr-history .his-chip.is-on{background:var(--text);color:#fff;font-weight:700}
.scr-history .his-meter{padding:16px;border-radius:16px;background:var(--surface);border:1px solid var(--divider);box-shadow:0 2px 8px rgba(0,0,0,.03)}
.scr-history .his-track{position:relative;height:7px;border-radius:4px;background:var(--surface-variant);overflow:hidden}
.scr-history .his-fill{position:absolute;inset:0 auto 0 0;display:block;background:var(--primary)}
.scr-history .his-dayhead{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:8px 4px;font-size:13px;font-weight:700;line-height:1.3}
.scr-history .his-daycard{border-radius:16px;background:var(--surface);border:1px solid var(--divider);overflow:hidden}
.scr-history .his-row{display:flex;align-items:center;min-height:72px;padding:4px 16px}
.scr-history .his-row + .his-row{box-shadow:inset 0 1px 0 var(--divider)}
.scr-history .his-lead{flex:none;width:38px;height:38px;margin-right:18px;display:grid;place-items:center;border-radius:10px;background:var(--mb);color:var(--m)}
.scr-history .his-title{font-size:15px;font-weight:700;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.scr-history .his-sub{margin-top:2px;font-size:12px;line-height:1.35;color:var(--text-2)}
.scr-history .his-amt{flex:none;margin-left:16px;font-size:15px;font-weight:700;color:var(--neutral)}
.scr-history .his-fab{position:absolute;right:16px;bottom:16px;z-index:3;width:56px;height:56px;display:grid;place-items:center;border-radius:16px;background:var(--primary);color:var(--on-primary);box-shadow:0 1px 3px rgba(0,0,0,.3),0 4px 8px 3px rgba(0,0,0,.15)}
`

function chip(c) {
  return `<span class="his-chip ${c.selected ? 'is-on' : ''}" data-k="chip">${c.icon ? icon(c.icon, 14) : ''}<span>${c.label}</span></span>`
}

function row([title, motive, time, amount]) {
  const m = MOTIVE[motive]
  return html`<div class="his-row" data-k="row">
    <span class="his-lead" data-motive="${motive}">${m.ic}</span>
    <div style="flex:1;min-width:0">
      <div class="his-title">${title}</div>
      <div class="his-sub">${m.label} • ${time}</div>
    </div>
    <span class="his-amt">${money(amount)}</span>
  </div>`
}

function day(d) {
  const total = d.items.reduce((s, it) => s + it[3], 0)
  return html`<div data-k="day" data-day="${d.key}" style="margin-top:16px">
    <div class="his-dayhead">
      <span style="flex:1;min-width:0;color:var(--text-2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${d.header}</span>
      <span data-k="total-${d.key}" style="color:var(--neutral)">${money(total)}</span>
    </div>
    <div class="his-daycard">${d.items.map(row)}</div>
  </div>`
}

export default {
  id: 'history',
  render() {
    return html`
      <div class="wib-screen scr-history">
        <style>${STYLE}</style>
        ${appBar({ back: 'chevron', title: 'Lịch sử', logoSize: 26, strong: true, actions: headerActions({ bell: 0, bookmark: 4 }) })}
        <div class="his-month" data-k="month">
          <span class="wib-iconbtn">${icon('chevron_left_rounded')}</span>
          <span class="his-month__pick">
            ${icon('calendar_month_outlined', 18)}
            <span style="margin-left:8px;font-size:15px;font-weight:800;line-height:1.3">Tháng 11/2026</span>
            <span style="margin-left:4px;display:flex;color:var(--text-2)">${icon('arrow_drop_down_rounded', 22)}</span>
          </span>
          <span class="wib-iconbtn">${icon('chevron_right_rounded')}</span>
        </div>
        <div class="his-chips" data-k="chips">${CHIPS.map(chip)}</div>
        <div class="wib-body" style="margin-top:8px">
          <div class="wib-scroll" data-k="scroll" style="padding:8px 16px 16px">
            <div class="his-meter" data-k="meter">
              <div class="wib-row">
                <span class="wib-row" style="flex:1;min-width:0">
                  <span style="display:flex;color:var(--neutral)">${icon('account_balance_wallet_outlined', 18)}</span>
                  <span style="min-width:0;margin-left:8px;font-size:14px;font-weight:700;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">Ngân sách tháng</span>
                  <span data-k="tag" style="flex:none;margin-left:6px;padding:2px 6px;border-radius:6px;background:var(--success-c);color:var(--on-success-c);font-size:11px;font-weight:700;line-height:1.3;white-space:nowrap">Trong hạn mức</span>
                </span>
                <span class="wib-row" style="flex:none;gap:4px;margin-left:8px;padding:4px 6px;color:var(--neutral);font-size:12px;font-weight:700;line-height:1.3">${icon('tune_rounded', 14)}<span>Chi tiết</span></span>
              </div>
              <div class="wib-row" style="justify-content:space-between;gap:8px;margin-top:12px">
                <span data-k="spent" style="font-size:18px;font-weight:800;line-height:1.3;color:var(--neutral)">${money(SPENT)}</span>
                <span style="font-size:13px;font-weight:600;line-height:1.3;color:var(--text-2);text-align:right">Mục tiêu: ${money(LIMIT)}</span>
              </div>
              <div class="his-track" style="margin-top:8px"><span class="his-fill" data-k="fill" data-pct="${PCT}" style="width:${PCT}%"></span></div>
              <div style="margin-top:6px;font-size:12px;line-height:1.35;color:var(--text-2)">Còn lại ${money(LIMIT - SPENT)} trong ngân sách dự kiến tháng này.</div>
            </div>
            ${DAYS.map(day)}
          </div>
          <span class="his-fab" data-k="fab">${icon('add', 24)}</span>
        </div>
        ${bottomNav('history')}
      </div>`
  },

  demo(tl, root, k) {
    const scroll = k.q('[data-k="scroll"]')
    const view = scroll.parentElement
    const dayEl = (d) => k.q(`[data-day="${d}"]`)
    // offset that puts a day group's header at the top of the list viewport
    const to = (d) => () => -Math.min(dayEl(d).offsetTop - 4, scroll.offsetHeight - view.clientHeight)

    // month selector, filter chips (Tất cả selected), budget meter, first day groups
    k.reveal(tl, '[data-k="month"]', { pos: 0, y: 10 })
    tl.fromTo(k.qa('[data-k="chip"]'), { opacity: 0, x: 18 }, { opacity: 1, x: 0, duration: 0.45, stagger: 0.05, ease: 'power3.out' }, 0.1)
    k.reveal(tl, '[data-k="meter"]', { pos: 0.25 })
    k.reveal(tl, '[data-k="day"][data-day="07"], [data-k="day"][data-day="06"], [data-k="day"][data-day="05"], [data-k="fab"]', { pos: 0.45, stagger: 0.09 })
    k.count(tl, '[data-k="spent"]', SPENT, { pos: 0.3, duration: 1.2 })
    k.fill(tl, '[data-k="fill"]', { pos: 0.45, duration: 1.1 })

    // slow scroll through the day groups, each with its daily total
    tl.to(scroll, { y: to('06'), duration: 1.6, ease: 'sine.inOut' }, 2.2)
    tl.to(scroll, { y: to('04'), duration: 1.8, ease: 'sine.inOut' }, 4.4)
    // 04/11: Kem chống nắng 265.000 + Bình giữ nhiệt 500ml 185.000, the biggest day
    k.callout(tl, '[data-k="total-04"]', 'Ngày chi nhiều nhất: 450.000 ₫', { pos: 6.3 })
    tl.to({}, { duration: 1.7 }, 6.3)
  },
}

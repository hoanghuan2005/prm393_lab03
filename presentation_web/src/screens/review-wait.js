// Chi tiết & Quyết định (lib/screens/item_detail_screen.dart) -> "Chờ" -> ReviewDateSheet
// (lib/widgets/review_date_sheet.dart in AppBottomSheet) -> "Đến đợt sale 11.11" -> the
// _ReviewInfo box and the SnackBar of _wait(), then back to Smart Wishlist where the card
// badge reads "Xem lại 11/11".
// Sample data: DemoDataService seeded on 07/11/2026 (Thứ Bảy). "Bộ son dưỡng 3 màu" is the
// demo item already waiting (reviewAt now + 3 days = 10/11). coolingOffDays = 3 (Remote
// Config default) and sale_calendar's default confirmed sale "11.11" on 11/11/2026.
// Every option resolves to 09:00 of the chosen day (ReviewDateSheet.reviewHour); that is a
// fixed reminder time, not a quiet-hours feature.
// The permission prompt is not shown: requestReminderPermission() only opens the system
// dialog the first time; the "granted" SnackBar is used.
// The item-detail markup is copied from wishlist.js (not imported) so both steps match.
import { html, icon, appBar, field, button, motiveChip, statusBadge, wishlistCard, money, MOTIVES } from './kit.js'

/* ------------------------------------------------------------------ */
/* Chi tiết & Quyết định (same markup as wishlist.js)                  */
/* ------------------------------------------------------------------ */
const DETAIL_CSS = `
.scr-item-detail{position:absolute;inset:0;display:flex;flex-direction:column;background:var(--bg)}
.scr-item-detail .d-view{position:relative;flex:1;min-height:0;overflow:hidden}
.scr-item-detail .d-scroll{position:relative;padding:16px 16px 34px;will-change:transform}
.scr-item-detail .d-card{background:var(--surface);border:1px solid var(--divider);border-radius:16px}
.scr-item-detail .d-t20{font-size:20px;font-weight:600;line-height:1.35}
.scr-item-detail .d-t18{font-size:18px;font-weight:600;line-height:1.35}
.scr-item-detail .d-t16{font-size:16px;font-weight:600;line-height:1.4}
.scr-item-detail .d-l14{font-size:14px;font-weight:600;line-height:1.4}
.scr-item-detail .d-b16{font-size:16px;font-weight:400;line-height:1.45}
.scr-item-detail .d-b14{font-size:14px;font-weight:400;line-height:1.45;color:var(--text-2)}
.scr-item-detail .d-l12{font-size:12px;font-weight:500;line-height:1.35;color:var(--text-2)}
.scr-item-detail .d-price{margin-top:12px;font-size:28px;font-weight:700;line-height:1.3}
.scr-item-detail .d-tbtn{display:inline-flex;align-items:center;gap:8px;min-height:48px;font-size:14px;font-weight:600;color:var(--text)}
.scr-item-detail .d-tbtn .mi{font-size:18px}
.scr-item-detail .d-wrap{display:flex;flex-wrap:wrap;align-items:flex-start;gap:8px 12px;margin-top:8px}
.scr-item-detail .d-seg{display:inline-flex;height:32px;border-radius:999px;box-shadow:inset 0 0 0 1px var(--outline);overflow:hidden}
.scr-item-detail .d-seg>span{display:grid;place-items:center;width:58px;font-size:14px;font-weight:600}
.scr-item-detail .d-seg>span+span{box-shadow:inset 1px 0 0 var(--outline)}
.scr-item-detail .d-seg>span.is-on{background:var(--primary-container)}
.scr-item-detail .d-ms{display:flex;align-items:center;gap:12px;padding:8px 4px}
.scr-item-detail .d-ms>.mi{font-size:20px;color:var(--text-2)}
.scr-item-detail .d-rule{height:24px;display:flex;align-items:center}
.scr-item-detail .d-rule::before{content:'';flex:1;height:1px;background:var(--divider)}
.scr-item-detail .d-exp{display:flex;align-items:center;min-height:56px;font-size:14px;font-weight:600}
.scr-item-detail .d-exp>span{flex:1}
.scr-item-detail .d-exp>.mi{color:var(--text-2)}
.scr-item-detail .d-cool{display:flex;align-items:center;gap:12px;margin-bottom:20px;padding:16px;border-radius:12px;background:#f3e8ff;border:1px solid rgba(168,85,247,.3)}
.scr-item-detail .d-cool>.mi{font-size:28px;color:#a855f7}
.scr-item-detail .d-box{position:relative;margin-bottom:16px;padding:16px;border-radius:12px;background:var(--surface-variant)}
.scr-item-detail .d-pill{flex:none;padding:3px 12px;border-radius:999px;background:var(--surface-variant);box-shadow:inset 0 0 0 1px var(--outline);font-size:14px;font-weight:600;line-height:1.4}
.scr-item-detail .d-src{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:999px;background:var(--surface-variant);color:var(--text-body);font-size:11px;font-weight:700}
.scr-item-detail .d-src .mi{font-size:12px}
.scr-item-detail .d-acts{display:flex;flex-wrap:wrap;column-gap:8px}
.scr-item-detail .d-btns{display:flex;flex-direction:column;gap:12px}
`

const MILESTONES = [
  { icon: 'south_rounded', label: 'Thấp nhất' },
  { icon: 'north_rounded', label: 'Cao nhất' },
  { icon: 'bookmark_border_rounded', label: 'Lúc bạn lưu' },
  { icon: 'schedule_rounded', label: 'Hiện tại thấp nhất' },
]

/** PriceHistoryPanel with fewer than 5 days of prices and no Shopee link */
function pricePanel(p) {
  return html`<div class="d-card" data-k="price-panel" style="margin-bottom:16px;padding:16px">
    <div class="wib-row" style="gap:8px">${icon('timeline_outlined', 24)}<span class="d-t16">Lịch sử giá</span></div>
    <div class="wib-row" style="justify-content:flex-end;margin-top:12px">
      <span class="d-seg"><span>7N</span><span class="is-on">30N</span><span>90N</span></span>
    </div>
    <div class="d-b14" style="margin-top:12px">Chưa đủ dữ liệu để vẽ biểu đồ (${p.days} ngày có giá)</div>
    <div style="margin-top:12px">
      ${MILESTONES.map(
        (m, i) => html`<div class="d-ms">${icon(m.icon, 20)}
          <div style="flex:1"><div class="d-l14">${m.label}</div><div class="d-l12">${p.milestones[i][0]}</div></div>
          <span class="d-t16">${money(p.milestones[i][1])}</span></div>`,
      )}
    </div>
    ${p.recordMore ? '<div class="d-b14" style="margin-top:8px">Ghi thêm giá để xem biến động</div>' : ''}
    <div style="margin-top:8px">
      <span class="d-tbtn">${icon('add_link_rounded', 18)}<span>Thêm link Shopee</span></span>
      <div class="d-l12">Có link thì xem được giá người khác ghi và cùng món ở shop khác.</div>
    </div>
    ${p.notes.length ? html`<div class="d-rule"></div>${p.notes.map((n) => `<div class="d-b14" style="margin-bottom:4px">• ${n}</div>`)}` : ''}
    <div class="d-exp"><span>Các lần ghi (${p.records})</span>${icon('expand_more', 24)}</div>
  </div>`
}

/** _ReviewInfo box above Mua · Chờ · Bỏ qua (before the review date) */
function reviewInfo(text) {
  return html`<div class="d-box wib-row" data-k="review" style="gap:12px">
    <span style="color:var(--neutral)">${icon('event', 24)}</span>
    <span class="d-b14" data-k="review-text" style="flex:1">${text}</span>
  </div>`
}

/** Body of Chi tiết & Quyết định for a considering item */
function itemDetail(it) {
  return html`
    ${appBar({
      title: 'Chi tiết & Quyết định',
      actions: html`<span class="wib-iconbtn">${icon('edit_outlined')}</span><span class="wib-iconbtn" style="margin-right:4px">${icon('delete_outline_rounded')}</span>`,
    })}
    <div class="d-view">
      <div class="d-scroll" data-k="dscroll">
        <div class="d-card" data-k="hcard" style="padding:20px">
          <div class="d-t20">${it.title}</div>
          <div class="d-price" data-k="price">${money(it.price)}</div>
          <div class="d-l12" style="margin-top:4px">${it.priceNote}</div>
          <span class="d-tbtn" style="color:var(--neutral)">${icon('price_change_outlined', 18)}<span>Cập nhật giá</span></span>
          <div class="d-wrap">${motiveChip(it.motive)}<span class="d-l12">Lưu ngày: ${it.savedOn}</span></div>
        </div>
        <div style="height:20px"></div>
        ${pricePanel(it.history)}
        ${it.duplicate
          ? html`<div class="d-box" data-k="dup" style="padding-bottom:4px;box-shadow:inset 0 0 0 1px var(--divider)">
              <div class="wib-row" style="gap:8px"><span class="t-2">${icon('layers_outlined', 20)}</span><span class="d-l14">Bạn đã có món tương tự</span></div>
              <div class="d-b14" style="margin-top:8px;margin-bottom:4px">• ${it.duplicate}</div>
              <div class="d-l12" style="margin-top:4px">Thông tin để bạn đối chiếu, không ảnh hưởng tới lựa chọn.</div>
              <span class="d-tbtn">${icon('done_all_rounded', 18)}<span>Món này trùng với đồ tôi đã có</span></span>
            </div>`
          : ''}
        <div class="d-t18" data-k="dtitle">Thẻ Quyết Định (Decision Card)</div>
        <div class="d-b14" style="margin-top:8px">Sau khi suy ngẫm, bạn lựa chọn hành động nào cho món đồ này?</div>
        <div class="d-card" data-k="dcard" style="margin:16px 0;padding:16px;border-radius:12px">
          <div class="wib-row"><span class="d-l14" style="flex:1">Nhận định</span><span class="d-pill">${it.label}</span></div>
          <div class="d-b16" style="margin-top:12px">${it.reason}</div>
          <div style="margin-top:4px"><span class="d-src">${icon('notes_rounded', 12)}Câu mẫu</span></div>
          <div class="d-rule"></div>
          ${it.signals.map((s) => `<div class="d-b14" style="margin-bottom:4px">• ${s}</div>`)}
          <div class="d-acts">${it.actions}</div>
          <div class="d-l12">Nhãn chỉ là quan sát từ số liệu; quyết định vẫn là của bạn.</div>
        </div>
        ${it.review ? reviewInfo(it.review) : ''}
        <div class="d-btns" data-k="decide">
          ${button('Mua', { icon: icon('shopping_bag_outlined', 20), variant: 'secondary', attrs: 'data-k="btn-buy"' })}
          ${button('Chờ', { icon: icon('schedule', 20), variant: 'secondary', attrs: 'data-k="btn-wait"' })}
          ${button('Bỏ qua', { icon: icon('do_not_disturb_on_outlined', 20), variant: 'secondary', attrs: 'data-k="btn-skip"' })}
        </div>
      </div>
    </div>`
}

/** distance to scroll so `el` sits `gap` px below the top of the detail viewport (clamped) */
function scrollY(root, el, gap = 12) {
  const scroller = root.querySelector('[data-k="dscroll"]')
  const max = Math.max(0, scroller.offsetHeight - scroller.parentElement.clientHeight)
  if (!el) return max
  return Math.max(0, Math.min(max, el.offsetTop - gap))
}

/* ------------------------------------------------------------------ */
/* data: DemoDataService                                               */
/* ------------------------------------------------------------------ */
// Smart Wishlist after the change: "Bộ son dưỡng 3 màu" now waits until 11/11
const ITEMS = [
  { k: 'camera', title: 'Máy ảnh film mini', price: 450000, motive: 'emotion', status: { kind: 'cooldown', text: '2 ngày hoãn' } },
  { k: 'course', title: 'Khoá học tiếng Anh online', price: null, motive: 'social', status: { kind: 'cooldown', text: '1 ngày hoãn' } },
  { k: 'lip', title: 'Bộ son dưỡng 3 màu', price: 299000, motive: 'sale', status: { kind: 'review', text: 'Xem lại 11/11' } },
  { k: 'bottle', title: 'Bình giữ nhiệt 500ml', price: 185000, motive: 'need', status: { kind: 'purchased' } },
  { k: 'speaker', title: 'Loa bluetooth mini', price: 799000, motive: 'ads', status: { kind: 'skipped' } },
  { k: 'coat', title: 'Áo khoác len oversize', price: 1290000, motive: 'want', status: { kind: 'considering' } },
]

// created now − 5 d (02/11), latestPriceAt now − 1 d (06/11), snapshots 329.000 (02/11)
// and 299.000 (04/11), cooldown over, group 'beauty' (no monthly limit), wait -> 10/11
const LIP = {
  title: 'Bộ son dưỡng 3 màu',
  price: 299000,
  priceNote: 'Giá ghi ngày 06/11/2026',
  motive: 'sale',
  savedOn: '02/11/2026',
  history: {
    days: 2,
    milestones: [['04/11', 299000], ['02/11', 329000], ['02/11', 329000], ['04/11', 299000]],
    recordMore: false,
    notes: ['Thấp hơn lúc lưu 9%.'],
    records: 2,
  },
  // findDuplicates: last month's purchase "Son dưỡng" (11/10, same group) is a code match
  duplicate: 'Son dưỡng · đã mua 11/10/2026 · 159.000 ₫',
  // DecisionRules: recent price, no cooldown, confirmed 11.11 within 7 days -> waitSale
  label: 'Có thể chờ',
  reason: 'Đợt 11.11 còn 4 ngày, có thể có giá tốt hơn.',
  signals: ['Thấp hơn lúc lưu 9%.', 'Đợt 11.11 còn 4 ngày, có thể có giá tốt hơn.', 'Chưa đủ dữ liệu về hạn mức tháng của nhóm.'],
  actions: `<span class="d-tbtn">${icon('event_outlined', 18)}<span>Danh sách cho 11.11</span></span><span class="d-tbtn">${icon('pie_chart_outline_rounded', 18)}<span>Đặt hạn mức nhóm</span></span>`,
  review: 'Bạn hẹn xem lại vào Thứ Ba, 10/11/2026. Bấm Chờ để đổi ngày.',
}
const REVIEW_AFTER = 'Bạn hẹn xem lại vào Thứ Tư, 11/11/2026. Bấm Chờ để đổi ngày.'
const SNACK = 'Đã hẹn xem lại vào Thứ Tư, 11/11/2026. App sẽ nhắc bạn hôm đó.'

// ReviewDateSheet rows: {coolingOffDays 3, 7} sorted, the next confirmed sale, a picker
const OPTIONS = [
  { k: 'opt-3', icon: icon('schedule', 24), title: 'Sau 3 ngày', sub: 'Thứ Ba, 10/11/2026' },
  { k: 'opt-7', icon: icon('schedule', 24), title: 'Sau 7 ngày', sub: 'Thứ Bảy, 14/11/2026' },
  { k: 'opt-sale', icon: icon('event_outlined', 24), title: 'Đến đợt sale 11.11', sub: 'Thứ Tư, 11/11/2026' },
  { k: 'opt-pick', icon: icon('calendar_month_outlined', 24), title: 'Chọn ngày khác', sub: '' },
]

const CSS = `
.scr-review-wait .rw-page{position:absolute;inset:0;display:flex;flex-direction:column;background:var(--bg)}
.scr-review-wait .rw-mrow{flex:none;display:flex;gap:8px;height:48px;padding:0 16px;overflow:hidden}
.scr-review-wait .rw-mrow .wib-motive{flex:none;min-height:48px}
.scr-review-wait .rw-frow{flex:none;display:flex;align-items:center;gap:8px;height:48px;margin-top:8px;padding:0 16px;overflow:hidden;white-space:nowrap}
.scr-review-wait .rw-fchip{flex:none;display:inline-flex;align-items:center;gap:8px;height:32px;padding:0 16px;border-radius:999px;box-shadow:inset 0 0 0 1px var(--divider);font-size:12px;font-weight:400;color:var(--text-2)}
.scr-review-wait .rw-fchip.is-on{padding-left:8px;background:var(--primary-container);box-shadow:none;color:var(--text);font-weight:600}
.scr-review-wait .rw-fchip .mi{font-size:18px}
.scr-review-wait .rw-list{position:relative;flex:1;min-height:0;overflow:hidden}
.scr-review-wait .rw-card-lip [data-status]{position:relative}
.scr-review-wait .rw-sheet{padding:12px 0 0}
.scr-review-wait .rw-sheet .wib-sheet__title{line-height:1.35}
.scr-review-wait .rw-sheet .wib-sheet__content{padding:8px 16px 24px}
.scr-review-wait .rw-intro{margin-bottom:8px;font-size:14px;line-height:1.45;color:var(--text-2)}
.scr-review-wait .rw-tile{position:relative;display:flex;align-items:center;gap:16px;min-height:48px;padding:8px 0}
.scr-review-wait .rw-tile>.mi{flex:none;font-size:24px;color:var(--text-2)}
.scr-review-wait .rw-tile__t{font-size:16px;line-height:1.45;color:var(--text)}
.scr-review-wait .rw-tile__s{font-size:14px;line-height:1.45;color:var(--text-2)}
.scr-review-wait .rw-tile.is-pressed{filter:none;background:rgba(15,23,42,.08)}
.scr-review-wait .rw-anchor{position:absolute;inset:0;pointer-events:none}
${DETAIL_CSS}`

export default {
  id: 'review-wait',
  render() {
    return html`
      <div class="wib-screen scr-review-wait">
        <style>${CSS}</style>
        <div class="wib-body">
          <div class="rw-page" data-k="list" style="display:none">
            ${appBar({
              title: 'Smart Wishlist',
              actions: html`<span class="wib-iconbtn">${icon('event_outlined')}</span><span class="wib-iconbtn" style="margin-right:4px">${icon('add')}</span>`,
            })}
            <div style="flex:none;padding:8px 16px">${field({ hint: 'Tìm kiếm sản phẩm hoặc động cơ...', prefix: icon('search', 20) })}</div>
            <div class="rw-mrow">${Object.keys(MOTIVES).map((m) => motiveChip(m, { compact: true }))}</div>
            <div class="rw-frow">
              <span class="rw-fchip is-on">${icon('check', 18)}Tất cả</span>
              <span class="rw-fchip">Cần xem lại (0)</span>
              <span class="rw-fchip">Đang cân nhắc</span>
              <span class="rw-fchip">Đã mua</span>
              <span class="rw-fchip">Bỏ qua</span>
            </div>
            <div class="wib-divider" style="flex:none;margin-top:8px"></div>
            <div class="rw-list"><div class="wib-scroll">${ITEMS.map((it) => wishlistCard(it, `rw-card-${it.k}`))}</div></div>
          </div>
          <div class="scr-item-detail" data-k="detail">${itemDetail(LIP)}</div>
          <div class="wib-snackbar" data-k="snack" style="left:15px;right:15px;bottom:28px;padding:14px 16px">
            <span class="wib-snackbar__text">${SNACK}</span>
          </div>
        </div>

        <!-- AppBottomSheet "Xem lại món này khi nào?" (modal barrier covers the whole screen) -->
        <div class="wib-scrim" data-k="scrim"></div>
        <div class="wib-sheet rw-sheet" data-k="sheet">
          <div class="wib-sheet__handle"></div>
          <div class="wib-sheet__title">Xem lại món này khi nào?</div>
          <div class="wib-sheet__content">
            <div class="rw-intro">Món vẫn ở "Đang cân nhắc". Bạn vẫn có thể Mua hoặc Bỏ qua bất cứ lúc nào.</div>
            ${OPTIONS.map(
              (o) => html`<div class="rw-tile" data-k="${o.k}">${o.icon}
                <div style="flex:1;min-width:0">
                  <div class="rw-tile__t">${o.title}</div>
                  ${o.sub ? `<div class="rw-tile__s">${o.sub}</div>` : ''}
                </div>
                ${o.k === 'opt-sale' ? '<i class="rw-anchor" data-k="anchor"></i>' : ''}
              </div>`,
            )}
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const list = k.q('[data-k="list"]')
    const detail = k.q('[data-k="detail"]')
    const scroller = k.q('[data-k="dscroll"]')
    const sheet = k.q('[data-k="sheet"]')
    const scrim = k.q('[data-k="scrim"]')
    const reviewBox = k.q('[data-k="review"]')
    const reviewText = k.q('[data-k="review-text"]')
    const badge = k.q('.rw-card-lip [data-status]')
    // the sale-row callout follows the chosen date: sheet row -> review box -> card badge
    const anchor = k.q('[data-k="anchor"]')
    tl.set(sheet, { y: 0, yPercent: 105 }, 0)

    // Chi tiết & Quyết định of "Bộ son dưỡng 3 màu", already waiting until 10/11
    k.reveal(tl, '[data-k="hcard"], [data-k="price-panel"]', { stagger: 0.08, duration: 0.45 })
    // down to the review box and the three equal buttons
    tl.to(scroller, { y: () => -scrollY(root, null), duration: 0.85, ease: 'power3.inOut' }, 0.5)

    // "Chờ" opens ReviewDateSheet
    k.tap(tl, '[data-k="btn-wait"]', { pos: '+=0.1' })
    tl.to(scrim, { opacity: 1, duration: 0.3, ease: 'power2.out' }, '-=0.12')
    tl.to(sheet, { yPercent: 0, duration: 0.45, ease: 'power3.out' }, '<')
    k.callout(tl, anchor, 'Lịch sale từ Remote Config', { pos: '+=0.05' })

    // pick "Đến đợt sale 11.11" (09:00 on 11/11): the sheet closes, the screen stays
    k.tap(tl, '[data-k="opt-sale"]', { pos: '+=0.55' })
    tl.to(sheet, { yPercent: 105, duration: 0.3, ease: 'power3.in' }, '-=0.08')
    tl.to(scrim, { opacity: 0, duration: 0.3 }, '<')
    tl.call(() => reviewBox.appendChild(anchor), null, '<')
    tl.to(reviewText, { opacity: 0, duration: 0.12 }, '>-0.04')
    k.text(tl, reviewText, REVIEW_AFTER, '>')
    tl.to(reviewText, { opacity: 1, duration: 0.25 }, '>')
    k.snack(tl, '[data-k="snack"]', { pos: '<' })
    k.callout(tl, '[data-k="snack"]', 'Nhắc lúc 09:00 sáng 11/11', { pos: '+=0.25' })

    // back to Smart Wishlist: the card badge now reads "Xem lại 11/11"
    k.tap(tl, '[data-k="detail"] .wib-appbar > .wib-iconbtn', { pos: '+=0.7' })
    k.page(tl, detail, list, { pos: '+=0.02', dir: -1 })
    tl.call(() => badge.appendChild(anchor), null, '<')
    k.lift(tl, '<')
    tl.fromTo(badge, { scale: 1 }, { scale: 1.12, duration: 0.22, yoyo: true, repeat: 1, ease: 'power2.out' }, '+=0.05')
    k.wait(tl, 0.8)
  },
}

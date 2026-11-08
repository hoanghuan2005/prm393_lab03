// Trước khi mua (lib/screens/pre_purchase_screen.dart + pre_purchase_result_screen.dart).
// One Scaffold whose body swaps between 3 or 4 question steps (setState, no route),
// then a pushed route: "AI đang phân tích" (>= 1,5 s in the app) cross-fades to
// "Nhận định trước khi mua". Cards and template sentences come from PrePurchaseRules;
// Gemini only rewrites the summary / question. No verdict, no traffic-light colours.
import { html, icon, field, button, money, grouped } from './kit.js'

const ITEM = { title: 'Tai nghe Bluetooth', price: 389000 }
const ITEM_LINE = `${ITEM.title} · ${money(ITEM.price)}`

// lib/models/pre_purchase_check.dart (these icons differ from the 8 BuyingMotive icons)
const WHY = [
  { key: 'need', label: 'Nhu cầu', icon: 'shield_outlined' },
  { key: 'want', label: 'Mong muốn', icon: 'auto_awesome_outlined' },
  { key: 'emotion', label: 'Cảm xúc', icon: 'favorite_border' },
  { key: 'other', label: 'Khác', icon: 'more_horiz' },
]
const INFLUENCE = [
  { key: 'sale', label: 'Khuyến mãi', icon: 'local_offer_outlined' },
  { key: 'social', label: 'Ảnh hưởng MXH', icon: 'people_outline' },
  { key: 'ads', label: 'Quảng cáo', icon: 'campaign_outlined' },
  { key: 'none', label: 'Không có', icon: 'more_horiz' },
]
const WITHOUT_SALE = [
  { key: 'yes', label: 'Có, vẫn muốn', icon: 'check_circle_outline' },
  { key: 'unsure', label: 'Chưa chắc', icon: 'more_horiz' },
  { key: 'no', label: 'Không', icon: 'local_offer_outlined' },
]
const USAGE = [
  { key: 'daily', label: 'Hằng ngày', icon: 'today_outlined' },
  { key: 'weekly', label: 'Vài lần mỗi tuần', icon: 'date_range_outlined' },
  { key: 'sometimes', label: 'Thỉnh thoảng', icon: 'event_outlined' },
  { key: 'unsure', label: 'Chưa rõ', icon: 'help_outline' },
]
const SIMILAR = [
  { key: 'none', label: 'Chưa có', icon: 'add_circle_outline' },
  { key: 'worn', label: 'Có, nhưng đã cũ/hỏng', icon: 'build_outlined' },
  { key: 'working', label: 'Có, vẫn dùng tốt', icon: 'inventory_2_outlined' },
]

// PrePurchaseRules.observationsFor(Mong muốn, Khuyến mãi, Chưa chắc, Vài lần mỗi tuần, Có, vẫn dùng tốt)
const OBSERVATIONS = [
  { icon: 'auto_awesome_outlined', text: 'Bạn chọn Mong muốn: món này hấp dẫn bạn, hơn là một nhu cầu bạn đã xác định.', chip: 'Mong muốn' },
  { icon: 'local_offer_outlined', text: 'Bạn chọn Khuyến mãi và chưa chắc sẽ muốn nó khi đủ giá. Ưu đãi là một phần sức hút.', chip: 'Khuyến mãi' },
  { icon: 'date_range_outlined', text: 'Bạn nghĩ mình sẽ dùng món này vài lần mỗi tuần.', chip: 'Dùng: Vài lần mỗi tuần' },
  { icon: 'inventory_2_outlined', text: 'Bạn đang có một món làm được việc tương tự và vẫn dùng tốt, nên món mới sẽ là món thêm vào.', chip: 'Đồ tương tự: Có, vẫn dùng tốt' },
]
// PrePurchaseFacts.build with the demo seed, today 07/11/2026: 'Tai nghe Bluetooth' bought
// 01/11 23:40; Khuyến mãi purchases in 30 days: 01/11, 03/11, 14/10. (The budget-% fact is
// runtime math, so it is left out here.)
const FACTS = [
  { icon: 'history', text: '5 ngày trước bạn đã mua "Tai nghe Bluetooth" (389.000 ₫).' },
  { icon: 'receipt_long_outlined', text: '30 ngày qua bạn đã ghi 3 khoản mua vì Khuyến mãi.' },
]
// Example of an accepted Gemini summary (only numbers from the facts); question = template
const SUMMARY = 'Bạn chưa chắc còn muốn món này khi hết ưu đãi, và 5 ngày trước bạn đã mua một chiếc tai nghe tương tự.'
const QUESTION = 'Món mới sẽ làm được điều gì mà món bạn đang có chưa làm được?'

const CSS = `
.scr-pp, .scr-pp *, .scr-pp *::before, .scr-pp *::after { box-sizing:border-box; }
.scr-pp .pp-route { position:absolute; inset:0; display:flex; flex-direction:column; background:var(--bg); }
.scr-pp .pp-main { position:relative; flex:1; min-height:0; overflow:hidden; }
.scr-pp .pp-page { position:absolute; inset:0; overflow:hidden; }
.scr-pp .pp-page > .wib-scroll { position:relative; }
.scr-pp .pp-head { display:flex; align-items:flex-start; }
.scr-pp .pp-head__text { flex:1; min-width:0; display:flex; flex-direction:column; align-items:flex-start; }
.scr-pp .pp-step { display:inline-block; border-radius:4px; font-size:12px; font-weight:500; line-height:1.35; letter-spacing:.4px; color:var(--neutral); }
.scr-pp .pp-h20 { font-size:20px; font-weight:600; line-height:1.35; color:var(--text); }
.scr-pp .pp-head .pp-h20 { margin-top:4px; }
.scr-pp .pp-dots { display:flex; align-items:center; }
.scr-pp .pp-dot { flex:none; width:8px; height:8px; margin-left:4px; border-radius:999px; background:var(--divider); }
.scr-pp .pp-dot.is-done { background:var(--primary); }
.scr-pp .pp-dot.is-cur { width:18px; }
.scr-pp .pp-dot--new { width:0; margin-left:0; }
.scr-pp .pp-panel { padding:16px; border-radius:16px; background:var(--surface); border:1px solid var(--divider); }
.scr-pp .pp-q { padding-bottom:12px; }
.scr-pp .pp-q__t { font-size:16px; font-weight:600; line-height:1.4; }
.scr-pp .pp-q__h { margin-top:4px; font-size:14px; line-height:1.45; color:var(--text-2); }
.scr-pp .pp-grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.scr-pp .pp-list > .pp-opt { margin-bottom:12px; }
.scr-pp .pp-opt { display:flex; align-items:center; min-height:64px; padding:12px; border-radius:16px; background:var(--surface); box-shadow:inset 0 0 0 1px var(--divider); transition:background .15s ease, box-shadow .15s ease; }
.scr-pp .pp-opt__ic { flex:none; width:40px; height:40px; display:grid; place-items:center; border-radius:50%; background:var(--surface-variant); color:var(--text); transition:background .15s ease; }
.scr-pp .pp-opt__label { flex:1; min-width:0; margin-left:12px; font-size:14px; font-weight:500; line-height:1.4; color:var(--text); }
.scr-pp .pp-opt__check { display:none; color:var(--text); }
.scr-pp .pp-opt.is-on { background:var(--primary-container); box-shadow:inset 0 0 0 2px var(--primary); }
.scr-pp .pp-opt.is-on .pp-opt__ic { background:var(--primary); }
.scr-pp .pp-opt.is-on .pp-opt__label { font-weight:700; }
.scr-pp .pp-opt.is-on .pp-opt__check { display:block; }
.scr-pp .pp-f-price .wib-input__suffix { opacity:0; transition:opacity .15s ease; }
.scr-pp .pp-f-price .wib-input.is-focused .wib-input__suffix,
.scr-pp .pp-f-price.has-value .wib-input__suffix { opacity:1; }
.scr-pp .pp-clear { display:none; margin:0 -4px 0 -4px; }
.scr-pp .pp-bottom { flex:none; padding:8px 16px 34px; }
.scr-pp .pp-bulb { width:72px; height:72px; margin:0 auto; display:grid; place-items:center; border-radius:50%; background:var(--primary-container); color:var(--text); }
.scr-pp .pp-prog { position:relative; height:6px; border-radius:999px; background:var(--surface-variant); overflow:hidden; }
.scr-pp .pp-prog > span { position:absolute; top:0; bottom:0; left:-45%; width:45%; border-radius:999px; background:var(--text); }
.scr-pp .pp-result { position:absolute; inset:0; display:flex; flex-direction:column; }
.scr-pp .pp-rview { position:relative; flex:1; min-height:0; overflow:hidden; }
.scr-pp .pp-obs { display:flex; align-items:flex-start; padding:16px; margin-bottom:12px; border-radius:16px; background:var(--surface); border:1px solid var(--divider); }
.scr-pp .pp-obs__ic { flex:none; width:40px; height:40px; display:grid; place-items:center; border-radius:12px; background:var(--surface-variant); color:var(--text); }
.scr-pp .pp-obs__body { flex:1; min-width:0; margin-left:12px; display:flex; flex-direction:column; align-items:flex-start; }
.scr-pp .pp-obs__text, .scr-pp .pp-fact__text { font-size:14px; line-height:1.45; color:var(--text); }
.scr-pp .pp-chip { margin-top:8px; padding:4px 8px; border-radius:999px; background:var(--surface-variant); font-size:11px; font-weight:500; letter-spacing:.5px; line-height:1.3; color:var(--text-2); }
.scr-pp .pp-facts { padding:16px; border-radius:16px; background:var(--primary-container); }
.scr-pp .pp-fact { display:flex; align-items:flex-start; gap:12px; margin-top:12px; }
.scr-pp .pp-rbottom { flex:none; padding:8px 16px 34px; display:flex; flex-direction:column; gap:8px; }
`

function bar(title, back, k) {
  return html`<div class="wib-appbar">
    <span class="wib-iconbtn" style="width:48px;height:48px">${back}</span>
    <div class="wib-appbar__title" style="padding-left:16px"><span data-k="${k}">${title}</span></div>
  </div>`
}

/** _StepHeader: 'BƯỚC x/y', heading, progress dots (newDot: hidden 4th dot for the sale step) */
function stepHeader(step, total, heading, { k = '', newDot = false } = {}) {
  const dots = []
  for (let i = 1; i <= total; i++) dots.push(`<span class="pp-dot ${i <= step ? 'is-done' : ''} ${i === step ? 'is-cur' : ''}"></span>`)
  if (newDot) dots.push('<span class="pp-dot pp-dot--new" data-k="dot-new"></span>')
  return html`<div class="pp-head">
    <div class="pp-head__text">
      <span class="pp-step" ${k ? `data-k="${k}"` : ''}>BƯỚC ${step}/${total}</span>
      <div class="pp-h20">${heading}</div>
    </div>
    <div class="pp-dots">${dots}</div>
  </div>`
}

function question(title, hint) {
  return `<div class="pp-q"><div class="pp-q__t">${title}</div><div class="pp-q__h">${hint}</div></div>`
}

/** _Option: selectable card shared by every question step */
function option(o, group) {
  return html`<div class="pp-opt" data-k="opt-${group}-${o.key}">
    <span class="pp-opt__ic">${icon(o.icon, 20)}</span>
    <span class="pp-opt__label">${o.label}</span>
    <span class="pp-opt__check">${icon('check_circle_outline', 20)}</span>
  </div>`
}
const grid = (list, group) => `<div class="pp-grid">${list.map((o) => option(o, group)).join('')}</div>`
const list = (items, group) => `<div class="pp-list">${items.map((o) => option(o, group)).join('')}</div>`

export default {
  id: 'pre-purchase',
  render() {
    return html`
      <div class="wib-screen scr-pp">
        <style>${CSS}</style>
        <div class="wib-body">
          <!-- PrePurchaseScreen: one Scaffold, the body swaps per step -->
          <div class="pp-route" data-k="route-q">
            ${bar('Trước khi mua', icon('chevron_left_rounded', 24), 'q-title')}
            <div class="pp-main">
              <div class="pp-page" data-k="p-item">
                <div class="wib-scroll">
                  ${stepHeader(1, 3, 'Bạn đang cân nhắc món gì?')}
                  <div class="t-body-m" style="margin-top:16px">Bắt đầu với món bạn đang cân nhắc. Bước này không ghi khoản mua.</div>
                  <div class="pp-panel" style="margin-top:16px">
                    ${field({ label: 'Tên món', hint: 'Ví dụ: Tai nghe Bluetooth', prefix: icon('shopping_bag_outlined', 20), cls: 'pp-f-name' })}
                    <div style="height:16px"></div>
                    ${field({ label: 'Giá dự kiến (không bắt buộc)', hint: 'Để trống nếu chưa biết giá', suffix: '₫', trailing: `<span class="pp-clear">${icon('close_rounded', 20)}</span>`, cls: 'pp-f-price' })}
                  </div>
                  <div class="t-title-l" style="margin-top:24px">Một chút để hiểu mình</div>
                  <div class="t-body-m" style="margin-top:8px">Tiếp theo, bạn sẽ xem vì sao mình muốn món này, điều gì thu hút bạn và bạn sẽ dùng nó ra sao. App cũng đối chiếu với dữ liệu bạn đã ghi. Không có câu trả lời đúng hay sai.</div>
                  <div class="t-caption" style="margin-top:16px">AI chỉ gợi ý để nhìn lại. Quyết định vẫn là của bạn.</div>
                </div>
              </div>

              <div class="pp-page" data-k="p-motive" style="display:none">
                <div class="wib-scroll">
                  ${stepHeader(2, 3, 'Điều gì đứng sau lựa chọn?', { k: 'step-motive', newDot: true })}
                  <div class="t-body-m" style="margin-top:16px">${ITEM_LINE}</div>
                  <div style="height:16px"></div>
                  ${question('Vì sao bạn muốn món này?', 'Chọn động cơ gần nhất với cảm nhận của bạn.')}
                  ${grid(WHY, 'why')}
                  <div style="height:24px"></div>
                  ${question('Điều gì tác động đến lần mua này?', 'Chọn tác động rõ nhất.')}
                  ${grid(INFLUENCE, 'inf')}
                  <div class="t-caption" style="margin-top:16px">Không có câu trả lời đúng hay sai.</div>
                </div>
              </div>

              <div class="pp-page" data-k="p-sale" style="display:none">
                <div class="wib-scroll">
                  ${stepHeader(3, 4, 'Thử bỏ qua ưu đãi')}
                  <div class="pp-panel" style="margin-top:16px">
                    <div class="t-title-l">${ITEM.title}</div>
                    <div class="t-body-m" style="margin-top:4px">${money(ITEM.price)} · Mong muốn + Khuyến mãi</div>
                  </div>
                  <div style="height:24px"></div>
                  ${question('Không có khuyến mãi, bạn vẫn muốn món này chứ?', 'Hãy nghĩ về món đó, tách khỏi ưu đãi.')}
                  ${list(WITHOUT_SALE, 'ws')}
                  <div class="t-caption">Chưa chắc cũng không sao. Câu trả lời giúp gợi ý sát hơn.</div>
                </div>
              </div>

              <div class="pp-page" data-k="p-usage" style="display:none">
                <div class="wib-scroll" data-k="uscroll">
                  ${stepHeader(4, 4, 'Bạn sẽ dùng nó ra sao?')}
                  <div class="t-body-m" style="margin-top:16px">${ITEM_LINE}</div>
                  <div style="height:16px"></div>
                  ${question('Bạn sẽ dùng món này thường xuyên thế nào?', 'Hình dung một tuần bình thường của bạn.')}
                  ${grid(USAGE, 'use')}
                  <div style="height:24px"></div>
                  ${question('Bạn đã có món nào làm được việc tương tự chưa?', 'Kể cả món không giống hệt nhưng dùng được cho cùng việc.')}
                  ${list(SIMILAR, 'sim')}
                  <div class="t-caption">Không có câu trả lời đúng hay sai.</div>
                </div>
              </div>
            </div>
            <div class="pp-bottom">${button('Tiếp tục', { attrs: 'data-k="next"' })}</div>
          </div>

          <!-- PrePurchaseResultScreen (pushed route): analyzing, then the result -->
          <div class="pp-route" data-k="route-r" style="display:none">
            ${bar('AI đang phân tích', icon('arrow_back', 24), 'r-title')}
            <div class="pp-main">
              <div class="pp-page" data-k="analyzing" style="padding:72px 24px 24px">
                <div class="pp-bulb">${icon('lightbulb_outline', 32)}</div>
                <div class="pp-h20" style="margin-top:24px;text-align:center">Đang xem kỹ hơn</div>
                <div class="t-body-m" style="margin-top:8px;text-align:center">Đang nhìn lại Mong muốn, Khuyến mãi và câu trả lời "Chưa chắc".</div>
                <div class="pp-panel" style="margin-top:24px">
                  <div class="t-title-m">${ITEM_LINE}</div>
                  <div class="pp-prog" data-k="prog" style="margin-top:12px"><span></span><span style="width:25%;left:-25%"></span></div>
                  <div class="t-caption" style="margin-top:12px">Đang kết nối các câu trả lời của bạn...</div>
                </div>
                <div class="t-caption" style="margin-top:24px;text-align:center">Hiểu trước khi thay đổi.</div>
              </div>

              <div class="pp-result" data-k="result" style="display:none">
                <div class="pp-rview">
                  <div class="wib-scroll" data-k="rscroll" style="position:relative">
                    <div class="pp-h20">Rõ hơn một chút trước khi mua</div>
                    <div class="t-title-l" style="margin-top:16px">${ITEM.title}</div>
                    <div class="t-body-m" style="margin-top:4px">${money(ITEM.price)} · Dựa trên câu trả lời của bạn</div>
                    <div style="height:16px"></div>
                    ${OBSERVATIONS.map(
                      (o, i) => html`<div class="pp-obs" data-k="obs${i + 1}">
                        <span class="pp-obs__ic">${icon(o.icon, 24)}</span>
                        <div class="pp-obs__body"><div class="pp-obs__text">${o.text}</div><span class="pp-chip">${o.chip}</span></div>
                      </div>`,
                    )}
                    <div class="pp-facts" data-k="facts" style="margin-top:12px">
                      <div class="t-title-m">Từ dữ liệu của bạn</div>
                      ${FACTS.map((f) => `<div class="pp-fact">${icon(f.icon, 20)}<div class="pp-fact__text">${f.text}</div></div>`)}
                    </div>
                    <div style="height:20px"></div>
                    <div data-k="summary" style="font-size:14px;line-height:1.45;color:var(--text-body)">${SUMMARY} Đây là gợi ý từ điều bạn chia sẻ, không phải dự đoán việc bạn sẽ làm.</div>
                    <div style="margin-top:8px"><span class="wib-ai-chip" data-k="chip">${icon('auto_awesome', 12)}AI</span></div>
                    <div class="t-title-l" style="margin-top:24px">Gợi mở</div>
                    <div class="t-body-l" data-k="question" style="margin-top:8px">${QUESTION}</div>
                    <div class="t-caption" style="margin-top:24px">Không có lựa chọn đúng hay sai. Quyết định là của bạn.</div>
                  </div>
                </div>
                <div class="pp-rbottom">
                  ${button('Để mình nghĩ thêm')}
                  ${button('Vẫn mua', { variant: 'secondary' })}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const q = k.q
    const next = q('[data-k="next"]')
    const nextLabel = next.querySelector('.wib-btn__label > span')

    /** setState step change: same Scaffold, body swaps (near-instant in the app) */
    const step = (from, to, pos, title, { label, disabled = true } = {}) => {
      const a = q(from)
      const b = q(to)
      tl.set(b, { display: '', opacity: 0 }, pos)
      tl.to(b, { opacity: 1, duration: 0.18, ease: 'power1.out' }, pos)
      tl.to(a, { opacity: 0, duration: 0.12, ease: 'power1.in' }, pos)
      tl.set(a, { display: 'none' }, pos + 0.18)
      k.text(tl, '[data-k="q-title"]', title, pos)
      if (label) k.text(tl, nextLabel, label, pos)
      k.cls(tl, next, 'is-disabled', disabled, pos)
    }
    const pick = (el) => el.classList.add('is-on')

    // 1. Item step: name + price typed quickly (AmountField groups digits while typing)
    const nameInput = q('.pp-f-name .wib-input')
    const priceField = q('.pp-f-price')
    const priceInput = priceField.querySelector('.wib-input')
    const priceValue = priceField.querySelector('.wib-input__value')
    const clear = priceField.querySelector('.pp-clear')
    k.cls(tl, nameInput, 'is-focused', true, 0.1)
    k.type(tl, nameInput.querySelector('.wib-input__value'), ITEM.title, { pos: 0.15, cps: 50 })
    k.cls(tl, nameInput, 'is-focused', false, 0.58)
    k.cls(tl, priceInput, 'is-focused', true, 0.58)
    k.cls(tl, priceField, 'has-value', true, 0.62)
    const digits = String(ITEM.price)
    const s = { n: 0 }
    tl.call(() => priceValue.classList.add('is-typing'), null, 0.62)
    tl.to(s, {
      n: digits.length,
      duration: 0.36,
      ease: 'none',
      onUpdate: () => {
        const d = digits.slice(0, Math.round(s.n))
        priceValue.textContent = d ? grouped(+d) : ''
        clear.style.display = d ? 'block' : 'none'
      },
    }, 0.62)
    k.tap(tl, next, {
      pos: 0.65,
      hold: 0.05,
      then: () => {
        priceValue.classList.remove('is-typing')
        priceInput.classList.remove('is-focused')
      },
    })

    // 2. Motive step: 'Mong muốn' + 'Khuyến mãi' -> a sale step is inserted (3 -> 4 steps)
    step('[data-k="p-item"]', '[data-k="p-motive"]', 1.2, 'Câu hỏi nhanh')
    k.tap(tl, '[data-k="opt-why-want"]', { pos: 1.3, hold: 0.05, then: pick })
    k.tap(tl, '[data-k="opt-inf-sale"]', { pos: 1.95, hold: 0.05, then: pick })
    const P = 2.45
    const stepLabel = q('[data-k="step-motive"]')
    k.text(tl, stepLabel, 'BƯỚC 2/4', P)
    k.cls(tl, next, 'is-disabled', false, P)
    tl.fromTo(q('[data-k="dot-new"]'), { width: 0, marginLeft: 0, scale: 0 }, { width: 8, marginLeft: 4, scale: 1, duration: 0.4, ease: 'back.out(3)' }, P)
    tl.fromTo(
      stepLabel,
      { backgroundColor: 'rgba(255,222,2,0)', boxShadow: '0 0 0 4px rgba(255,222,2,0)' },
      { backgroundColor: 'rgba(255,222,2,0.45)', boxShadow: '0 0 0 4px rgba(255,222,2,0.45)', duration: 0.2, yoyo: true, repeat: 1, repeatDelay: 0.75 },
      P,
    )

    // 3. Inserted step 'Câu hỏi về khuyến mãi' (BƯỚC 3/4)
    k.tap(tl, next, { pos: 2.8, hold: 0.05 })
    step('[data-k="p-motive"]', '[data-k="p-sale"]', 3.35, 'Câu hỏi về khuyến mãi')
    k.tap(tl, '[data-k="opt-ws-unsure"]', { pos: 3.45, hold: 0.05, then: pick })
    k.cls(tl, next, 'is-disabled', false, 3.95)

    // 4. Usage step (BƯỚC 4/4), answered quickly
    k.tap(tl, next, { pos: 4.1, hold: 0.05 })
    step('[data-k="p-sale"]', '[data-k="p-usage"]', 4.65, 'Câu hỏi nhanh', { label: 'Xem nhận định' })
    const flash = (sel, pos) => {
      k.cls(tl, sel, 'is-on', true, pos)
      tl.fromTo(q(sel), { scale: 0.96 }, { scale: 1, duration: 0.25, ease: 'power2.out', immediateRender: false }, pos)
    }
    flash('[data-k="opt-use-weekly"]', 4.9)
    const uscroll = q('[data-k="uscroll"]')
    tl.to(uscroll, { y: () => -Math.max(0, uscroll.offsetHeight - uscroll.parentElement.clientHeight), duration: 0.4, ease: 'power2.inOut' }, 4.98)
    flash('[data-k="opt-sim-working"]', 5.4)
    k.cls(tl, next, 'is-disabled', false, 5.45)
    k.tap(tl, next, { pos: 5.05, hold: 0.05 })
    k.lift(tl, 5.75)

    // 5. Pushed route: 'AI đang phân tích' (>= 1,5 s in the app, shortened here)
    k.page(tl, '[data-k="route-q"]', '[data-k="route-r"]', { pos: 5.62 })
    // indeterminate LinearProgressIndicator: a long and a short segment chasing each other
    const [segA, segB] = k.qa('[data-k="prog"] > span')
    tl.fromTo(segA, { left: '-45%' }, { left: '100%', duration: 0.7, ease: 'power1.inOut', repeat: 1 }, 5.6)
    tl.fromTo(segB, { left: '-25%' }, { left: '100%', duration: 0.7, ease: 'power2.in', repeat: 1, immediateRender: false }, 5.95)

    // 6. AnimatedSwitcher (250 ms) to 'Nhận định trước khi mua'
    const R = 6.95
    const result = q('[data-k="result"]')
    tl.set(result, { display: '', opacity: 0 }, R)
    tl.to(result, { opacity: 1, duration: 0.25, ease: 'power1.out' }, R)
    tl.to(q('[data-k="analyzing"]'), { opacity: 0, duration: 0.25 }, R)
    k.text(tl, '[data-k="r-title"]', 'Nhận định trước khi mua', R)
    k.reveal(tl, '[data-k^="obs"]', { pos: R + 0.05, y: 10, stagger: 0.07, duration: 0.4 })

    // scroll so the last observation card, facts, summary + chip and the question share the frame
    const rscroll = q('[data-k="rscroll"]')
    const card4 = q('[data-k="obs4"]')
    tl.to(rscroll, {
      y: () => -Math.max(0, Math.min(card4.offsetTop - 10, rscroll.offsetHeight - rscroll.parentElement.clientHeight)),
      duration: 0.85,
      ease: 'power3.inOut',
    }, R + 0.55)
    const chip = q('[data-k="chip"]')
    tl.fromTo(chip, { scale: 0.6, opacity: 0 }, { scale: 1, opacity: 1, duration: 0.35, ease: 'back.out(2.2)' }, R + 1.3)
    k.callout(tl, card4, 'Thẻ quan sát do quy tắc tạo', { pos: R + 1.3 })
    k.callout(tl, chip, 'Gemini chỉ viết câu, không phán xét', { pos: R + 1.55 })
    k.wait(tl, 0.3)
  },
}

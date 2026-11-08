// Ghi khoản mua (lib/screens/record_purchase_screen.dart), new manual purchase:
// step 1 (AmountField, quick-add ActionChips, title, budget group + rule-based
// suggestion chip) -> step 2 (8 motive OutlinedButtons, default Cảm xúc) -> save.
// A new manual purchase shows the SnackBar and replaces the route with
// 'Chi tiết khoản mua' (purchase_detail_screen.dart), so the demo ends there.
// Step 1 -> 2 is a setState inside the same Scaffold (no route transition).
import { html, icon, button, snackbar, grouped, MOTIVES } from './kit.js'

const ORDER = ['need', 'want', 'sale', 'emotion', 'social', 'convenience', 'ads', 'other']

const STYLE = `
.scr-rp,.scr-rp *,.scr-rp *::before,.scr-rp *::after{box-sizing:border-box}
.scr-rp .rp-page{position:absolute;inset:0;display:flex;flex-direction:column;background:var(--bg);padding-bottom:18px}
.scr-rp .rp-step{flex:none;padding:16px;font-size:14px;font-weight:600;line-height:1.4}
.scr-rp .rp-scroll{position:relative;flex:1;min-height:0;overflow:hidden;padding:0 16px}
.scr-rp .rp-bottom{flex:none;padding:16px}
.scr-rp .rp-tf{position:relative}
.scr-rp .rp-label{position:absolute;left:12px;top:28px;transform:translateY(-50%);padding:0 4px;background:linear-gradient(transparent calc(50% - .5px),var(--surface) calc(50% - .5px));font-size:16px;line-height:1.2;color:var(--text-2);white-space:nowrap;pointer-events:none;z-index:1}
.scr-rp .rp-label.is-float{top:0;font-size:12px}
.scr-rp .rp-tf .wib-input:not(.is-focused) .wib-input__value:empty::before{content:none}
.scr-rp .rp-counter{padding:4px 16px 0;text-align:right;font-size:12px;line-height:16px;color:var(--text-2)}
.scr-rp .rp-amount .wib-input:not(.is-focused):not(.has-value) .wib-input__suffix{opacity:0}
.scr-rp .rp-amount .wib-input__suffix{font-size:14px;color:var(--hint)}
.scr-rp .rp-amount .wib-input__value.is-typing:empty{display:flex;align-items:center}
.scr-rp .rp-amount .wib-input__value.is-typing:empty::after{order:-1;margin:0 1px 0 0}
.scr-rp .rp-clear{display:none;margin-right:-2px;color:var(--text-2)}
.scr-rp .wib-input.has-value .rp-clear{display:grid}
.scr-rp .rp-dd{min-height:52px}
.scr-rp .rp-dd .wib-input__value{font-size:14px;line-height:1.45;color:var(--text-2)}
.scr-rp .rp-chips{display:flex;align-items:center;gap:8px;height:48px}
.scr-rp .rp-chip{display:inline-flex;align-items:center;gap:8px;height:36px;padding:0 16px;border-radius:8px;background:transparent;box-shadow:inset 0 0 0 1px var(--divider);font-size:14px;font-weight:600;line-height:1.4;color:var(--text);white-space:nowrap}
.scr-rp .rp-chip--avatar{padding-left:8px}
.scr-rp .rp-anchor{position:absolute;left:0;top:0;width:1px;height:1px;visibility:hidden;pointer-events:none}
.scr-rp .wib-snackbar{left:0;right:0;bottom:0;min-height:0;padding:14px 24px 32px;border-radius:0;line-height:1.45;transform:translateY(100%);box-shadow:0 -2px 8px rgba(0,0,0,.18)}
.scr-rp .rp-chip--avatar .mi{color:var(--primary)}
.scr-rp .rp-sug{height:0;opacity:0;overflow:hidden}
.scr-rp .rp-date{display:flex;align-items:center;justify-content:center;gap:8px;height:48px;border-radius:999px;box-shadow:inset 0 0 0 1.5px var(--outline);font-size:14px;font-weight:600}
.scr-rp .rp-check{display:flex;align-items:center;min-height:56px;font-size:16px}
.scr-rp .rp-box{flex:none;width:18px;height:18px;margin:0 31px 0 15px;border-radius:2px;box-shadow:inset 0 0 0 2px var(--text-2)}
.scr-rp .rp-msg{padding:16px;border-radius:12px;background:var(--primary-container);font-size:16px;line-height:1.45}
.scr-rp .rp-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.scr-rp .rp-mt{display:flex;align-items:center;gap:8px;min-height:72px;padding:12px;border-radius:12px;background:var(--surface);box-shadow:inset 0 0 0 1px var(--divider);font-size:14px;font-weight:600;line-height:1.4}
.scr-rp .rp-mt > span{flex:1;min-width:0}
.scr-rp .rp-mt .rp-ck{display:none}
.scr-rp .rp-mt.is-sel{background:var(--primary-container);box-shadow:inset 0 0 0 1px var(--text)}
.scr-rp .rp-mt.is-sel .rp-ck{display:inline-block}
.scr-rp .rp-card{background:var(--surface);border:1px solid var(--divider);border-radius:16px;box-shadow:0 2px 8px rgba(0,0,0,.02);padding:18px}
.scr-rp .rp-k{font-size:12px;font-weight:500;color:var(--text-2)}
.scr-rp .rp-ibox{flex:none;width:36px;height:36px;border-radius:10px;display:grid;place-items:center}
.scr-rp .rp-hr{height:1px;margin:14px 0;background:var(--surface-variant)}
.scr-rp .rp-dbar{flex:none;padding:12px 20px 16px;background:var(--surface);box-shadow:inset 0 1px 0 var(--divider)}
.scr-rp .rp-dbtn{display:flex;align-items:center;justify-content:center;gap:8px;height:50px;border-radius:999px;background:var(--primary);font-size:16px;font-weight:700}
`

function appBar(title, { trailing = '', strong = false } = {}) {
  return html`<div class="wib-appbar">
    <span class="wib-iconbtn">${icon('chevron_left_rounded')}</span>
    <div class="wib-appbar__title" style="padding-left:20px${strong ? ';font-weight:700' : ''}"><span>${title}</span></div>
    ${trailing}
  </div>`
}

/** layout box of `el` inside `root` (offsets only, so slide/reveal transforms are ignored) */
function boxIn(el, root) {
  let left = 0
  let top = 0
  for (let n = el; n && n !== root; n = n.offsetParent) {
    left += n.offsetLeft
    top += n.offsetTop
  }
  return { left, top, width: el.offsetWidth, height: el.offsetHeight }
}

function motiveTile(key) {
  const m = MOTIVES[key]
  return `<div class="rp-mt ${key === 'emotion' ? 'is-sel' : ''}" data-mt="${key}">${icon(m.icon, 20)}<span>${m.label}</span>${icon('check', 16, 'rp-ck')}</div>`
}

/** digits typed into the AmountField: '339000' shows 3 → 33 → 339 → 3.390 → 33.900 → 339.000 */
function typeDigits(tl, input, el, digits, { pos = '+=0.1', cps = 11 } = {}) {
  const s = { n: 0 }
  tl.to(s, {
    n: digits.length,
    duration: digits.length / cps,
    ease: 'none',
    onUpdate: () => {
      const d = digits.slice(0, Math.round(s.n))
      el.textContent = d ? grouped(+d) : ''
      input.classList.toggle('has-value', !!d)
    },
  }, pos)
}

/** text typed into a TextFormField with a maxLength counter ('18/60') */
function typeText(tl, el, counter, text, { pos = '+=0.1', cps = 26 } = {}) {
  const s = { n: 0 }
  tl.to(s, {
    n: text.length,
    duration: text.length / cps,
    ease: 'none',
    onUpdate: () => {
      const n = Math.round(s.n)
      el.textContent = text.slice(0, n)
      counter.textContent = n
    },
  }, pos)
}

export default {
  id: 'record-purchase',
  render() {
    return html`
      <div class="wib-screen wib-screen--white scr-rp">
        <style>${STYLE}</style>
        <div class="wib-body">
          <div class="rp-page" data-k="form">
            ${appBar('Ghi khoản mua', { trailing: `<span class="wib-iconbtn" data-k="help" style="margin-right:4px;visibility:hidden">${icon('help_outline_rounded')}</span>` })}
            <div class="rp-step" data-k="step"><span data-k="step1">Bước 1/2: Thông tin khoản mua</span><span data-k="step2" style="display:none">Bước 2/2: Động cơ và ghi chú</span></div>
            <div class="rp-scroll">
              <div data-k="s1">
                <div class="rp-amount" data-k="f">
                  <div class="wib-field__label">Số tiền thực trả *</div>
                  <div class="wib-input" data-k="amount" style="margin-top:8px">
                    <span class="wib-input__value" data-k="amount-v" data-hint="Ví dụ: 389.000"></span>
                    <span class="wib-input__suffix">₫</span>
                    <span class="rp-clear">${icon('close_rounded', 20)}</span>
                  </div>
                </div>
                <div class="t-label-m" data-k="f" style="margin-top:8px">Số tiền sau giảm giá, không bao gồm phí vận chuyển.</div>
                <div class="rp-chips" data-k="f" data-chips style="margin-top:12px">
                  <span class="rp-chip">+20.000 ₫</span>
                  <span class="rp-chip" data-k="add50">+50.000 ₫</span>
                  <span class="rp-chip">+100.000 ₫</span>
                </div>
                <div class="rp-tf" data-k="f" style="margin-top:24px">
                  <div class="wib-input" data-k="title">
                    <span class="rp-label" data-k="title-l">Tên món hoặc dịch vụ *</span>
                    <span class="wib-input__value" data-k="title-v" data-hint="Ví dụ: Tai nghe Bluetooth"></span>
                  </div>
                  <div class="rp-counter"><span data-k="title-c">0</span>/60</div>
                </div>
                <div class="rp-tf" data-k="f" style="margin-top:16px">
                  <div class="wib-input rp-dd">
                    <span class="rp-label is-float">Nhóm ngân sách</span>
                    <span class="wib-input__value" data-k="group-v">Khác</span>
                    <span style="display:grid;margin-right:-4px">${icon('keyboard_arrow_down_rounded', 24)}</span>
                  </div>
                </div>
                <div class="rp-sug" data-k="sug">
                  <div style="display:flex;align-items:center;height:48px;margin-top:8px">
                    <span class="rp-chip rp-chip--avatar" data-k="sug-chip">${icon('lightbulb_outline_rounded', 18)}Gợi ý nhóm: Công nghệ</span>
                  </div>
                </div>
                <div class="rp-date" data-k="f" style="margin-top:16px">${icon('calendar_month_outlined', 18)}<span>07/11/2026 · 14:32</span></div>
                <div class="rp-check" data-k="f" style="margin-top:12px"><span class="rp-box"></span><span>Có dùng mã giảm giá</span></div>
              </div>

              <div data-k="s2" style="display:none">
                <div class="rp-msg">Tai nghe Bluetooth<br /><span data-k="m-amount">389.000 ₫</span></div>
                <div class="t-title-m" style="margin-top:24px">Điều gì thúc đẩy bạn mua món này?</div>
                <div class="t-body-m" style="margin-top:8px">Chọn một động cơ chính.</div>
                <div class="rp-grid" data-k="grid" style="margin-top:16px">${ORDER.map(motiveTile)}</div>
                <div class="rp-tf" style="margin-top:24px">
                  <div class="wib-input" style="min-height:80px;align-items:flex-start;padding-top:16px">
                    <span class="rp-label">Ghi chú (không bắt buộc)</span>
                    <span class="wib-input__value" data-hint="Điều bạn muốn ghi nhớ về khoản mua này"></span>
                  </div>
                  <div class="rp-counter">0/200</div>
                </div>
              </div>
            </div>
            <div class="rp-bottom">
              ${button('Tiếp tục', { icon: icon('arrow_forward_rounded', 20), attrs: 'data-k="next"' })}
              ${button('Lưu khoản mua', { icon: icon('check_rounded', 20), attrs: 'data-k="save" style="display:none"' })}
            </div>
          </div>

          <div class="rp-page" data-k="detail" style="display:none">
            ${appBar('Chi tiết khoản mua', { strong: true, trailing: `<span class="wib-iconbtn" style="margin-right:4px;color:var(--error)">${icon('delete_outline_rounded')}</span>` })}
            <div style="flex:1;min-height:0;overflow:hidden;padding:20px">
              <div class="rp-card">
                <div class="wib-row" style="justify-content:space-between">
                  <span style="font-size:11px;font-weight:700;letter-spacing:.6px;color:var(--text-2)">MỤC ĐÃ CHI TIÊU</span>
                  <span data-motive="sale" style="width:36px;height:36px;border-radius:50%;display:grid;place-items:center;background:var(--mb);color:var(--m)">${icon('local_offer_outlined', 18)}</span>
                </div>
                <div style="margin-top:8px;font-size:20px;font-weight:800;line-height:1.3">Tai nghe Bluetooth</div>
                <div style="margin-top:6px;font-size:30px;font-weight:800;letter-spacing:-.5px;line-height:1.25;color:var(--neutral)"><span data-k="d-amount">389.000 ₫</span></div>
                <div class="rp-hr"></div>
                <div class="wib-row" style="justify-content:space-between">
                  <span style="font-size:13px;font-weight:500;color:var(--text-2)">Động cơ</span>
                  <span class="wib-row" data-motive="sale" data-k="d-motive" style="gap:5px;padding:4px 10px;border-radius:999px;background:var(--mb);color:var(--m);font-size:12.5px;font-weight:700">${icon('local_offer_outlined', 14)}Khuyến mãi</span>
                </div>
              </div>
              <div class="rp-card" style="margin-top:16px">
                <div class="wib-row" style="align-items:flex-start;gap:12px">
                  <span class="rp-ibox" style="background:var(--surface-variant);color:var(--neutral)">${icon('access_time_rounded', 18)}</span>
                  <div>
                    <div class="rp-k">Thời gian ghi nhận</div>
                    <div style="margin-top:2px;font-size:15px;font-weight:700">Hôm nay 14:32</div>
                    <div style="margin-top:2px;font-size:12px;color:var(--text-2)">Thứ Bảy, 07/11/2026</div>
                  </div>
                </div>
                <div class="rp-hr"></div>
                <div class="wib-row" style="align-items:flex-start;gap:12px">
                  <span class="rp-ibox" style="background:var(--primary-container)">${icon('edit_note_rounded', 20)}</span>
                  <div style="flex:1;min-width:0">
                    <div class="rp-k">Ghi chú của bạn</div>
                    <div style="margin-top:6px;padding:12px;border-radius:10px;border:1px solid var(--divider);background:var(--bg);font-size:13.5px;line-height:1.4;color:var(--hint)">Không có ghi chú thêm</div>
                  </div>
                </div>
              </div>
              <div class="wib-row" style="align-items:flex-start;gap:10px;margin-top:16px;padding:16px;border-radius:16px;background:var(--primary-container);border:1px solid rgba(255,222,2,.5)">
                ${icon('lightbulb_rounded', 22)}
                <div style="flex:1">
                  <div style="font-size:13.5px;font-weight:700">Góc nhìn Why I Buy</div>
                  <div style="margin-top:4px;font-size:12.5px;line-height:1.4;color:var(--neutral)">Bạn ghi khoản này với động cơ Khuyến mãi, vào buổi chiều lúc 14:32, thuộc nhóm ngân sách Công nghệ.</div>
                </div>
              </div>
              <div class="wib-row" style="margin-top:16px;padding:16px;border-radius:16px;background:var(--surface);border:1px solid var(--divider)">
                <div style="flex:1">
                  <div style="font-size:15px;font-weight:700;color:var(--text-2)">Mức hài lòng</div>
                  <div style="margin-top:4px;font-size:16px;color:#f59e0b">Chưa chấm</div>
                </div>
                <span class="wib-textbtn">Chấm</span>
              </div>
            </div>
            <div class="rp-dbar"><span class="rp-dbtn">${icon('edit_outlined', 18)}Sửa khoản mua</span></div>
          </div>
        </div>
        ${snackbar('Đã lưu khoản mua.')}
        <span class="rp-anchor" data-k="a-amount"></span>
        <span class="rp-anchor" data-k="a-motive"></span>
      </div>`
  },

  demo(tl, root, k) {
    const q = (s) => root.querySelector(`[data-k="${s}"]`)
    const amount = q('amount')
    const amountV = q('amount-v')
    const title = q('title')
    const titleV = q('title-v')
    const sug = q('sug')
    const save = q('save')

    // Callout lines follow their target until the next chapter, and a display:none
    // target measures 0x0 (the line would jump to the window corner). So the two
    // callouts point at invisible anchors that glide with what they describe:
    // the amount (chips -> step-2 box -> detail) and the motive (grid -> detail pill).
    const aAmount = q('a-amount')
    const aMotive = q('a-motive')
    const place = (anchor, el, pos, duration = 0) => {
      const v = (key) => () => boxIn(el, root)[key]
      tl.to(anchor, { left: v('left'), top: v('top'), width: v('width'), height: v('height'), duration, ease: 'power2.inOut' }, pos)
    }
    place(aAmount, root.querySelector('[data-chips]'), 0.05)

    k.reveal(tl, '[data-k="step"], [data-k="f"]', { stagger: 0.035, duration: 0.4, y: 10 })

    // 1. amount: type digits (AmountField groups them), then the '+50.000 ₫' ActionChip
    //    adds to the current value: 339.000 + 50.000 = 389.000
    k.tap(tl, amount, {
      pos: 0.25,
      then: () => {
        amount.classList.add('is-focused')
        amountV.classList.add('is-typing')
      },
    })
    typeDigits(tl, amount, amountV, '339000', { pos: '-=0.15', cps: 15 })
    k.callout(tl, aAmount, 'Nhập nhanh trong vài giây', { pos: '+=0.08' })
    k.tap(tl, '[data-k="add50"]', { pos: '<', then: () => (amountV.textContent = '389.000') })

    // 2. title: label floats (focused label = colorScheme.primary), counter counts.
    //    Tapped right of the text so the finger does not hide what is typed.
    tl.addLabel('tTitle', '+=0.02')
    k.tap(tl, title, {
      pos: 'tTitle',
      anchor: [0.82, 0.5],
      then: () => {
        amount.classList.remove('is-focused')
        amountV.classList.remove('is-typing')
        title.classList.add('is-focused')
        titleV.classList.add('is-typing')
      },
    })
    tl.to(q('title-l'), { top: 0, fontSize: 12, color: '#ffde02', duration: 0.18, ease: 'power2.out' }, 'tTitle+=0.55')
    typeText(tl, titleV, q('title-c'), 'Tai nghe Bluetooth', { pos: 'tTitle+=0.66', cps: 30 })

    // 3. 600 ms after typing stops the keyword rule ('tai nghe' -> tech) offers
    //    'Gợi ý nhóm: Công nghệ'; the dropdown changes only when the chip is tapped
    tl.to(sug, { height: 56, opacity: 1, duration: 0.2, ease: 'power2.out' }, '+=0.6')
    tl.addLabel('tSug', '+=0.12')
    k.tap(tl, '[data-k="sug-chip"]', { pos: 'tSug', anchor: [0.09, 0.5], then: () => (q('group-v').textContent = 'Công nghệ') })
    tl.to(sug, { height: 0, opacity: 0, duration: 0.15, ease: 'power2.inOut' }, 'tSug+=0.62')

    // 4. 'Tiếp tục' -> step 2 (same Scaffold, setState)
    tl.addLabel('tNext', 'tSug+=0.95')
    k.tap(tl, q('next'), { pos: 'tNext' })
    const swap = 'tNext+=0.62'
    tl.set([q('s1'), q('step1'), q('next')], { display: 'none' }, swap)
    tl.set([q('s2'), q('step2'), save], { display: '' }, swap)
    tl.set(q('help'), { visibility: 'visible' }, swap)
    tl.fromTo([q('s2'), q('step2')], { opacity: 0 }, { opacity: 1, duration: 0.2, ease: 'power1.out' }, swap)
    place(aAmount, q('m-amount'), 'tNext+=0.64', 0.35)
    place(aMotive, q('grid'), 'tNext+=0.64')
    k.callout(tl, aMotive, '8 động cơ mua', { pos: 'tNext+=0.75' })

    // 5. pick 'Khuyến mãi' instead of the default 'Cảm xúc'
    k.tap(tl, '[data-mt="sale"]', {
      pos: 'tNext+=0.9',
      then: () => {
        root.querySelector('[data-mt="emotion"]').classList.remove('is-sel')
        root.querySelector('[data-mt="sale"]').classList.add('is-sel')
      },
    })

    // 6. save: spinner, SnackBar 'Đã lưu khoản mua.', route replaced by 'Chi tiết khoản mua'
    tl.addLabel('tSave', '+=0.05')
    k.tap(tl, save, { pos: 'tSave', then: () => save.classList.add('is-loading') })
    k.lift(tl, 'tSave+=0.85')
    k.snack(tl, '.wib-snackbar', { pos: 'tSave+=1.15' })
    k.page(tl, q('form'), q('detail'), { pos: 'tSave+=1.2' })
    place(aAmount, q('d-amount'), 'tSave+=1.22', 0.4)
    place(aMotive, q('d-motive'), 'tSave+=1.22', 0.4)
  },
}

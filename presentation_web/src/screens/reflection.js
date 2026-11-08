// Chiêm nghiệm tháng (lib/screens/monthly_reflection_screen.dart) + PDF report
// (services/report_service.dart, report_share_service.dart). The PDF is built on
// the device with the `pdf` package and handed to the Android share sheet through
// Printing.sharePdf: nothing is uploaded (decision D7, no Cloud Storage).
import { html, icon, appBar, button, MOTIVES } from './kit.js'

// Demo month 11/2026 (DemoDataService seeded Sat 07/11/2026).
// Summary shares the Góc nhìn report; this AI wording only reuses allowed numbers.
const SUMMARY = 'Tháng 11/2026 bạn ghi 11 khoản mua, tổng 1.589.000 ₫, nhiều nhất là Nhu cầu (27%). Bạn cũng đã cân nhắc và quyết định không mua 1 món. Nhìn lại, khoản nào khiến bạn thấy hài lòng nhất?'
const COUNTS = { need: 3, want: 1, sale: 2, emotion: 1, social: 1, convenience: 1, ads: 1, other: 1 }
const GOAL = 'Để ý những lần mua sau 22h và chờ một ngày trước khi đặt.'

// PDF table: purchases of the month sorted by date (seed spread over 01..07/11)
const ROWS = [
  ['01/11/2026', 'Cơm tấm', '40.000 ₫', 'Tiện lợi'],
  ['01/11/2026', 'Tai nghe Bluetooth', '389.000 ₫', 'Khuyến mãi'],
  ['02/11/2026', 'Trà sữa nướng', '45.000 ₫', 'Cảm xúc'],
  ['03/11/2026', 'Sách Tâm lý học về tiền', '143.000 ₫', 'Mong muốn'],
  ['03/11/2026', 'Áo khoác gió', '200.000 ₫', 'Khuyến mãi'],
  ['04/11/2026', 'Bình giữ nhiệt 500ml', '185.000 ₫', 'Nhu cầu'],
  ['04/11/2026', 'Kem chống nắng', '265.000 ₫', 'Quảng cáo'],
  ['05/11/2026', 'Cà phê sáng', '35.000 ₫', 'Nhu cầu'],
  ['05/11/2026', 'Vé xem phim cùng bạn', '120.000 ₫', 'Ảnh hưởng MXH'],
  ['06/11/2026', 'Ốp lưng điện thoại', '99.000 ₫', 'Khác'],
  ['07/11/2026', 'Bút và sổ tay', '68.000 ₫', 'Nhu cầu'],
]

const STYLE = `
.scr-ref,.scr-ref *,.scr-ref *::before,.scr-ref *::after{box-sizing:border-box}
.scr-ref .scr-ref__head{padding:20px;border-radius:16px;background:var(--primary-container);border:1px solid var(--primary)}
.scr-ref .scr-ref__box{padding:16px;border-radius:12px;background:var(--surface);border:1px solid var(--divider)}
.scr-ref .scr-ref__mchip{display:inline-flex;align-items:center;gap:6px;padding:8px 12px;border-radius:12px;background:var(--mb);color:var(--m);border:1px solid color-mix(in srgb,var(--m) 30%,transparent);font-size:12px;font-weight:600;line-height:1.35}
.scr-ref .scr-ref__mchip .mi{font-size:16px}
.scr-ref .scr-ref__rate{flex:none;width:38px;height:38px;margin:5px 0;display:grid;place-items:center;border-radius:50%;background:var(--surface-variant);box-shadow:inset 0 0 0 1px var(--divider);font-size:14px;font-weight:600;transition:background .15s ease,box-shadow .15s ease}
.scr-ref .scr-ref__rate.is-on{background:var(--primary);box-shadow:none}
.scr-ref .scr-ref__input{height:calc(4.35em + 32px);padding:16px;overflow:hidden;border-radius:12px;background:var(--surface);box-shadow:inset 0 0 0 1px var(--divider);font-size:16px;line-height:1.45;transition:box-shadow .15s ease}
.scr-ref .scr-ref__input.is-focused{box-shadow:inset 0 0 0 1.5px var(--text)}
.scr-ref .scr-ref__goal{display:block}
.scr-ref .wib-btn--primary.is-loading{background:rgba(255,222,2,.5)}
.scr-ref .wib-btn--secondary.is-disabled{background:var(--surface);color:rgba(15,23,42,.5)}
.scr-ref .scr-ref__goal:empty::before{content:attr(data-hint);color:var(--hint);font-size:14px}
.scr-ref .scr-ref__scrim{position:absolute;inset:0;z-index:30;background:rgba(0,0,0,.32);opacity:0}
.scr-ref .scr-ref__share{position:absolute;left:0;right:0;bottom:0;z-index:31;padding:10px 20px 34px;border-radius:28px 28px 0 0;background:#f7f8fb;font-family:Roboto,system-ui,sans-serif;color:#1b1c1f;transform:translateY(110%)}
.scr-ref .scr-ref__thumb{flex:none;width:74px;height:105px;border-radius:4px;overflow:hidden;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.18),0 0 0 1px rgba(0,0,0,.06)}
.scr-ref .scr-ref__a4{width:595px;height:842px;padding:32px;position:relative;background:#fff;color:#000;font-family:'Be Vietnam Pro',sans-serif;font-size:12px;line-height:1.35;transform:scale(.1244);transform-origin:0 0}
.scr-ref .scr-ref__a4 table{width:100%;margin-top:8px;border-collapse:collapse;table-layout:fixed}
.scr-ref .scr-ref__a4 td{padding:5px;border:1px solid #000}
.scr-ref .scr-ref__a4 li{margin:4px 0 0 14px}
.scr-ref .scr-ref__app{display:flex;flex-direction:column;align-items:center;gap:8px;width:64px;font-size:12px;text-align:center;color:#44474e}
.scr-ref .scr-ref__app>span:first-child{width:52px;height:52px;display:grid;place-items:center;border-radius:50%;color:#fff}
`

const motiveCount = (key) => {
  const m = MOTIVES[key]
  return `<span class="scr-ref__mchip" data-motive="${key}" data-k="mchip">${icon(m.icon)}${m.label}: ${COUNTS[key]}</span>`
}

/** the A4 page of report_service.dart, scaled down as a thumbnail */
const pdfPage = () => html`<div class="scr-ref__a4">
  <div style="display:flex;justify-content:space-between;align-items:center;padding:16px;border-radius:8px;background:#FFDE02;color:#070E20">
    <b style="font-size:18px">WHY I BUY – CHIÊM NGHIỆM THÁNG</b><span>Tháng 11/2026</span>
  </div>
  <div style="margin-top:20px;font-size:14px;font-weight:700">Người dùng: Minh Anh</div>
  <div style="margin:12px 0;height:1px;background:#9e9e9e"></div>
  <div style="font-size:14px;font-weight:700">Tổng quan tháng</div>
  <ul style="margin-top:4px">
    <li>Số khoản mua đã ghi: 11</li><li>Tổng đã chi: 1.589.000 ₫</li><li>Món đã quyết định mua: 1</li>
    <li>Món đã quyết định không mua: 1</li><li>Giá trị món đã quyết định không mua: tổng giá đã ghi 799.000 ₫</li>
  </ul>
  <div style="margin-top:20px;font-size:14px;font-weight:700">Khoản mua trong tháng</div>
  <table>
    <colgroup><col style="width:70px" /><col style="width:60%" /><col style="width:90px" /><col style="width:40%" /></colgroup>
    <tr style="background:#eee;font-weight:700"><td>Ngày</td><td>Tên</td><td>Số tiền</td><td>Động cơ</td></tr>
    ${ROWS.map((r) => `<tr><td>${r[0]}</td><td>${r[1]}</td><td style="text-align:right">${r[2]}</td><td>${r[3]}</td></tr>`)}
  </table>
  <div style="position:absolute;right:32px;bottom:32px;font-size:9px;color:#757575">Trang 1/1</div>
</div>`

const shareApp = (ic, label, bg) => `<span class="scr-ref__app"><span style="background:${bg}">${ic}</span><span>${label}</span></span>`

export default {
  id: 'reflection',
  render() {
    return html`
      <div class="wib-screen scr-ref">
        <style>${STYLE}</style>
        ${appBar({ title: 'Chiêm nghiệm tháng' })}
        <div class="wib-body" data-k="body">
          <div class="wib-scroll" data-k="scroll" style="padding-bottom:28px">
            <div class="scr-ref__head" data-k="head">
              <div class="wib-row">
                <span class="t-title-m" style="flex:1">Tháng 11/2026</span>
                <span class="wib-ai-chip" style="padding:3px 8px;line-height:1.35">${icon('auto_awesome', 12)}AI</span>
              </div>
              <div data-k="total" style="margin-top:12px;font-size:24px;font-weight:800;line-height:1.3">1.589.000 ₫</div>
              <div class="t-body-m">Tổng đã chi từ 11 khoản mua bạn đã ghi</div>
              <div style="margin-top:16px;font-size:16px;line-height:1.5">${SUMMARY}</div>
            </div>
            <div class="scr-ref__box t-body-m" data-k="note" style="margin-top:16px">Tháng này bạn đã cân nhắc và không mua 1 món, tổng giá đã ghi 799.000 ₫.</div>

            <div data-k="motives" style="margin-top:24px">
              <div class="t-title-l">Phân bổ 8 động cơ mua sắm</div>
              <div class="t-body-m" style="margin-top:8px">Số khoản mua trong tháng theo động cơ bạn đã ghi:</div>
              <div style="display:flex;flex-wrap:wrap;gap:8px;margin-top:16px">
                ${Object.keys(MOTIVES).map(motiveCount)}
              </div>
            </div>

            <div class="scr-ref__box" data-k="rating" style="margin-top:32px">
              <div class="t-title-m">Mức độ hài lòng của bạn</div>
              <div class="wib-row" style="justify-content:space-between;margin-top:12px;padding:0 2px">
                ${[1, 2, 3, 4, 5].map((n) => `<span class="scr-ref__rate" data-k="rate${n}">${n}</span>`)}
              </div>
              <div class="wib-row t-label-m" style="justify-content:space-between;margin-top:8px"><span>Không hài lòng</span><span>Rất hài lòng</span></div>
            </div>

            <div class="scr-ref__box" data-k="goalbox" style="margin-top:12px">
              <div class="t-title-m">Mục tiêu cho tháng 12</div>
              <div class="scr-ref__input" data-k="input" style="margin-top:12px">
                <span class="scr-ref__goal" data-k="goal" data-hint="Một điều bạn muốn để ý trong tháng 12"></span>
              </div>
              <div class="t-label-m" data-k="counter" style="margin-top:4px;padding-right:16px;text-align:right;font-weight:400">0/200</div>
            </div>

            <div style="margin-top:12px">${button('Lưu chiêm nghiệm', { icon: icon('check', 20), cls: 'is-disabled', attrs: 'data-k="save"' })}</div>

            <div data-k="pdf" style="margin-top:16px">
              <div class="t-title-l">Báo cáo PDF</div>
              <div class="t-body-m" style="margin-top:8px">Báo cáo tháng 11/2026 được tạo ngay trên máy. Bạn chọn ứng dụng để lưu hoặc gửi.</div>
              <div style="margin-top:16px">${button('Xuất và chia sẻ PDF', { icon: icon('ios_share', 20), attrs: 'data-k="export"' })}</div>
              <div style="margin-top:8px">${button('Xem trước', { icon: icon('visibility_outlined', 20), variant: 'secondary', attrs: 'data-k="preview"' })}</div>
            </div>
          </div>
        </div>

        <div class="scr-ref__scrim" data-k="scrim"></div>
        <div class="scr-ref__share" data-k="share">
          <div style="width:32px;height:4px;margin:0 auto 18px;border-radius:2px;background:#c4c6cf"></div>
          <div class="wib-row" style="gap:14px;padding:12px;border-radius:16px;background:#fff">
            <div class="scr-ref__thumb" data-k="thumb">${pdfPage()}</div>
            <div style="font-size:14px;font-weight:500;line-height:1.35;word-break:break-all">why-i-buy_2026-11.pdf</div>
          </div>
          <div class="wib-row" style="justify-content:space-between;margin-top:22px;padding:0 4px">
            ${shareApp(icon('mail_outline', 24), 'Email', '#5b7bd5')}
            ${shareApp(icon('sms_outlined', 24), 'Tin nhắn', '#3e9e6e')}
            ${shareApp(icon('folder_outlined', 24), 'Tệp', '#c98a2b')}
            ${shareApp(icon('bluetooth', 24), 'Bluetooth', '#6b7280')}
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    // 1. month summary: total, reflection paragraph with source chip, 8 motives
    k.reveal(tl, '[data-k="head"], [data-k="note"], [data-k="motives"]', { stagger: 0.08, pos: 0 })
    k.count(tl, '[data-k="total"]', 1589000, { pos: 0.15, duration: 1 })
    tl.fromTo(k.qa('[data-k="mchip"]'), { opacity: 0, scale: 0.8 }, { opacity: 1, scale: 1, duration: 0.35, stagger: 0.04, ease: 'back.out(2)' }, 0.4)

    // 2. scroll to the end: rating + goal form and the PDF section all fit in one view.
    //    translate(-100%) + body height = bottom of the page, resolved live by the browser
    //    (independent of when the web fonts finish loading)
    tl.to(k.q('[data-k="scroll"]'), { yPercent: -100, y: () => k.q('[data-k="body"]').clientHeight, duration: 0.8, ease: 'power3.inOut' }, 1.15)

    // 3. rating 4 -> 'Lưu chiêm nghiệm' becomes enabled
    k.tap(tl, '[data-k="rate4"]', {
      pos: 1.9,
      then: (el) => {
        el.classList.add('is-on')
        k.q('[data-k="save"]').classList.remove('is-disabled')
      },
    })
    k.callout(tl, '[data-k="rate4"]', 'Tự chấm mức hài lòng 1–5', { pos: 2.45 })

    // 4. goal for next month, counter follows the text
    const input = k.q('[data-k="input"]')
    k.tap(tl, input, { pos: '+=0.05', anchor: [0.3, 0.35], then: () => input.classList.add('is-focused') })
    typeGoal(tl, k.q('[data-k="goal"]'), k.q('[data-k="counter"]'), GOAL, 48)

    // 5. export: spinner while the PDF renders on the device ('Xem trước' disabled
    //    meanwhile, AppButton isLoading), then the system share sheet (Printing.sharePdf)
    const exp = k.q('[data-k="export"]')
    const preview = k.q('[data-k="preview"]')
    k.tap(tl, exp, {
      pos: '+=0.2',
      then: () => {
        input.classList.remove('is-focused')
        exp.classList.add('is-loading')
        preview.classList.add('is-disabled')
      },
    })
    k.lift(tl, '+=0.05')
    k.cls(tl, exp, 'is-loading', false, '+=0.3')
    k.cls(tl, preview, 'is-disabled', false, '<')
    tl.to(k.q('[data-k="scrim"]'), { opacity: 1, duration: 0.3, ease: 'power2.out' }, '<')
    tl.fromTo(k.q('[data-k="share"]'), { y: 0, yPercent: 110 }, { yPercent: 0, duration: 0.5, ease: 'power3.out', immediateRender: false }, '<')
    k.callout(tl, '[data-k="thumb"]', 'PDF tạo trên máy, không upload', { pos: '+=0.05' })
    k.wait(tl, 0.9)
  },
}

/** k.type() plus the TextField counter '{len}/200' */
function typeGoal(tl, el, counter, text, cps = 36) {
  const s = { n: 0 }
  tl.call(() => el.classList.add('is-typing'), null, '+=0.05')
  tl.to(s, {
    n: text.length,
    duration: text.length / cps,
    ease: 'none',
    onUpdate: () => {
      const n = Math.round(s.n)
      el.textContent = text.slice(0, n)
      counter.textContent = `${n}/200`
    },
  }, '>')
  tl.call(() => el.classList.remove('is-typing'), null, '>+=0.15')
}

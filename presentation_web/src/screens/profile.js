// Cá nhân (lib/screens/profile_screen.dart): one long scroll. Account card,
// linked accounts/devices, theme, settings groups, then the FIREBASE DEMO AREA
// (Remote Config values + Live Fetch, FCM Center with the on-device inbox).
// Release-build view: the debug-only 'Khu trình diễn' card and 'Widget Gallery'
// button are not shown, nor the admin-only price sample card.
import gsap from 'gsap'
import { html, icon, appBar, bottomNav, button, section } from './kit.js'

const STYLE = `<style>
.scr-profile, .scr-profile *, .scr-profile *::before, .scr-profile *::after { box-sizing: border-box; }
.scr-profile .wib-scroll { position: relative; padding-bottom: 24px; }
.scr-profile .p-tile { display: flex; align-items: center; gap: 16px; min-height: 56px; padding: 8px 0; }
.scr-profile .p-tile__lead { flex: none; display: grid; place-items: center; width: 24px; }
.scr-profile .p-tile__main { flex: 1; min-width: 0; }
.scr-profile .p-tile__title { font-size: 16px; font-weight: 600; line-height: 1.4; }
.scr-profile .p-tile__title--reg { font-weight: 400; }
.scr-profile .p-tile__sub { font-size: 14px; line-height: 1.45; color: var(--text-2); }
.scr-profile .p-textbtn { flex: none; display: inline-flex; align-items: center; min-height: 40px; padding: 0 12px; font-size: 14px; font-weight: 600; color: var(--text); white-space: nowrap; }
.scr-profile .p-textbtn.is-off { color: rgba(15, 23, 42, .38); }
.scr-profile .p-outlined { display: flex; align-items: center; justify-content: center; gap: 8px; width: 100%; min-height: 48px; padding: 12px 24px; border-radius: 999px; box-shadow: inset 0 0 0 1.5px var(--outline); font-size: 14px; font-weight: 600; line-height: 1.4; color: var(--text); background: transparent; }
.scr-profile .p-outlined .mi { font-size: 18px; }
.scr-profile .p-label { padding-bottom: 8px; font-size: 12px; font-weight: 500; line-height: 1.35; letter-spacing: .4px; color: var(--text-2); }
.scr-profile .p-group { background: var(--surface); border: 1px solid var(--divider); border-radius: 16px; overflow: hidden; }
.scr-profile .p-group__div { height: 1px; margin: 0 16px; background: var(--divider); }
.scr-profile .p-stile { display: flex; align-items: center; gap: 16px; min-height: 64px; padding: 12px 16px; }
.scr-profile .p-stile .mi { font-size: 24px; }
.scr-profile .p-switch { flex: none; position: relative; width: 52px; height: 32px; border-radius: 999px; background: var(--surface-variant); box-shadow: inset 0 0 0 2px var(--outline); }
.scr-profile .p-switch__thumb { position: absolute; left: 8px; top: 8px; width: 16px; height: 16px; border-radius: 50%; background: var(--outline); display: grid; place-items: center; }
.scr-profile .p-switch--icon .p-switch__thumb { left: 4px; top: 4px; width: 24px; height: 24px; background: var(--primary); color: var(--on-primary); }
.scr-profile .p-switch--icon .p-switch__thumb .mi { font-size: 16px; }
.scr-profile .p-kv { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
.scr-profile .p-kv__k { flex: 1; min-width: 0; font-size: 14px; line-height: 1.45; color: var(--text-2); }
.scr-profile .p-kv__v { flex: none; padding: 1px 6px; margin-right: -6px; border-radius: 6px; font-size: 14px; font-weight: 600; line-height: 1.4; white-space: nowrap; }
.scr-profile .p-snack-fixed { left: 0; right: 0; bottom: 78px; border-radius: 0; padding: 14px 16px; box-shadow: none; }
.scr-profile .p-snack-fcm { align-items: center; padding: 10px 8px 10px 16px; }
.scr-profile .p-snack-fcm__t { font-size: 16px; font-weight: 600; line-height: 1.4; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.scr-profile .p-snack-fcm__b { font-size: 14px; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.scr-profile .p-perm { z-index: 31; left: 28px; right: 28px; padding: 24px 20px 20px; border-radius: 28px; background: #fff; text-align: center; }
.scr-profile .p-perm__btn { display: block; padding: 14px 12px; background: #e9eef6; color: #1f1f1f; font-size: 15px; font-weight: 500; line-height: 1.3; }
.scr-profile .p-perm-scrim { z-index: 30; }
</style>`

/** ListTile with zero content padding (Tài khoản liên kết, theme, devices, inbox) */
const tile = ({ lead = '', title = '', sub = '', trail = '', reg = false, cls = '', attrs = '' }) => html`
  <div class="p-tile ${cls}" ${attrs}>
    ${lead ? `<span class="p-tile__lead">${lead}</span>` : ''}
    <div class="p-tile__main">
      <div class="p-tile__title ${reg ? 'p-tile__title--reg' : ''}">${title}</div>
      ${sub}
    </div>
    ${trail}
  </div>`

/** _SettingsTile: min height 64, chevron_right_rounded in the title colour */
const settingsTile = (title, sub = '', { danger = false, cls = '' } = {}) => html`
  <div class="p-stile ${cls}" style="${danger ? 'color:var(--error)' : ''}">
    <div style="flex:1;min-width:0">
      <div class="p-tile__title">${title}</div>
      ${sub ? `<div class="p-tile__sub">${sub}</div>` : ''}
    </div>
    ${icon('chevron_right_rounded')}
  </div>`

/** _buildKeyValueRow of the Remote Config card */
const kv = (k, v, cls = '') => html`<div class="p-kv"><span class="p-kv__k">${k}</span><span class="p-kv__v ${cls}">${v}</span></div>`

/** one row of 'Hộp thư nhận thông báo' (no timestamp in the app) */
const inboxRow = (title, body, opened = false) =>
  tile({
    lead: `<span style="color:var(--info)">${icon('mark_email_unread_outlined')}</span>`,
    title,
    sub: html`<div class="p-tile__sub">${body}</div>${opened ? '<div class="t-caption">Đã mở</div>' : ''}`,
  })

// FCM test messages sent from the Firebase Console (wording illustrative; the
// data keys type / sale_type / sale_id are the ones the app routes on).
const MSG_REVIEW = {
  title: 'Đến hẹn xem lại',
  body: 'Có món đã đến hẹn xem lại. Mua, Chờ hay Bỏ qua đều được.',
  data: { type: 'review' },
}
const MSG_SALE = {
  title: 'Nhắc đợt sale 11.11',
  body: 'Còn 4 ngày nữa là 11.11. Bạn có 4 món đang cân nhắc, mở xem nhé?',
  data: { type: 'sale', sale_type: 'double_day', sale_id: '2026-11-11' },
}

/** y offset of `el` inside the scroll content (layout based, ignores 3D transforms) */
function offsetIn(el, container) {
  let y = 0
  let n = el
  while (n && n !== container) {
    y += n.offsetTop
    n = n.offsetParent
  }
  return y
}

export default {
  id: 'profile',
  render() {
    return html`
      <div class="wib-screen scr-profile">
        ${STYLE}
        ${appBar({ back: 'chevron', title: 'Cá nhân', logoSize: 26, strong: true, actions: `<span class="wib-iconbtn" style="margin-right:4px">${icon('logout_rounded')}</span>` })}
        <div class="wib-body" data-k="body">
          <div class="wib-scroll" data-k="scroll">
            <!-- AccountHeaderCard -->
            <div class="wib-card wib-row" data-k="account" style="gap:16px">
              <span style="flex:none;width:56px;height:56px;border-radius:50%;background:var(--primary);display:grid;place-items:center;font-size:20px;font-weight:600;color:var(--on-primary)">M</span>
              <div style="flex:1;min-width:0">
                <div class="t-title-m">Minh Anh</div>
                <div class="t-body-m">m…@gmail.com</div>
              </div>
            </div>
            <div style="height:16px"></div>

            ${section({
              title: 'Tài khoản liên kết',
              icon: icon('link_rounded'),
              cls: 'p-linked',
              body: html`
                ${tile({
                  lead: icon('g_mobiledata'),
                  title: 'Google',
                  sub: '<div class="p-tile__sub">Đã liên kết · m…@gmail.com</div><div class="p-tile__sub">Phải giữ ít nhất một cách đăng nhập.</div>',
                  trail: '<span class="p-textbtn is-off">Huỷ liên kết</span>',
                })}
                ${tile({ lead: icon('code_rounded'), title: 'GitHub', trail: '<span class="p-textbtn">Liên kết</span>' })}`,
            })}
            <div style="height:16px"></div>

            ${section({
              title: 'Thiết bị đã liên kết',
              icon: icon('computer_rounded'),
              cls: 'p-devices',
              body: html`
                <span class="p-outlined">${icon('qr_code_scanner_rounded')}Quét mã QR</span>
                ${tile({
                  lead: `<span style="color:var(--text-2)">${icon('laptop_chromebook_rounded')}</span>`,
                  title: 'Chrome',
                  reg: true,
                  sub: '<div class="t-caption">Liên kết ngày 07/11/2026</div>',
                  trail: '<span class="p-textbtn">Huỷ liên kết</span>',
                })}`,
            })}
            <div style="height:16px"></div>

            ${section({
              title: 'Giao diện ứng dụng',
              icon: icon('palette_outlined'),
              cls: 'p-theme',
              body: tile({
                lead: `<span style="color:var(--primary)">${icon('light_mode_rounded')}</span>`,
                title: 'Chế độ tối',
                reg: true,
                trail: `<span class="p-switch p-switch--icon"><span class="p-switch__thumb">${icon('light_mode_rounded')}</span></span>`,
              }),
            })}
            <div style="height:16px"></div>

            <div data-k="g-remind">
              <div class="p-label">CÀI ĐẶT NHẮC NHỞ</div>
              <div class="p-group">
                <div class="p-stile" style="padding:12px 16px">
                  <div style="flex:1;min-width:0">
                    <div class="p-tile__title">Nhắc ghi khoản mua</div>
                    <div class="p-tile__sub">Nhắc bạn ghi lại khoản mua lúc 21:00 mỗi tối. Chạm để đổi giờ.</div>
                  </div>
                  <span class="p-switch"><span class="p-switch__thumb"></span></span>
                </div>
              </div>
            </div>
            <div style="height:16px"></div>

            <div data-k="g-data">
              <div class="p-label">CÀI ĐẶT DỮ LIỆU</div>
              <div class="p-group">
                ${settingsTile('Xuất dữ liệu', 'Tải bản sao nhật ký và động cơ dưới dạng CSV', { cls: 'p-export' })}
                <div class="p-group__div"></div>
                ${settingsTile('Xóa toàn bộ dữ liệu', '<span style="color:var(--text-2)">Xóa vĩnh viễn mọi khoản mua đã ghi.</span>', { danger: true })}
              </div>
            </div>
            <div style="height:16px"></div>
            <div class="wib-row" data-k="privacy" style="align-items:flex-start;gap:12px;padding:0 16px">
              <span style="color:var(--text-2)">${icon('shield_outlined', 20)}</span>
              <span class="t-body-m">Dữ liệu được lưu trên máy và đồng bộ với tài khoản của bạn khi có mạng.</span>
            </div>
            <div style="height:24px"></div>

            <div data-k="g-support">
              <div class="p-label">HỖ TRỢ &amp; THÔNG TIN</div>
              <div class="p-group">
                ${settingsTile('Gửi góp ý', 'Báo lỗi hoặc đề xuất tính năng mới')}
                <div class="p-group__div"></div>
                ${settingsTile('Điều khoản sử dụng')}
                <div class="p-group__div"></div>
                ${settingsTile('Chính sách quyền riêng tư')}
              </div>
            </div>
            <div style="height:24px"></div>
            <span class="p-outlined">${icon('school_outlined', 20)}Xem màn hình giới thiệu (01 Onboarding)</span>
            <div style="height:24px"></div>

            <!-- FIREBASE DEMO AREA -->
            <span data-k="fb-pill" style="display:inline-block;padding:6px 12px;border-radius:999px;background:var(--primary-container);font-size:12px;font-weight:700;line-height:1.35">FIREBASE DEMO AREA</span>
            <div style="height:16px"></div>
            ${section({
              title: 'Ngân sách chi tiêu',
              icon: icon('account_balance_wallet_outlined'),
              body: html`<div style="font-size:13px;line-height:1.45;color:var(--text-2)">Thiết lập ngân sách tham chiếu theo tháng và theo nhóm hàng, tự động đồng bộ Firestore:</div>
                <div style="height:12px"></div>
                ${button('Quản lý ngân sách theo nhóm', { icon: icon('bar_chart_rounded') })}`,
            })}
            <div style="height:16px"></div>
            ${section({
              title: 'Hồ sơ mua sắm',
              icon: icon('inventory_2_outlined'),
              body: html`<div class="t-body-m">Ghi đồ đang dùng, phong cách và thương hiệu hay dùng để Thẻ Quyết Định nhắc khi bạn cân nhắc món cùng loại. Tất cả tùy chọn.</div>
                <div style="height:12px"></div>
                ${button('Mở hồ sơ mua sắm', { icon: icon('chevron_right_rounded'), variant: 'secondary' })}`,
            })}
            <div style="height:16px"></div>
            ${section({
              title: 'Dữ liệu demo',
              icon: icon('dataset_outlined'),
              body: html`<div class="t-body-m">Tạo khoảng 20 khoản mua, 6 món mong muốn, ngân sách tháng này và chiêm nghiệm tháng trước để thử các màn hình.</div>
                <div style="height:12px"></div>
                ${button('Tạo lại dữ liệu demo', { icon: icon('auto_awesome_motion_outlined') })}`,
            })}
            <div style="height:16px"></div>

            ${section({
              title: '1. Firebase Remote Config',
              icon: icon('tune'),
              cls: 'p-rc',
              body: html`
                <div class="p-rc-rows">
                  ${kv('Thời gian hoãn mua (cooling_off_days):', '3 ngày', 'p-cool')}
                  ${kv('Bật tính năng AI (enable_ai_insight):', 'Bật (True)')}
                  ${kv('Số món tối đa (max_wishlist_items):', '20 món')}
                  ${kv('Nhắc nhở đợt sale (sale_reminder_enabled):', 'Bật (True)')}
                </div>
                <div style="height:12px"></div>
                ${button('Cập nhật Remote Config (Live Fetch)', { variant: 'secondary', cls: 'p-fetch' })}`,
            })}
            <div style="height:16px"></div>

            ${section({
              title: '2. Cloud Messaging (FCM) Center',
              icon: icon('notifications_active_outlined'),
              cls: 'p-fcm',
              body: html`
                <span class="p-outlined p-perm-btn">${icon('notifications_outlined')}Bật thông báo</span>
                <div class="t-body-m p-perm-on" style="display:none">Đã bật thông báo cho ứng dụng.</div>
                <div style="height:12px"></div>
                <div class="t-label-l p-inbox-head">Hộp thư nhận thông báo (1 tin nhắn):</div>
                <div style="height:8px"></div>
                <div class="p-inbox">
                  <div class="p-new" style="display:none;overflow:hidden">
                    ${inboxRow(MSG_SALE.title, MSG_SALE.body)}
                    <div class="wib-divider"></div>
                  </div>
                  ${inboxRow(MSG_REVIEW.title, MSG_REVIEW.body)}
                </div>`,
            })}
            <div style="height:24px"></div>
            ${button('Đăng xuất tài khoản', { icon: icon('logout'), variant: 'secondary' })}
            <div style="height:16px"></div>
            <div class="t-caption" style="text-align:center">Phiên bản 1.0.0</div>
          </div>
        </div>
        ${bottomNav('profile')}

        <!-- SnackBar of Live Fetch (not floating: full width above the nav) -->
        <div class="wib-snackbar p-snack-fixed" data-k="snack-rc"><span class="wib-snackbar__text">Đã cập nhật cấu hình Remote Config mới nhất từ Firebase.</span></div>
        <!-- foreground FCM message (AppLifecycleBridge): floating, action 'Xem' for type sale -->
        <div class="wib-snackbar p-snack-fcm" data-k="snack-fcm">
          <span class="wib-snackbar__text"><span class="p-snack-fcm__t" style="display:block">${MSG_SALE.title}</span><span class="p-snack-fcm__b">${MSG_SALE.body}</span></span>
          <span class="wib-snackbar__action">Xem</span>
        </div>

        <!-- Android 13+ POST_NOTIFICATIONS dialog, raised by FirebaseMessaging.requestPermission() -->
        <div class="wib-scrim p-perm-scrim" data-k="perm-scrim"></div>
        <div class="wib-dialog p-perm" data-k="perm">
          <span style="color:#1a73e8">${icon('notifications_rounded', 26)}</span>
          <div style="margin:14px 4px 20px;font-size:20px;line-height:1.35;color:#1f1f1f">Cho phép <b style="font-weight:600">Why I Buy</b> gửi thông báo cho bạn?</div>
          <div style="display:flex;flex-direction:column;gap:3px">
            <span class="p-perm__btn" data-k="perm-allow" style="border-radius:20px 20px 4px 4px">Cho phép</span>
            <span class="p-perm__btn" style="border-radius:4px 4px 20px 20px">Không cho phép</span>
          </div>
        </div>
      </div>`
  },

  demo(tl, root, k) {
    const scroll = k.q('[data-k="scroll"]')
    const body = k.q('[data-k="body"]')
    const max = () => Math.max(0, scroll.offsetHeight - body.clientHeight)
    const clamp = (y) => Math.min(max(), Math.max(0, y))
    const scrollTo = (yFn, pos, duration = 0.85) =>
      tl.to(scroll, { y: () => -clamp(yFn()), duration, ease: 'power3.inOut' }, pos)
    const rc = k.q('.p-rc')
    const rows = k.q('.p-rc-rows')
    const cool = k.q('.p-cool')
    const fetch = k.q('.p-fetch')
    const snackRc = k.q('[data-k="snack-rc"]')
    const snackFcm = k.q('[data-k="snack-fcm"]')
    const fresh = k.q('.p-new')

    // 1. Top of the tab: account card (masked email), linked accounts, devices
    k.reveal(tl, '[data-k="account"], .p-linked, .p-devices', { stagger: 0.08 })

    // 2. Settings: theme, daily reminder 21:00, CSV export, delete data
    scrollTo(() => offsetIn(k.q('.p-theme'), scroll) - 12, 0.7)

    // 3. Remote Config card: tap Live Fetch -> spinner -> new value + SnackBar
    scrollTo(() => offsetIn(rc, scroll) - 12, 2.0, 0.9)
    k.tap(tl, fetch, { pos: 2.9, then: () => fetch.classList.add('is-loading') })
    tl.addLabel('fetched', 3.95)
    tl.call(() => fetch.classList.remove('is-loading'), null, 'fetched')
    k.text(tl, cool, '5 ngày', 'fetched')
    tl.fromTo(cool, { backgroundColor: 'rgba(255,222,2,0.9)' }, { backgroundColor: 'rgba(255,222,2,0)', duration: 1.6, ease: 'power1.in', immediateRender: false }, 'fetched')
    k.snack(tl, snackRc, { pos: 'fetched' })
    k.callout(tl, rows, 'Đổi cấu hình, không cập nhật app', { pos: 'fetched+=0.1' })
    tl.to(snackRc, { opacity: 0, y: 16, duration: 0.3, ease: 'power2.in' }, 'fetched+=1.0')

    // 4. FCM Center: the permission is asked only from the tap on 'Bật thông báo'
    scrollTo(() => offsetIn(rows, scroll) - 4, 'fetched+=0.95', 0.7)
    k.tap(tl, '.p-perm-btn', { pos: 'fetched+=1.6' })
    k.dialog(tl, '[data-k="perm"]', { scrim: '[data-k="perm-scrim"]', pos: 'fetched+=2.25' })
    k.tap(tl, '[data-k="perm-allow"]', { pos: 'fetched+=2.7' })
    k.dialog(tl, '[data-k="perm"]', { scrim: '[data-k="perm-scrim"]', open: false, pos: 'fetched+=3.4' })
    tl.call(() => {
      k.q('.p-perm-btn').style.display = 'none'
      k.q('.p-perm-on').style.display = ''
    }, null, 'fetched+=3.5')
    k.lift(tl, 'fetched+=3.5')

    // 5. A push arrives while the app is open: SnackBar + new row on top of the inbox
    tl.addLabel('push', 'fetched+=3.95')
    k.snack(tl, snackFcm, { pos: 'push' })
    k.text(tl, '.p-inbox-head', 'Hộp thư nhận thông báo (2 tin nhắn):', 'push+=0.15')
    tl.set(fresh, { display: '' }, 'push+=0.15')
    tl.fromTo(fresh, { height: 0, opacity: 0 }, { height: 'auto', opacity: 1, duration: 0.45, ease: 'power3.out', immediateRender: false }, 'push+=0.15')
    // keep the new row above the SnackBar
    scrollTo(() => {
      const snackTop = snackFcm.offsetTop - body.offsetTop
      const want = offsetIn(fresh, scroll) + fresh.scrollHeight - snackTop + 8
      return Math.max(-gsap.getProperty(scroll, 'y'), want)
    }, 'push+=0.15', 0.45)
    k.callout(tl, '.p-inbox', 'Tin FCM: mở, nền, đã đóng', { pos: 'push+=0.4' })
    tl.to({}, { duration: 0.01 }, 'push+=1.0')
  },

  demos: {
    // static backdrop for 'Hệ sinh thái': top of the tab, no finger
    idle(tl, root, k) {
      k.reveal(tl, '[data-k="account"], .p-linked, .p-devices, .p-theme', { stagger: 0.08, pos: 0.4 })
    },
  },
}

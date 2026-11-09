/**
 * Left-hand visuals of the non-phone slides (guideline V11: Problem / Design / Proof).
 * Facts come from prm393_lab03/docs (data-model.md, architecture.md), lib/ and the evidence files.
 */
import { graph, table, tag } from './kit.js'
import { evidence, team } from '../data/chapters.js'

const lane = (id, y, title) => [
  { id: `${id}-band`, x: 0, y, w: 1000, h: 176, tone: 'group', z: 0 },
  { id: `${id}-lbl`, x: 12, y: y + 58, w: 84, h: 60, tone: 'muted', z: 1, title, cls: 'dg-lane' },
]

export const visuals = {
  problem: () => `
    <p class="vis-title">Pain point → nguyên nhân → hậu quả</p>
    ${table({
      cols: [{ label: 'Pain point', w: '1.05fr' }, { label: 'Nguyên nhân', w: '1.2fr' }, { label: 'Hậu quả', w: '1.1fr' }],
      rows: [
        ['Mua theo cảm xúc, theo sale', 'Flash sale, voucher sắp hết hạn, thông báo dồn dập tạo cảm giác gấp gáp', 'Mua món chưa cần; nhận ra khi đã thanh toán'],
        ['Không biết vì sao mình mua', 'App chi tiêu chỉ ghi số tiền, không ghi lý do mua', 'Không thấy mô hình lặp lại: mua đêm muộn, mua vì mạng xã hội'],
        ['Món muốn mua nằm rải rác', 'Link Shopee để trong giỏ hàng, tin nhắn, ảnh chụp màn hình', 'Quên giá đã thấy, mua trùng, không có chỗ để cân nhắc'],
      ],
    })}
    <p class="vis-note" style="margin-top:12px">Bối cảnh: sale ngày đôi 9.9 · 10.10 · 11.11 · 12.12, giữa tháng (15) và lương về (25) lặp lại quanh năm.</p>`,

  solution: () => `
    ${table({
      cols: [{ label: 'Pain point', w: '1fr' }, { label: 'Giải pháp trong app', w: '1.35fr' }, { label: 'Giá trị kỳ vọng', w: '1fr' }],
      rows: [
        ['Mua theo cảm xúc', 'Danh sách cân nhắc + thời gian hoãn mặc định 3 ngày; Mua · Chờ · Bỏ qua ngang hàng; bong bóng nhắc khi xem một món quá 15 giây', 'Có một khoảng dừng trước khi trả tiền, ngay trong app mua sắm'],
        ['Không biết vì sao mua', '8 động cơ mua gắn vào mọi món và khoản mua; Mô hình, Góc nhìn AI, Chiêm nghiệm', 'Thấy được mình mua vì đâu, lúc nào'],
        ['Món rải rác', 'Chia sẻ link Shopee vào app; bong bóng lưu link vừa sao chép; tiện ích Chrome lưu món, ghép với app bằng QR', 'Một chỗ duy nhất, có lịch sử giá'],
      ],
    })}
    <div class="vis-grid" style="grid-template-columns:1fr 1fr;margin-top:14px">
      <div class="vis-card"><span class="k">In-scope (MVP) · demo</span><h4>WF-01 · WF-02 · WF-03</h4><p>Lưu món và hoãn mua · Quyết định và ghi khoản mua · Nhìn lại cuối tháng. Kèm web admin cho staff/admin.</p></div>
      <div class="vis-card"><span class="k" style="color:#fca5a5">Out-of-scope</span><h4>Để giai đoạn sau</h4><p>Đọc giá từ ảnh chụp màn hình (OCR); lấy voucher, giá tự động từ sàn (sàn chặn bot); bản iOS chưa kiểm thử.</p></div>
    </div>`,

  actors: () =>
    table({
      cols: [{ label: 'Actor', w: '0.9fr' }, { label: 'Là ai', w: '1.25fr' }, { label: 'Quyền hạn chính', w: '1.45fr' }],
      rows: [
        [`Người dùng ${tag('role: user')}`, 'Người trẻ hay mua sắm online, dùng app Android', 'Lưu món, quyết định Mua · Chờ · Bỏ qua, ghi khoản mua, xem góc nhìn; chỉ dữ liệu của chính mình'],
        [`Nhân viên ${tag('role: staff', 'brand')}`, 'Người vận hành nội dung trên web admin', 'Quản lý sự kiện sale, duyệt đề xuất, đăng thông báo, nhắn tin riêng; lấy voucher Shopee bằng tiện ích, xem và xoá trên web'],
        [`Quản trị viên ${tag('role: admin', 'brand')}`, 'Người phụ trách hệ thống', 'Như staff + dashboard số liệu thật toàn hệ thống + đổi vai trò người khác'],
        [`Tiện ích Chrome ${tag('client')}`, 'Phần mở rộng trình duyệt của chính người dùng', 'Đăng nhập ẩn danh, ghép đôi bằng QR rồi ghi món vào danh sách của chủ tài khoản'],
        [`Firebase · Gemini ${tag('hệ thống ngoài', 'ok')}`, 'Dịch vụ Google Cloud', 'Xác thực, lưu trữ, gửi thông báo, cấu hình từ xa; Gemini chỉ viết lại câu chữ'],
        [`Push server ${tag('hệ thống ngoài', 'ok')}`, 'Spring Boot của nhóm', 'Gửi FCM hàng loạt; chỉ nhận yêu cầu có ID token của admin'],
      ],
    }),

  features: () => `
    <div class="vis-grid" style="grid-template-columns:1fr 1fr">
      <div class="vis-card"><span class="k">Nhóm 1 · WF-01</span><h4>Lưu & cân nhắc</h4><p>Chia sẻ từ Shopee · bong bóng nổi Android (xem lâu, sao chép link) · tiện ích Chrome + QR · danh sách mong muốn · thời gian hoãn · lịch sử giá</p></div>
      <div class="vis-card"><span class="k">Nhóm 2 · WF-02</span><h4>Quyết định & ghi chi</h4><p>Trước khi mua (thẻ quan sát + Gemini) · Mua · Chờ (lịch sale) · Bỏ qua (hoàn tác) · Ghi khoản mua 2 bước</p></div>
      <div class="vis-card"><span class="k">Nhóm 3 · WF-03</span><h4>Nhìn lại</h4><p>Ngân sách không chặn mua · Mô hình theo động cơ, khung giờ · Góc nhìn AI · Chiêm nghiệm + PDF</p></div>
      <div class="vis-card"><span class="k" style="color:var(--ink-2)">Nhóm 4 · hỗ trợ</span><h4>Vận hành</h4><p>Web admin (sale, voucher Shopee, đề xuất, thông báo, dashboard) · Remote Config · FCM · Analytics · Crashlytics</p></div>
    </div>
    <p class="vis-note" style="margin-top:12px">3 workflow được chọn để demo đều đổi trạng thái của món hoặc tạo dữ liệu mới, không phải "mở màn hình".</p>`,

  businessFlow: () =>
    graph({
      w: 1000,
      h: 560,
      deep: true,
      nodes: [
        ...lane('u', 0, 'Người dùng'),
        ...lane('a', 192, 'App'),
        ...lane('f', 384, 'Firebase'),
        { id: 'u1', x: 112, y: 52, w: 150, h: 72, tone: 'ext', title: 'Thấy món trên Shopee', z: 1 },
        { id: 'u2', x: 287, y: 52, w: 160, h: 72, title: 'Chia sẻ link hoặc lưu từ tiện ích', z: 1 },
        { id: 'a1', x: 287, y: 244, w: 160, h: 72, title: 'Form tự điền, chọn động cơ', z: 2 },
        { id: 'f1', x: 287, y: 430, w: 160, h: 84, tone: 'accent', title: 'Món: considering', code: 'BR-01 · hoãn +3 ngày', z: 2 },
        { id: 'a2', x: 472, y: 244, w: 160, h: 72, title: 'Đếm ngược, nhắc khi đến hẹn', z: 2 },
        { id: 'u3', x: 472, y: 52, w: 160, h: 72, tone: 'accent', title: 'Quyết định Mua · Chờ · Bỏ qua', z: 2 },
        { id: 'f3', x: 472, y: 430, w: 160, h: 84, title: 'decisions', code: 'wait · skip · undo', z: 2 },
        { id: 'a3', x: 657, y: 244, w: 160, h: 72, title: 'Ghi khoản mua (2 bước)', z: 2 },
        { id: 'f2', x: 657, y: 430, w: 160, h: 84, tone: 'ok', title: 'purchases + món → purchased', code: '1 batch', z: 2 },
        { id: 'a4', x: 842, y: 244, w: 148, h: 72, title: 'Ngân sách · Góc nhìn AI · Chiêm nghiệm', z: 2 },
        { id: 'u4', x: 842, y: 52, w: 148, h: 72, tone: 'ok', title: 'Hiểu mình mua vì sao', z: 1 },
      ],
      edges: [
        { from: 'u1', to: 'u2' },
        { from: 'u2', to: 'a1', fs: 'b', ts: 't' },
        { from: 'a1', to: 'f1', fs: 'b', ts: 't', label: 'ghi' },
        { from: 'f1', to: 'a2', fs: 'r', ts: 'b', via: [[552, 472]], label: 'realtime', lx: 552, ly: 372 },
        { from: 'a2', to: 'u3', fs: 't', ts: 'b', label: 'hết hoãn · đến hẹn' },
        { from: 'u3', to: 'f3', fs: 'l', ts: 'l', via: [[459, 88], [459, 472]], label: '◇ Chờ (BR-03) · Bỏ qua (BR-04)', lx: 459, ly: 180 },
        { from: 'u3', to: 'a3', fs: 'r', ts: 't', via: [[737, 88]], label: '◇ Mua (BR-02)' },
        { from: 'a3', to: 'f2', fs: 'b', ts: 't', label: 'batch' },
        { from: 'f3', to: 'f1', fs: 'l', ts: 'r', warn: true, dash: true, label: 'Hoàn tác ≤ 5 s', lx: 459, ly: 500 },
        { from: 'f2', to: 'a4', fs: 'r', ts: 'b', via: [[916, 472]], label: 'realtime', lx: 916, ly: 372 },
        { from: 'a4', to: 'u4', fs: 't', ts: 'b' },
      ],
    }),

  stateMachine: () =>
    graph({
      w: 1000,
      h: 600,
      deep: true,
      nodes: [
        { id: 'st', x: 20, y: 281, w: 22, h: 22, tone: 'accent', cls: 'dg-dot', z: 2 },
        { id: 's1', x: 62, y: 236, w: 200, h: 112, tone: 'accent', title: 'Đang cân nhắc · đang hoãn', sub: 'cooldownUntil = +3 ngày, trừ Nhu cầu', code: 'considering', z: 2 },
        { id: 's2', x: 400, y: 236, w: 200, h: 112, title: 'Đang cân nhắc', sub: 'Hoãn chỉ là lời nhắc: vẫn bấm Mua · Chờ · Bỏ qua', code: 'considering', z: 2 },
        { id: 's3', x: 420, y: 24, w: 180, h: 100, title: 'Chờ', sub: 'Hẹn xem lại, thông báo 09:00', code: 'considering + reviewAt', z: 2 },
        { id: 's4', x: 780, y: 240, w: 190, h: 104, tone: 'ok', title: 'Đã mua', sub: 'Qua Ghi khoản mua', code: 'purchased + purchaseId', z: 2 },
        { id: 's5', x: 420, y: 470, w: 180, h: 100, tone: 'ok', title: 'Bỏ qua', sub: 'Hoàn tác được', code: 'skipped', z: 2 },
        { id: 'ban', x: 700, y: 400, w: 290, h: 180, tone: 'warn', kicker: 'Chuyển bị cấm (Rules)', html: '<span class="dg-sub">✕ status ngoài 3 giá trị, vd “waiting” → <b>TC-03 · R-84</b></span><span class="dg-sub">✕ sửa giá đã ghi → <b>TC-08 · R-96</b></span><span class="dg-sub">✕ decision có choice lạ → <b>TC-08 · R-97</b></span><span class="dg-sub">✕ purchased thiếu purchaseId (rules bắt buộc)</span>', z: 2 },
      ],
      edges: [
        { from: 'st', to: 's1' },
        { from: 's1', to: 's2', label: 'Hết hoãn · BR-01', lx: 331 },
        { from: 's2', to: 's3', fp: [545, 236], tp: [545, 124], label: 'Chờ [đặt reviewAt] · BR-03', lx: 690, ly: 180 },
        { from: 's3', to: 's2', fp: [465, 124], tp: [465, 236], label: 'Đến hẹn', lx: 400, ly: 180 },
        { from: 's2', to: 's4', label: 'Mua [có purchaseId] · BR-02', lx: 690 },
        { from: 's2', to: 's5', fp: [545, 348], tp: [545, 470], label: 'Bỏ qua · BR-04', lx: 650, ly: 410 },
        { from: 's5', to: 's2', fp: [465, 470], tp: [465, 348], warn: true, dash: true, label: 'Hoàn tác ≤ 5 s · Cân nhắc lại', lx: 330, ly: 410 },
      ],
    }),

  architecture: () =>
    graph({
      w: 1000,
      h: 600,
      deep: true,
      nodes: [
        { id: 'fb', x: 580, y: 20, w: 410, h: 560, tone: 'group', kicker: 'Google Cloud', title: 'Firebase · prm393-34056', z: 0, cls: 'dg-group-head' },
        { id: 'auth', x: 600, y: 96, w: 180, h: 64, title: 'Authentication', sub: 'Email · Google · GitHub · ẩn danh', z: 1 },
        { id: 'rc', x: 790, y: 96, w: 180, h: 64, title: 'Remote Config', sub: 'cooling_off_days · AI · sale', z: 1 },
        { id: 'fs', x: 600, y: 172, w: 370, h: 72, tone: 'accent', title: 'Cloud Firestore + Security Rules', sub: 'users/{uid}/… · saleEvents · announcements', z: 2 },
        { id: 'fcm', x: 600, y: 256, w: 180, h: 64, title: 'Cloud Messaging', z: 1 },
        { id: 'ai', x: 790, y: 256, w: 180, h: 64, title: 'AI Logic · Gemini', sub: 'model từ Remote Config', z: 1 },
        { id: 'ac', x: 600, y: 332, w: 180, h: 64, title: 'App Check', z: 1 },
        { id: 'an', x: 790, y: 332, w: 180, h: 64, title: 'Analytics · Crashlytics', z: 1 },
        { id: 'host', x: 600, y: 408, w: 370, h: 64, title: 'Hosting', sub: 'web admin (Flutter Web)', z: 1 },
        { id: 'app', x: 20, y: 70, w: 320, h: 104, tone: 'accent', kicker: 'Android', title: 'App Why I Buy? (Flutter)', sub: 'MVVM: Screen → ViewModel → Service · Kotlin: bong bóng nổi', z: 2 },
        { id: 'ext', x: 20, y: 214, w: 320, h: 84, kicker: 'Chrome / Edge', title: 'Tiện ích Why I Buy?', z: 2 },
        { id: 'web', x: 20, y: 338, w: 320, h: 92, kicker: 'staff · admin', title: 'Web admin (Flutter Web)', z: 2 },
        { id: 'push', x: 20, y: 470, w: 320, h: 84, tone: 'muted', kicker: 'Java 21', title: 'Push server (Spring Boot)', z: 1 },
        { id: 'shop', x: 600, y: 500, w: 370, h: 56, tone: 'ext', title: 'Trang Shopee (Open Graph) · Android Share Sheet', z: 1 },
      ],
      edges: [
        { from: 'app', to: 'fb', fp: [340, 122], tp: [580, 122], label: 'stream realtime (async) · Gemini · FCM' },
        { from: 'ext', to: 'fb', fp: [340, 256], tp: [580, 256], label: 'ẩn danh · QR · ghi món' },
        { from: 'web', to: 'fb', fp: [340, 384], tp: [580, 384], label: 'sale · duyệt · thông báo' },
        { from: 'push', to: 'fb', fp: [340, 512], tp: [580, 512], label: 'HTTPS (sync) · ID token admin → FCM' },
      ],
    }),

  stack: () =>
    table({
      cols: [{ label: 'Mảng', w: '0.75fr' }, { label: 'Công nghệ', w: '1.4fr' }, { label: 'Vai trò', w: '1.35fr' }],
      rows: [
        ['App mobile', 'Flutter · Dart · Provider · Material 3', 'Giao diện Android, MVVM, một luồng phụ thuộc Screen → ViewModel → Service'],
        ['Android native', 'Kotlin · MethodChannel · Overlay · AccessibilityService', 'Bong bóng nổi trên app mua sắm; xem một món quá 15 giây thì nhắc; chỉ đọc trên máy, không gửi lên server'],
        ['Dữ liệu', 'Cloud Firestore · Security Rules · Indexes', 'Lưu theo users/{uid}, đồng bộ realtime, bộ đệm offline, phân quyền user/staff/admin'],
        ['Xác thực', 'Firebase Auth · google_sign_in · App Check', 'Email, Google, GitHub, Khách; chặn client giả gọi AI'],
        ['AI', 'Firebase AI Logic (Gemini)', 'Chỉ viết lại câu từ số liệu code đã tính; có câu mẫu dự phòng'],
        ['Thông báo', 'Cloud Messaging · flutter_local_notifications', 'Tin từ server/Console; nhắc xem lại 09:00, nhắc ghi chi 21:00'],
        ['Vận hành', 'Remote Config · Analytics · Crashlytics', 'Đổi cấu hình từ xa, đo sự kiện, gom lỗi'],
        ['Web & server', 'Flutter Web + Hosting · Spring Boot (Java 21) + Admin SDK', 'Web admin cho staff/admin; gửi push hàng loạt'],
        ['Kiểm thử', 'flutter_test · fake_cloud_firestore · rules-unit-testing + Emulator', '609/610 test app · 42/42 web · 268/268 Rules'],
      ],
    }),

  sequence: () => {
    const cols = ['Góc nhìn (Screen)', 'InsightsViewModel', 'AiInsightService', 'Remote Config', 'AI Logic · Gemini']
    const cx = (i) => 100 + i * 200
    const nodes = cols.map((c, i) => ({ id: `p${i}`, x: cx(i) - 88, y: 0, w: 176, h: 50, tone: i === 4 ? 'accent' : 'base', title: c, z: 2 }))
    nodes.push({ id: 'check', x: cx(2) - 92, y: 340, w: 184, h: 58, tone: 'warn', title: 'Kiểm tra câu AI', sub: 'số lạ · quá dài · từ cấm → câu mẫu', z: 2 })
    const lifelines = cols.map((_, i) => ({ from: `p${i}`, to: `p${i}`, fp: [cx(i), 50], tp: [cx(i), 590], dash: true }))
    const m = (a, b, y, label, dash) => ({ from: `p${a}`, to: `p${b}`, fp: [cx(a), y], tp: [cx(b), y], label, dash, lx: (cx(a) + cx(b)) / 2, ly: y - 14 })
    return graph({
      w: 1000,
      h: 600,
      nodes,
      edges: [
        ...lifelines,
        m(0, 1, 100, 'mở tab: setVisible(true)'),
        m(1, 2, 160, 'số liệu tháng (≥ 3 khoản)'),
        m(2, 3, 220, 'enable_ai_insight · ai_insight_model'),
        m(2, 4, 280, 'prompt + JSON schema (App Check)'),
        m(4, 2, 330, 'câu viết lại', true),
        m(2, 1, 450, 'câu hợp lệ hoặc câu mẫu', true),
        m(1, 0, 520, 'chip AI / Câu mẫu', true),
      ],
      cls: 'dg--seq',
    })
  },

  classDesign: () =>
    graph({
      w: 1000,
      h: 600,
      nodes: [
        { id: 'vm', x: 20, y: 20, w: 300, h: 150, kicker: 'ChangeNotifier', title: 'WishlistViewModel', sub: 'addItem() · wait() · skip() · reconsider() · updatePrice()', z: 1 },
        { id: 'svc', x: 360, y: 20, w: 290, h: 150, kicker: 'interface', title: 'WishlistService', sub: 'add() · setReview() · skip() · undoSkip() · addPrice()', z: 1 },
        { id: 'fsvc', x: 690, y: 20, w: 290, h: 150, tone: 'muted', kicker: 'Firestore', title: 'FirestoreWishlistService', sub: 'ghi wishlistItems + decisions trong 1 batch', z: 1 },
        { id: 'item', x: 20, y: 230, w: 300, h: 190, tone: 'accent', kicker: 'model', title: 'WishlistItem', sub: 'title · status · motive · priority · latestPriceVnd · cooldownUntil · reviewAt · purchaseId · saveChannel', z: 2 },
        { id: 'dec', x: 360, y: 230, w: 290, h: 130, kicker: 'model · chỉ thêm', title: 'Decision', sub: 'choice: buy | wait | skip | undo · itemId · at · reviewAt?', z: 1 },
        { id: 'pur', x: 690, y: 230, w: 290, h: 150, kicker: 'model', title: 'PurchaseItem', sub: 'title · amountVnd · motive · occurredAt · budgetGroupId · wishlistItemId? · satisfaction?', z: 1 },
        { id: 'mot', x: 20, y: 470, w: 300, h: 110, kicker: 'enum', title: 'BuyingMotive (8)', sub: 'need · want · sale · emotion · social · convenience · ads · other', z: 1 },
        { id: 'psvc', x: 690, y: 440, w: 290, h: 110, kicker: 'service', title: 'PurchaseService', sub: 'buyFromWishlist(): purchase + món → purchased, 1 batch', z: 1 },
      ],
      edges: [
        { from: 'vm', to: 'svc', label: 'dùng' },
        { from: 'fsvc', to: 'svc', dash: true, label: 'implements' },
        { from: 'vm', to: 'item', fs: 'b', ts: 't', label: 'giữ danh sách' },
        { from: 'svc', to: 'dec', fs: 'b', ts: 't', label: 'tạo' },
        { from: 'item', to: 'mot', fs: 'b', ts: 't', label: 'motive' },
        { from: 'psvc', to: 'pur', fs: 't', ts: 'b', label: 'tạo' },
        { from: 'pur', to: 'item', fp: [690, 330], tp: [320, 330], dash: true, label: 'wishlistItemId ↔ purchaseId', lx: 505, ly: 400 },
      ],
    }),

  dbConcept: () =>
    graph({
      w: 1000,
      h: 600,
      nodes: [
        { id: 'u', x: 380, y: 250, w: 240, h: 90, tone: 'accent', title: 'Người dùng', code: 'role: user · staff · admin', z: 2 },
        { id: 'w', x: 30, y: 40, w: 230, h: 76, title: 'Món mong muốn', sub: 'trạng thái, động cơ, giá', z: 1 },
        { id: 'ps', x: 30, y: 170, w: 230, h: 66, tone: 'muted', title: 'Lần ghi giá', sub: 'chỉ thêm', z: 1 },
        { id: 'd', x: 380, y: 40, w: 240, h: 76, title: 'Quyết định', sub: 'mua · chờ · bỏ qua · hoàn tác', z: 1 },
        { id: 'p', x: 740, y: 40, w: 230, h: 76, title: 'Khoản mua', sub: 'số tiền, động cơ, thời điểm', z: 1 },
        { id: 'bg', x: 740, y: 210, w: 230, h: 66, title: 'Nhóm ngân sách', z: 1 },
        { id: 'b', x: 740, y: 330, w: 230, h: 66, title: 'Ngân sách tháng', sub: 'limits theo nhóm', z: 1 },
        { id: 'r', x: 740, y: 450, w: 230, h: 66, title: 'Chiêm nghiệm tháng', z: 1 },
        { id: 'x', x: 30, y: 330, w: 230, h: 66, title: 'Phiên tiện ích', sub: 'pending → approved', z: 1 },
        { id: 'se', x: 30, y: 470, w: 230, h: 76, tone: 'ext', title: 'Sự kiện sale · Thông báo', sub: 'dùng chung, staff ghi', z: 1 },
        { id: 'ss', x: 380, y: 470, w: 240, h: 76, tone: 'ext', title: 'Đề xuất sale', sub: 'người dùng gửi, staff duyệt', z: 1 },
      ],
      edges: [
        { from: 'u', to: 'w', label: '1 — n' },
        { from: 'w', to: 'ps', fs: 'b', ts: 't', label: '1 — n' },
        { from: 'u', to: 'd', fs: 't', ts: 'b', label: '1 — n' },
        { from: 'u', to: 'p', label: '1 — n' },
        { from: 'u', to: 'bg', label: '1 — 6' },
        { from: 'u', to: 'b', label: '1 — n' },
        { from: 'u', to: 'r', label: '1 — n' },
        { from: 'u', to: 'x', label: '1 — n' },
        { from: 'u', to: 'ss', fs: 'b', ts: 't', label: '1 — n' },
        { from: 'p', to: 'w', fp: [740, 96], tp: [260, 96], dash: true, label: 'mua từ món (0..1)', lx: 500, ly: 150 },
      ],
    }),

  dbPhysical: () =>
    table({
      cols: [{ label: 'Collection (Firestore)', w: '1.25fr' }, { label: 'Trường chính', w: '1.6fr' }, { label: 'Rules · index', w: '1.2fr' }],
      rows: [
        ['users/{uid}', 'role · displayName · fcmTokens · settings.coolingOffDays', 'chủ tài khoản; chỉ admin đổi role người khác'],
        ['…/wishlistItems/{id}', 'title · status · motive · latestPriceVnd · cooldownUntil · reviewAt · purchaseId', 'purchased bắt buộc purchaseId · index status↑ createdAt↓'],
        ['…/wishlistItems/{id}/priceSnapshots', 'priceVnd · source · at', 'chỉ thêm (update: false)'],
        ['…/decisions/{id}', 'choice · itemId · at · reviewAt', 'chỉ thêm'],
        ['…/purchases/{id}', 'title 1–60 · amountVnd 1…999.999.999 · motive (8 key) · occurredAt', 'admin chỉ count/sum (collection group)'],
        ['…/budgets/{yyyy-MM}', 'limits {groupId: int > 0}', 'id phải khớp ^[0-9]{4}-[0-9]{2}$'],
        ['saleEvents · announcements', 'name · date · status draft/published/archived', 'staff/admin ghi; mọi người đọc bản published'],
        ['saleSuggestions', 'uid · name · date · status pending → approved | rejected', 'duyệt = 1 batch tạo saleEvents + inbox'],
      ],
    }),

  traceability: () =>
    table({
      cols: [{ label: 'Nhóm tính năng', w: '1fr' }, { label: 'UI', w: '1.05fr' }, { label: 'Code', w: '1.15fr' }, { label: 'Data', w: '1fr' }, { label: 'Test', w: '1.2fr' }],
      rows: [
        ['Lưu món (WF-01)', 'Thêm món · Liên kết thiết bị', 'ShareIntentService · ExtensionLinkViewModel', 'wishlistItems · extensionSessions', 'share_intent · extension_link'],
        ['Quyết định (WF-02)', 'Chi tiết món · Trước khi mua', 'WishlistViewModel · PrePurchaseViewModel', 'decisions · wishlistItems', 'decision_and_budget · pre_purchase'],
        ['Ghi chi (WF-02)', 'Ghi khoản mua', 'PurchaseService.buyFromWishlist', 'purchases', 'purchase_flow · purchase_service'],
        ['Nhìn lại (WF-03)', 'Ngân sách · Góc nhìn', 'BudgetViewModel · AiInsightService', 'budgets · reflections', 'available_budget · ai_insight'],
        ['Phân quyền', 'Web admin', 'firestore.rules', 'users.role', 'rules.test.mjs (268 ca)'],
      ],
    }),

  demoPlan: () =>
    graph({
      w: 1000,
      h: 520,
      deep: true,
      nodes: [
        { id: 'w1', x: 20, y: 150, w: 250, h: 150, tone: 'accent', kicker: 'WF-01 · khởi tạo', title: 'Lưu món & hoãn mua', sub: 'Chia sẻ từ Shopee hoặc tiện ích → món đang cân nhắc, hoãn 3 ngày', z: 2 },
        { id: 'w2', x: 375, y: 150, w: 250, h: 150, kicker: 'WF-02 · xử lý', title: 'Quyết định & ghi chi', sub: 'Trước khi mua → Chờ 11.11 hoặc Bỏ qua → Mua thì ghi khoản mua', z: 2 },
        { id: 'w3', x: 730, y: 150, w: 250, h: 150, kicker: 'WF-03 · tổng hợp', title: 'Nhìn lại cuối tháng', sub: 'Ngân sách → Góc nhìn AI → Chiêm nghiệm + PDF', z: 2 },
        { id: 'o1', x: 50, y: 380, w: 190, h: 60, tone: 'muted', title: 'Món: considering', code: 'cooldownUntil', z: 1 },
        { id: 'o2', x: 405, y: 380, w: 190, h: 60, tone: 'muted', title: 'Khoản mua · quyết định', code: 'purchases · decisions', z: 1 },
        { id: 'o3', x: 760, y: 380, w: 190, h: 60, tone: 'ok', title: 'Hiểu mình mua vì sao', code: 'reflections', z: 1 },
        { id: 'a', x: 20, y: 40, w: 960, h: 60, tone: 'ext', title: 'Một người dùng, một món: “Máy ảnh film mini” 450.000 ₫ · động cơ Cảm xúc', z: 1 },
      ],
      edges: [
        { from: 'w1', to: 'w2', label: 'món', lx: 322, ly: 205 },
        { from: 'w2', to: 'w3', label: 'khoản mua', lx: 677, ly: 205 },
        { from: 'w1', to: 'o1', fs: 'b', ts: 't' },
        { from: 'w2', to: 'o2', fs: 'b', ts: 't' },
        { from: 'w3', to: 'o3', fs: 'b', ts: 't' },
      ],
    }),

  testing: () => `
    <div class="stat-grid">${evidence
      .map(
        (s) => `<div class="stat"><div class="stat__value ${s.brand ? 'is-brand' : ''}">${s.value}<small>${s.unit}</small></div><div class="stat__label">${s.label}</div><div class="stat__src">${s.src}</div></div>`,
      )
      .join('')}</div>
    ${table({
      cols: [{ label: 'Loại kiểm thử', w: '1fr' }, { label: 'Kiểm tra gì', w: '2fr' }],
      rows: [
        ['Security Rules', 'Mỗi role có ít nhất 1 ca cho phép và 1 ca từ chối ở mỗi collection; chuyển trạng thái hợp lệ'],
        ['Widget / ViewModel', 'Luồng Bỏ qua → Hoàn tác, ngân sách khả dụng, chia sẻ link, ghép QR, form ở cỡ chữ 200%'],
        ['Business rule', 'Giá null không thành 0 ₫, quyết định chỉ thêm, câu AI có số lạ bị loại'],
      ],
    })}`,

  achievements: () =>
    table({
      cols: [{ label: 'Mục tiêu', w: '1.1fr' }, { label: 'Kết quả', w: '1.4fr' }, { label: 'Minh chứng', w: '1fr' }],
      rows: [
        ['Một khoảng dừng trước khi mua', 'Danh sách cân nhắc + hoãn 3 ngày (Remote Config) + Mua · Chờ · Bỏ qua ngang hàng', `WF-01, WF-02 ${tag('demo', 'brand')}`],
        ['Ghi được lý do mua', '8 động cơ trên mọi món, khoản mua; Mô hình, Góc nhìn, Chiêm nghiệm', `WF-03 ${tag('demo', 'brand')}`],
        ['Lưu món nhanh từ Shopee', 'Android Share Intent + tiện ích Chrome ghép QR 5 phút', 'share_intent · extension_link test'],
        ['AI có trách nhiệm', 'Gemini chỉ viết câu; câu sai bị loại, có chip AI / Câu mẫu', 'ai_insight test · Remote Config'],
        ['Một hệ thống trên Firebase', 'App + tiện ích + web admin dùng chung Firestore, phân quyền 3 role', '268/268 Rules · web đã deploy'],
      ],
    }),

  limitations: () =>
    table({
      cols: [{ label: 'Giới hạn', w: '1.2fr' }, { label: 'Tác động', w: '1.2fr' }, { label: 'Hướng xử lý', w: '1.2fr' }],
      rows: [
        ['App chưa đọc hộp thư, thông báo, lịch sale do web admin đăng (backend đã sẵn)', 'Staff đăng nội dung nhưng người dùng chưa thấy trong app', 'Nối app với packages/core (InboxService, AnnouncementService)'],
        ['1/610 test app đang lỗi (Bỏ qua → Hoàn tác)', 'Luồng hoàn tác chưa được kiểm thử tự động đầy đủ', 'Sửa test trước khi chấm'],
        ['Chưa đọc giá từ ảnh chụp màn hình (OCR)', 'Không có giá khi link không lộ giá', 'ML Kit on-device ở bản sau'],
        ['Chỉ kiểm thử trên Android', 'Chưa biết hành vi trên iOS', 'Thêm cấu hình và test iOS'],
        ['Chưa có khảo sát người dùng định lượng', 'Chưa chứng minh được mức giảm mua bốc đồng', 'Khảo sát trước/sau 2 tuần dùng app'],
      ],
    }),

  conclusion: () => `
    <div class="vis-grid">
      <div class="vis-card"><span class="k">01</span><h4>Một khoảng dừng có chủ đích</h4><p>Món vào danh sách cân nhắc thay vì giỏ hàng; quyết định Mua · Chờ · Bỏ qua không bị app ép.</p></div>
      <div class="vis-card"><span class="k">02</span><h4>Hiểu vì sao mình mua</h4><p>8 động cơ đi xuyên suốt từ lúc lưu món đến chiêm nghiệm cuối tháng.</p></div>
      <div class="vis-card"><span class="k">03</span><h4>Một hệ thống chạy thật trên Firebase</h4><p>App, tiện ích, web admin; phân quyền bằng Rules và có test tự động làm bằng.</p></div>
    </div>
    <div class="team" style="margin-top:16px">${team.map((m) => `<div class="team__member"><div class="team__name">${m.name}</div><div class="team__role">${m.role}</div></div>`).join('')}</div>`,
}

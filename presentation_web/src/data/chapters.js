/**
 * The presentation script: one entry per scroll step.
 * Every claim here was checked against the Flutter code (prm393_lab03/lib)
 * or the evidence files in the repo. Edit freely; the page is generated.
 *
 * screen: id of a module in src/screens (what the phone shows)
 * demo:   optional key of an alternative demo exported by that screen
 * rail:   label in the bottom flow rail (journey steps only)
 * pose:   phone pose { ry, rx, rz, x, y, s } (radians / phone heights)
 */

const chip = (label, kind = '') => ({ label, kind })
const F = (label) => chip(label, 'firebase')
const AI = (label) => chip(label, 'ai')
const AND = (label) => chip(label, 'android')
const WEB = (label) => chip(label, 'web')

export const chapters = [
  {
    id: 'hero',
    kind: 'hero',
    screen: 'home',
    demo: 'idle',
    pose: { ry: 0.3, rx: -0.04 },
    eyebrow: 'PRM393 · Final Assignment · One complete system on Firebase',
    nav: 'Thuyết trình sản phẩm · PRM393',
  },
  {
    id: 'van-de',
    screen: 'lockscreen',
    pose: { ry: 0.2, rx: -0.03, rz: 0.015 },
    eyebrow: 'Vấn đề',
    title: 'Mua vì cần, <em>hay vì cảm xúc?</em>',
    lead: 'Sale ngày đôi, voucher hết hạn sau 2 giờ, thông báo dồn dập: các sàn được thiết kế để mình bấm “Mua ngay” trước khi kịp nghĩ.',
    points: [
      'App chi tiêu thông thường chỉ trả lời <strong>“tiêu bao nhiêu”</strong>, không trả lời <strong>“vì sao lại mua”</strong>.',
      'App săn sale còn đẩy mạnh thêm: cào voucher, báo giảm giá liên tục, càng dễ mua bốc đồng.',
      'Cảm hứng từ <strong>The Psychology of Money</strong> (Morgan Housel): tiền là hành vi, không chỉ là con số.',
    ],
    chips: [chip('Mua sắm bốc đồng'), chip('Ngày đôi 9.9 · 10.10 · 11.11'), chip('8 động cơ mua')],
    note: 'Màn hình khoá bên trái là minh hoạ bối cảnh, không phải màn của app.',
  },
  {
    id: 'muc-tieu',
    screen: 'onboarding',
    rail: 'Mở app',
    pose: { ry: 0.26, rx: -0.05 },
    eyebrow: 'Người dùng & mục tiêu',
    title: 'Một <em>khoảng dừng</em> trước khi bấm mua',
    lead: 'Cho người trẻ hay mua sắm online: sinh viên, người mới đi làm, những người muốn hiểu thói quen của mình mà không bị phán xét.',
    points: [
      '<strong>Mục tiêu:</strong> đưa món vào danh sách cân nhắc thay vì giỏ hàng, rồi tự quyết Mua · Chờ · Bỏ qua.',
      '<strong>Cách đo:</strong> số món chuyển sang “Bỏ qua”, giá trị các món đã bỏ qua, tỉ lệ mua theo từng động cơ. Web admin tính các số này từ dữ liệu thật trên Firestore.',
      'Giọng điệu xuyên suốt: <strong>“Hiểu mình, không phán xét”</strong>. App không bao giờ chặn mua.',
    ],
    chips: [chip('Người trẻ mua online'), chip('Mua · Chờ · Bỏ qua'), F('Firestore aggregation')],
  },
  {
    id: 'dang-nhap',
    screen: 'login',
    rail: 'Đăng nhập',
    pose: { ry: 0.22, rx: -0.03 },
    eyebrow: 'Đăng nhập',
    title: 'Vào app theo <em>cách bạn thích</em>',
    lead: 'Email, Google, GitHub hoặc chế độ Khách. Tất cả do Firebase Authentication xử lý.',
    points: [
      '<strong>Chế độ Khách</strong> dùng đăng nhập ẩn danh: trải nghiệm ngay, không cần tạo tài khoản.',
      'Mã lỗi Firebase được dịch sang tiếng Việt, ví dụ “Email hoặc mật khẩu không đúng.”',
      'Lần đầu đăng nhập, app tự tạo hồ sơ <strong>users/{uid}</strong> và các nhóm ngân sách mặc định trên Firestore.',
    ],
    chips: [F('Firebase Auth'), F('Analytics: login'), F('Crashlytics'), F('Firestore')],
    path: 'users/{uid}',
  },
  {
    id: 'trang-chu',
    screen: 'home',
    rail: 'Trang chủ',
    pose: { ry: 0.3, rx: -0.04 },
    eyebrow: 'Trang chủ',
    title: 'Một màn, <em>ba câu trả lời</em>',
    lead: 'Tháng này chi bao nhiêu, vì động cơ gì, còn trong ngân sách không.',
    points: [
      'Thanh màu chia theo <strong>8 động cơ mua</strong> biến tâm lý tiêu dùng thành hình ảnh.',
      'Dữ liệu stream <strong>realtime</strong> từ Firestore: vừa ghi khoản mua là tổng tháng cập nhật ngay.',
      'Lối tắt “Trước khi mua” và “Chụp để tìm” để dừng lại trước một quyết định bốc đồng.',
    ],
    chips: [F('Firestore realtime'), F('FCM'), chip('Provider · MVVM')],
    path: 'users/{uid}/purchases',
  },
  {
    id: 'luu-mon',
    screen: 'add-item',
    rail: 'Lưu món',
    pose: { ry: 0.24, rx: -0.04, rz: -0.01 },
    eyebrow: 'Lưu món từ Shopee',
    title: 'Chia sẻ vào <em>danh sách cân nhắc</em> thay vì giỏ hàng',
    lead: 'Đang lướt app Shopee, bấm Chia sẻ rồi chọn Why I Buy: form Thêm món mở ra với tên, link, giá và ảnh đã điền sẵn.',
    points: [
      'Kênh native Kotlin (<strong>ACTION_SEND</strong>) nhận link cả khi app đang tắt lẫn đang chạy, và lọc trùng.',
      'Bộ lọc tự bỏ câu quảng cáo như [FREESHIP XTRA], “Cơ hội sở hữu sản phẩm” khỏi tên món.',
      'Link rút gọn được giải mã, đọc thẻ Open Graph để lấy ảnh và tên shop. <strong>Không bao giờ bịa giá.</strong>',
    ],
    chips: [AND('Android Share Intent'), chip('Open Graph'), F('Firestore'), F('Analytics')],
    path: 'users/{uid}/wishlistItems',
  },
  {
    id: 'tien-ich',
    screen: 'extension-link',
    rail: 'Từ máy tính',
    pose: { ry: 0.32, rx: -0.03 },
    eyebrow: 'Tiện ích Chrome “Why I Buy?”',
    title: 'Quét QR, <em>máy tính</em> và điện thoại thành một',
    lead: 'Tiện ích trên Chrome/Edge lưu món ngay trên trang Shopee. Điện thoại quét mã QR để cấp quyền, không cần gõ mật khẩu trên máy tính.',
    points: [
      'Mã QR chỉ sống <strong>5 phút</strong> và luôn đọc bản mới từ máy chủ Firestore, chặn dùng lại mã cũ.',
      'Một <strong>batch</strong> Firestore vừa tạo phiên đã duyệt vừa đóng yêu cầu ghép đôi.',
      'Món lưu từ máy tính hiện trong app với nhãn <strong>“Từ máy tính”</strong>; huỷ liên kết bất cứ lúc nào.',
    ],
    chips: [WEB('Chrome Extension'), F('Anonymous Auth'), F('Firestore batch'), AND('Camera QR')],
    path: 'users/{uid}/extensionSessions/{id}',
  },
  {
    id: 'can-nhac',
    screen: 'wishlist',
    rail: 'Cân nhắc',
    pose: { ry: 0.26, rx: -0.05 },
    eyebrow: 'Danh sách mong muốn',
    title: 'Mỗi món đều có <em>thời gian hạ nhiệt</em>',
    lead: 'Món mua vì cảm xúc, sale hay mạng xã hội được hoãn mặc định 3 ngày. Huy hiệu tím đếm ngược, rồi tự chọn Mua, Chờ hoặc Bỏ qua.',
    points: [
      'Chỉ món <strong>Nhu cầu</strong> được bỏ qua thời gian hoãn; số ngày đổi từ xa bằng Remote Config.',
      'Ba nút Mua · Chờ · Bỏ qua <strong>cùng kích thước, cùng màu</strong>: app không đẩy về lựa chọn nào.',
      'Bỏ qua có <strong>Hoàn tác 5 giây</strong>; mỗi quyết định ghi vào Firestore và Analytics.',
    ],
    chips: [F('Remote Config: cooling_off_days'), F('Firestore'), F('Analytics: make_decision')],
    path: 'users/{uid}/decisions',
  },
  {
    id: 'cho-sale',
    screen: 'review-wait',
    rail: 'Chờ sale',
    pose: { ry: 0.2, rx: -0.03, rz: 0.01 },
    eyebrow: 'Chờ & lịch sale',
    title: 'Chờ <em>có chủ đích</em> chứ không phải từ chối',
    lead: 'Bấm Chờ để hẹn ngày xem lại: sau vài ngày, đến đợt sale 11.11, hoặc một ngày tự chọn. App nhắc đúng 9 giờ sáng hôm đó.',
    points: [
      'Lịch sale minh bạch: <strong>“Đã xác nhận”</strong> khi sàn công bố, còn lại là “Dự kiến”. App không dự đoán giá.',
      'Nhóm cập nhật đợt sale qua Remote Config <strong>sale_calendar</strong>, không cần phát hành bản mới.',
      'Quyền thông báo chỉ được hỏi khi người dùng chọn Chờ, không làm phiền lúc mở app.',
    ],
    chips: [F('Remote Config: sale_calendar'), AND('Local notifications'), F('Firestore')],
  },
  {
    id: 'truoc-khi-mua',
    screen: 'pre-purchase',
    rail: 'Trước khi mua',
    pose: { ry: 0.28, rx: -0.04 },
    eyebrow: 'Trước khi mua',
    title: 'Vài câu hỏi, <em>không chấm điểm</em>',
    lead: 'Vì sao mình muốn món này? Điều gì bên ngoài đang tác động? Chọn “Khuyến mãi” thì app tự chèn thêm một bước hỏi về đợt sale.',
    points: [
      'Thẻ quan sát do <strong>quy tắc trong code</strong> tạo, luôn có kết quả kể cả khi AI tắt hoặc lỗi.',
      '<strong>Gemini</strong> chỉ viết lời tóm tắt và câu hỏi gợi mở, không bao giờ khuyên mua hay không mua.',
      'Câu AI bị loại nếu có số bịa hoặc từ phán xét như “nên mua”, “lãng phí”. Chip <strong>AI / Câu mẫu</strong> ghi rõ nguồn.',
    ],
    chips: [AI('Firebase AI Logic · Gemini'), F('Remote Config: enable_ai_suggestions'), F('App Check')],
  },
  {
    id: 'ghi-chi',
    screen: 'record-purchase',
    rail: 'Ghi khoản mua',
    pose: { ry: 0.24, rx: -0.04, rz: -0.01 },
    eyebrow: 'Ghi khoản mua',
    title: 'Ghi lại <em>lý do</em> chứ không chỉ số tiền',
    lead: 'Hai bước: số tiền thực trả, tên món và nhóm ngân sách; rồi một trong 8 động cơ mua và ghi chú.',
    points: [
      'Nút cộng nhanh <strong>+20.000 · +50.000 · +100.000 ₫</strong> để nhập trong vài giây.',
      'Gợi ý nhóm bằng từ khoá trước, chỉ gọi Gemini khi cần; luôn chờ người dùng chạm xác nhận.',
      'Analytics chỉ ghi <strong>nhóm số tiền</strong>, không gửi số tiền thật, tôn trọng quyền riêng tư.',
    ],
    chips: [F('Firestore'), F('Analytics: purchase_recorded'), AI('Gemini (dự phòng)')],
    path: 'users/{uid}/purchases/{id}',
  },
  {
    id: 'ngan-sach',
    screen: 'budget',
    rail: 'Ngân sách',
    pose: { ry: 0.3, rx: -0.04 },
    eyebrow: 'Ngân sách',
    title: 'Vượt mốc <em>không chuyển đỏ</em>',
    lead: 'Ngân sách là mốc tham chiếu tự đặt cho từng nhóm. App không đồng bộ ngân hàng và không bao giờ chặn mua.',
    points: [
      'Vượt mốc hiện màu <strong>xám trung tính</strong> kèm dòng “App không chặn mua”, để quan sát thay vì gây cảm giác tội lỗi.',
      'Phần <strong>khả dụng cho danh sách mong muốn</strong> trừ dự phòng chi thường ngày và chừa 10% an toàn.',
      'Nút “Vì sao con số này?” trình bày từng bước tính bằng chính số liệu của người dùng.',
    ],
    chips: [F('Firestore realtime'), chip('Tính trên máy')],
    path: 'users/{uid}/budgets/{yyyy-MM}',
  },
  {
    id: 'mo-hinh',
    screen: 'patterns',
    rail: 'Mô hình',
    pose: { ry: 0.22, rx: -0.03 },
    eyebrow: 'Mô hình chi tiêu',
    title: 'Mình hay mua lúc nào, <em>vì điều gì?</em>',
    lead: 'Một kỳ tuần hoặc tháng cho mọi con số: tổng chi, số khoản, tỉ lệ 8 động cơ và khung giờ mua sắm.',
    points: [
      'Khung giờ mua sắm hé lộ thói quen <strong>mua buổi tối</strong>, lúc cảm xúc dễ chi phối quyết định.',
      'Màu động cơ thống nhất giữa app và web admin.',
      'Thống kê tính ngay trên máy từ luồng Firestore realtime.',
    ],
    chips: [F('Firestore realtime'), chip('Aggregation on-device')],
  },
  {
    id: 'goc-nhin',
    screen: 'insights',
    rail: 'Góc nhìn',
    pose: { ry: 0.3, rx: -0.05 },
    eyebrow: 'Góc nhìn AI',
    title: 'Code tính số, <em>AI chỉ viết câu</em>',
    lead: 'Mỗi thẻ hiện câu mẫu trước, rồi thay bằng câu Gemini viết lại nếu câu đó qua được bộ kiểm tra.',
    points: [
      'Câu AI có số lạ, quá dài hoặc có từ phán xét (“lãng phí”, “bốc đồng”, “nên mua”…) sẽ <strong>giữ nguyên câu mẫu</strong>.',
      'Chỉ gửi số liệu tổng hợp và động cơ; <strong>không gửi ghi chú hay link</strong>. Cần ít nhất 3 khoản mua trong tháng.',
      '<strong>Remote Config</strong> bật/tắt AI và đổi model từ xa; <strong>App Check</strong> bảo vệ mọi lời gọi.',
    ],
    chips: [AI('Gemini · ai_insight_model'), F('Remote Config'), F('App Check')],
  },
  {
    id: 'chiem-nghiem',
    screen: 'reflection',
    rail: 'Chiêm nghiệm',
    pose: { ry: 0.24, rx: -0.04, rz: 0.01 },
    eyebrow: 'Chiêm nghiệm tháng',
    title: 'Nhìn lại tháng, <em>đặt một mục tiêu nhỏ</em>',
    lead: 'Tổng chi, đoạn chiêm nghiệm, phân bổ 8 động cơ; tự chấm mức hài lòng 1–5 và đặt mục tiêu cho tháng sau.',
    points: [
      'Món đã quyết định không mua là con số trung tính, <strong>không bao giờ gọi là “tiết kiệm”</strong>.',
      'Báo cáo <strong>PDF dựng ngay trên máy</strong>, nhúng font Be Vietnam Pro nên đủ dấu tiếng Việt và ký hiệu ₫.',
      'Không tải lên Cloud Storage (quyết định D7): người dùng tự chọn app để lưu, gửi hoặc in.',
    ],
    chips: [F('Firestore: reflections'), chip('PDF on-device'), F('Analytics: export_report')],
    path: 'users/{uid}/reflections/{yyyy-MM}',
  },
  {
    id: 'ca-nhan',
    screen: 'profile',
    rail: 'Cá nhân',
    pose: { ry: 0.28, rx: -0.04 },
    eyebrow: 'Cá nhân & thông báo',
    title: 'Đổi cấu hình <em>không cần cập nhật app</em>',
    lead: 'Xem cấu hình Remote Config đang áp dụng, bật thông báo, đọc lại tin FCM đã nhận, xuất dữ liệu ra CSV.',
    points: [
      'FCM nhận tin ở cả ba trạng thái: <strong>đang mở, chạy nền, đã đóng</strong>; tối đa 50 tin lưu trên máy.',
      'Quyền thông báo chỉ hỏi khi người dùng bấm <strong>“Bật thông báo”</strong>.',
      'CSV có BOM UTF-8 để Excel đọc đúng tiếng Việt; xoá dữ liệu luôn qua hộp thoại đỏ “Không thể hoàn tác.”',
    ],
    chips: [F('Remote Config'), F('Cloud Messaging'), AND('Local notifications'), chip('CSV export')],
  },
  {
    id: 'he-sinh-thai',
    kind: 'ecosystem',
    screen: 'profile',
    demo: 'idle',
    pose: { ry: Math.PI - 0.42, rx: -0.06, s: 0.96 },
    eyebrow: 'Hệ sinh thái',
    title: 'Một hệ thống, <em>ba cửa vào</em>',
    lead: 'App Android, tiện ích Chrome và web admin dùng chung một dự án Firebase, phân quyền bằng Security Rules.',
    nav: 'Hệ sinh thái',
  },
  {
    id: 'bang-chung',
    kind: 'evidence',
    screen: 'history',
    pose: { ry: 0.26, rx: -0.04 },
    eyebrow: 'Bằng chứng',
    title: 'Con số <em>chạy được</em> thay cho lời hứa',
    lead: 'Các kết quả dưới đây sinh ra từ test tự động trong repo, có thể chạy lại trước mặt thầy.',
    nav: 'Bằng chứng',
  },
  {
    id: 'cam-on',
    kind: 'thanks',
    screen: 'onboarding',
    demo: 'idle',
    pose: { ry: -0.2, rx: -0.02 },
    eyebrow: 'Cảm ơn thầy và các bạn',
    title: 'Hiểu mình, <em>không phán xét</em>',
    lead: 'Why I Buy? giúp người trẻ dừng lại một nhịp trước mỗi lần mua, và hiểu vì sao mình mua.',
    nav: 'Cảm ơn',
  },
]

export const ecosystem = {
  core: {
    kicker: 'Firebase project',
    name: 'prm393-34056',
    desc: 'Một nguồn dữ liệu cho cả ba cửa vào. Firestore Security Rules phân quyền theo role user / staff / admin.',
    services: ['Auth', 'Firestore', 'Rules', 'FCM', 'Remote Config', 'Analytics', 'Crashlytics', 'App Check', 'AI Logic', 'Hosting'],
  },
  nodes: [
    { kicker: 'Android · Flutter', name: 'App mobile', desc: 'Lưu món, cân nhắc, ghi khoản mua, góc nhìn AI. MVVM + Provider.' },
    { kicker: 'Chrome / Edge', name: 'Tiện ích Why I Buy?', desc: 'Lưu món ngay trên trang Shopee, liên kết với app qua mã QR.' },
    { kicker: 'Flutter Web · Hosting', name: 'Web admin', desc: 'Staff/admin: sự kiện sale, duyệt đề xuất, thông báo, dashboard số liệu thật.' },
  ],
}

/** Numbers re-checked from the repo; `src` says where each one comes from. */
export const evidence = [
  { value: '268', unit: '/268', label: 'ca test Security Rules đạt trên Firebase Emulator (user, staff, admin; cho phép và từ chối)', src: 'prm393_lab03/evidence/rules/firestore-rules-results.md', brand: true },
  // Re-run on 07/11/2026: 609 pass, 1 fail ("Bỏ qua … Hoàn tác" in decision_and_budget_test.dart). Update after the fix.
  { value: '609', unit: '/610', label: 'test Flutter của app mobile đạt (unit, widget, viewmodel)', src: 'prm393_lab03/test · flutter test' },
  { value: '42', unit: '/42', label: 'test của web admin: viewmodel, AI, giao diện ở 3 kích thước × sáng/tối', src: 'prm393_flutter_admin/test · flutter test' },
  { value: '8', unit: ' động cơ', label: 'động cơ mua có màu, icon riêng, dùng thống nhất ở app, extension và web admin', src: 'lib/models/buying_motive.dart' },
]

export const team = [
  { name: 'Huân', role: 'Thành viên' },
  { name: 'Hoàng', role: 'Thành viên' },
  { name: 'Kiệt', role: 'Thành viên' },
  { name: 'Khoa', role: 'Thành viên' },
  { name: 'An', role: 'Thành viên' },
]

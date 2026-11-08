/**
 * Presentation script following "Software Project Presentation Guideline V11":
 * P1 Problem (01–06) · P2 Design (07–16) · P3 Demo (17–20) · P4 Proof (21–24).
 * Every claim was checked against prm393_lab03 (lib/, docs/, evidence/).
 *
 * Phone slides: screen (one module) or screens [{ screen, demo }] played in sequence.
 * Diagram slides: visual = key of src/diagrams/visuals.js (the phone fades out).
 * Demo slides: wf = { actor, trigger, pre, result, exception, steps: [{ t, s }] } (s = index in screens).
 */

const chip = (label, kind = '') => ({ label, kind })
const F = (label) => chip(label, 'firebase')
const AI = (label) => chip(label, 'ai')
const AND = (label) => chip(label, 'android')

export const chapters = [
  // ---------------- P1 · PROBLEM ----------------
  {
    id: 'overview',
    kind: 'hero',
    part: 'Problem',
    screen: 'home',
    demo: 'idle',
    pose: { ry: 0.3, rx: -0.04 },
    eyebrow: 'PRM393 · Final Assignment · One complete system on Firebase',
    nav: 'P1 · Problem · Overview',
  },
  {
    id: 'context',
    part: 'Problem',
    screen: 'lockscreen',
    pose: { ry: 0.2, rx: -0.03, rz: 0.015 },
    eyebrow: 'Context',
    title: 'Mua sắm online diễn ra <em>trong vài giây</em>',
    qa: 'Đề tài ra đời trong bối cảnh nào, hiện nay người dùng làm ra sao?',
    points: [
      '<strong>Môi trường:</strong> người trẻ mua trên Shopee và các sàn khác ngay trên điện thoại, nhiều nhất vào các đợt sale.',
      '<strong>Quy trình hiện tại:</strong> thấy món → thả vào giỏ hoặc mua ngay → quên lý do; món chưa mua nằm rải rác trong giỏ, tin nhắn, ảnh chụp.',
      '<strong>Công cụ đang dùng:</strong> giỏ hàng của sàn, ghi chú, app chi tiêu chỉ ghi số tiền.',
    ],
    chips: [chip('9.9 · 10.10 · 11.11 · 12.12'), chip('ngày 15 · ngày 25')],
    note: 'Màn hình khoá bên trái là minh hoạ bối cảnh, không phải màn của app.',
  },
  {
    id: 'problem',
    part: 'Problem',
    visual: 'problem',
    eyebrow: 'Problem',
    title: 'Mua vì cảm xúc, rồi <em>không biết vì sao</em>',
    qa: 'Vấn đề có thật không, và gây hậu quả gì?',
    points: [
      'Ba điểm nghẽn: <strong>mua theo cảm xúc/sale</strong>, <strong>không ghi lý do mua</strong>, <strong>món muốn mua nằm rải rác</strong>.',
      'Người bị ảnh hưởng nhiều nhất: người trẻ thu nhập chưa ổn định, hay mua đêm muộn và mua theo mạng xã hội.',
    ],
    evidence: 'Lịch sale định kỳ của sàn · đề xuất giải pháp của nhóm (mục 1, 4)',
  },
  {
    id: 'solution',
    part: 'Problem',
    visual: 'solution',
    eyebrow: 'Proposed solution',
    title: 'Mỗi pain point có <em>một câu trả lời</em> trong app',
    qa: 'Giải pháp có trúng vấn đề không, làm tới đâu?',
    points: [
      'Một giải pháp tổng thể: <strong>người cố vấn tỉnh táo</strong>, không phải app săn sale. Nếu mua vì cảm xúc thì app gợi ý chờ.',
      'Khác biệt: ngôn ngữ trung lập, ngân sách không chặn mua, AI chỉ diễn đạt chứ không phán xét.',
    ],
    evidence: 'Bảng ánh xạ bên trái · phạm vi MVP = 3 workflow sẽ demo',
  },
  {
    id: 'actors',
    part: 'Problem',
    visual: 'actors',
    eyebrow: 'Main actors',
    title: 'Ba vai trò người, <em>ba hệ thống</em> đi kèm',
    qa: 'Ai dùng hệ thống, mỗi vai trò được làm gì?',
    points: [
      'Vai trò nằm ở <strong>users/{uid}.role</strong>; chỉ admin đổi vai trò người khác, không ai tự nâng quyền.',
      'Web admin chỉ cho <strong>staff</strong> và <strong>admin</strong> đăng nhập; tài khoản <strong>user</strong> bị từ chối.',
    ],
    evidence: 'firestore.rules · bảng phân quyền trong docs/data-model.md',
  },
  {
    id: 'features',
    part: 'Problem',
    visual: 'features',
    eyebrow: 'Main features',
    title: 'Bốn nhóm tính năng, <em>ba workflow</em> để demo',
    qa: 'Hệ thống làm được gì, đâu là workflow quan trọng nhất?',
    points: [
      '<strong>WF-01</strong> Lưu món & hoãn mua · <strong>WF-02</strong> Quyết định & ghi chi · <strong>WF-03</strong> Nhìn lại cuối tháng.',
      'Kết quả của workflow trước là đầu vào của workflow sau, nên demo kể được một câu chuyện liền mạch.',
    ],
    evidence: 'Tính năng ↔ actor ↔ vấn đề nối ở slide Traceability (16)',
  },

  // ---------------- P2 · DESIGN ----------------
  {
    id: 'business-flow',
    part: 'Design',
    visual: 'businessFlow',
    eyebrow: 'Business flow',
    title: 'Từ “thấy món” đến <em>“hiểu vì sao mua”</em>',
    qa: 'Các actor phối hợp với nhau thế nào, từ đầu đến cuối?',
    points: [
      'Ba làn: <strong>Người dùng</strong> quyết định, <strong>App</strong> nhắc và tính toán, <strong>Firebase</strong> lưu trạng thái.',
      'Nhánh rẽ duy nhất là quyết định Mua · Chờ · Bỏ qua; mỗi nhánh để lại một bản ghi trong decisions.',
    ],
    evidence: 'docs/data-model.md · Quy tắc nghiệp vụ 2–6',
  },
  {
    id: 'state-machine',
    part: 'Design',
    visual: 'stateMachine',
    eyebrow: 'State machine',
    title: 'Một món qua bốn trạng thái, <em>không bao giờ bị khoá</em>',
    qa: 'Đối tượng nghiệp vụ đổi trạng thái thế nào, theo luật nào?',
    points: [
      'Rules chỉ cho <strong>considering ↔ purchased</strong> (bắt buộc purchaseId) và <strong>skipped</strong>.',
      '<strong>Chờ</strong> không đổi status: chỉ đặt reviewAt + một decision “wait”.',
      'Thời gian hoãn là lời nhắc: khi đang hoãn vẫn bấm được Mua · Chờ · Bỏ qua.',
    ],
    evidence: 'firestore.rules · 268/268 ca test Rules',
  },
  {
    id: 'architecture',
    part: 'Design',
    visual: 'architecture',
    eyebrow: 'System architecture',
    title: 'Ba cửa vào, <em>một nguồn dữ liệu</em> Firebase',
    qa: 'Hệ thống gồm những khối nào, đặt ở đâu, vì sao chọn?',
    points: [
      '<strong>Quyết định 1 · Firebase thay backend tự viết:</strong> có realtime, offline, phân quyền bằng Rules. Đổi lại: phụ thuộc Google, truy vấn phức tạp phải dựng index/aggregation.',
      '<strong>Quyết định 2 · PDF dựng trên máy (D7), không lên Cloud Storage:</strong> dữ liệu chi tiêu không rời máy. Đổi lại: không có link chia sẻ sẵn.',
      'Triển khai: app Android (APK) · web admin trên Firebase Hosting · push server Spring Boot chạy riêng.',
    ],
    evidence: 'docs/decisions.md (D7) · firebase.json · docs/architecture.md',
  },
  {
    id: 'tech-stack',
    part: 'Design',
    visual: 'stack',
    eyebrow: 'Technology stack',
    title: 'Mỗi công nghệ gắn với <em>một vai trò</em>',
    qa: 'Dùng công nghệ gì, cho việc gì?',
    points: [
      'Không dùng công nghệ chỉ để “có”: AI chỉ viết câu, Remote Config để đổi luật mà không phát hành lại app.',
      'Kiểm thử chạy trên Firebase Emulator, không đụng dữ liệu thật.',
    ],
    evidence: 'pubspec.yaml · spring-boot-push/pom.xml',
  },
  {
    id: 'uiux',
    part: 'Design',
    visual: 'sitemap',
    eyebrow: 'UI/UX design',
    title: 'Một ngôn ngữ thiết kế, <em>không phán xét</em>',
    qa: 'Giao diện tổng thể, điều hướng và các trạng thái UI ra sao?',
    points: [
      '5 tab: Trang chủ · Lịch sử · Mô hình · Góc nhìn · Cá nhân. Màu vàng <strong>#FFDE02</strong>, chữ Be Vietnam Pro.',
      '8 động cơ có màu và icon riêng; <strong>vượt ngân sách vẫn màu xám</strong>, Mua · Chờ · Bỏ qua cùng màu.',
      'Đủ trạng thái Loading · Empty · Error · Offline; nút tối thiểu 48dp, chữ từ 14sp, nhãn đọc màn hình tiếng Việt.',
    ],
    evidence: 'lib/app/routes.dart · docs/design-tokens.md · docs/design-traceability.md',
  },
  {
    id: 'sequence',
    part: 'Design',
    visual: 'sequence',
    eyebrow: 'Sequence diagram',
    title: 'Code tính số, <em>Gemini chỉ viết câu</em>',
    qa: 'Các thành phần phối hợp thế nào trong một tương tác tiêu biểu?',
    points: [
      'Chỉ gọi AI khi tab Góc nhìn đang mở và tháng có ít nhất 3 khoản mua.',
      'Câu AI có số lạ, quá dài hoặc có từ phán xét thì giữ <strong>câu mẫu</strong>; chip ghi rõ nguồn.',
    ],
    evidence: 'lib/services/ai_insight_service.dart · test ai_insight',
  },
  {
    id: 'class-design',
    part: 'Design',
    visual: 'classDesign',
    eyebrow: 'Class design',
    title: 'Phụ thuộc <em>đi một chiều</em>',
    qa: 'Code được tổ chức thế nào, ai chịu trách nhiệm gì?',
    points: [
      'MVVM: <strong>Screen → ViewModel → Service → Firebase</strong>; service là interface nên test thay bằng bản giả.',
      'Mua từ danh sách là một <strong>batch</strong>: tạo purchase và đổi món sang purchased cùng lúc.',
    ],
    evidence: 'docs/architecture.md · lib/viewmodels · lib/services',
  },
  {
    id: 'db-concept',
    part: 'Design',
    visual: 'dbConcept',
    eyebrow: 'Database · conceptual',
    title: 'Dữ liệu cá nhân <em>nằm dưới người dùng</em>',
    qa: 'Có những thực thể nào, quan hệ ra sao?',
    points: [
      'Mọi dữ liệu cá nhân thuộc <strong>users/{uid}</strong>, chỉ chủ tài khoản đọc/ghi.',
      'Sự kiện sale, thông báo, đề xuất là dữ liệu dùng chung do staff quản lý.',
    ],
    evidence: 'docs/data-model.md',
  },
  {
    id: 'db-physical',
    part: 'Design',
    visual: 'dbPhysical',
    eyebrow: 'Database · logical / physical',
    title: 'Ràng buộc nằm ngay <em>trong Security Rules</em>',
    qa: 'Cấu trúc thật trên database đang chạy là gì?',
    points: [
      'Firestore không có schema: kiểu, độ dài, giá trị hợp lệ được kiểm tra bằng Rules.',
      'Lịch sử giá và quyết định <strong>chỉ thêm, không sửa</strong>; giá chưa biết là null, không bao giờ 0.',
    ],
    evidence: 'firestore.rules · firestore.indexes.json',
  },
  {
    id: 'traceability',
    part: 'Design',
    visual: 'traceability',
    eyebrow: 'Traceability',
    title: 'Mỗi tính năng thấy được <em>từ UI tới test</em>',
    qa: 'Thiết kế có nhất quán qua UI, code, dữ liệu và kiểm thử không?',
    points: ['Mỗi nhóm tính năng có mã F-xx gắn actor; mỗi business rule BR-xx sinh ít nhất một test TC-xx.', 'Không có class hay màn hình nào “có hình nhưng không dùng” trong 3 workflow.'],
    evidence: 'prm393_lab03/test · firebase/tests/rules.test.mjs',
  },

  // ---------------- P3 · DEMO ----------------
  {
    id: 'demo-plan',
    part: 'Demo',
    visual: 'demoPlan',
    eyebrow: 'Demo plan',
    title: 'Ba workflow, <em>một câu chuyện</em>',
    qa: 'Demo chứng minh điều gì, theo thứ tự nào?',
    points: [
      'Theo một món: <strong>“Máy ảnh film mini”</strong>, 450.000 ₫, động cơ Cảm xúc.',
      'Kết quả của WF-01 là đầu vào của WF-02; kết quả WF-02 là dữ liệu cho WF-03.',
      'Dữ liệu cố định: Cá nhân → Dữ liệu mẫu (DemoDataService), tài khoản demo riêng. Demo chạy trên điện thoại Android thật, web này là bản dự phòng.',
    ],
    evidence: 'Dữ liệu mẫu DemoDataService (07/11/2026)',
  },
  {
    id: 'wf-01',
    part: 'WF-01',
    screens: [{ screen: 'add-item' }, { screen: 'extension-link' }],
    pose: { ry: 0.26, rx: -0.04 },
    eyebrow: 'Demo WF-01',
    title: 'Lưu món vào <em>danh sách cân nhắc</em>',
    wf: {
      actor: 'Người dùng · Tiện ích Chrome',
      trigger: 'Chia sẻ link từ app Shopee, hoặc bấm lưu trên tiện ích',
      pre: 'Đã đăng nhập (chưa thì giữ dữ liệu chia sẻ, mở lại sau khi vào app)',
      result: 'Món mới ở trạng thái considering, cooldownUntil = +3 ngày',
      decision: 'Nhu cầu? → không hoãn (BR-01) · có giá? (BR-06) · mã QR còn hạn? (BR-08)',
      exception: 'Không đọc được giá → để trống, không bịa; QR hết hạn → báo tạo mã mới',
      trace: 'F-01 · UI-03, UI-13 · ShareIntentService · TC-01, 02, 09, 11',
      steps: [
        { t: 'Form tự điền tên, link; đọc ảnh và shop từ trang Shopee', s: 0 },
        { t: 'Link không có giá → ô giá để trống (BR-06)', s: 0, exc: true },
        { t: 'Chọn động cơ (mặc định Cảm xúc), hoãn 3 ngày (BR-01), lưu', s: 0 },
        { t: 'Từ máy tính: quét QR, đồng ý liên kết tiện ích (BR-08)', s: 1 },
      ],
    },
    chips: [AND('Share Intent'), F('Firestore'), F('Anonymous Auth')],
  },
  {
    id: 'wf-02',
    part: 'WF-02',
    screens: [{ screen: 'pre-purchase' }, { screen: 'review-wait' }, { screen: 'wishlist' }, { screen: 'record-purchase' }],
    pose: { ry: 0.24, rx: -0.04, rz: -0.01 },
    eyebrow: 'Demo WF-02',
    title: 'Quyết định <em>Mua · Chờ · Bỏ qua</em>',
    wf: {
      actor: 'Người dùng · Gemini (chỉ viết câu)',
      trigger: 'Hết thời gian hoãn, đến hẹn xem lại, hoặc mở “Trước khi mua”',
      pre: 'Món đang ở considering',
      result: 'Chờ: reviewAt · Bỏ qua: skipped · Mua: purchases + purchased (1 batch)',
      decision: 'Mua (BR-02) · Chờ (BR-03) · Bỏ qua (BR-04)',
      exception: 'AI tắt/lỗi → câu mẫu (BR-07) · Bỏ qua nhầm → Hoàn tác 5 giây',
      trace: 'F-02, F-03 · UI-05, 06, 07 · WishlistViewModel, PurchaseService · TC-03…08',
      steps: [
        { t: 'Trước khi mua: vài câu hỏi, thẻ quan sát, câu gợi mở', s: 0 },
        { t: 'Chờ đến đợt sale 11.11: đặt reviewAt, status giữ nguyên (BR-03)', s: 1 },
        { t: 'Bỏ qua nhầm → Hoàn tác trong 5 giây (BR-04)', s: 2, exc: true },
        { t: 'Mua: ghi khoản mua 2 bước, món → purchased cùng batch (BR-02)', s: 3 },
      ],
    },
    chips: [AI('AI Logic · Gemini'), F('Firestore batch'), AND('Local notifications')],
  },
  {
    id: 'wf-03',
    part: 'WF-03',
    screens: [{ screen: 'budget' }, { screen: 'insights' }, { screen: 'reflection' }],
    pose: { ry: 0.3, rx: -0.05 },
    eyebrow: 'Demo WF-03',
    title: 'Lập <em>chiêm nghiệm chi tiêu</em> tháng',
    wf: {
      actor: 'Người dùng · Gemini',
      trigger: 'Cuối tháng, hoặc mở tab Góc nhìn',
      pre: 'Có khoản mua trong tháng (AI cần ≥ 3 khoản)',
      result: 'Chiêm nghiệm tháng (mức hài lòng + mục tiêu) và file PDF',
      decision: 'Vượt mốc ngân sách? → xám, không chặn · câu AI hợp lệ? (BR-07)',
      exception: 'Vượt ngân sách → “App không chặn mua” · câu AI sai → giữ câu mẫu',
      trace: 'F-04 · UI-09, 11, 12 · AiInsightService · TC-10',
      steps: [
        { t: 'Ngân sách theo nhóm, giảm hạn mức → vượt mốc vẫn xám', s: 0 },
        { t: 'Góc nhìn: câu mẫu trước, câu AI hợp lệ thay vào', s: 1 },
        { t: 'Một thẻ AI có số lạ → giữ câu mẫu (BR-07)', s: 1, exc: true },
        { t: 'Chiêm nghiệm: chấm 1–5, đặt mục tiêu, xuất PDF ngay trên máy', s: 2 },
      ],
    },
    chips: [F('Firestore realtime'), AI('Gemini'), chip('PDF on-device')],
  },

  // ---------------- P4 · PROOF ----------------
  {
    id: 'testing',
    part: 'Proof',
    visual: 'testing',
    eyebrow: 'Testing',
    title: 'Kiểm thử <em>luật nghiệp vụ</em> chứ không chỉ màn hình',
    qa: 'Đã kiểm chứng những gì, kết quả ra sao?',
    points: [
      'Mỗi business rule và chuyển trạng thái có test: BR-01…09 → TC-01…12 (phụ lục A2).',
      'Chạy lại ngày 07/11/2026: TC-07 còn lỗi, nêu ở Limitations. Chưa có CI tự động.',
      'Rules chạy trên Firebase Emulator, sinh báo cáo Markdown trong evidence/.',
    ],
    evidence: 'evidence/rules/firestore-rules-results.md · flutter test',
  },
  {
    id: 'achievements',
    part: 'Proof',
    visual: 'achievements',
    eyebrow: 'Achievements',
    title: 'Mục tiêu đặt ra <em>đã có bằng chứng</em>',
    qa: 'Kết quả so với mục tiêu ban đầu?',
    points: ['Mỗi mục tiêu ghi kèm nơi kiểm chứng: workflow vừa demo hoặc file test trong repo.'],
  },
  {
    id: 'limitations',
    part: 'Proof',
    visual: 'limitations',
    eyebrow: 'Limitations',
    title: 'Những gì <em>chưa làm được</em>',
    qa: 'Giới hạn là gì, ảnh hưởng thế nào, xử lý ra sao?',
    points: ['Nêu thẳng để hội đồng thấy phạm vi thật của sản phẩm.'],
  },
  {
    id: 'conclusion',
    part: 'Proof',
    visual: 'conclusion',
    eyebrow: 'Conclusion',
    title: 'Hiểu mình, <em>không phán xét</em>',
    qa: 'Ba điều cần nhớ về Why I Buy?',
    points: ['Cảm ơn thầy và các bạn đã lắng nghe. Nhóm sẵn sàng nhận câu hỏi.'],
    chips: [chip('github.com/hoanghuan2005/prm393_lab03'), chip('prm393-34056.web.app'), chip('presentation-lab3.vercel.app')],
  },

  // ---------------- APPENDIX (dự phòng khi hội đồng hỏi sâu) ----------------
  {
    id: 'a1',
    part: 'Phụ lục',
    visual: 'wfSpec',
    eyebrow: 'A1 · Đặc tả workflow',
    title: 'Ba workflow theo <em>mẫu đặc tả W10</em>',
    qa: 'Mỗi workflow có đủ actor, trigger, quyết định, ngoại lệ và postcondition không?',
    points: ['Mỗi workflow 3–7 bước, có ít nhất một nhánh ngoại lệ, postcondition khớp state machine.'],
  },
  {
    id: 'a2',
    part: 'Phụ lục',
    visual: 'brTc',
    eyebrow: 'A2 · Business rule',
    title: 'Mỗi business rule có <em>ít nhất một test</em>',
    qa: 'Luật nghiệp vụ nào được kiểm thử?',
    points: ['Mỗi BR gắn với điểm rẽ trong business flow (slide 07) hoặc guard trong state machine (slide 08).'],
  },
  {
    id: 'a3',
    part: 'Phụ lục',
    visual: 'tcList',
    eyebrow: 'A3 · Test case',
    title: 'Ca kiểm thử <em>và kết quả thật</em>',
    qa: 'Các test case nằm ở đâu, kết quả ra sao?',
    points: ['TC-03, TC-08, TC-12 chạy trên Firebase Emulator (Rules); còn lại là flutter test. TC-07 đang lỗi.'],
    evidence: 'evidence/rules/firestore-rules-results.md · prm393_lab03/test',
  },
]

/** Numbers re-checked from the repo; `src` says where each one comes from. */
export const evidence = [
  { value: '268', unit: '/268', label: 'ca test Security Rules đạt trên Firebase Emulator', src: 'evidence/rules/firestore-rules-results.md', brand: true },
  // Re-run on 07/11/2026: 609 pass, 1 fail ("Bỏ qua … Hoàn tác" in decision_and_budget_test.dart). Update after the fix.
  { value: '609', unit: '/610', label: 'test Flutter của app mobile đạt', src: 'prm393_lab03/test' },
  { value: '42', unit: '/42', label: 'test của web admin đạt', src: 'prm393_flutter_admin/test' },
  { value: '3', unit: ' role', label: 'user · staff · admin, mỗi role có ca cho phép và từ chối', src: 'firestore.rules' },
]

export const team = [
  { name: 'Nguyễn Đình Ngọc Ân', role: 'Thành viên' },
  { name: 'Ngô Gia Kiệt', role: 'Thành viên' },
  { name: 'Huỳnh Đăng Khoa', role: 'Thành viên' },
  { name: 'Đào Tâm Hoàng', role: 'Thành viên' },
  { name: 'Hồ Hữu Hoàng Huân', role: 'Thành viên' },
]

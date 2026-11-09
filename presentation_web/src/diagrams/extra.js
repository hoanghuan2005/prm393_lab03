/**
 * Guideline additions: BR / TC / UI codes, sitemap, workflow specs (W10 template),
 * appendix tables, and the Proof visuals that cite those codes.
 * Test names are the real ones in prm393_lab03/test and evidence/rules.
 */
import { graph, table, tag } from './kit.js'
import { visuals } from './visuals.js'
import { team } from '../data/chapters.js'

export const BR = [
  ['BR-01', 'Mọi món được hoãn mặc định 3 ngày (Remote Config cooling_off_days), trừ động cơ Nhu cầu', 'TC-01, TC-02'],
  ['BR-02', 'Status chỉ considering · purchased · skipped; purchased bắt buộc purchaseId; mua từ món là 1 batch', 'TC-03, TC-04'],
  ['BR-03', 'Chờ chỉ đặt reviewAt + decision “wait”, status vẫn considering', 'TC-05'],
  ['BR-04', 'Bỏ qua → skipped; Hoàn tác trong 5 giây hoặc Cân nhắc lại → considering, cùng batch', 'TC-06, TC-07'],
  ['BR-05', 'decisions và priceSnapshots chỉ thêm, không sửa', 'TC-08'],
  ['BR-06', 'Giá chưa biết là null, không bao giờ lưu 0', 'TC-09'],
  ['BR-07', 'Câu AI có số lạ hoặc từ phán xét bị thay bằng câu mẫu', 'TC-10'],
  ['BR-08', 'Ghép tiện ích chỉ hợp lệ khi yêu cầu pending và dưới 5 phút', 'TC-11'],
  ['BR-09', 'Không ai tự đổi role; web admin chỉ cho staff/admin', 'TC-12'],
]

export const TC = [
  ['TC-01', 'decision_sale_test · cooling-off period (not for Nhu cầu)', 'Pass'],
  ['TC-02', 'notification_and_list_test · cooldown countdown is rounded up', 'Pass'],
  ['TC-03', 'rules · R-84 status “waiting” bị chặn', 'Pass'],
  ['TC-04', 'decision_and_budget_test · buyFromWishlist (batch)', 'Pass'],
  ['TC-05', 'decision_and_budget_test · Chờ keeps “Đang cân nhắc”, logs “wait”', 'Pass'],
  ['TC-06', 'decision_and_budget_test · returns the item to “Đang cân nhắc” in the same batch', 'Pass'],
  ['TC-07', 'decision_and_budget_test · Bỏ qua … 5-second “Hoàn tác”', 'Fail (đang sửa)'],
  ['TC-08', 'rules · R-96 sửa giá đã ghi · R-97 choice lạ bị chặn', 'Pass'],
  ['TC-09', 'share_intent_test · returns null for null or empty input', 'Pass'],
  ['TC-10', 'ai_insight_test · replaces a card that invents a number', 'Pass'],
  ['TC-11', 'extension_link_test · only a pending request under 5 minutes old is asked', 'Pass'],
  ['TC-12', 'rules · R-04 tự nâng role · R-11 admin tự đổi role bị chặn', 'Pass'],
]

export const WF_SPEC = {
  'WF-01': {
    name: 'Lưu món vào danh sách cân nhắc',
    actor: 'Người dùng · Tiện ích Chrome · Bong bóng Android',
    trigger: 'Chia sẻ link Shopee / bấm lưu trên tiện ích / bong bóng nhắc khi xem một món quá 15 giây',
    pre: 'Đã đăng nhập; nếu chưa, dữ liệu chia sẻ được giữ lại',
    decision: 'Động cơ Nhu cầu? → không hoãn (BR-01) · có giá? (BR-06) · yêu cầu ghép còn hạn? (BR-08)',
    exception: 'Không đọc được giá → để trống; mã QR hết hạn → báo tạo mã mới; mất mạng → ghi offline',
    post: 'wishlistItems: considering, cooldownUntil',
    trace: 'F-01 · UI-03, UI-13 · ShareIntentService, FloatingBubbleService · TC-01, 02, 09, 11',
  },
  'WF-02': {
    name: 'Quyết định mua và ghi khoản mua',
    actor: 'Người dùng · Gemini (chỉ viết câu)',
    trigger: 'Hết hoãn / đến hẹn / mở Trước khi mua',
    pre: 'Món ở considering',
    decision: 'Mua (BR-02) · Chờ (BR-03) · Bỏ qua (BR-04)',
    exception: 'Bỏ qua nhầm → Hoàn tác 5 s; AI lỗi → câu mẫu (BR-07)',
    post: 'purchased + purchases (1 batch) · hoặc reviewAt · hoặc skipped; luôn có decision',
    trace: 'F-02, F-03 · UI-05, 06, 07 · WishlistViewModel, PurchaseService · TC-03…08',
  },
  'WF-03': {
    name: 'Lập chiêm nghiệm chi tiêu tháng',
    actor: 'Người dùng · Gemini',
    trigger: 'Cuối tháng / mở Góc nhìn',
    pre: 'Có khoản mua trong tháng (AI cần ≥ 3)',
    decision: 'Vượt mốc ngân sách? → xám, không chặn · câu AI hợp lệ? (BR-07)',
    exception: 'AI tắt hoặc câu sai → câu mẫu; chưa đặt hạn mức → “chưa đặt”',
    post: 'reflections/{yyyy-MM}: rating + goal; file PDF trên máy',
    trace: 'F-04 · UI-09, 11, 12 · AiInsightService · TC-10',
  },
}

visuals.traceability = () =>
  table({
    cols: [
      { label: 'Feature', w: '1.05fr' },
      { label: 'Screen', w: '0.9fr' },
      { label: 'Class / Service', w: '1.25fr' },
      { label: 'Entity', w: '0.9fr' },
      { label: 'BR → Test', w: '0.95fr' },
    ],
    rows: [
      ['F-01 Lưu món ' + tag('WF-01', 'brand'), 'UI-03 · UI-13', 'ShareIntentService · FloatingBubbleService · ExtensionLinkViewModel', 'wishlistItems · extensionSessions', 'BR-01, 06, 08 → TC-01, 02, 09, 11'],
      ['F-02 Quyết định ' + tag('WF-02', 'brand'), 'UI-05 · UI-06', 'WishlistViewModel · WishlistService', 'wishlistItems · decisions', 'BR-02…05 → TC-03…08'],
      ['F-03 Ghi chi ' + tag('WF-02', 'brand'), 'UI-07', 'PurchaseService.buyFromWishlist', 'purchases', 'BR-02 → TC-04'],
      ['F-04 Nhìn lại ' + tag('WF-03', 'brand'), 'UI-09 · UI-11 · UI-12', 'BudgetViewModel · AiInsightService', 'budgets · reflections', 'BR-07 → TC-10'],
      ['F-05 Phân quyền', 'Web admin', 'firestore.rules', 'users.role', 'BR-09 → TC-12'],
    ],
  }) +
  '<p class="vis-note" style="margin-top:12px">Actor: F-01…F-04 = Người dùng (F-01 thêm Tiện ích Chrome) · F-05 = Staff / Admin. Mã UI ở slide 11; đầy đủ BR → TC ở phụ lục A2.</p>'

visuals.sitemap = () =>
  graph({
    w: 1000,
    h: 600,
    nodes: [
      { id: 'login', x: 20, y: 20, w: 190, h: 64, tone: 'muted', title: 'UI-01 Đăng nhập', sub: 'Onboarding → Auth', z: 1 },
      { id: 'shell', x: 260, y: 20, w: 720, h: 64, tone: 'accent', title: 'Thanh điều hướng 5 tab', sub: 'Trang chủ · Lịch sử · Mô hình · Góc nhìn · Cá nhân', z: 2 },
      { id: 'home', x: 260, y: 130, w: 132, h: 70, title: 'UI-02', sub: 'Trang chủ', z: 1 },
      { id: 'hist', x: 407, y: 130, w: 132, h: 70, title: 'UI-08', sub: 'Lịch sử', z: 1 },
      { id: 'pat', x: 554, y: 130, w: 132, h: 70, title: 'UI-10', sub: 'Mô hình', z: 1 },
      { id: 'ins', x: 701, y: 130, w: 132, h: 70, title: 'UI-11', sub: 'Góc nhìn AI', z: 1 },
      { id: 'pro', x: 848, y: 130, w: 132, h: 70, title: 'UI-13', sub: 'Cá nhân · thiết bị', z: 1 },
      { id: 'add', x: 20, y: 250, w: 190, h: 70, title: 'UI-03 Thêm món', sub: 'Share Shopee · form', z: 1 },
      { id: 'wish', x: 260, y: 250, w: 190, h: 70, title: 'UI-04 Danh sách', sub: 'mong muốn', z: 1 },
      { id: 'pre', x: 500, y: 250, w: 190, h: 70, title: 'UI-06 Trước khi mua', sub: '3–4 bước + kết quả', z: 1 },
      { id: 'bud', x: 740, y: 250, w: 240, h: 70, title: 'UI-09 Ngân sách', sub: 'từ Trang chủ / Lịch sử', z: 1 },
      { id: 'sale', x: 20, y: 370, w: 190, h: 70, title: 'UI-14 Lịch sale', sub: 'đợt 11.11', z: 1 },
      { id: 'det', x: 260, y: 370, w: 190, h: 70, title: 'UI-05 Chi tiết món', sub: 'Mua · Chờ · Bỏ qua', z: 1 },
      { id: 'rec', x: 500, y: 370, w: 190, h: 70, title: 'UI-07 Ghi khoản mua', sub: '2 bước', z: 1 },
      { id: 'ref', x: 740, y: 370, w: 240, h: 70, title: 'UI-12 Chiêm nghiệm', sub: 'mức hài lòng · PDF', z: 1 },
      {
        id: 'st',
        x: 20,
        y: 490,
        w: 960,
        h: 84,
        tone: 'group',
        title: 'Trạng thái chung cho mọi màn',
        html: `<span class="dg-sub">${tag('Loading')} ${tag('Empty')} ${tag('Error · Thử lại', 'warn')} ${tag('Success · SnackBar', 'ok')} ${tag('Offline · ghi sau', 'brand')}</span>`,
        z: 1,
      },
    ],
    edges: [
      { from: 'login', to: 'shell' },
      { from: 'home', to: 'wish', fp: [326, 200], tp: [326, 250] },
      { from: 'add', to: 'wish' },
      { from: 'wish', to: 'det', fs: 'b', ts: 't' },
      { from: 'det', to: 'sale' },
      { from: 'home', to: 'pre', fp: [360, 200], via: [[360, 226], [595, 226]], tp: [595, 250] },
      { from: 'det', to: 'rec' },
      { from: 'pre', to: 'rec', fs: 'b', ts: 't', label: 'Vẫn mua' },
      { from: 'hist', to: 'bud', fp: [473, 200], via: [[473, 236], [860, 236]], tp: [860, 250] },
      { from: 'ins', to: 'ref', fp: [767, 200], via: [[720, 216], [720, 405]], tp: [740, 405] },
    ],
  })

const wfRow = (code, f) => [
  `${code}<br><span style="font-weight:400;color:var(--ink-2)">${f.name}</span>`,
  `<b>Actor</b> ${f.actor}<br><b>Trigger</b> ${f.trigger}<br><b>Pre</b> ${f.pre}`,
  `<b>◇</b> ${f.decision}<br><b>Ngoại lệ</b> ${f.exception}`,
  `${f.post}<br><span style="color:var(--ink-2)">${f.trace}</span>`,
]

visuals.wfSpec = () =>
  table({
    cols: [
      { label: 'Workflow', w: '0.85fr' },
      { label: 'Actor · trigger · pre', w: '1.25fr' },
      { label: 'Quyết định · ngoại lệ', w: '1.3fr' },
      { label: 'Postcondition · truy vết', w: '1.2fr' },
    ],
    rows: Object.entries(WF_SPEC).map(([k, f]) => wfRow(k, f)),
    cls: 'dt--dense',
  })

visuals.brTc = () =>
  table({ cols: [{ label: 'BR', w: '0.45fr' }, { label: 'Business rule', w: '2.4fr' }, { label: 'Test', w: '0.7fr' }], rows: BR })

visuals.tcList = () =>
  table({
    cols: [{ label: 'TC', w: '0.45fr' }, { label: 'Ca kiểm thử (file · tên)', w: '2.4fr' }, { label: 'Kết quả', w: '0.7fr' }],
    rows: TC.map((r) => [r[0], r[1], r[2].startsWith('Fail') ? tag(r[2], 'warn') : tag(r[2], 'ok')]),
    cls: 'dt--dense',
  })

visuals.limitations = () =>
  table({
    cols: [{ label: 'Giới hạn', w: '1.25fr' }, { label: 'Loại · ưu tiên', w: '0.72fr' }, { label: 'Tác động', w: '1.1fr' }, { label: 'Bước tiếp theo', w: '1.1fr' }],
    rows: [
      ['App chưa đọc thông báo, hộp thư, lịch sale do web admin đăng (backend đã sẵn)', `${tag('product')} ${tag('cao', 'warn')}`, 'Staff đăng nội dung nhưng người dùng chưa thấy trong app', 'Nối app với InboxService, AnnouncementService trong packages/core'],
      ['Bong bóng nổi chưa có test tự động; chỉ chạy trên Android', `${tag('testing')} ${tag('trung bình')}`, 'Chỉ kiểm bằng tay trên máy thật; cần người dùng tự cấp quyền Overlay và Trợ năng', 'Viết test cho MethodChannel; thêm hướng dẫn cấp quyền trong app'],
      ['TC-07 đang lỗi: Bỏ qua → Hoàn tác', `${tag('testing')} ${tag('cao', 'warn')}`, 'BR-04 chưa có kiểm thử tự động xanh hoàn toàn', 'Sửa test trước buổi bảo vệ, chạy lại flutter test'],
      ['Chưa có khảo sát người dùng định lượng', `${tag('data')} ${tag('trung bình')}`, 'Chưa đo được mức giảm mua bốc đồng', 'Khảo sát trước/sau 2 tuần với nhóm dùng thử'],
    ],
  }) + '<p class="vis-note" style="margin-top:12px">Ngoài phạm vi (đã nêu ở slide 04): OCR giá từ ảnh chụp, bản iOS.</p>'

visuals.achievements = () =>
  table({
    cols: [{ label: 'Mục tiêu', w: '1fr' }, { label: 'Deliverable', w: '1.35fr' }, { label: 'Minh chứng', w: '1.05fr' }],
    rows: [
      ['Khoảng dừng trước khi mua', 'Danh sách cân nhắc, hoãn 3 ngày, Mua · Chờ · Bỏ qua ngang hàng', 'WF-01, WF-02 · TC-01, 05, 06'],
      ['Ghi được lý do mua', '8 động cơ ở mọi món, khoản mua; Mô hình, Góc nhìn, Chiêm nghiệm', 'WF-03 · TC-10'],
      ['Lưu món nhanh từ Shopee', 'Android Share Intent + bong bóng nổi + tiện ích Chrome ghép QR', 'TC-09, TC-11 · bong bóng: thử tay'],
      ['Một hệ thống trên Firebase', 'App Android · tiện ích · web admin dùng chung Firestore, 3 role', '268/268 ca Rules · TC-12'],
    ],
  }) +
  `<div class="vis-grid" style="grid-template-columns:repeat(3,1fr);margin-top:14px">
    <div class="vis-card"><span class="k">Đang chạy</span><h4>Firebase prm393-34056</h4><p>App Android · Firestore, Auth, FCM, Remote Config, AI Logic</p></div>
    <div class="vis-card"><span class="k">Web admin</span><h4>prm393-34056.web.app</h4><p>Firebase Hosting, cho staff/admin</p></div>
    <div class="vis-card"><span class="k">Mã nguồn</span><h4>github.com/hoanghuan2005</h4><p>/prm393_lab03 · app, web, rules, test</p></div>
  </div>`

visuals.conclusion = () => `
  <div class="vis-grid">
    <div class="vis-card"><span class="k">Vấn đề · người hưởng lợi</span><h4>Người trẻ mua theo cảm xúc, không biết vì sao</h4><p>Why I Buy? tạo khoảng dừng trước khi mua và ghi lại động cơ.</p></div>
    <div class="vis-card"><span class="k">Đã xây · đã demo</span><h4>App + tiện ích + web admin trên một Firebase</h4><p>WF-01 Lưu món · WF-02 Quyết định và ghi chi · WF-03 Chiêm nghiệm tháng.</p></div>
    <div class="vis-card"><span class="k">Minh chứng · hướng tiếp</span><h4>268/268 ca Rules · 609/610 test app · 42/42 web</h4><p>Tiếp theo: nối nội dung web admin vào app, sửa TC-07, khảo sát người dùng.</p></div>
  </div>
  <div class="team" style="margin-top:16px">${team.map((m) => `<div class="team__member"><div class="team__name">${m.name}</div><div class="team__role">${m.role}</div></div>`).join('')}</div>`

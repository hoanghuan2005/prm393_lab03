// Read-only UI inventory. Candidates require review; source files are never edited.
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const baseline = process.argv.includes('--baseline');
const files = dir => fs.readdirSync(dir, {withFileTypes: true}).flatMap(e =>
  e.isDirectory() ? files(path.join(dir, e.name)) : e.name.endsWith('.dart') ? [path.join(dir, e.name)] : []);
const findings = [];
for (const file of ['lib/screens', 'lib/widgets'].flatMap(p => files(path.join(root, p)))) {
  const source = fs.readFileSync(file, 'utf8');
  const relative = path.relative(root, file).replaceAll('\\', '/');
  const rules = {
    spacing: /(?:EdgeInsets\.[a-zA-Z]+\(|SizedBox\((?:height|width):)\s*(?:[a-zA-Z]+:\s*)?\d+/g,
    typography: /\b(?:fontSize:\s*[\d.]+|(?:const\s+)?TextStyle\()/g,
    radius: /\bBorderRadius\.circular\(\s*[\d.]+/g,
    color: /\bColor\(0x[\da-fA-F]+|(?<![\w])Colors\.(?!transparent)\w+|\bisDark\s*\?/g,
    touch: /\b(?:IconButton|GestureDetector|InkWell)\(/g,
    longText: /\bText\(\s*(?:\w+\.)*(?:title|name|note|shopName)\b/g,
    copy: /['"][^'"\r\n]*(?:Hãy|hãy|nên mua|tốt nhất|Decision Card|Wishlist|Section|Figma|debug|!)[^'"\r\n]*['"]/g,
  };
  for (const [kind, regex] of Object.entries(rules)) {
    for (const match of source.matchAll(regex)) {
      const line = source.slice(0, match.index).split('\n').length;
      const text = source.split('\n')[line - 1].trim();
      if (text.startsWith('//') || text.startsWith('*')) continue;
      findings.push({file: relative, line, kind, text});
    }
  }
}
const folder = path.join(root, 'build/ui-audit');
fs.mkdirSync(folder, {recursive: true});
fs.writeFileSync(path.join(folder, baseline ? 'static-baseline.json' : 'static.json'), JSON.stringify(findings, null, 2));
const counts = Object.fromEntries([...new Set(findings.map(f => f.kind))].map(kind => [kind, findings.filter(f => f.kind === kind).length]));
console.log(JSON.stringify({files: new Set(findings.map(f => f.file)).size, candidates: counts}, null, 2));

if (process.argv.includes('--report')) {
  for (const name of ['baseline.json', 'static-baseline.json', 'results.json']) {
    if (!fs.existsSync(path.join(folder, name))) {
      throw new Error(`Missing local audit evidence: ${name}. Existing docs/ui-audit.md was not overwritten.`);
    }
  }
  const load = name => {
    const file = path.join(folder, name);
    return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : [];
  };
  const before = load('baseline.json'), after = load('results.json');
  const staticBefore = load('static-baseline.json');
  const failed = rows => rows.filter(r => r.errors.length).length;
  const esc = text => text.replaceAll('|', '/').replaceAll('\n', ' ');
  const sourceScreens = files(path.join(root, 'lib/screens')).map(f => path.relative(path.join(root, 'lib/screens'), f).replaceAll('\\', '/'));
  const screenNames = f => f === 'sale_screens.dart' ? ['sale_calendar','sale_list','sale_plan']
    : [f.replace(/_screen\.dart$/, '').replace(/\.dart$/, '')];
  const matrix = (rows, name, w, scale, theme) => {
    const matches=rows.filter(r=>screenNames(name).includes(r.screen)&&r.width===w&&r.scale===scale&&r.theme===theme);
    return matches.length ? failed(matches)+'/'+matches.length : '—';
  };
  let report = `# Rà giao diện U1–U4 — Why I Buy?\n\nCập nhật 10/11/2026. Mã gốc trước sửa UI: bde58fa. Chỉ thay đổi giao diện, token, câu chữ và test. Không đổi service, ViewModel, dữ liệu, điều hướng hoặc dependency.\n\n`;
  report += `## 1. Lỗi hiển thị tự động\n\n`;
  report += `Lượt gốc: **${failed(before)}/${before.length} ca có lỗi**. Lượt gần nhất: **${failed(after)}/${after.length} ca có lỗi**. Một ca là một màn/trạng thái × kích thước × cỡ chữ × theme. Bộ mở rộng có ${new Set(after.map(r => r.screen)).size} loại màn/form/dialog, tổng ${after.length} ca. Không dùng skip. Mặc định mọi FlutterError đều làm test thất bại; chế độ UI_AUDIT_RECORD_ONLY chỉ dùng để thu baseline trước sửa. Baseline có ít biến thể hơn bộ cuối, nên không coi hai mẫu là cùng một mẫu đo.\n\n`;
  report += `Dữ liệu đầy: tên món 60 ký tự, tên shop dài, giá 999.999.999 ₫, 20 khoản mua/20 món mong muốn; dữ liệu rỗng chạy riêng. Cuộn đầu/giữa/cuối danh sách. Camera dùng MobileScannerPlatform giả cho preview và lỗi quyền; AI dùng service giả, không gửi ảnh/dữ liệu ra mạng. Các màn chi tiết cần đối tượng đầu vào luôn có đối tượng mẫu; “rỗng” ở đó là danh sách/tài khoản phụ thuộc trống, không phải truyền null trái API của màn. Hai form thêm món/ghi khoản mua thực tế là màn riêng, không tạo bottom sheet giả cho hai form đó.\n\n`;
  report += `Bảng dưới ghi **số ca lỗi/tổng ca**, trước → sau. L/D là light/dark; mỗi ô gộp dữ liệu rỗng/đầy. sale_screens gộp ba màn sale. Đủ ${sourceScreens.length} file màn hình, kể cả hai file dev.\n\n`;
  report += '| File trong lib/screens | 360 · 1.0 L | 360 · 1.0 D | 360 · 1.3 L | 360 · 1.3 D | 412 · 1.0 L | 412 · 1.0 D | 412 · 1.3 L | 412 · 1.3 D |\n|---|---|---|---|---|---|---|---|---|\n';
  for (const file of sourceScreens) {
    const cells=[];
    for(const w of [360,412])for(const scale of [1,1.3])for(const theme of ['light','dark'])cells.push(matrix(before,file,w,scale,theme)+' → '+matrix(after,file,w,scale,theme));
    report+='| '+file+' | '+cells.join(' | ')+' |\n';
  }
  report += '\nCác ca bổ sung: đăng ký/quên mật khẩu, ghi khoản mua bước 2, thêm món/ghi khoản mua khi bàn phím chiếm 300px, bottom sheet ngân sách/chọn tháng/thông báo và dialog xác nhận xoá. Dữ liệu đầy còn có 20 đồ đang dùng, thẻ hồ sơ mua sắm dài, một món định mua từ tiện ích trình duyệt, 20 thông báo và kết quả nhận diện ảnh với preview PNG cùng 20 nơi bán tên dài. Đây là dữ liệu giả để kiểm tra layout, không xác nhận dịch vụ AI/FCM hoạt động.\n\n';
  report += '### P1 và vị trí gốc trước sửa\n\n| Vị trí bde58fa | Lỗi phát hiện | Trạng thái |\n|---|---|---|\n';
  const locations=new Map();
  for(const row of before)for(const error of row.errors){
    const loc=error.match(/lib\/[^\n:]+:\d+:\d+/)?.[0];
    if(loc&&!locations.has(loc))locations.set(loc,error.match(/A RenderFlex overflowed[^\n]*/)?.[0]||error.slice(0,90));
  }
  for(const [loc,error]of locations)report+='| '+loc+' | '+esc(error)+' | '+(failed(after)===0?'Đã sửa, bộ mở rộng đạt':'Đang đối chiếu lượt cuối')+' |\n';
  if(failed(after)){
    report+='\n### Ca còn lỗi ở lượt gần nhất\n\n';
    for(const row of after.filter(r=>r.errors.length))report+='- '+row.screen+' '+row.width+'×'+row.height+' / '+row.scale+' / '+row.theme+' / '+row.data+': '+esc(row.errors[0].slice(0,350))+'\n';
  }
  report+='\nCác P1 phát hiện sau khi mở rộng fixture: thông báo dài tràn dọc (`lib/widgets/app_header_actions.dart`, đổi sang cuộn); hàng giá AI tràn ngang (`lib/screens/photo_search_screen.dart`, giá dưới tên shop); nhãn độ tin cậy cạnh ảnh thiếu chỗ (`photo_search_screen.dart`, Flexible cho nội dung). Các ca này chạy cùng ma trận cuối.\n\n';
  report+='\n## 2. Quét mã\n\nQuét chỉ đọc bằng `node tool/ui_audit.mjs`. Đây là ứng viên cần đọc ngữ cảnh, không cộng số match regex thành số lỗi thật. Vị trí trong bảng này là dòng của mã gốc bde58fa để đối chiếu diff. Không phải mọi Text dài đều cần cắt: ghi chú/chính sách cho phép xuống dòng; tên trong danh sách dùng ellipsis; số tiền giữ đầy đủ.\n\n';
  report+='| Loại | Match gốc | Match còn lại | Cách xử lý/ngoại lệ đã rà |\n|---|---:|---:|---|\n';
  const notes={
    spacing:'Dùng AppDimens; offset mũi tên 52px và inset hệ thống là hình học, không phải khoảng cách nội dung.',
    typography:'167 TextStyle có cỡ số chuyển sang AppTextStyles. Các override chỉ weight/color và cỡ do đo biểu đồ kế thừa typography, không tự đặt cỡ lẻ. withInheritedColor giữ foreground của nút/ngữ cảnh.',
    radius:'Chuyển BorderRadius.circular sang borderSmall/Medium/Large/XLarge/Pill.',
    color:'Không còn hex hoặc Colors màu cứng trong screens/widgets. isDark còn lại chọn icon sáng/tối, không phân nhánh màu.',
    touch:'Back/avatar, nút xem tất cả, chọn tháng/kỳ, chip lịch sử, sửa ngân sách và nút mã giảm giá được tăng lên >=48dp. Card/image có hitbox lớn; hình trang trí không phải control. Đánh giá thao tác thật ở U5 vẫn cần máy.',
    longText:'Expanded/Wrap ở tiêu đề và hàng thông tin; tên shop/món ở list giới hạn dòng, nội dung chi tiết vẫn đọc đầy đủ.',
    copy:'Bỏ câu Hãy/lời khen/dấu cảm thán và Wishlist/debug ngoài dev. Match còn lại là dấu ! toán tử null assertion trong nội suy Dart, không phải chữ hiển thị.',
  };
  for(const kind of Object.keys(notes))report+='| '+kind+' | '+staticBefore.filter(x=>x.kind===kind).length+' | '+findings.filter(x=>x.kind===kind).length+' | '+notes[kind]+' |\n';
  report+='\n### Danh sách file:dòng của ứng viên gốc\n\n| File | Loại | Dòng gốc |\n|---|---|---|\n';
  for(const file of [...new Set(staticBefore.map(x=>x.file))])for(const kind of Object.keys(notes)){
    const lines=[...new Set(staticBefore.filter(x=>x.file===file&&x.kind===kind).map(x=>x.line))];
    if(lines.length)report+='| '+file+' | '+kind+' | '+lines.join(', ')+' |\n';
  }
  report+='\n### Ưu tiên và kết quả U3/U4\n\n| Mức | Phạm vi | Xử lý |\n|---|---|---|\n| P1 | Overflow/không đọc được/không bấm được | Tiêu đề dùng Expanded; hàng thông tin dùng Wrap; giá so sánh chuyển dưới tên shop; footer/trạng thái ngắn có cuộn; navigation tăng chiều cao theo textScaler. |\n| P2 · U3 | Login, onboarding, navigation, home, wishlist, thêm/chi tiết món, ghi khoản mua, ngân sách, cá nhân, giá tham khảo | Chuẩn hoá token, title/back, copy và target; cùng bộ 8 cấu hình và hai loại dữ liệu. |\n| P2 · U4 | Các màn còn lại và widgets | Cùng token, copy, trạng thái rỗng/lỗi cuộn được; không đổi nghiệp vụ. |\n| P3 | Hình học minh hoạ, offset mũi tên, font-weight override kế thừa, brand/AI/QR/CSV/PDF | Giữ theo mục đích, không coi là lỗi chỉ vì có số hoặc tên riêng. |\n\n';
  report+='Luồng async: Home/history/patterns/budget dùng stateView hoặc state tương đương; wishlist/giá tham khảo/hồ sơ mua sắm dùng UiStateBuilder; chiêm nghiệm/AI có trạng thái riêng của ViewModel; form có busy/error khi submit; QR có errorBuilder. Không thêm request hay thay đổi trạng thái nghiệp vụ để phục vụ audit. Gallery kiểm tra cả UiLoading/UiEmpty/UiError trong panel hẹp.\n\n';
  report+='## 3. Rà bằng mắt — U5\n\n**Chưa chạy trên Redmi; chưa build/cài APK trong U1–U4.** Test widget không thay thế kiểm tra font thật, bàn phím thật, camera hay thao tác chạm.\n\n- [ ] So lề và khoảng cách giữa các tab trên Redmi.\n- [ ] Bật cỡ chữ hệ thống lớn nhất, thử nội dung tên dài/số tiền lớn ở light và dark.\n- [ ] Mở bàn phím ở Thêm món và Ghi khoản mua; cuộn tới ô nhập/nút lưu.\n- [ ] Kiểm tra tooltip, target chạm, popup/dropdown và sheet.\n- [ ] Xoay ngang nếu máy/app cho phép; chụp lỗi vào mục này.\n- [ ] Thử camera QR/nhận diện ảnh thật; audit chỉ dựng preview/service giả.\n\n';
  report+='## Chạy lại\n\nChạy trong thư mục Flutter `prm393_lab03` có pubspec.yaml:\n\n```powershell\nflutter test test/ui\nnode tool/ui_audit.mjs\nflutter analyze\nflutter test\n```\n\n`node tool/ui_audit.mjs --report` chỉ tái sinh báo cáo khi còn đủ baseline.json/static-baseline.json/results.json tại build/ui-audit trên máy audit. Các JSON là artifact local; báo cáo Markdown lưu bằng chứng đã tổng hợp. Thiếu artifact thì script báo lỗi và giữ nguyên báo cáo, không ghi đè bằng kết quả 0/0.\n\nChỉ thu baseline trên mã **trước sửa**: `flutter test test/ui --dart-define=UI_AUDIT_RECORD_ONLY=true`. Chế độ này ghi lỗi vào build/ui-audit/baseline.json và không assert, không dùng làm bằng chứng bộ test xanh sau sửa. `flutter test test/ui` bình thường ghi results.json và assert toàn bộ lỗi. Không có skip để giấu lỗi.\n';
  report+='\n### Cách kiểm tra U5 trên điện thoại\n\n1. Kết nối Redmi bằng USB hoặc ADB Wi-Fi; kiểm tra `flutter devices`, chạy `flutter run -d <device_id>`.\n2. Đổi cỡ chữ hệ thống lên lớn nhất, thử lần lượt light/dark ở Cá nhân.\n3. Qua các tab Trang chủ/Lịch sử/Mô hình/Góc nhìn/Cá nhân; kiểm tra lề, cuộn và nút ở cuối màn.\n4. Thử tên món/shop dài, số tiền lớn; mở chọn tháng, ngân sách, danh sách thông báo và xác nhận xoá.\n5. Mở form thêm món/ghi khoản mua, bật bàn phím và cuộn tới nút lưu; thử xoay ngang nếu app cho phép.\n6. Kiểm tra kết quả tìm ảnh/so sánh giá với dữ liệu thật, ghi lỗi và ảnh chụp vào mục 3. Không dùng kết quả widget test để kết luận camera/AI/network đã hoạt động.\n';
  const editedScreens='add_item budget compare_items email_verification extension_qr_scan feedback history home info_text insights item_detail login main_navigation monthly_reflection onboarding patterns photo_search pre_purchase_result pre_purchase profile purchase_detail record_purchase reminder_permission shopping_profile wishlist'.split(' ').map(n=>'lib/screens/'+n+'_screen.dart').concat('lib/screens/sale_screens.dart');
  const editedWidgets='app_dropdown_field app_header_actions buy_intent_section decision_card_panel demo_data_badge insight_source_chip month_picker_sheet price_history_chart price_history_panel satisfaction_dialog voucher_suggestion_card states/empty_view states/error_view states/loading_view'.split(' ').map(n=>'lib/widgets/'+n+'.dart');
  const auditFiles=[...editedScreens,'lib/theme/app_text_styles.dart',...editedWidgets,
    'test/ui/screen_render_test.dart','test/ui/ui_audit_harness.dart','test/ui/ui_tokens_test.dart',
    'test/support/purchase_harness.dart','test/purchase_flow_test.dart','test/notification_and_list_test.dart',
    'test/profile_history_compare_test.dart','test/profile_settings_test.dart',
    'tool/ui_audit.mjs','docs/ui-audit.md','docs/design-tokens.md','docs/ai-log.md'];
  report+='\n## Tệp thay đổi trong U1–U4\n\n'+auditFiles.map(p=>'- `'+p+'`').join('\n')+'\n';
  report+='\n## Ngoài phạm vi, tôi không sửa\n\nKhông đổi logic nghiệp vụ, models/ViewModels/services, Firestore rules/dữ liệu thật, routing, dependencies, backend, giao diện admin hoặc cấu hình Facebook/Firebase. Không commit/push/build/cài APK. Các test cũ chỉ bổ sung fake/provider còn thiếu và đổi finder/assertion cho câu chữ UI mới; không bỏ assertion nghiệp vụ. U5 cần thao tác máy thật.\n';
  report+='\n## Xác nhận cuối ngày 10/11/2026\n\n- `dart format` trên các file Dart thực tế thay đổi: hoàn tất.\n- `flutter test`: **1.328/1.328 đạt**, gồm 640 ca render và 3 test typography/foreground/target. Không còn 4 lỗi purchase_flow được ghi ở lần bàn giao Facebook trước: hai lỗi fake Auth/provider được bổ sung trong test, hai lỗi overflow được sửa ở UI.\n- `flutter analyze`: không có error/warning; còn 2 info cũ `use_null_aware_elements` ở `lib/viewmodels/own_price_view.dart:71,75` (exit 1 vì info, không sửa ngoài phạm vi).\n- `git diff --check` và `node --check tool/ui_audit.mjs`: đạt.\n- Quét screens/widgets: 0 hex hoặc named Colors ngoài transparent; test/ui không có skip.\n- Các số trên là kết quả lượt xác nhận này, không tự cập nhật chỉ bằng việc tái sinh bảng. U5 và APK trên Redmi chưa được kiểm tra/cập nhật.\n';
  fs.writeFileSync(path.join(root,'docs/ui-audit.md'),report);
}

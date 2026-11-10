# Facebook Login F1–F3

Cập nhật 10/11/2026. Code đã thêm; đăng nhập thật còn cần F0. Không tự deploy hoặc commit.

## Cấu trúc và giới hạn

- `flutter_facebook_auth` **7.3.3** (Android Facebook SDK 18.1.3 theo dependency của plugin). Native SDK chỉ nằm trong `FacebookLoginService`; `AuthService` đổi credential với Firebase. Web dùng Firebase popup, không cần khởi tạo Facebook JS SDK.
- Chỉ xin `public_profile`, `email`; không có email vẫn tạo hồ sơ được. iOS Limited Login dùng ID token và nonce SHA-256/raw nonce riêng cho mỗi lần đăng nhập; Android dùng access token thông thường.
- Nút theo thứ tự Google → Facebook → GitHub, màu theo theme; huỷ Facebook không hiện lỗi. App hỗ trợ Android, web và có nhánh iOS; ẩn Facebook trên desktop.
- Liên kết giữ nguyên UID/dữ liệu. Khách được liên kết để nâng thành tài khoản thật, giống luồng Google/GitHub hiện có. Không gộp hai tài khoản đã tồn tại. Không cho huỷ cách đăng nhập cuối.
- Đăng xuất/huỷ liên kết Facebook dọn phiên SDK trên mobile. Lỗi dọn SDK không biến thao tác huỷ liên kết Firebase đã thành công thành thất bại.
- Repo hiện **không có project iOS**; chưa build hay kiểm tra iOS. Không tạo project iOS trong F1–F3.

## F0 — nhóm cần làm trong console

1. Tạo app có use case Facebook Login ở [Meta for Developers](https://developers.facebook.com/). Ghi App ID, Client Token. App Secret chỉ nhập trong Firebase Console, không đưa vào repo, APK hoặc Dart.
2. Firebase project `prm393-34056` → Authentication → Sign-in method → Facebook → Enable → App ID + App Secret → Save.
3. Sao chép **đúng OAuth redirect URI hiển thị trong Firebase**, thêm vào Meta → Facebook Login → Settings → Valid OAuth Redirect URIs. Với authDomain hiện tại, URI dự kiến là `https://prm393-34056.firebaseapp.com/__/auth/handler`; ưu tiên giá trị console nếu khác.
4. Meta → Android platform: package `com.group07.whyibuy`, class `com.group07.whyibuy.MainActivity`, thêm key hash của từng máy debug và chứng thư ký bản phát hành.
5. Khi dùng web: thêm Website platform/domain hosting, kiểm tra Firebase Authentication → Settings → Authorized domains có domain chạy app và `localhost` nếu test local. Popup phải được trình duyệt cho phép.
6. Development: thêm tài khoản Facebook của người thử vào App Roles (Tester/Developer), người được mời chấp nhận lời mời. Kiểm tra dashboard Meta nếu cần tạo test user.
7. Muốn cho người ngoài dùng: xuất bản hai trang chính sách bên dưới, điền Privacy Policy URL và User Data Deletion **Instructions URL** trong Meta. Đây là trang hướng dẫn, không phải callback tự động xử lý `signed_request`.
8. Kiểm tra yêu cầu quyền/access level, review, xác minh và chế độ Live mà dashboard Meta yêu cầu cho app/use case của nhóm. Không mặc định rằng xin hai quyền này luôn được miễn mọi bước review/xác minh.

## Điền cấu hình Android

File `android/app/src/main/res/values/strings.xml` có ba placeholder:

```xml
<string name="facebook_app_id" translatable="false">APP_ID_CUA_NHOM</string>
<string name="facebook_client_token" translatable="false">CLIENT_TOKEN_CUA_NHOM</string>
<string name="fb_login_protocol_scheme" translatable="false">fbAPP_ID_CUA_NHOM</string>
```

Thay bằng giá trị thật, ví dụ scheme là `fb` nối App ID, không có dấu cách. Hiện repo để `0`, `0`, `fb0`: giá trị đệm vì SDK được khởi tạo khi đăng ký plugin; **không phải thông tin đăng nhập thật**. `MainActivity` kiểm tra cả ba qua MethodChannel; khi chưa điền, app báo chưa cấu hình và không mở đăng nhập SDK. Không để rỗng hai chuỗi khiến SDK lỗi khởi tạo. Không đưa App Secret vào đây. Nếu chia sẻ repo công khai, giữ placeholder trong commit và điền giá trị của nhóm tại máy/build riêng theo quy ước nhóm.

Manifest đã có INTERNET, ApplicationId/ClientToken metadata, FacebookActivity, CustomTabActivity và query app Facebook. Tắt Meta AutoLogAppEvents và AdvertiserIDCollection; Analytics của app vẫn dùng Firebase. Không sửa `google-services.json` hay `firebase_options.dart`.

Sau khi đổi native resource/plugin, dừng app và **build/cài lại**, hot reload không cập nhật native:

```powershell
cd C:\Users\DELL\prm393_lab03\prm393_lab03
flutter pub get
flutter run -d <ID_DIEN_THOAI>
```

## Key hash debug/release trên Windows

Key hash là **Base64 của SHA-1 chứng thư**, khác chuỗi SHA-1 dạng hex. Dùng `keytool` của JDK, không cần OpenSSL; tránh pipe dữ liệu nhị phân qua PowerShell 5.1:

```powershell
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -file "$env:TEMP\whyibuy-facebook-debug.der"
$fbSha1 = (Get-FileHash -LiteralPath "$env:TEMP\whyibuy-facebook-debug.der" -Algorithm SHA1).Hash
$fbBytes = for ($i = 0; $i -lt $fbSha1.Length; $i += 2) { [Convert]::ToByte($fbSha1.Substring($i, 2), 16) }
[Convert]::ToBase64String([byte[]]$fbBytes)
```

Dán kết quả vào Meta → Android → Key Hashes. Nếu `keytool` chưa có trong PATH, dùng đường dẫn `bin\keytool.exe` của JDK mà `flutter doctor -v` đang báo.

Release: chạy cùng cách với **keystore và alias thực sự ký APK**, bỏ `-storepass android` để nhập mật khẩu ở prompt. Hiện `android/app/build.gradle.kts` vẫn dùng debug signing cho release, nên bản build hiện tại trên cùng máy dùng cùng key hash debug; chưa phải cấu hình ký sản xuất. Khi đổi signing phải thêm hash mới. Với Google Play App Signing, thêm cả hash chứng thư **App signing key** từ Play Console (không chỉ upload key). Mỗi máy dev có debug keystore riêng.

## iOS nếu bổ sung target sau này

Thực hiện setup iOS theo [plugin](https://github.com/darwin-morocho/flutter-facebook-auth), gồm Info.plist URL scheme `fb<App ID>`, FacebookAppID, FacebookClientToken, FacebookDisplayName, LSApplicationQueriesSchemes và xử lý AppDelegate theo phiên bản plugin. Đăng ký bundle ID trong Meta và Firebase. Tắt tự động events/advertising ID nếu không dùng. Nhánh Dart hiện dùng Limited Login + nonce; không thêm yêu cầu ATT chỉ để đăng nhập. Cần test trên iOS thật trước khi công bố hỗ trợ.

## Chính sách và hosting (F3)

Nguồn duy nhất: `lib/core/constants/legal_texts.dart`. Trong app route `/profile/privacy` đọc `LegalTexts.privacy`; script sinh HTML cũng đọc cùng nội dung, tránh lệch chính sách. Email công khai do nhóm cung cấp: **daotamhoang2005@gmail.com**. Nhóm chưa chốt SLA xoá dữ liệu; trang ghi sẽ xác nhận thời gian sau khi tiếp nhận/xác minh, không tự hứa 7 ngày.

Hai file versioned: `../prm393_flutter_admin/web/privacy.html`, `data-deletion.html`. Flutter web build sao chép sang public hosting hiện có `prm393_flutter_admin/build/web`; không sửa giao diện admin/index hoặc cấu hình hosting. File tĩnh được phục vụ trước rewrite SPA.

Nhóm tự chạy các lệnh sau, giữ các build flags/cấu hình admin đang dùng nếu có:

```powershell
cd C:\Users\DELL\prm393_lab03\prm393_lab03
dart run tool/generate_auth_policy_pages.dart
cd ..\prm393_flutter_admin
flutter build web
Test-Path build\web\privacy.html
Test-Path build\web\data-deletion.html
cd ..
firebase deploy --only hosting --project prm393-34056
```

Deploy hosting sẽ xuất bản **cả bản build admin đang nằm trong public**, nên kiểm tra đúng cấu hình admin trước khi tự chạy. Hai URL **dự kiến sau deploy**, chưa xác nhận đã công khai trong tác vụ này:

- `https://prm393-34056.web.app/privacy.html`
- `https://prm393-34056.web.app/data-deletion.html`

Mở hai URL trong cửa sổ riêng tư, không yêu cầu đăng nhập, kiểm tra tiếng Việt/email/nội dung rồi mới điền Meta. Có thể mở trực tiếp HTML local để xem trước.

### Xử lý yêu cầu xoá dữ liệu thủ công

Nút xoá dữ liệu trong app chỉ xoá các subcollection mà `FirestoreDemoDataService.clearAll` đang xử lý: wishlist + priceSnapshots, purchases, decisions, budgets, reflections, ownedItems. Nó giữ Firebase Auth user, user document và budgetGroups; không phải xoá tài khoản. Chính sách đã nói rõ giới hạn này.

Nhóm xác minh chủ tài khoản và phạm vi trước khi thao tác. Nếu yêu cầu xoá hoàn toàn: kiểm tra tất cả dữ liệu theo UID, gồm hồ sơ/token thiết bị, các subcollection, góp ý và extensionSessions, rồi xoá Auth user. Xoá document Firestore cha **không tự xoá subcollection**. Đánh giá riêng dữ liệu giá cộng đồng đã được ẩn danh/băm định danh và dữ liệu thống kê/lỗi theo khả năng truy vết thực tế; không hứa xoá mọi báo cáo vô danh bằng UID nếu không xác định được. Xác nhận kết quả/giới hạn cho người yêu cầu. Không triển khai endpoint xoá tự động hoặc tính năng xoá tài khoản mới trong F3.

## Kiểm tra sau F0

1. Android đã thêm key hash: bấm Facebook → vào app, Firebase Authentication có provider `facebook.com`.
2. Huỷ hộp thoại: vẫn ở màn đăng nhập, không có lỗi. Thử mất mạng: thông báo tiếng Việt, không lộ token/mã kỹ thuật.
3. Facebook không chia sẻ email: vẫn vào app; hồ sơ/linked row dùng tên hoặc “Chưa có email”.
4. Trùng email: câu trung tính yêu cầu đăng nhập cách cũ rồi liên kết; không tự gộp hay đoán provider.
5. Google → liên kết Facebook → đăng xuất → Facebook: cùng UID và wishlist. Khách liên kết cũng giữ UID.
6. Facebook đã thuộc tài khoản khác: báo rõ cần huỷ ở tài khoản đó trước, dữ liệu hiện tại giữ nguyên.
7. Chỉ còn Facebook: không huỷ được. Có Google/email khác: huỷ được; tải lại thấy trạng thái đúng.
8. Web: kiểm tra popup, huỷ popup, liên kết/huỷ liên kết; iOS cần project và thiết bị riêng.
9. Light/dark: thứ tự nút, loading riêng, thông báo lỗi và row Facebook đọc rõ.

Lỗi thường gặp: **Invalid key hash** → thêm hash đúng keystore/máy; app Development → kiểm tra role và lời mời; redirect mismatch → copy URI từ Firebase; operation-not-allowed → bật Facebook provider; chưa cấu hình → điền đủ ba resource và build lại; popup blocked → cho phép popup; đã sửa native mà vẫn cũ → cài APK mới.

Tài liệu gốc: [Firebase Flutter federated auth](https://firebase.google.com/docs/auth/flutter/federated-auth), [flutter_facebook_auth](https://pub.dev/packages/flutter_facebook_auth), [Meta Facebook Login](https://developers.facebook.com/docs/facebook-login/).

## Tệp thay đổi trong F1–F3

Đường dẫn sau tính từ thư mục Flutter `prm393_lab03/`, trừ hai trang HTML có tiền tố `../`:

- Dependency: `pubspec.yaml`, `pubspec.lock`.
- Android: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/strings.xml`, `android/app/src/main/kotlin/com/group07/whyibuy/MainActivity.kt`.
- Service: `lib/services/auth_service.dart`, `lib/services/facebook_login_service.dart`.
- ViewModel: `lib/viewmodels/auth_viewmodel.dart`, `lib/viewmodels/linked_accounts_viewmodel.dart`.
- UI: `lib/screens/login_screen.dart`, `lib/screens/profile_screen.dart`.
- Hỗ trợ: `lib/firebase/platform_support.dart`, `lib/core/errors/firebase_error_mapper.dart`, `lib/core/constants/legal_texts.dart`.
- Plugin registrant sinh từ dependency: `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`.
- Test: `test/facebook_auth_test.dart`, `test/facebook_web_auth_test.dart`, `test/auth_policy_pages_test.dart`, `test/auth_error_message_test.dart`, `test/account_header_card_test.dart`, `test/linked_accounts_viewmodel_test.dart`, `test/linked_accounts_section_test.dart`, `test/support/linked_auth_fakes.dart`.
- Trang tĩnh và công cụ: `tool/generate_auth_policy_pages.dart`, `../prm393_flutter_admin/web/privacy.html`, `../prm393_flutter_admin/web/data-deletion.html`.
- Tài liệu: `docs/auth-facebook.md`, `docs/analytics-plan.md`, `docs/decisions.md`, `docs/ai-log.md`.

Ngoài phạm vi, không sửa: luồng Google/GitHub/email, theme/bố cục khác, dữ liệu/rules, AI/voucher, Firebase options/Google services, giao diện admin, backend. Không cấu hình console, không tạo project iOS, không cài lên điện thoại, không commit/push/deploy. Các file generated Windows đổi vì plugin mới kéo dependency desktop/secure storage, dù app ẩn nút Facebook trên desktop.

## Kết quả kiểm tra 10/11/2026

| Kiểm tra | Kết quả |
| --- | --- |
| Format Dart các file liên quan; `git diff --check` | Đạt |
| `flutter analyze` | Không có error/warning mới; còn 2 info `use_null_aware_elements` có sẵn tại `own_price_view.dart:71,75` (lệnh vẫn trả exit 1 do info) |
| `flutter test` toàn bộ bản cuối | **681 đạt / 685**, 4 lỗi cũ của `purchase_flow_test.dart` |
| 7 file auth/policy, `--dart-define=TEST_DARK_THEME=true` | **89/89 đạt**, gồm kiểm tra Google/GitHub cũ, row/header và nút Facebook |
| `flutter test --platform chrome test/facebook_web_auth_test.dart` | **3/3 đạt**, SDK/Firebase dùng fake, không đăng nhập tài khoản thật |
| `flutter build apk --debug` | Đạt; `build/app/outputs/flutter-apk/app-debug.apk`, chưa cài lên máy |
| Admin `flutter build web --no-wasm-dry-run` | Đạt; hai HTML được sao chép vào `build/web`, SHA-256 khớp nguồn |
| Chrome mở hai trang HTML qua HTTP local | Đạt; nội dung, tiêu đề, điều hướng/email xuất hiện; chưa deploy công khai |

Bốn test cũ lỗi: Home bookmark, Home wishlist card (fake Auth thiếu getter `isAnonymous`), manual form và confirmed buy (overflow). Các lỗi này đã được tái hiện trước F1–F3 trong đợt dark mode; không sửa purchase flow ở đây.

Lưu ý môi trường Windows/Flutter 3.47.8: Chrome test bị kẹt ở `loading` do server test trả 404 cho `/canvaskit/chromium/canvaskit.js` và `.wasm` dù SDK cache có file. Lượt xác nhận 3/3 dùng CDP cung cấp đúng hai asset từ cache SDK cho trình duyệt test rồi tải lại iframe; không sửa SDK hay code ứng dụng để né lỗi. Nếu máy khác gặp cùng triệu chứng, kiểm tra CanvasKit trước khi kết luận Facebook lỗi. Build hosting lần đầu dùng `--no-pub` gặp package config cũ thiếu `url_launcher`; chạy build có pub get đã giải quyết, không thay dependency admin. `--no-wasm-dry-run` bỏ bước dry run của SDK; không bật chế độ build Wasm.

Chưa thể xác nhận đăng nhập/liên kết Facebook đầu cuối trên Redmi hoặc tài khoản thật khi F0 chưa hoàn tất; iOS cũng chưa có target. Làm theo checklist sau F0 ở trên.

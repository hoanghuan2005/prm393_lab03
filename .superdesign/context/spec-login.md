# login
files: lib/screens/login_screen.dart, lib/widgets/app_button.dart, lib/viewmodels/auth_viewmodel.dart, lib/services/auth_service.dart, lib/theme/app_theme.dart, lib/theme/app_text_styles.dart, lib/app/app.dart (AuthGate)
purpose: Đăng nhập vào Why I Buy? bằng email/mật khẩu, Google, GitHub hoặc dùng thử chế độ Khách.
firebase: Firebase Auth: signInWithEmailAndPassword, Firebase Auth + google_sign_in: native GoogleAuthProvider.credential (web dùng signInWithPopup), Firebase Auth: GithubAuthProvider qua signInWithProvider, scope read:user và user:email, Firebase Auth: signInAnonymously (chế độ Khách), Firebase Analytics: logLogin(method: email/google/github/guest), setUserId, Firebase Crashlytics: recordHandledError cho lỗi auth, setUserId, Cloud Firestore: sau đăng nhập, ensureUserDocument users/{uid} và nhóm ngân sách mặc định

## layout
- Scaffold nền #F8FAFC, SafeArea, Center, SingleChildScrollView padding trái 24 / trên 20 / phải 24 / dưới 24, maxWidth 430, cột căn stretch. KHÔNG có AppBar.
- **Nút quay lại**: TextButton.icon căn trái, padding 0. Icons.chevron_left_rounded 24 + 'Quay lại' (14px w600 #0F172A). Bấm sẽ pushReplacement sang Onboarding.
- khoảng 18
- **Header thương hiệu** (Row): ô 40x40, radius 13, gradient trái -> phải #FFD166 -> #FFDE02, chứa Icons.psychology_alt_rounded 24 #0F172A; gap 10; 'Why I Buy?' 18px w800 #0F172A
- khoảng 26
- Tiêu đề 'Chào bạn trở lại' 24px w800 #0F172A, line-height 1.3
- khoảng 6
- Phụ đề 'Tiếp tục hiểu mình qua những khoản mua, từng chút một.' 14px #64748B, line-height 1.45
- khoảng 22
- **Hộp lỗi** (chỉ khi có authVm.errorMessage), sau hộp là khoảng 16: padding 12, nền #EF4444 ở 10%, radius 12, viền #EF4444 ở 30%. Gồm Icons.info_outline 20 #EF4444, gap 8, nội dung 14px #EF4444. Ví dụ: 'Email hoặc mật khẩu không đúng.'
- **Form** (TextFormField theo kiểu ô nhập liệu chung, cao khoảng 56, label nổi):
  - Ô Email: label 'Email', hint 'Nhập email của bạn', prefix Icons.mail_outline_rounded 20, bàn phím email
  - khoảng 14
  - Ô Mật khẩu: label 'Mật khẩu', hint 'Nhập mật khẩu', prefix Icons.lock_outline_rounded 20, ẩn ký tự. Suffix là IconButton Icons.visibility_outlined (đổi thành Icons.visibility_off_outlined khi đang hiện chữ), tooltip 'Hiện hoặc ẩn mật khẩu'.
  - Lỗi validate hiện dưới ô, 12px #EF4444: 'Hãy nhập email.' / 'Email chưa đúng định dạng.' / 'Hãy nhập mật khẩu.' / 'Mật khẩu cần ít nhất 6 ký tự.'
- khoảng 10
- TextButton căn phải 'Quên mật khẩu?' (14 w600 #0F172A)
- **AppButton primary** 'Đăng nhập', icon Icons.login_rounded [shared]
- khoảng 16
- Row căn giữa: 'Chưa có tài khoản?' (14px #64748B) + TextButton 'Đăng ký' (14 w600 #0F172A)
- khoảng 22
- Dòng phân cách: Divider #E2E8F0 | 'hoặc' (14px #64748B, padding ngang 12) | Divider
- khoảng 16
- **AppButton primary** 'Đăng nhập với Google', icon Icons.g_mobiledata (nút vàng, không có logo Google)
- khoảng 10
- **AppButton secondary** 'Đăng nhập với GitHub', icon Icons.code_rounded (nền trắng, viền 1.5px #CBD5E1)
- khoảng 10
- **AppButton secondary** 'Dùng thử chế độ Khách', icon Icons.person_outline_rounded
- khoảng 22
- **Ghi chú tin cậy**: padding 12, nền #FFFCE6, radius 12, Row gồm Icons.lightbulb_outline_rounded 20 #0F172A, gap 8, chữ 12px line-height 1.35 #0F172A gồm 2 dòng (đều weight thường): 'Hiểu mình, không phán xét' / 'Mỗi khoản mua là một dịp để lắng nghe chính bạn.'
- Màn này không có điều khoản hay văn bản pháp lý.
- Loading: chỉ nút vừa bấm đổi thành spinner 22px; các lần bấm khác bị bỏ qua cho tới khi xong. Đăng nhập thành công thì AuthGate tự chuyển sang Trang chủ (hoặc Xác minh email).

## sample_data
Email: 'linh.nguyen@example.com'. Mật khẩu: 8 ký tự ẩn (••••••••). Lỗi khi sai mật khẩu (Firebase trả mã invalid-credential/wrong-password/user-not-found): 'Email hoặc mật khẩu không đúng.' Các lỗi được map khác: 'Bạn thử quá nhiều lần. Hãy thử lại sau.' (too-many-requests), 'Email chưa đúng định dạng.' (invalid-email).

## demo_beats
- Chạm ô Email: viền đổi sang #0F172A 1.5px, label 'Email' nổi lên; gõ 'linh.nguyen@example.com'
- Ô 'Mật khẩu' hiện ••••••••; chạm Icons.visibility_outlined để hiện chữ, icon đổi thành visibility_off_outlined
- Chạm nút vàng 'Đăng nhập': nhãn đổi thành spinner tròn 22px #0F172A
- (Nhánh lỗi) Hộp đỏ 'Email hoặc mật khẩu không đúng.' trượt vào trên form
- (Nhánh Google) Chạm 'Đăng nhập với Google': spinner trên nút, bảng chọn tài khoản Google của hệ điều hành hiện lên, AuthGate chuyển sang Trang chủ

## talking_points
- Bốn cách vào app: email, Google, GitHub, hoặc Khách; tất cả do Firebase Authentication xử lý.
- Chế độ Khách dùng đăng nhập ẩn danh, trải nghiệm ngay không cần tạo tài khoản.
- Mã lỗi Firebase được dịch sang tiếng Việt thân thiện, ví dụ 'Email hoặc mật khẩu không đúng.'
- Mỗi lần đăng nhập ghi sự kiện login vào Analytics; lỗi bất thường gửi về Crashlytics.
- Lần đầu đăng nhập, app tự tạo hồ sơ users/{uid} và nhóm ngân sách mặc định trên Firestore.
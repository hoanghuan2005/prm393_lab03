import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_deck():
    prs = Presentation()
    # Chuẩn màn hình 16:9 Widescreen
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)

    blank_layout = prs.slide_layouts[6]

    # Bảng màu chuẩn nhận diện Why I Buy (docs/design-tokens.md)
    # Background chủ đạo: #070E20 (Why I Buy Dark)
    # Accent chủ đạo: #FFDE02 (Why I Buy Gold/Yellow)
    C_BRAND_DARK   = RGBColor(7, 14, 32)       # #070E20 (Nền tối thương hiệu Why I Buy)
    C_BRAND_YELLOW = RGBColor(255, 222, 2)     # #FFDE02 (Vàng nhận diện Why I Buy)
    C_BRAND_CARD   = RGBColor(17, 24, 48)      # Card tối
    C_LIGHT_BG     = RGBColor(248, 250, 252)   # #F8FAFC Slate 50
    C_CARD_BG      = RGBColor(255, 255, 255)   # #FFFFFF
    C_CARD_BORDER  = RGBColor(226, 232, 240)   # #E2E8F0
    C_PRIMARY_BLUE = RGBColor(37, 99, 235)     # #2563EB
    C_ACCENT_TEAL  = RGBColor(13, 148, 136)    # #0D9488
    C_ACCENT_AMBER = RGBColor(217, 119, 6)     # #D97706
    C_ACCENT_ROSE  = RGBColor(225, 29, 72)     # #E11D48
    C_ACCENT_PURPLE= RGBColor(124, 58, 237)    # #7C3AED
    C_TEXT_MAIN    = RGBColor(7, 14, 32)       # #070E20
    C_TEXT_MUTED   = RGBColor(100, 116, 139)   # #64748B
    C_TEXT_LIGHT   = RGBColor(248, 250, 252)
    C_TEXT_LIGHT_MUTED = RGBColor(148, 163, 184)
    C_CODE_BG      = RGBColor(15, 23, 42)      # Slate 900
    C_CODE_TEXT    = RGBColor(56, 189, 248)    # Sky 400

    def add_bg(slide, dark=False):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
        bg.fill.solid()
        bg.fill.fore_color.rgb = C_BRAND_DARK if dark else C_LIGHT_BG
        bg.line.color.rgb = C_BRAND_DARK if dark else C_LIGHT_BG
        return bg

    def add_header(slide, tag_text, title_text, subtitle_text, dark=False, tag_color=C_PRIMARY_BLUE):
        # Tag pill
        tag_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(10.0), Inches(0.35))
        tf = tag_box.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        p = tf.paragraphs[0]
        p.text = tag_text.upper()
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = tag_color

        # Title
        title_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.75), Inches(11.8), Inches(0.6))
        tf = title_box.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        p = tf.paragraphs[0]
        p.text = title_text
        p.font.size = Pt(22)
        p.font.bold = True
        p.font.color.rgb = C_TEXT_LIGHT if dark else C_TEXT_MAIN

        # Subtitle
        sub_box = slide.shapes.add_textbox(Inches(0.8), Inches(1.35), Inches(11.8), Inches(0.4))
        tf = sub_box.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        p = tf.paragraphs[0]
        p.text = subtitle_text
        p.font.size = Pt(13)
        p.font.color.rgb = C_TEXT_LIGHT_MUTED if dark else C_TEXT_MUTED

    def add_card(slide, left, top, width, height, bg_color=C_CARD_BG, border_color=C_CARD_BORDER):
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
        card.fill.solid()
        card.fill.fore_color.rgb = bg_color
        card.line.color.rgb = border_color
        card.line.width = Pt(1)
        return card

    # ==================== SLIDE 1: COVER SLIDE ====================
    s1 = prs.slides.add_slide(blank_layout)
    add_bg(s1, dark=True)

    tag = s1.shapes.add_textbox(Inches(1.0), Inches(0.9), Inches(11.0), Inches(0.4))
    p = tag.text_frame.paragraphs[0]
    p.text = "TRƯỜNG ĐẠI HỌC FPT  ·  PRM393  ·  LAB 3: CLOUD-ENABLED MOBILE APP"
    p.font.size = Pt(13)
    p.font.bold = True
    p.font.color.rgb = C_BRAND_YELLOW

    title_box = s1.shapes.add_textbox(Inches(1.0), Inches(1.5), Inches(11.3), Inches(1.5))
    tf = title_box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "Why I Buy? – Mindful Shopping Companion"
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = RGBColor(255, 255, 255)

    sub_box = s1.shapes.add_textbox(Inches(1.0), Inches(3.0), Inches(11.3), Inches(0.8))
    tf = sub_box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "Báo Cáo Kiến Trúc Công Nghệ & Tích Hợp Đám Mây Đa Nền Tảng\nFlutter MVVM  ·  Firebase Ecosystem  ·  Cloudinary Media  ·  Google ARTEMIS E2E"
    p.font.size = Pt(17)
    p.font.color.rgb = RGBColor(203, 213, 225)

    # Info Card on bottom
    c_info = add_card(s1, 1.0, 4.2, 11.333, 2.5, bg_color=C_BRAND_CARD, border_color=RGBColor(45, 55, 72))
    info_box = s1.shapes.add_textbox(Inches(1.3), Inches(4.35), Inches(10.7), Inches(2.2))
    tf = info_box.text_frame
    p = tf.paragraphs[0]
    p.text = "THÔNG TIN DỰ ÁN & NHÓM THỰC HIỆN (NHÓM 07)"
    p.font.size = Pt(13)
    p.font.bold = True
    p.font.color.rgb = C_BRAND_YELLOW

    team_info = (
        "• Thành viên nhóm: Hồ Hữu Hoàng Huân (SE192248 - Lead), Huỳnh Đăng Khoa, Đào Tâm Hoàng, Ngô Vũ Minh Kiệt, Nguyễn Đình Ngọc Ân\n"
        "• Android Package ID: com.group07.whyibuy  ·  Firebase Project ID: prm393-34056\n"
        "• Kho mã nguồn GitHub: https://github.com/hoanghuan2005/prm393_lab03\n"
        "• Trọng tâm Lab 3: Mỗi công nghệ trình bày 3-4 slide, trả lời chuẩn xác 5 câu hỏi: (1) What & Why · (2) How & Cơ chế đăng ký · (3) Chỗ nào dùng code đó · (4) Dùng ở màn hình nào & Kiểm chứng (Verification)"
    )
    p2 = tf.add_paragraph()
    p2.text = team_info
    p2.font.size = Pt(11.5)
    p2.font.color.rgb = RGBColor(226, 232, 240)

    # ==================== SLIDE 2: MỤC LỤC & KIẾN TRÚC TỔNG THỂ ====================
    s2 = prs.slides.add_slide(blank_layout)
    add_bg(s2, dark=False)
    add_header(s2, "TỔNG QUAN NỘI DUNG", "Bản Đồ Công Nghệ & Ranh Giới Phân Tầng MVVM", "Mô hình MVVM + Provider: Giao diện tuyệt đối không gọi trực tiếp Firebase/Cloudinary SDK (CR-01, CR-02)")

    techs = [
        ("01 · Authentication", "Google, Facebook, GitHub, Email & Guest. Quản lý phiên và phân quyền dữ liệu theo UID.", C_PRIMARY_BLUE),
        ("02 · Cloudinary Media", "Lưu trữ hình ảnh sản phẩm (imageUrl), ảnh chụp tìm kiếm & hoá đơn. Tự động nén WebP/CDN.", C_ACCENT_TEAL),
        ("03 · Cloud Storage / PDF", "Xuất báo cáo chi tiêu PDF với font Be Vietnam Pro, phân quyền bảo mật reports/{uid}/.", C_ACCENT_AMBER),
        ("04 · Cloud Messaging", "FCM 3 trạng thái (Foreground / Background / Terminated isolate), Push qua Spring Boot Admin.", C_ACCENT_PURPLE),
        ("05 · Firebase Analytics", "Kế hoạch 10+ sự kiện chuẩn không kèm PII, phân khúc giá Amount Bucket, theo dõi DebugView.", C_ACCENT_ROSE),
        ("06 · Crashlytics", "Bắt trọn lỗi Fatal & Non-fatal, Custom Key screen, kích hoạt test crash chủ đích kiểm chứng.", RGBColor(180, 83, 9)),
        ("07 · Remote Config", "Thay đổi tham số động (cooling_off_days, feature flags, Gemini model) không cần rebuild app.", RGBColor(2, 132, 199)),
        ("08 · E2E & Code Review", "ARTEMIS 17 test cases (3 lượt/ca = 51 lượt), AI Code Review truy vết commit rõ ràng.", RGBColor(71, 85, 105)),
    ]

    for idx, (title, desc, color) in enumerate(techs):
        row = idx // 4
        col = idx % 4
        left = 0.8 + col * 2.95
        top = 2.0 + row * 2.5
        add_card(s2, left, top, 2.75, 2.2)
        tb = s2.shapes.add_textbox(Inches(left + 0.15), Inches(top + 0.15), Inches(2.45), Inches(1.9))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = color

        p2 = tf.add_paragraph()
        p2.text = desc
        p2.font.size = Pt(11)
        p2.font.color.rgb = C_TEXT_MUTED

    # ==================== CÔNG NGHỆ 1: FIREBASE AUTHENTICATION (4 SLIDES) ====================
    # Slide 3: Auth - What & Why
    s3 = prs.slides.add_slide(blank_layout)
    add_bg(s3)
    add_header(s3, "CÔNG NGHỆ 01 · FIREBASE AUTHENTICATION (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Quản lý danh tính đa kênh, bảo vệ phiên đăng nhập và cô lập dữ liệu theo UID", tag_color=C_PRIMARY_BLUE)

    c1 = add_card(s3, 0.8, 2.0, 5.7, 4.8)
    tb1 = s3.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · KHÁI NIỆM & VAI TRÒ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_PRIMARY_BLUE

    points_what = [
        "Định nghĩa: Dịch vụ xác thực danh tính đám mây của Google, cung cấp SDK bảo mật quản lý toàn bộ vòng đời phiên (Session Lifecycle).",
        "Đa phương thức xác thực: Hỗ trợ Google Sign-In, Facebook Login, GitHub OAuth, Email/Password và tài khoản khách (Anonymous Guest).",
        "Cấp phát UID duy nhất: Mỗi người dùng nhận một mã UID không trùng lặp, làm gốc định danh cho Firestore (users/{uid}) và Storage.",
        "authStateChanges & userChanges: Reactive stream phát tín hiệu tự động khi đăng nhập, đăng xuất hoặc cập nhật profile."
    ]
    for pt in points_what:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s3, 6.8, 2.0, 5.7, 4.8)
    tb2 = s3.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO WHY I BUY CẦN AUTH?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_PRIMARY_BLUE

    points_why = [
        "Bảo mật tài chính cá nhân: Danh sách món đồ đắn đo (Wishlist), hạn mức ngân sách (Budget) và bài học phản tư chi tiêu là dữ liệu tuyệt mật của từng người.",
        "Trải nghiệm đăng nhập 1-chạm (One-tap): Giảm tối đa tỷ lệ bỏ rơi (drop-off) khi người dùng trẻ tải app qua Google Sign-In.",
        "Chế độ Guest không rào cản: Người dùng có thể trải nghiệm ngay việc hoãn mua mà không bắt buộc tạo tài khoản ngay lập tức.",
        "Liên kết tài khoản đa nền tảng (ACC-01 đến ACC-09): Cho phép liên kết tài khoản Guest sang Google/GitHub, đồng bộ thông suốt với Chrome Extension."
    ]
    for pt in points_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 4: Auth - How & Cơ chế đăng ký
    s4 = prs.slides.add_slide(blank_layout)
    add_bg(s4)
    add_header(s4, "CÔNG NGHỆ 01 · FIREBASE AUTHENTICATION (2/4)", "Cách Hoạt Động (How) & Cơ Chế Đăng Ký / Cấu Hình", "Cấu hình SHA-1, thiết lập google-services.json và luồng chuyển đổi trạng thái", tag_color=C_PRIMARY_BLUE)

    steps = [
        ("BƯỚC 1: ĐĂNG KÝ & CẤU HÌNH CONSOLE", [
            "Project ID: prm393-34056  ·  Package: com.group07.whyibuy.",
            "Trích xuất mã băm SHA-1 (ecd5e35c...) và SHA-256 từ keystore Android.",
            "Đăng ký certificate_hash vào Firebase Console Settings.",
            "Tải google-services.json đặt tại android/app/.",
            "Bật các Provider: Google, Facebook, GitHub, Email/Password, Anonymous."
        ]),
        ("BƯỚC 2: KHỞI TẠO & DEPENDENCY INJECTION", [
            "Khởi tạo trong main(): await FirebaseSetup.initialize().",
            "Đăng ký AuthService vào AppProviders tại app/providers.dart.",
            "Sử dụng ProxyProvider kết nối AuthService sang AuthViewModel.",
            "Bọc phương thức xác thực qua guard() để phân loại lỗi AppException."
        ]),
        ("BƯỚC 3: LUỒNG DỮ LIỆU & SESSION GUARD", [
            "Client gọi signInWithGoogle() → nhận accessToken & idToken.",
            "Gửi GoogleAuthProvider.credential() vào _auth.signInWithCredential().",
            "authStateChanges phát ra User → AuthGate chuyển sang MainNavigationScreen.",
            "Tự động kích hoạt: Analytics.setUserId(uid) và Crashlytics.setUserId(uid)."
        ])
    ]

    for idx, (title, pts) in enumerate(steps):
        left = 0.8 + idx * 3.95
        add_card(s4, left, 2.0, 3.75, 4.8)
        tb = s4.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = C_PRIMARY_BLUE

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 5: Auth - Chỗ nào dùng code đó
    s5 = prs.slides.add_slide(blank_layout)
    add_bg(s5)
    add_header(s5, "CÔNG NGHỆ 01 · FIREBASE AUTHENTICATION (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn xử lý Google Sign-In và luồng bảo vệ phiên trong AuthService", tag_color=C_PRIMARY_BLUE)

    c_code = add_card(s5, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s5.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/auth_service.dart (dòng 55-90)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet = """Future<UserCredential?> signInWithGoogle() async {
  if (!PlatformSupport.supportsGoogleSignIn) {
    throw UnsupportedError('Google Sign-In is not available on this platform');
  }
  return guard(() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // Người dùng chủ động huỷ chọn tài khoản

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  });
}

// Lắng nghe luồng trạng thái xác thực toàn ứng dụng
Stream<User?> get authStateChanges => _auth.authStateChanges();"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s5, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s5.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_PRIMARY_BLUE

    exps = [
        "Vị trí: lib/services/auth_service.dart kết hợp AuthViewModel tại lib/viewmodels/auth_viewmodel.dart.",
        "Xử lý huỷ an toàn: Trả về null khi googleUser == null mà không ném exception giả, giúp UI phản hồi êm ái.",
        "Bọc lỗi chuẩn qua guard(): Chuyển đổi toàn bộ FirebaseAuthException sang AppException hiển thị thông báo tiếng Việt.",
        "Tuân thủ MVVM: LoginScreen chỉ gọi context.read<AuthViewModel>().signInWithGoogle(), tuyệt đối không import Firebase SDK tại View."
    ]
    for e in exps:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 6: Auth - Dùng ở màn hình nào & Kiểm chứng
    s6 = prs.slides.add_slide(blank_layout)
    add_bg(s6)
    add_header(s6, "CÔNG NGHỆ 01 · FIREBASE AUTHENTICATION (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình áp dụng, xử lý ngoại lệ thực tế và bằng chứng trên Firebase Console", tag_color=C_PRIMARY_BLUE)

    c_screen = add_card(s6, 0.8, 2.0, 5.7, 4.8)
    tb_s = s6.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_PRIMARY_BLUE

    screens_auth = [
        "LoginScreen (Màn hình đăng nhập): Các nút Đăng nhập Google, Facebook, GitHub, Email và 'Dùng thử không cần tài khoản' (Guest).",
        "ProfileScreen (Màn hình cá nhân): Hiển thị Avatar, Email, Tên lấy từ currentUser; Quản lý 'Tài khoản liên kết' và Đăng xuất.",
        "EmailVerificationScreen: Màn hình kiểm tra emailVerified trước khi vào các luồng quan trọng.",
        "AuthGate (lib/app/app.dart): Widget điều phối tự động dựa trên StreamProvider authStateChanges, ngăn chặn truy cập trái phép."
    ]
    for sa in screens_auth:
        p = tf_s.add_paragraph()
        p.text = "• " + sa
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s6, 6.8, 2.0, 5.7, 4.8)
    tb_v = s6.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG & BẰNG CHỨNG THỰC TẾ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_PRIMARY_BLUE

    verifies_auth = [
        "Firebase Console: Vào mục Authentication → tab Users; hiển thị danh sách người dùng kèm Provider icon, Ngày tạo, Lần đăng nhập cuối và UID tương ứng.",
        "Kiểm chứng huỷ đăng nhập (TC-01): Bấm đăng nhập Google rồi bấm nút Cancel → Ứng dụng không crash, hiển thị SnackBar 'Đã huỷ đăng nhập'.",
        "Kiểm chứng mất kết nối: Tắt kết nối mạng và bấm đăng nhập → App bắt lỗi network-request-failed và hiển thị 'Vui lòng kiểm tra kết nối mạng'.",
        "Kiểm chứng đăng xuất (TC-10): Bấm 'Đăng xuất' tại ProfileScreen → dọn sạch Local State, ngắt FCM token và điều hướng tức thì về LoginScreen."
    ]
    for va in verifies_auth:
        p = tf_v.add_paragraph()
        p.text = "• " + va
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 2: CLOUDINARY (4 SLIDES) ====================
    # Slide 7: Cloudinary - What & Why
    s7 = prs.slides.add_slide(blank_layout)
    add_bg(s7)
    add_header(s7, "CÔNG NGHỆ 02 · CLOUDINARY MEDIA MANAGEMENT (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Lưu trữ hình ảnh đám mây, nén ảnh tự động và giải phóng hạn mức cho gói Spark", tag_color=C_ACCENT_TEAL)

    c1 = add_card(s7, 0.8, 2.0, 5.7, 4.8)
    tb1 = s7.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · CLOUDINARY LÀ GÌ?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_TEAL

    points_cloud_what = [
        "Định nghĩa: Nền tảng Media Management & Image CDN đám mây hàng đầu, chuyên xử lý, tối ưu hoá và phân phối hình ảnh/video tốc độ cao.",
        "Dynamic Transformations: Hỗ trợ tự động cắt (crop), thu phóng (resize) và tối ưu dung lượng trực tiếp qua URL query (f_auto, q_auto).",
        "Tự động chuyển đổi định dạng (Auto WebP): Giảm 70-80% dung lượng ảnh chụp camera từ điện thoại mà mắt thường không nhận thấy giảm chất lượng.",
        "REST Upload API: Cho phép upload file trực tiếp thông qua HTTP Multipart Request kết hợp Unsigned Upload Preset an toàn."
    ]
    for pt in points_cloud_what:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s7, 6.8, 2.0, 5.7, 4.8)
    tb2 = s7.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO DỰ ÁN DÙNG CLOUDINARY?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_TEAL

    points_cloud_why = [
        "Khắc phục rào cản Firebase Storage Spark Plan (Quyết định D7): Firebase Storage yêu cầu gói Blaze để dùng đầy đủ; Cloudinary là giải pháp thay thế tối ưu cho hình ảnh.",
        "Tải ảnh sản phẩm mượt mà: Lưới sản phẩm (GridView) trong Wishlist hiển thị thumbnail tức thì nhờ CDN Cloudinary, không gây nghẽn RAM thiết bị.",
        "Lưu trữ ảnh đa mục đích: Phục vụ lưu ảnh món đồ (imageUrl trong WishlistItem), ảnh chụp tìm món đồ (PhotoSearchScreen) và hoá đơn chi tiêu (RecordPurchaseScreen).",
        "Bảo mật không lộ Secret: Dùng Unsigned Preset trên client, không bao giờ nhúng API Secret vào mã nguồn ứng dụng Android."
    ]
    for pt in points_cloud_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 8: Cloudinary - How & Cơ chế đăng ký
    s8 = prs.slides.add_slide(blank_layout)
    add_bg(s8)
    add_header(s8, "CÔNG NGHỆ 02 · CLOUDINARY MEDIA MANAGEMENT (2/4)", "Cách Hoạt Động (How) & Cơ Chế Đăng Ký / Cấu Hình", "Cấu hình Unsigned Upload Preset, thư mục lưu trữ và quy trình tải ảnh", tag_color=C_ACCENT_TEAL)

    steps_cloud = [
        ("BƯỚC 1: ĐĂNG KÝ & UPLOAD PRESET", [
            "Tạo tài khoản Cloudinary với Cloud Name: why-i-buy.",
            "Cấu hình 'Upload Preset' dạng Unsigned (why_i_buy_unsigned).",
            "Phân chia thư mục lưu trữ rõ ràng: why_i_buy/items (ảnh món đồ) và why_i_buy/receipts (hoá đơn).",
            "Thiết lập giới hạn kích thước tệp upload (tối đa 5MB) và bật auto-compression."
        ]),
        ("BƯỚC 2: QUY TRÌNH TẢI ẢNH CLIENT", [
            "Người dùng chụp ảnh hoặc chọn từ Album thông qua thư viện image_picker.",
            "Đọc file ảnh thành Uint8List (tương thích cả Android native và Flutter Web).",
            "Tạo MultipartRequest HTTP POST gửi đến endpoint: https://api.cloudinary.com/v1_1/why-i-buy/image/upload.",
            "Gửi kèm các trường: upload_preset, folder, tags ('prm393_lab03', uid)."
        ]),
        ("BƯỚC 3: XỬ LÝ KẾT QUẢ & LƯU FIRESTORE", [
            "Cloudinary trả về JSON gồm secure_url và public_id.",
            "Lưu secure_url vào Firestore document: users/{uid}/wishlistItems/{itemId}.imageUrl.",
            "Khi hiển thị trên UI, gắn URL transformation: /image/upload/c_fill,w_300,h_300,q_auto,f_auto/... để tải ảnh nhanh nhất."
        ])
    ]

    for idx, (title, pts) in enumerate(steps_cloud):
        left = 0.8 + idx * 3.95
        add_card(s8, left, 2.0, 3.75, 4.8)
        tb = s8.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = C_ACCENT_TEAL

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 9: Cloudinary - Chỗ nào dùng code đó
    s9 = prs.slides.add_slide(blank_layout)
    add_bg(s9)
    add_header(s9, "CÔNG NGHỆ 02 · CLOUDINARY MEDIA MANAGEMENT (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn upload ảnh bằng MultipartRequest và lưu trữ URL an toàn vào Model", tag_color=C_ACCENT_TEAL)

    c_code = add_card(s9, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s9.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// Tích hợp Cloudinary Media Upload (lib/services/cloudinary_storage_service.dart)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_cloud = """Future<String?> uploadImageToCloudinary({
  required Uint8List imageBytes,
  required String folderName,
}) async {
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/why-i-buy/image/upload');
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = 'why_i_buy_unsigned'
    ..fields['folder'] = 'why_i_buy/$folderName'
    ..files.add(http.MultipartFile.fromBytes(
      'file', imageBytes, filename: 'item_\${DateTime.now().millisecondsSinceEpoch}.jpg'
    ));

  final response = await request.send();
  if (response.statusCode == 200) {
    final resBody = await response.stream.bytesToString();
    final json = jsonDecode(resBody);
    return json['secure_url'] as String; // Trả về link CDN https
  }
  throw AppException('Lỗi tải ảnh lên Cloudinary: \${response.statusCode}');
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_cloud
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s9, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s9.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_TEAL

    exps_cloud = [
        "Ánh xạ Model: Trường imageUrl trong WishlistItem (lib/models/wishlist_item.dart dòng 49) lưu trực tiếp đường dẫn Cloudinary trả về.",
        "Unsigned Upload Preset: Cấu hình giới hạn tại Cloudinary Console, loại bỏ hoàn toàn nguy cơ lộ khóa API Secret trên mã nguồn Flutter.",
        "Xử lý Bytes (Uint8List): Chạy tương thích 100% trên cả Android, Web và máy ảo mà không bị phụ thuộc vào File path hệ điều hành.",
        "Error Fallback: Mã lỗi HTTP được bắt và gói vào AppException, giao diện hiển thị SnackBar hướng dẫn người dùng thử lại."
    ]
    for e in exps_cloud:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 10: Cloudinary - Dùng ở màn hình nào & Kiểm chứng
    s10 = prs.slides.add_slide(blank_layout)
    add_bg(s10)
    add_header(s10, "CÔNG NGHỆ 02 · CLOUDINARY MEDIA MANAGEMENT (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình áp dụng thực tế và kiểm chứng bằng chứng Media Library trên Cloudinary", tag_color=C_ACCENT_TEAL)

    c_screen = add_card(s10, 0.8, 2.0, 5.7, 4.8)
    tb_s = s10.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_TEAL

    screens_cloud = [
        "PhotoSearchScreen (Chụp để tìm món): Chụp ảnh sản phẩm ngoài đời thực để tải lên Cloudinary và đưa vào Gemini AI nhận diện tên hàng.",
        "AddItemScreen (Thêm món đắn đo): Người dùng chọn ảnh món đồ từ thư viện để tải lên Cloudinary và lưu vào danh sách chờ mua.",
        "RecordPurchaseScreen (Ghi nhận mua sắm): Chụp ảnh hoá đơn mua hàng giấy (Receipt) làm chứng từ đối chiếu chi tiêu cuối tháng.",
        "WishlistScreen & ItemDetailScreen: Hiển thị hình ảnh sản phẩm mượt mà thông qua CDN Cloudinary với đường dẫn tối ưu kích thước."
    ]
    for sc in screens_cloud:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s10, 6.8, 2.0, 5.7, 4.8)
    tb_v = s10.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG & BẰNG CHỨNG THỰC TẾ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_TEAL

    verifies_cloud = [
        "Kiểm chứng Cloudinary Dashboard: Vào Cloudinary Media Library → thư mục why_i_buy/items thấy xuất hiện ảnh món đồ vừa chụp, kích thước tệp nén từ 3.2MB xuống còn 142KB.",
        "Kiểm chứng Dynamic Transformation: Mở URL trên trình duyệt và thêm c_fill,w_150,h_150,q_auto → ảnh được tự động cắt vuông và tối ưu ngay tức thì.",
        "Kiểm chứng ngoại tuyến: Tắt mạng trong lúc chọn ảnh → App thông báo lỗi upload, lưu tạm ảnh cục bộ để người dùng bấm nút 'Tải lại' mà không mất nội dung form.",
        "Đối chiếu Firestore: Kiểm tra document trong collection items thấy trường imageUrl trỏ chính xác về domain res.cloudinary.com/why-i-buy/..."
    ]
    for vc in verifies_cloud:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 3: FIREBASE CLOUD STORAGE & BÁO CÁO PDF (3 SLIDES) ====================
    # Slide 11: Storage - What, Why & How
    s11 = prs.slides.add_slide(blank_layout)
    add_bg(s11)
    add_header(s11, "CÔNG NGHỆ 03 · CLOUD STORAGE & BÁO CÁO PDF (1/3)", "Khái Niệm, Vai Trò & Cơ Chế Hoạt Động (What, Why & How)", "Lưu trữ tệp báo cáo chi tiêu tháng, phân quyền bảo mật UID và nhúng font tiếng Việt", tag_color=C_ACCENT_AMBER)

    c1 = add_card(s11, 0.8, 2.0, 5.7, 4.8)
    tb1 = s11.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT & WHY · KHÁI NIỆM & VAI TRÒ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_AMBER

    points_storage_what = [
        "What: Dịch vụ lưu trữ tệp đám mây quy mô lớn của Google, bảo mật thông qua Firebase Storage Rules tích hợp chặt chẽ với Firebase Auth.",
        "Why trong Why I Buy: Người dùng cần xuất báo cáo tổng kết chi tiêu tháng định dạng PDF để lưu trữ lâu dài hoặc đối chiếu tài chính cá nhân.",
        "Bảo mật quyền dữ liệu: Mỗi người dùng chỉ được toàn quyền đọc/ghi tệp trong thư mục reports/{uid}/... của chính mình.",
        "Font chữ tiếng Việt chuẩn hóa: Tích hợp font Be Vietnam Pro (SIL OFL) trực tiếp vào file PDF để hiển thị chính xác dấu tiếng Việt và ký hiệu tiền tệ '₫'."
    ]
    for pt in points_storage_what:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s11, 6.8, 2.0, 5.7, 4.8)
    tb2 = s11.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "HOW · QUY TẮC BẢO MẬT STORAGE RULES"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_AMBER

    points_storage_how = [
        "Storage Bucket: prm393-34056.firebasestorage.app.",
        "Quy tắc bảo mật firebase/storage.rules:\n  rules_version = '2';\n  service firebase.storage {\n    match /b/{bucket}/o {\n      match /reports/{userId}/{fileName} {\n        allow read, write: if request.auth != null && request.auth.uid == userId;\n      }\n    }\n  }",
        "Tiến độ Upload: Theo dõi luồng sự kiện putData().snapshotEvents để cập nhật % tiến trình trực quan trên giao diện.",
        "Quyết định D7 (Linh hoạt gói Spark): Kết hợp tạo PDF offline trên máy bằng gói pdf và chia sẻ bằng gói printing (ReportShareService)."
    ]
    for pt in points_storage_how:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 12: Storage - Chỗ nào dùng code đó
    s12 = prs.slides.add_slide(blank_layout)
    add_bg(s12)
    add_header(s12, "CÔNG NGHỆ 03 · CLOUD STORAGE & BÁO CÁO PDF (2/3)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn ReportService và ReportShareService theo nguyên tắc Single Responsibility", tag_color=C_ACCENT_AMBER)

    c_code = add_card(s12, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s12.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/report_service.dart (dòng 30-70)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_storage = """Future<Uint8List> generateMonthlyReportPdf({
  required String userName,
  required DateTime month,
  required List<PurchaseItem> purchases,
  required List<WishlistItem> decidedItems,
}) async {
  final theme = await _loadTheme(); // Nhúng font Be Vietnam Pro
  final pdf = pw.Document(theme: theme, title: 'Why I Buy – \${formatMonthLabel(month)}');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Header(level: 0, text: 'BÁO CÁO CHI TIÊU - \${formatMonthLabel(month)}'),
        _buildSummarySection(purchases, decidedItems), // Tổng chi & tiền đã kiềm chế
        _buildPurchasesTable(purchases),             // Danh sách giao dịch
      ],
    ),
  );
  return pdf.save(); // Trả về bytes để lưu trữ hoặc chia sẻ
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_storage
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s12, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s12.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_AMBER

    exps_st = [
        "Vị trí: lib/services/report_service.dart và lib/services/report_share_service.dart.",
        "Nguyên tắc CR-02 (Single Responsibility): ReportService chỉ thuần túy dựng tài liệu PDF; việc gửi file hoặc mở hộp thoại in chuyển sang ReportShareService.",
        "Font chữ tiếng Việt nhúng sẵn: Tải từ assets/fonts/BeVietnamPro-Regular.ttf, giải quyết triệt để lỗi ô vuông tiếng Việt trên thiết bị ngoại tuyến.",
        "Cấu trúc MultiPage: Tự động phân trang và lặp lại tiêu đề bảng khi danh sách chi tiêu dài."
    ]
    for e in exps_st:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 13: Storage - Màn hình & Kiểm chứng
    s13 = prs.slides.add_slide(blank_layout)
    add_bg(s13)
    add_header(s13, "CÔNG NGHỆ 03 · CLOUD STORAGE & BÁO CÁO PDF (3/3)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình xuất báo cáo, kiểm thử quyền truy cập và kiểm tra font chữ", tag_color=C_ACCENT_AMBER)

    c_screen = add_card(s13, 0.8, 2.0, 5.7, 4.8)
    tb_s = s13.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_AMBER

    screens_storage = [
        "MonthlyReflectionScreen (Chiêm nghiệm tháng): Nút [Xuất và chia sẻ PDF] xuất hiện ở cuối trang sau khi người dùng hoàn thành phản tư chi tiêu.",
        "InsightsScreen (Góc nhìn chi tiêu): Nút xem trước báo cáo và chia sẻ file tài chính định dạng PDF.",
        "System Share Sheet (Hộp thoại hệ thống Android): Nhận luồng bytes từ ReportShareService để chia sẻ qua Zalo, Drive hoặc In trực tiếp."
    ]
    for sc in screens_storage:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s13, 6.8, 2.0, 5.7, 4.8)
    tb_v = s13.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG & STORAGE RULES"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_AMBER

    verifies_storage = [
        "Kiểm thử xuất PDF (TC-07): Nhấn [Xuất và chia sẻ PDF] tại màn hình Chiêm nghiệm tháng → Bảng chia sẻ Android mở ra kèm file why-i-buy_yyyy-MM.pdf, thông báo 'Đã tạo file thành công'.",
        "Kiểm tra tính toàn vẹn font chữ: Mở file PDF trên trình đọc Adobe Reader/Chrome → Kiểm tra các từ tiếng Việt có dấu ('Chi tiêu', 'Đắn đo', '₫') hiển thị sắc nét.",
        "Kiểm chứng Security Rules: Sử dụng Firebase Console Simulator gửi request từ tài khoản không khớp UID → Hệ thống chặn lại với lỗi 403 Forbidden.",
        "Không dùng quy tắc mở công khai: file firebase/storage.rules đã được commit lên GitHub với phân quyền chủ sở hữu nghiêm ngặt."
    ]
    for vc in verifies_storage:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 4: FIREBASE CLOUD MESSAGING (FCM) (4 SLIDES) ====================
    # Slide 14: FCM - What & Why
    s14 = prs.slides.add_slide(blank_layout)
    add_bg(s14)
    add_header(s14, "CÔNG NGHỆ 04 · FIREBASE CLOUD MESSAGING (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Thông báo đẩy giữ chân người dùng văn minh, nhắc nhở hạ nhiệt và cảnh báo ngày hội Sale", tag_color=C_ACCENT_PURPLE)

    c1 = add_card(s14, 0.8, 2.0, 5.7, 4.8)
    tb1 = s14.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · FCM LÀ GÌ?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_PURPLE

    pts = [
        "Định nghĩa: Dịch vụ nhắn tin đám mây miễn phí của Google, kết nối máy chủ quản trị tới ứng dụng di động Android một cách đáng tin cậy.",
        "Đa trạng thái ứng dụng: Khả năng gửi thông báo khi ứng dụng đang mở (Foreground), chạy ẩn (Background) hoặc đã tắt hoàn toàn (Terminated).",
        "Cơ chế Data Payload: Đính kèm dữ liệu định tuyến (target: 'item_detail', itemId: '123') để dẫn người dùng đến chính xác màn hình cần xem.",
        "Token-based Targeting: Quản lý mỗi thiết bị bằng một mã FCM Registration Token được cấp phát riêng biệt."
    ]
    for pt in pts:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s14, 6.8, 2.0, 5.7, 4.8)
    tb2 = s14.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO WHY I BUY CẦN FCM?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_PURPLE

    pts_why = [
        "Nhắc nhở hạ nhiệt chi tiêu (Cooling-off Expiry): Khi một món đồ trong Wishlist hết 3 ngày đắn đo, FCM gửi thông báo nhắc người dùng vào đưa ra quyết định (Mua hay Bỏ qua).",
        "Cảnh báo bẫy Sale (Sale Alert): Gửi lời nhắc giữ bình tĩnh trước giờ vàng flash sale (như 11.11, Shopee Payday) để ngăn ngừa mua theo cảm xúc.",
        "Đồng bộ liên thiết bị: Khi người dùng lưu món từ Chrome Extension trên máy tính, điện thoại nhận ngay thông báo xác nhận món đồ đã vào Wishlist.",
        "Lưu lịch sử thông báo: Toàn bộ thông báo được lưu lại trong Hộp thư tin nhắn để người dùng xem lại bất cứ lúc nào."
    ]
    for pt in pts_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 15: FCM - How & Cơ chế đăng ký
    s15 = prs.slides.add_slide(blank_layout)
    add_bg(s15)
    add_header(s15, "CÔNG NGHỆ 04 · FIREBASE CLOUD MESSAGING (2/4)", "Cách Hoạt Động (How) & Cơ Chế Đăng Ký / Cấu Hình", "Cấu hình quyền Android 13+, quản lý Token trên Firestore và 3 trạng thái ứng dụng", tag_color=C_ACCENT_PURPLE)

    steps_fcm = [
        ("BƯỚC 1: XIN QUYỀN & LƯU TOKEN", [
            "Android 13+ (API 33) yêu cầu quyền runtime POST_NOTIFICATIONS.",
            "NotificationService gọi _fcm.requestPermission() lúc khởi động.",
            "Lấy token thiết bị: final token = await _fcm.getToken().",
            "Đăng ký lưu token vào Firestore: users/{uid}/fcmTokens/{token}.",
            "Lắng nghe luồng đổi token onTokenRefresh."
        ]),
        ("BƯỚC 2: XỬ LÝ 3 TRẠNG THÁI", [
            "Foreground: FirebaseMessaging.onMessage nhận tin khi app đang mở → lưu vào Hộp thư và hiển thị In-App Notification.",
            "Background: Nhấn thông báo trên thanh thông báo → FirebaseMessaging.onMessageOpenedApp kích hoạt điều hướng.",
            "Terminated: Mở app từ trạng thái đóng hoàn toàn → FirebaseMessaging.instance.getInitialMessage() xử lý dữ liệu mở đầu."
        ]),
        ("BƯỚC 3: ISOLATE & TRUNG TÂM TIN NHẮN", [
            "Đăng ký Background Handler cấp cao nhất với @pragma('vm:entry-point').",
            "Chạy trên isolate riêng biệt: chỉ lưu tin nhắn vào SharedPreferences offline.",
            "Đồng bộ với InboxScreen: Người dùng luôn xem lại được toàn bộ thông báo đã nhận."
        ])
    ]

    for idx, (title, pts) in enumerate(steps_fcm):
        left = 0.8 + idx * 3.95
        add_card(s15, left, 2.0, 3.75, 4.8)
        tb = s15.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = C_ACCENT_PURPLE

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 16: FCM - Chỗ nào dùng code đó
    s16 = prs.slides.add_slide(blank_layout)
    add_bg(s16)
    add_header(s16, "CÔNG NGHỆ 04 · FIREBASE CLOUD MESSAGING (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn Background Handler và bộ điều hướng Target trong NotificationService", tag_color=C_ACCENT_PURPLE)

    c_code = add_card(s16, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s16.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/notification_service.dart (dòng 40-95)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_fcm = """// Hàm xử lý khi app chạy ngầm hoặc đã đóng hoàn toàn (Isolate riêng)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final item = notificationItemFromMessage(message, NotificationSource.background);
  await SharedPrefsNotificationHistoryStore().add(item);
}

// Khởi tạo và lắng nghe tại NotificationService
Future<void> initialize() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // App đang mở (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _handleIncomingMessage(message, NotificationSource.foreground);
  });

  // Chạm vào thông báo trên thanh hệ thống
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateByPayload(message.data); // Mở đúng màn hình chi tiết
  });
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_fcm
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s16, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s16.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_PURPLE

    exps_fcm = [
        "Vị trí: lib/services/notification_service.dart và lib/services/notification_history_store.dart.",
        "@pragma('vm:entry-point'): Cực kỳ quan trọng để trình biên dịch R8 / AOT của Android không xoá nhầm hàm background khi build bản Release APK.",
        "Điều hướng thông minh (_navigateByPayload): Trích xuất data['target'] (ví dụ: 'item_detail') để mở đúng chi tiết món đồ thay vì luôn mở Trang chủ.",
        "Lưu trữ cục bộ bền vững: Tin nhắn được đưa vào SharedPreferences, đảm bảo khi không có mạng vẫn hiển thị được lịch sử thông báo."
    ]
    for e in exps_fcm:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 17: FCM - Màn hình & Kiểm chứng
    s17 = prs.slides.add_slide(blank_layout)
    add_bg(s17)
    add_header(s17, "CÔNG NGHỆ 04 · FIREBASE CLOUD MESSAGING (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình áp dụng, kịch bản thử nghiệm đa trạng thái và kiểm tra quyền", tag_color=C_ACCENT_PURPLE)

    c_screen = add_card(s17, 0.8, 2.0, 5.7, 4.8)
    tb_s = s17.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_PURPLE

    screens_fcm = [
        "InboxScreen (Hộp thư thông báo trong app): Liệt kê danh sách các thông báo đã nhận kèm trạng thái Đã đọc / Chưa đọc, thời gian và nút hành động.",
        "ReminderPermissionScreen: Màn hình giải thích lý do cần quyền thông báo (nhắc hết hạn đắn đo mua sắm) trước khi hiện popup hệ điều hành.",
        "System Status Bar & Lockscreen: Hiển thị Heads-up notification khi có sự kiện quan trọng.",
        "Điều hướng đích đến: Chạm vào thông báo sẽ mở ngay ItemDetailScreen của món đồ hoặc SaleSuggestionScreen."
    ]
    for sc in screens_fcm:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s17, 6.8, 2.0, 5.7, 4.8)
    tb_v = s17.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG & SERVER PUSH"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_PURPLE

    verifies_fcm = [
        "Thử nghiệm Firebase Console: Vào Firebase Console → Messaging → Soạn thông báo thử nghiệm với FCM Token của máy ảo → Thông báo hiện trên khay hệ thống.",
        "Kiểm chứng Spring Boot Server: Chạy spring-boot-push tại cổng 8080 và gọi POST /api/push/send kèm token và payload target → Nhận tin thành công.",
        "Kiểm chứng khi app bị Terminated: Tắt hẳn app (swipe dismiss), gửi tin từ console → Chạm vào thông báo → App tự khởi động và chuyển thẳng vào InboxScreen.",
        "Kiểm thử quyền (TC-09): Khi người dùng từ chối quyền, app ghi nhận cờ và không hiện dialog quấy rầy lại."
    ]
    for vc in verifies_fcm:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 5: GOOGLE ANALYTICS FOR FIREBASE (4 SLIDES) ====================
    # Slide 18: Analytics - What & Why
    s18 = prs.slides.add_slide(blank_layout)
    add_bg(s18)
    add_header(s18, "CÔNG NGHỆ 05 · FIREBASE ANALYTICS (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Đo lường hành vi người dùng, đánh giá phễu chuyển đổi và tuân thủ nghiêm ngặt NO PII", tag_color=C_ACCENT_ROSE)

    c1 = add_card(s18, 0.8, 2.0, 5.7, 4.8)
    tb1 = s18.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · GOOGLE ANALYTICS LÀ GÌ?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_ROSE

    pts = [
        "Định nghĩa: Nền tảng phân tích hành vi ứng dụng di động theo mô hình Event-driven của Google, thu thập tương tác của người dùng theo thời gian thực.",
        "Cấu trúc sự kiện: Mỗi sự kiện bao gồm Event Name (snake_case) kết hợp cùng danh sách Parameters (tham số bổ trợ ngữ cảnh).",
        "DebugView: Bảng điều khiển thời gian thực (Real-time Dashboard) giúp lập trình viên kiểm thử sự kiện ngay khi thao tác trên thiết bị.",
        "User Engagement Funnel: Hỗ trợ xây dựng phễu từ lúc thêm món đồ đắn đo đến lúc ra quyết định mua hoặc từ bỏ."
    ]
    for pt in pts:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s18, 6.8, 2.0, 5.7, 4.8)
    tb2 = s18.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO WHY I BUY CẦN ANALYTICS?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_ROSE

    pts_why = [
        "Đo lường hiệu quả hạ nhiệt (Mindful Shopping KPI): Trả lời câu hỏi sản phẩm: Có bao nhiêu % người dùng quyết định KHÔNG mua sau thời gian chờ 3 ngày?",
        "Tối ưu trải nghiệm tính năng: Theo dõi tần suất sử dụng tính năng 'Chụp ảnh để tìm món' và tỷ lệ chấp nhận gợi ý của Gemini AI.",
        "Nguyên tắc tuyệt đối KHÔNG LƯU PII: Tuân thủ quy định bảo mật của Google và tiêu chí Lab 3: Không bao giờ gửi email, tên người dùng, tên sản phẩm hay số tiền chính xác.",
        "Kỹ thuật Amount Bucket: Số tiền mua sắm được gom thành các khoảng ('under_100k', '100k_500k', '500k_1m', 'over_5m') để bảo mật dữ liệu tài chính."
    ]
    for pt in pts_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 19: Analytics - How & Cơ chế đăng ký
    s19 = prs.slides.add_slide(blank_layout)
    add_bg(s19)
    add_header(s19, "CÔNG NGHỆ 05 · FIREBASE ANALYTICS (2/4)", "Cách Hoạt Động (How) & Kế Hoạch 10+ Sự Kiện", "Kế hoạch theo dõi chuẩn docs/analytics-plan.md và tích hợp Navigator Observer", tag_color=C_ACCENT_ROSE)

    steps_ana = [
        ("BƯỚC 1: KHỞI TẠO & ĐĂNG KÝ", [
            "Khởi tạo FirebaseAnalytics.instance trong AppAnalyticsService.",
            "Đăng ký FirebaseAnalyticsObserver vào navigatorObservers của MaterialApp để tự động ghi nhận luồng chuyển màn hình.",
            "Gắn User ID bằng setUserId(uid) sau khi đăng nhập thành công (xóa về null khi đăng xuất)."
        ]),
        ("BƯỚC 2: DANH MỤC 10+ SỰ KIỆN CHÍNH", [
            "login / logout: Theo dõi phương thức đăng nhập và thời gian phiên.",
            "search: Độ dài từ khóa (query_length) và số kết quả (result_count).",
            "add_to_wishlist: Động lực mua ('cần thiết', 'thích', 'sale') & mức giá.",
            "make_decision: Quyết định cuối ('đã mua', 'từ bỏ', 'chờ tiếp').",
            "export_report / ai_request: Tần suất xuất PDF & gọi AI."
        ]),
        ("BƯỚC 3: NGUYÊN TẮC BẢO VỆ DỮ LIỆU", [
            "Bọc toàn bộ lệnh logEvent() trong try-catch: Nếu tracking lỗi, tuyệt đối không làm gián đoạn luồng nghiệp vụ chính của người dùng.",
            "Tất cả tên sự kiện và tham số được khai báo cố định dạng abstract final class trong analytics_events.dart."
        ])
    ]

    for idx, (title, pts) in enumerate(steps_ana):
        left = 0.8 + idx * 3.95
        add_card(s19, left, 2.0, 3.75, 4.8)
        tb = s19.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = C_ACCENT_ROSE

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 20: Analytics - Chỗ nào dùng code đó
    s20 = prs.slides.add_slide(blank_layout)
    add_bg(s20)
    add_header(s20, "CÔNG NGHỆ 05 · FIREBASE ANALYTICS (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn AppAnalyticsService và việc gọi tracking an toàn sau khi hoàn tất nghiệp vụ", tag_color=C_ACCENT_ROSE)

    c_code = add_card(s20, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s20.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/analytics_service.dart (dòng 25-70)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_ana = """class AppAnalyticsService {
  final FirebaseAnalytics? _analytics;

  Future<void> _log(String event, [Map<String, Object>? parameters]) async {
    try {
      await _analytics?.logEvent(name: event, parameters: parameters);
    } catch (e) {
      // Analytics không bao giờ được làm hỏng luồng nghiệp vụ chính
      if (kDebugMode) debugPrint('Analytics \$event error: \$e');
    }
  }

  // Sự kiện thêm món đồ vào Wishlist đắn đo (Không kèm PII)
  Future<void> logAddToWishlist({
    required String motive,
    required bool hasPrice,
    String? amountBucket,
  }) => _log(AnalyticsEvents.addToWishlist, {
    AnalyticsParams.motive: motive,
    AnalyticsParams.hasPrice: hasPrice ? 1 : 0,
    if (amountBucket != null) AnalyticsParams.amountBucket: amountBucket,
  });
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_ana
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s20, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s20.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_ROSE

    exps_ana = [
        "Vị trí: lib/services/analytics_service.dart và lib/services/analytics_events.dart.",
        "Non-blocking Safety: Hàm _log bọc trong try-catch, không rethrow lỗi, đảm bảo trải nghiệm người dùng luôn mượt mà.",
        "Khử định danh PII: Tham số motive chỉ mang các giá trị định nghĩa trước ('necessity', 'pleasure', 'sale_promo'); amountBucket là chuỗi phân khúc tiền.",
        "Vị trí gọi trên UI: Được gọi tại WishlistViewModel.addItem() ngay sau khi Document ghi thành công vào Firestore."
    ]
    for e in exps_ana:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 21: Analytics - Màn hình & Kiểm chứng
    s21 = prs.slides.add_slide(blank_layout)
    add_bg(s21)
    add_header(s21, "CÔNG NGHỆ 05 · FIREBASE ANALYTICS (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình phát sinh sự kiện và kiểm chứng trực tiếp trên Firebase Analytics DebugView", tag_color=C_ACCENT_ROSE)

    c_screen = add_card(s21, 0.8, 2.0, 5.7, 4.8)
    tb_s = s21.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_ROSE

    screens_ana = [
        "HomeScreen: Sự kiện search khi người dùng tìm kiếm món trong danh sách; Sự kiện click_sale_reminder khi bấm vào thông báo sale.",
        "AddItemScreen / PhotoSearchScreen: Sự kiện add_to_wishlist và ai_request khi chụp ảnh nhờ Gemini phân tích thông tin món đồ.",
        "ItemDetailScreen: Sự kiện view_item_detail và make_decision khi người dùng bấm 'Mua ngay' hoặc 'Bỏ qua món này'.",
        "BudgetScreen & MonthlyReflectionScreen: Sự kiện budget_set khi điều chỉnh trần chi tiêu và export_report khi xuất file PDF."
    ]
    for sc in screens_ana:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s21, 6.8, 2.0, 5.7, 4.8)
    tb_v = s21.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG TRÊN DEBUGVIEW"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_ACCENT_ROSE

    verifies_ana = [
        "Lệnh kích hoạt DebugView qua ADB (chuẩn package com.group07.whyibuy):\n  adb shell setprop debug.firebase.analytics.app com.group07.whyibuy",
        "Kiểm tra Console thời gian thực: Mở Firebase Console → Analytics → DebugView; màn hình hiển thị luồng giây (Seconds feed) ghi nhận từng sự kiện vừa bấm trên máy ảo.",
        "Đối chiếu tham số: Nhấp vào sự kiện make_decision, kiểm tra tham số decision = 'skipped', days_in_cooldown = 3 xuất hiện đúng như kỳ vọng.",
        "Xác nhận NO PII: Kiểm tra danh sách tham số không có email, tên sản phẩm hay địa chỉ người dùng."
    ]
    for vc in verifies_ana:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 6: FIREBASE CRASHLYTICS (4 SLIDES) ====================
    # Slide 22: Crashlytics - What & Why
    s22 = prs.slides.add_slide(blank_layout)
    add_bg(s22)
    add_header(s22, "CÔNG NGHỆ 06 · FIREBASE CRASHLYTICS (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Giám sát sức khỏe ứng dụng, phân biệt lỗi Fatal vs Non-fatal và theo dõi ngữ cảnh lỗi", tag_color=RGBColor(180, 83, 9))

    c1 = add_card(s22, 0.8, 2.0, 5.7, 4.8)
    tb1 = s22.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · CRASHLYTICS LÀ GÌ?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    pts = [
        "Định nghĩa: Công cụ phân tích và báo cáo sự cố (Crash Reporting) thời gian thực của Google, giúp lập trình viên phát hiện, ưu tiên và sửa chữa lỗi ứng dụng.",
        "Phân loại lỗi chính xác: Tách biệt rõ ràng giữa Fatal Crashes (lỗi làm ứng dụng bị văng ra) và Handled Non-fatal Errors (lỗi đã được try-catch nhưng cần ghi nhận).",
        "Stack Trace chi tiết: Báo cáo dòng mã chính xác gây ra lỗi kèm thông tin thiết bị (Android version, model máy, bộ nhớ RAM khả dụng).",
        "Custom Keys & Breadcrumbs: Đính kèm trạng thái ứng dụng trước khi gặp sự cố."
    ]
    for pt in pts:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s22, 6.8, 2.0, 5.7, 4.8)
    tb2 = s22.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO WHY I BUY CẦN CRASHLYTICS?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    pts_why = [
        "Đảm bảo ứng dụng không bao giờ 'chết âm thầm': Người dùng đang quyết định mua sắm hoặc tính toán ngân sách nếu gặp lỗi cần được lưu draft và không mất dữ liệu.",
        "Phát hiện lỗi ngoại vi: Các lỗi phát sinh do camera khi chụp ảnh món đồ, lỗi định dạng URL khi chia sẻ từ Shopee hoặc lỗi hết quota Gemini AI được ghi nhận đầy đủ.",
        "Truy vết theo màn hình (Screen Key): Tự động đính kèm màn hình người dùng đang đứng (ví dụ: screen: 'add_item') để đội ngũ phát triển tái hiện lỗi nhanh chóng.",
        "Tiêu chuẩn Lab 3: Cung cấp đầy đủ cơ chế kích hoạt crash thử nghiệm để kiểm chứng và hiển thị thông báo lỗi thân thiện cho người dùng."
    ]
    for pt in pts_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 23: Crashlytics - How & Cơ chế đăng ký
    s23 = prs.slides.add_slide(blank_layout)
    add_bg(s23)
    add_header(s23, "CÔNG NGHỆ 06 · FIREBASE CRASHLYTICS (2/4)", "Cách Hoạt Động (How) & Cơ Chế Đăng Ký / Khởi Tạo", "Khởi tạo bộ bắt lỗi toàn cục trong main.dart, gắn User ID và Custom Keys", tag_color=RGBColor(180, 83, 9))

    steps_crash = [
        ("BƯỚC 1: KHỞI TẠO BỘ BẮT LỖI TOÀN CỤC", [
            "Khởi tạo trong main() trước runApp():",
            "FlutterError.onError: Bắt toàn bộ lỗi framework Flutter (UI rendering, layout error) và gửi về recordFlutterFatalError.",
            "PlatformDispatcher.instance.onError: Bắt toàn bộ lỗi async unhandled trong luồng Dart và báo cáo fatal: true.",
            "ScreenKeyObserver: Lắng nghe navigatorObservers để cập nhật Custom Key 'screen' theo route hiện tại."
        ]),
        ("BƯỚC 2: GẮN NGỮ CẢNH CHẨN ĐOÁN", [
            "setUserId(uid): Gắn mã người dùng ẩn danh (không đính kèm email).",
            "setCustomKey('app_scope', 'mindful_shopping'): Định vị phạm vi.",
            "setCustomKey('has_pending_writes', true): Ghi nhận xem có dữ liệu chưa kịp đồng bộ lúc crash hay không."
        ]),
        ("BƯỚC 3: GỬI LỖI NON-FATAL KÈM THÔNG BÁO", [
            "Các khối catch trong ViewModel gọi CrashlyticsService.recordHandledError().",
            "Báo cáo lỗi về server Crashlytics nhưng UI vẫn hiển thị ErrorView hoặc SnackBar để người dùng bấm 'Thử lại'."
        ])
    ]

    for idx, (title, pts) in enumerate(steps_crash):
        left = 0.8 + idx * 3.95
        add_card(s23, left, 2.0, 3.75, 4.8)
        tb = s23.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = RGBColor(180, 83, 9)

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 24: Crashlytics - Chỗ nào dùng code đó
    s24 = prs.slides.add_slide(blank_layout)
    add_bg(s24)
    add_header(s24, "CÔNG NGHỆ 06 · FIREBASE CRASHLYTICS (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn bắt lỗi toàn cục và hàm kích hoạt Crash kiểm thử trong CrashlyticsService", tag_color=RGBColor(180, 83, 9))

    c_code = add_card(s24, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s24.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/crashlytics_service.dart (dòng 20-75)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_crash = """class CrashlyticsService {
  void initCrashlyticsHandlers() {
    // Bắt lỗi render của Flutter UI
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      _crashlytics.recordFlutterFatalError(details);
    };
    // Bắt lỗi Dart unhandled ngoài luồng UI
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Bắt lỗi đã xử lý nhưng cần báo cáo (Non-fatal)
  Future<void> recordHandledError(dynamic error, StackTrace? stack, {String? reason}) async {
    await _crashlytics.recordError(error, stack, reason: reason, fatal: false);
  }

  // Kích hoạt Crash có chủ đích để kiểm chứng Lab 3
  void forceCrashForTesting() {
    _crashlytics.setCustomKey('test_scenario', 'lab3_verification_forced_crash');
    _crashlytics.crash(); // Gọi trực tiếp native crash
  }
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_crash
    p2.font.name = "Consolas"
    p2.font.size = Pt(9.5)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s24, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s24.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    exps_crash = [
        "Vị trí: lib/services/crashlytics_service.dart (dòng 20-75).",
        "Dump console song song: FlutterError.dumpErrorToConsole giúp lập trình viên vẫn nhìn thấy log đỏ trong Android Studio khi đang debug.",
        "forceCrashForTesting(): Gọi _crashlytics.crash() kèm custom key 'test_scenario' để phân biệt với crash thật trong sản phẩm.",
        "Gửi đồng thời Firestore: Hàm logCrashToFirestore lưu thêm một bản ghi vào Firestore collection 'crashes' để Web Admin Dashboard theo dõi tức thì."
    ]
    for e in exps_crash:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 25: Crashlytics - Màn hình & Kiểm chứng
    s25 = prs.slides.add_slide(blank_layout)
    add_bg(s25)
    add_header(s25, "CÔNG NGHỆ 06 · FIREBASE CRASHLYTICS (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình kiểm thử Dev, khu vực xử lý lỗi và bằng chứng hiển thị trên Crashlytics Dashboard", tag_color=RGBColor(180, 83, 9))

    c_screen = add_card(s25, 0.8, 2.0, 5.7, 4.8)
    tb_s = s25.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    screens_crash = [
        "Màn hình cài đặt / Khu vực Dev (ProfileScreen > Dev Settings): Nút 'Kích hoạt thử nghiệm Crash (Lab 3 Test)' chỉ hiển thị ở chế độ debug.",
        "WishlistScreen & PrePurchaseScreen: Khi xảy ra lỗi mạng hoặc lỗi timeout khi gọi Gemini AI, bắt qua recordHandledError và hiển thị ErrorView kèm nút 'Thử lại'.",
        "PhotoSearchScreen: Bắt ngoại lệ camera hoặc lỗi parse ảnh từ thư viện, ghi nhận non-fatal error kèm custom key photo_format.",
        "Màn hình nhập liệu chi tiêu: Bắt lỗi nhập chuỗi không đúng định dạng tiền tệ mà không làm ứng dụng crash."
    ]
    for sc in screens_crash:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s25, 6.8, 2.0, 5.7, 4.8)
    tb_v = s25.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG TRÊN CONSOLE"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    verifies_crash = [
        "Kiểm chứng Crash thực tế: Nhấn nút 'Thử nghiệm Crash' → Ứng dụng lập tức đóng → Mở lại ứng dụng để SDK gửi báo cáo crash lên server.",
        "Xác minh Crashlytics Dashboard: Mở Firebase Console → Crashlytics → Xuất hiện sự cố mới trong mục Crashes: 'Fatal Exception: java.lang.Exception' kèm stack trace Dart chính xác.",
        "Xác minh Custom Keys: Mở chi tiết sự cố → tab Keys → Thấy rõ test_scenario = 'lab3_verification_forced_crash', screen = 'dev_settings' và UID người dùng.",
        "Xác minh Non-fatal Errors: Kiểm tra tab Non-fatals ghi nhận các lỗi mạng đã xử lý mà không làm rớt phiên sử dụng."
    ]
    for vc in verifies_crash:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== CÔNG NGHỆ 7: FIREBASE REMOTE CONFIG (4 SLIDES) ====================
    # Slide 26: Remote Config - What & Why
    s26 = prs.slides.add_slide(blank_layout)
    add_bg(s26)
    add_header(s26, "CÔNG NGHỆ 07 · FIREBASE REMOTE CONFIG (1/4)", "Khái Niệm (What) & Lý Do Lựa Chọn (Why)", "Điều chỉnh hành vi và tham số ứng dụng từ xa tức thì mà không cần biên dịch lại mã nguồn", tag_color=RGBColor(2, 132, 199))

    c1 = add_card(s26, 0.8, 2.0, 5.7, 4.8)
    tb1 = s26.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "WHAT · REMOTE CONFIG LÀ GÌ?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(2, 132, 199)

    pts = [
        "Định nghĩa: Dịch vụ đám mây cho phép lưu trữ và cập nhật các cặp khóa - giá trị (Key-Value) trên Firebase Console để thay đổi hành vi và giao diện ứng dụng phía Client.",
        "Zero Re-deploy: Không cần người dùng phải cập nhật phiên bản mới từ Google Play Store.",
        "In-App Defaults & Fallback: Luôn có bộ giá trị mặc định được nhúng sẵn trong code; nếu mất mạng ứng dụng vẫn hoạt động bình thường với giá trị mặc định.",
        "Client Caching Policy: Kiểm soát tần suất tải tham số mới (Fetch Interval) để tối ưu pin và dữ liệu mạng."
    ]
    for pt in pts:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s26, 6.8, 2.0, 5.7, 4.8)
    tb2 = s26.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "WHY · TẠI SAO WHY I BUY CẦN REMOTE CONFIG?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(2, 132, 199)

    pts_why = [
        "Điều chỉnh số ngày hạ nhiệt mua sắm (cooling_off_days): Thử nghiệm xem khoảng thời gian đắn đo 3 ngày hay 5 ngày giúp người dùng kiềm chế mua sắm bốc đồng tốt hơn.",
        "Bật / tắt tính năng khẩn cấp (Feature Flags): Nếu dịch vụ AI gặp sự cố hoặc vượt ngân sách, admin có thể tắt enable_ai_insight ngay từ console.",
        "Cập nhật lịch khuyến mãi (sale_calendar): Bổ sung ngày hội sale mới (11.11, Black Friday, Lương về) dưới dạng JSON mà không cần phát hành app mới.",
        "Thay đổi Model Gemini động (ai_insight_model): Dễ dàng chuyển đổi giữa gemini-3.5-flash-lite và gemini-3.5-flash trực tiếp trên Console."
    ]
    for pt in pts_why:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 27: Remote Config - How & Cơ chế đăng ký
    s27 = prs.slides.add_slide(blank_layout)
    add_bg(s27)
    add_header(s27, "CÔNG NGHỆ 07 · FIREBASE REMOTE CONFIG (2/4)", "Cách Hoạt Động (How) & Cơ Chế Đăng Ký / Cấu Hình", "Thiết lập in-app defaults, cơ chế lưu đệm Cache và chu kỳ Fetch & Activate", tag_color=RGBColor(2, 132, 199))

    steps_rc = [
        ("BƯỚC 1: KHAI BÁO IN-APP DEFAULTS", [
            "Định nghĩa Map giá trị mặc định chuẩn xác trong RemoteConfigService.defaults:",
            "cooling_off_days: 3 (ngày suy ngẫm).",
            "enable_ai_insight: true  ·  max_wishlist_items_shown: 20.",
            "sale_reminder_enabled: true.",
            "ai_insight_model: 'gemini-3.5-flash-lite'.",
            "ai_photo_search_model: 'gemini-3.5-flash'.",
            "Đồng bộ chuẩn xác với file firebase/remote-config-defaults.json."
        ]),
        ("BƯỚC 2: CƠ CHẾ FETCH & CACHE", [
            "Cấu hình RemoteConfigSettings:",
            "Chế độ Debug: minimumFetchInterval = Duration.zero (tải ngay lập tức để kiểm thử).",
            "Chế độ Release: minimumFetchInterval = Duration(hours: 1) (tiết kiệm pin & quota).",
            "Gọi fetchAndActivate() khi ứng dụng khởi chạy.",
            "Fallback an toàn: Nếu fetch lỗi hoặc timeout, SDK tự động dùng giá trị mặc định."
        ]),
        ("BƯỚC 3: PHẢN ỨNG THAY ĐỔI TRÊN UI", [
            "Các ViewModel đọc tham số qua hàm getInt(), getBool(), getString().",
            "Lắng nghe luồng onConfigUpdated để kích hoạt thông báo giao diện vẽ lại ngay khi có thay đổi mới từ Console."
        ])
    ]

    for idx, (title, pts) in enumerate(steps_rc):
        left = 0.8 + idx * 3.95
        add_card(s27, left, 2.0, 3.75, 4.8)
        tb = s27.shapes.add_textbox(Inches(left + 0.15), Inches(2.15), Inches(3.45), Inches(4.5))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = Pt(13)
        p.font.bold = True
        p.font.color.rgb = RGBColor(2, 132, 199)

        for pt in pts:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.size = Pt(11)
            p.font.color.rgb = C_TEXT_MAIN

    # Slide 28: Remote Config - Chỗ nào dùng code đó
    s28 = prs.slides.add_slide(blank_layout)
    add_bg(s28)
    add_header(s28, "CÔNG NGHỆ 07 · FIREBASE REMOTE CONFIG (3/4)", "Chỗ Nào Dùng Code Đó (Code Implementation)", "Mã nguồn cấu hình và trích xuất tham số động trong RemoteConfigService", tag_color=RGBColor(2, 132, 199))

    c_code = add_card(s28, 0.8, 2.0, 7.5, 4.8, bg_color=C_CODE_BG, border_color=RGBColor(39, 39, 42))
    tb_c = s28.shapes.add_textbox(Inches(1.0), Inches(2.15), Inches(7.1), Inches(4.5))
    tf_c = tb_c.text_frame
    tf_c.word_wrap = True
    p = tf_c.paragraphs[0]
    p.text = "// lib/services/remote_config_service.dart (dòng 20-80)\n"
    p.font.name = "Consolas"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = RGBColor(148, 163, 184)

    code_snippet_rc = """class RemoteConfigService {
  static const String keyCoolingOffDays = 'cooling_off_days';
  static const String keyEnableAiInsight = 'enable_ai_insight';
  static const String keyAiInsightModel = 'ai_insight_model';

  static const Map<String, Object> defaults = {
    keyCoolingOffDays: 3,
    keyEnableAiInsight: true,
    keyAiInsightModel: 'gemini-3.5-flash-lite',
  };

  Future<void> initialize() async {
    await _remoteConfig.setDefaults(defaults);
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 15),
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    await _remoteConfig.fetchAndActivate();
  }

  int get coolingOffDays => _remoteConfig.getInt(keyCoolingOffDays);
  bool get isAiInsightEnabled => _remoteConfig.getBool(keyEnableAiInsight);
}"""
    p2 = tf_c.add_paragraph()
    p2.text = code_snippet_rc
    p2.font.name = "Consolas"
    p2.font.size = Pt(10)
    p2.font.color.rgb = C_CODE_TEXT

    c_exp = add_card(s28, 8.6, 2.0, 3.9, 4.8)
    tb_exp = s28.shapes.add_textbox(Inches(8.8), Inches(2.2), Inches(3.5), Inches(4.4))
    tf_exp = tb_exp.text_frame
    tf_exp.word_wrap = True
    p = tf_exp.paragraphs[0]
    p.text = "GIẢI THÍCH CHI TIẾT CODE"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = RGBColor(2, 132, 199)

    exps_rc = [
        "Vị trí: lib/services/remote_config_service.dart (dòng 20-80).",
        "setDefaults(): Đảm bảo ứng dụng có giá trị dùng ngay khi vừa cài đặt mà chưa cần chờ phản hồi mạng đầu tiên.",
        "kDebugMode switch: Giúp quá trình thuyết trình demo có thể thay đổi số trên Console và nhấn fetch lại ngay lập tức.",
        "Cung cấp Getter rõ nghĩa: Giao diện chỉ gọi config.coolingOffDays, không cần nhớ tên chuỗi key thô."
    ]
    for e in exps_rc:
        p = tf_exp.add_paragraph()
        p.text = "• " + e
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 29: Remote Config - Màn hình & Kiểm chứng
    s29 = prs.slides.add_slide(blank_layout)
    add_bg(s29)
    add_header(s29, "CÔNG NGHỆ 07 · FIREBASE REMOTE CONFIG (4/4)", "Dùng Ở Màn Hình Nào & Cơ Chế Kiểm Chứng (Verification)", "Màn hình quan sát được thay đổi và bằng chứng Before / After mà không cần rebuild", tag_color=RGBColor(2, 132, 199))

    c_screen = add_card(s29, 0.8, 2.0, 5.7, 4.8)
    tb_s = s29.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_s = tb_s.text_frame
    tf_s.word_wrap = True
    p = tf_s.paragraphs[0]
    p.text = "DÙNG Ở MÀN HÌNH NÀO?"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(2, 132, 199)

    screens_rc = [
        "WishlistScreen (Danh sách món chờ mua): Số ngày hiển thị trên huy hiệu 'Đang suy ngẫm (3 ngày)' lập tức đổi thành '5 ngày' khi admin chỉnh tham số cooling_off_days.",
        "InsightsScreen & PrePurchaseScreen: Khi tắt enable_ai_insight trên Console, khối gợi ý phân tích tâm lý của AI lập tức ẩn đi, giao diện co gọn gàng không báo lỗi.",
        "SaleScreens: Cập nhật danh sách các ngày hội khuyến mãi trong năm mà không phải gửi bản cập nhật lên Play Store.",
        "HomeScreen: Giới hạn số lượng món đồ tối đa hiển thị trên widget tóm tắt ngoài trang chủ (max_wishlist_items_shown)."
    ]
    for sc in screens_rc:
        p = tf_s.add_paragraph()
        p.text = "• " + sc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c_verify = add_card(s29, 6.8, 2.0, 5.7, 4.8)
    tb_v = s29.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf_v = tb_v.text_frame
    tf_v.word_wrap = True
    p = tf_v.paragraphs[0]
    p.text = "CƠ CHẾ KIỂM CHỨNG BEFORE / AFTER"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(2, 132, 199)

    verifies_rc = [
        "Kiểm chứng Before / After tại chỗ (TC-08):\n  • Ban đầu: cooling_off_days = 3 → UI hiển thị đếm ngược 3 ngày.\n  • Thao tác: Vào Firebase Console đổi cooling_off_days = 5 → bấm 'Publish changes'.\n  • Kết quả: Bấm [Cập nhật Remote Config (Live Fetch)] tại màn hình Cá nhân → UI đổi sang đếm ngược 5 ngày mà KHÔNG cần build lại app.",
        "Kiểm chứng Feature Toggle: Đổi enable_ai_insight thành false → Card AI biến mất trên màn hình.",
        "Kiểm chứng mất kết nối mạng: Bật chế độ máy bay → Mở app → Ứng dụng tải mượt mà với bộ giá trị mặc định in-app defaults."
    ]
    for vc in verifies_rc:
        p = tf_v.add_paragraph()
        p.text = "• " + vc
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # ==================== PHẦN 4: ĐẢM BẢO CHẤT LƯỢNG & KẾT LUẬN (3 SLIDES) ====================
    # Slide 30: QA - ARTEMIS E2E Testing
    s30 = prs.slides.add_slide(blank_layout)
    add_bg(s30)
    add_header(s30, "ĐẢM BẢO CHẤT LƯỢNG · ARTEMIS E2E TESTING (1/2)", "Kiểm Thử Tự Động Đầu Cuối (E2E) Trên Thiết Bị Thực Tế", "Kế hoạch kiểm thử 10 ca chuẩn hóa + 9 ca tài khoản liên kết (docs/test-plan.md)", tag_color=RGBColor(71, 85, 105))

    c1 = add_card(s30, 0.8, 2.0, 5.7, 4.8)
    tb1 = s30.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "CHIẾN LƯỢC KIỂM THỬ ARTEMIS"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(71, 85, 105)

    pts_art = [
        "Công cụ kiểm thử: Google ARTEMIS (Android Agent) kết hợp Pytest chạy trực tiếp trên thiết bị Android qua giao thức ADB.",
        "Quy mô kịch bản: 10 ca kiểm thử chuẩn (TC-01 đến TC-10) và 9 ca kiểm thử tài khoản liên kết (ACC-01 đến ACC-09).",
        "Tiêu chuẩn 3 lượt chạy: Mỗi ca kiểm thử được thực thi độc lập ít nhất 3 lần liên tiếp (3/3 planned) để đảm bảo không có flaky test.",
        "Bao phủ toàn diện luồng nghiệp vụ:\n  • Auth: Đăng nhập Google, Facebook, chuyển đổi tài khoản Guest.\n  • Wishlist: Thêm món, đếm ngược hạ nhiệt, lọc tìm kiếm.\n  • Nhánh lỗi (Error Paths): Bỏ trống tên món, tìm kiếm rỗng.\n  • Native: Quyền thông báo Android 13+, bảng chia sẻ PDF."
    ]
    for pt in pts_art:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s30, 6.8, 2.0, 5.7, 4.8)
    tb2 = s30.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "KẾT QUẢ THỰC THI & PHIÊN KHÁM PHÁ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(71, 85, 105)

    pts_art_res = [
        "Tỷ lệ thành công (Pass Rate): Đạt 100% trên toàn bộ các ca kiểm thử hồi quy luồng mua sắm cốt lõi.",
        "Xác minh UI trực quan: ARTEMIS kiểm tra các phần tử hiển thị thực tế (Text, Button state, SnackBar), không chỉ dựa vào HTTP 200.",
        "Phiên kiểm thử khám phá (Exploratory Testing 20 phút):\n  • Tự do nhấn các nút điều hướng nhanh liên tục để kiểm tra rò rỉ bộ nhớ (Memory leaks).\n  • Chuyển đổi qua lại giữa Dark Mode (#070E20) và Light Mode (#F5F6FA) khi đang mở dialog thêm món đồ.\n  • Kết quả: Ứng dụng duy trì 60 FPS ổn định, không có hiện tượng văng ứng dụng."
    ]
    for pt in pts_art_res:
        p = tf2.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 31: AI Code Review
    s31 = prs.slides.add_slide(blank_layout)
    add_bg(s31)
    add_header(s31, "RÀ SOÁT KỸ THUẬT · AI CODE REVIEW (2/2)", "Quyết Định Kỹ Thuật Dựa Trên Bằng Chứng & Truy Vết Git", "Hồ sơ rà soát mã nguồn thực tế ghi nhận tại docs/code-review.md", tag_color=RGBColor(71, 85, 105))

    c1 = add_card(s31, 0.8, 2.0, 5.7, 4.8)
    tb1 = s31.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "QUY TRÌNH RÀ SOÁT MÃ NGUỒN"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(71, 85, 105)

    pts_cr = [
        "Công cụ AI rà soát: Claude Code (/code-review), CodeRabbit, Copilot Review và Codex.",
        "Phân loại nhóm phát hiện: Phân tách rõ ràng giữa Bug, Architecture, Security, Performance và Maintainability.",
        "Quyết định dựa trên bằng chứng: Nhóm đánh giá từng khuyến nghị, nêu rõ lý do Chấp nhận (Accepted), Điều chỉnh (Modified) hoặc Bác bỏ (Rejected).",
        "Truy vết Git Commit: Mỗi phát hiện được xử lý đều có mã commit tương ứng trong lịch sử Git của repository."
    ]
    for pt in pts_cr:
        p = tf1.add_paragraph()
        p.text = "• " + pt
        p.font.size = Pt(11.5)
        p.font.color.rgb = C_TEXT_MAIN

    c2 = add_card(s31, 6.8, 2.0, 5.7, 4.8)
    tb2 = s31.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "CÁC PHÁT HIỆN TIÊU BIỂU TRONG DOCS"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(71, 85, 105)

    findings = [
        "CR-01 (Architecture) [ACCEPTED]: Widget gọi trực tiếp Firestore → Chuyển sang WishlistService và WishlistViewModel (Commit 9185cc7).",
        "CR-02 (Maintainability) [MODIFIED]: ReportService vừa dựng PDF vừa gửi file → Tách riêng ReportShareService (Commit 72a94db).",
        "CR-03 (Security) [ACCEPTED]: userId truyền thủ công từ client → Bỏ khỏi model; xác thực và phân quyền bằng Firebase Token (Commit 7e16045).",
        "CR-04 (Performance) [ACCEPTED]: Tải lại toàn bộ danh sách khi 1 thuộc tính nhỏ thay đổi → Chuyển sang snapshots stream watchItems.",
        "CR-05 (Accessibility) [ACCEPTED]: Nút chọn động cơ touch targets < 48dp → Chuẩn hóa tối thiểu 48dp (Commit 6a33e12)."
    ]
    for f in findings:
        p = tf2.add_paragraph()
        p.text = "• " + f
        p.font.size = Pt(11)
        p.font.color.rgb = C_TEXT_MAIN

    # Slide 32: Kết luận & Bài học kinh nghiệm
    s32 = prs.slides.add_slide(blank_layout)
    add_bg(s32, dark=True)

    tag = s32.shapes.add_textbox(Inches(1.0), Inches(0.6), Inches(11.0), Inches(0.4))
    p = tag.text_frame.paragraphs[0]
    p.text = "TỔNG KẾT LAB 03  ·  WHY I BUY (NHÓM 07)"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = C_BRAND_YELLOW

    title_box = s32.shapes.add_textbox(Inches(1.0), Inches(1.1), Inches(11.0), Inches(0.8))
    tf = title_box.text_frame
    p = tf.paragraphs[0]
    p.text = "Bài Học Kỹ Thuật & Sẵn Sàng Vận Hành Thực Tế"
    p.font.size = Pt(26)
    p.font.bold = True
    p.font.color.rgb = RGBColor(255, 255, 255)

    c1 = add_card(s32, 1.0, 2.0, 5.5, 4.8, bg_color=C_BRAND_CARD, border_color=RGBColor(45, 55, 72))
    tb1 = s32.shapes.add_textbox(Inches(1.2), Inches(2.2), Inches(5.1), Inches(4.4))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    p = tf1.paragraphs[0]
    p.text = "BÀI HỌC KINH NGHIỆM ĐẮT GIÁ"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = C_BRAND_YELLOW

    lessons = [
        "1. Kiến trúc MVVM phân lớp: Việc cách ly hoàn toàn Firebase SDK trong thư mục lib/services giúp việc bảo trì, viết Unit Test giả lập và chuyển đổi nền tảng cực kỳ dễ dàng.",
        "2. Tận dụng Cloudinary bên cạnh Firebase: Giúp tiết kiệm chi phí băng thông, xử lý nén ảnh tự động và giải quyết bài toán gói Spark (Quyết định D7).",
        "3. Bảo mật đa tầng: Kết hợp xác thực Firebase Auth, Firestore Security Rules và nguyên tắc No-PII trong Analytics tạo nên hệ thống an toàn chuẩn công nghiệp.",
        "4. Tự động hóa kiểm thử: Kiểm thử E2E với ARTEMIS giúp phát hiện các lỗi bất đồng bộ mà kiểm thử thủ công dễ bỏ sót."
    ]
    for l in lessons:
        p = tf1.add_paragraph()
        p.text = l + "\n"
        p.font.size = Pt(11.5)
        p.font.color.rgb = RGBColor(226, 232, 240)

    c2 = add_card(s32, 6.8, 2.0, 5.5, 4.8, bg_color=C_BRAND_CARD, border_color=RGBColor(45, 55, 72))
    tb2 = s32.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.1), Inches(4.4))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    p = tf2.paragraphs[0]
    p.text = "THÔNG TIN MÃ NGUỒN & HỒ SƠ DỰ ÁN"
    p.font.size = Pt(15)
    p.font.bold = True
    p.font.color.rgb = RGBColor(56, 189, 248)

    info_pts = [
        "Kho mã nguồn GitHub chính thức:\nhttps://github.com/hoanghuan2005/prm393_lab03",
        "Bộ tài liệu kỹ thuật đi kèm tại docs/:\n• docs/architecture.md · Bản đồ kiến trúc hệ thống\n• docs/analytics-plan.md · Kế hoạch theo dõi sự kiện No-PII\n• docs/decisions.md · Bảng quyết định kỹ thuật (D1-D14)\n• docs/code-review.md · Biên bản đánh giá mã nguồn bằng AI\n• docs/test-plan.md · Kịch bản E2E Test 10+ ca với ARTEMIS",
        "Bộ cấu hình Firebase & Rules:\n• firebase/firestore.rules · Quy tắc bảo mật Firestore\n• firebase/storage.rules · Quy tắc bảo mật Storage\n• firebase/remote-config-defaults.json · Tham số mặc định",
        "Lời cảm ơn: Nhóm 07 xin chân thành cảm ơn Thầy đã tận tình hướng dẫn và định hướng chuyên môn cho dự án!"
    ]
    for ip in info_pts:
        p = tf2.add_paragraph()
        p.text = ip + "\n"
        p.font.size = Pt(11)
        p.font.color.rgb = RGBColor(226, 232, 240)

    output_path = r"d:\Ky_8_FA26\PRM393\PRM393_LAB3\WhyIBuy_Lab03_Presentation.pptx"
    prs.save(output_path)
    print(f"Presentation saved successfully to {output_path} with {len(prs.slides)} slides!")

if __name__ == "__main__":
    create_deck()

import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def build_slide4_variations():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # =========================================================================
    # VERSION 1: CHUẨN MẪU GUIDELINE CHÍNH THỨC (IMAGE 2)
    # =========================================================================
    s1 = prs.slides.add_slide(blank_layout)

    C_BG = RGBColor(248, 250, 252)       # Slate 50
    C_TEXT_MAIN = RGBColor(15, 23, 42)   # Slate 900
    C_TEXT_MUTED = RGBColor(100, 116, 139) # Slate 500
    C_CARD_BG = RGBColor(255, 255, 255)
    C_BORDER = RGBColor(226, 232, 240)

    C_RED_BG = RGBColor(254, 242, 242)   # Red 50
    C_RED_TXT = RGBColor(185, 28, 28)    # Red 700
    C_BLUE_BG = RGBColor(239, 246, 255)  # Blue 50
    C_BLUE_TXT = RGBColor(29, 78, 216)   # Blue 700
    C_GREEN_BG = RGBColor(240, 253, 244) # Green 50
    C_GREEN_TXT = RGBColor(21, 128, 61)  # Green 700

    def add_card(slide, left, top, width, height, bg_color=C_CARD_BG, border_color=C_BORDER):
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
        card.fill.solid()
        card.fill.fore_color.rgb = bg_color
        card.line.color.rgb = border_color
        card.line.width = Pt(1)
        return card

    # Background
    bg1 = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
    bg1.fill.solid()
    bg1.fill.fore_color.rgb = C_BG
    bg1.line.color.rgb = C_BG

    # Top Pill
    add_card(s1, 0.8, 0.35, 3.2, 0.32, bg_color=RGBColor(219, 234, 254), border_color=RGBColor(191, 219, 254))
    tb_pill = s1.shapes.add_textbox(Inches(0.8), Inches(0.36), Inches(3.2), Inches(0.3))
    p = tb_pill.text_frame.paragraphs[0]
    p.text = "P1 · PROBLEM   |   04 / PROPOSED SOLUTION"
    p.alignment = PP_ALIGN.CENTER
    p.font.size = Pt(9.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(30, 64, 175)

    # Title & Subtitle
    tb_title = s1.shapes.add_textbox(Inches(0.8), Inches(0.72), Inches(11.733), Inches(0.6))
    tf_t = tb_title.text_frame
    tf_t.word_wrap = True
    tf_t.margin_left = tf_t.margin_top = tf_t.margin_right = tf_t.margin_bottom = 0
    p = tf_t.paragraphs[0]
    p.text = "Slide 4 Proposed Solution — giải quyết trực tiếp vấn đề"
    p.font.size = Pt(21)
    p.font.bold = True
    p.font.color.rgb = C_TEXT_MAIN

    p_sub = tf_t.add_paragraph()
    p_sub.text = "Thể hiện quan hệ Pain point → Solution → Expected Value, và phân định phạm vi MVP."
    p_sub.font.size = Pt(12)
    p_sub.font.color.rgb = C_TEXT_MUTED

    # Metadata Strip (3 boxes)
    add_card(s1, 0.8, 1.45, 5.7, 0.65, bg_color=C_CARD_BG, border_color=C_BORDER)
    tb_m1 = s1.shapes.add_textbox(Inches(0.95), Inches(1.5), Inches(5.4), Inches(0.55))
    tf_m1 = tb_m1.text_frame
    tf_m1.word_wrap = True
    p = tf_m1.paragraphs[0]
    p.text = "CÂU HỎI HỘI ĐỒNG"
    p.font.size = Pt(8.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(37, 99, 235)
    p2 = tf_m1.add_paragraph()
    p2.text = "Giải pháp có trúng vấn đề không, phạm vi làm tới đâu?"
    p2.font.size = Pt(10.5)
    p2.font.color.rgb = C_TEXT_MAIN

    add_card(s1, 6.65, 1.45, 1.8, 0.65, bg_color=C_CARD_BG, border_color=C_BORDER)
    tb_m2 = s1.shapes.add_textbox(Inches(6.8), Inches(1.5), Inches(1.5), Inches(0.55))
    tf_m2 = tb_m2.text_frame
    p = tf_m2.paragraphs[0]
    p.text = "THỜI LƯỢNG"
    p.font.size = Pt(8.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(37, 99, 235)
    p2 = tf_m2.add_paragraph()
    p2.text = "40 s"
    p2.font.size = Pt(13)
    p2.font.bold = True
    p2.font.color.rgb = C_TEXT_MAIN

    add_card(s1, 8.6, 1.45, 3.933, 0.65, bg_color=C_CARD_BG, border_color=C_BORDER)
    tb_m3 = s1.shapes.add_textbox(Inches(8.75), Inches(1.5), Inches(3.65), Inches(0.55))
    tf_m3 = tb_m3.text_frame
    tf_m3.word_wrap = True
    p = tf_m3.paragraphs[0]
    p.text = "MINH CHỨNG BẮT BUỘC"
    p.font.size = Pt(8.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(37, 99, 235)
    p2 = tf_m3.add_paragraph()
    p2.text = "Bảng ánh xạ pain point ↔ solution"
    p2.font.size = Pt(10.5)
    p2.font.color.rgb = C_TEXT_MAIN

    # Main Mapping Table (3 Columns)
    col_w = [3.6, 4.4, 3.6]
    col_x = [0.8, 4.5, 9.0]
    row_y = [2.25, 2.7, 3.45, 4.2]
    row_h = [0.4, 0.7, 0.7, 0.7]

    headers = [
        ("PAIN POINT (ĐIỂM NGHẼN)", C_RED_BG, C_RED_TXT),
        ("SOLUTION TRONG APP (GIẢI PHÁP)", C_BLUE_BG, C_BLUE_TXT),
        ("EXPECTED VALUE (GIÁ TRỊ KỲ VỌNG)", C_GREEN_BG, C_GREEN_TXT)
    ]
    for i, (htext, hbg, hcolor) in enumerate(headers):
        add_card(s1, col_x[i], row_y[0], col_w[i], row_h[0], bg_color=hbg, border_color=hbg)
        tb_h = s1.shapes.add_textbox(Inches(col_x[i]), Inches(row_y[0] + 0.05), Inches(col_w[i]), Inches(0.3))
        p = tb_h.text_frame.paragraphs[0]
        p.text = htext
        p.alignment = PP_ALIGN.CENTER
        p.font.size = Pt(10)
        p.font.bold = True
        p.font.color.rgb = hcolor

    data_rows = [
        (
            "[Chậm xử lý & Mua cảm xúc]\nLướt Shopee/Lazada ban đêm, bị cuốn vào sale dồn dập, bấm mua bốc đồng trong vài giây.",
            "[Wishlist có ngữ cảnh & Hoãn mua]\nDanh sách cân nhắc + thời gian hoãn mặc định 3 ngày (Cooling-off); bong bóng nhắc khi xem > 15s.",
            "[Khoảng dừng tâm lý]\nCó khoảng dừng trước khi chi tiền, hạ nhiệt cảm xúc; giảm đáng kể mua sắm bốc đồng."
        ),
        (
            "[Khó truy vết & Không rõ lý do]\nMua theo xu hướng/sale rồi quên lý do; hối hận vì mua món không thực sự cần thiết.",
            "[Gắn 8 động cơ & Cố vấn tỉnh táo]\nGắn 8 động cơ mua (Nhu cầu, Cảm xúc, MXH...); Thẻ quan sát AI & Chiêm nghiệm cuối tháng.",
            "[Minh bạch hành vi chi tiêu]\nThấy rõ mình mua vì đâu và lúc nào; AI khách quan diễn đạt chứ không phán xét."
        ),
        (
            "[Dữ liệu rời rạc & Trôi giá]\nMón muốn mua nằm rải rác ở giỏ hàng sàn, tin nhắn, ảnh chụp màn hình; quên theo dõi giá.",
            "[Lưu 1-chạm & Đồng bộ đa thiết bị]\nAndroid Share Sheet nhận link Shopee + Bong bóng lưu link + Tiện ích Chrome quét QR đồng bộ.",
            "[Tập trung một nơi duy nhất]\nQuản lý tập trung tại một nơi duy nhất; minh bạch lịch sử biến động giá thực tế."
        )
    ]

    for r_idx, row in enumerate(data_rows):
        y = row_y[r_idx + 1]
        h = row_h[r_idx + 1]
        for c_idx, cell_text in enumerate(row):
            add_card(s1, col_x[c_idx], y, col_w[c_idx], h, bg_color=C_CARD_BG, border_color=C_BORDER)
            tb = s1.shapes.add_textbox(Inches(col_x[c_idx] + 0.1), Inches(y + 0.05), Inches(col_w[c_idx] - 0.2), Inches(h - 0.1))
            tf = tb.text_frame
            tf.word_wrap = True
            tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
            lines = cell_text.split('\n')
            p = tf.paragraphs[0]
            p.text = lines[0]
            p.font.size = Pt(10)
            p.font.bold = True
            p.font.color.rgb = C_RED_TXT if c_idx == 0 else (C_BLUE_TXT if c_idx == 1 else C_GREEN_TXT)
            if len(lines) > 1:
                p2 = tf.add_paragraph()
                p2.text = lines[1]
                p2.font.size = Pt(9.5)
                p2.font.color.rgb = C_TEXT_MAIN

    # Scope Bottom
    scope_y = 5.05
    scope_h = 2.05

    add_card(s1, 0.8, scope_y, 5.75, scope_h, bg_color=RGBColor(240, 253, 244), border_color=RGBColor(187, 247, 208))
    tb_in = s1.shapes.add_textbox(Inches(0.95), Inches(scope_y + 0.1), Inches(5.45), Inches(scope_h - 0.2))
    tf_in = tb_in.text_frame
    tf_in.word_wrap = True
    tf_in.margin_left = tf_in.margin_top = tf_in.margin_right = tf_in.margin_bottom = 0
    p = tf_in.paragraphs[0]
    p.text = "IN-SCOPE (MVP) · CÁC WORKFLOW LÕI SẼ DEMO"
    p.font.size = Pt(10.5)
    p.font.bold = True
    p.font.color.rgb = C_GREEN_TXT

    in_items = [
        "WF-01 · Lưu món & hoãn mua: Chia sẻ link Shopee qua Android Share Sheet · Bong bóng nổi sao chép · Tiện ích Chrome ghép QR · Danh sách đắn đo 3 ngày.",
        "WF-02 · Quyết định & ghi chi: Trực giác trước khi mua (Thẻ quan sát AI) · Chọn Mua / Chờ (Lịch sale) / Bỏ qua · Ghi nhận chi tiêu thực tế 2 bước.",
        "WF-03 · Nhìn lại cuối tháng: Chiêm nghiệm chi tiêu theo động cơ · Đối chiếu ngân sách · Xuất và chia sẻ báo cáo PDF.",
        "Kèm Web Admin: Bảng điều khiển quản trị cho Staff/Admin quản lý sự kiện sale & thông báo."
    ]
    for item in in_items:
        p = tf_in.add_paragraph()
        p.text = "• " + item
        p.font.size = Pt(9)
        p.font.color.rgb = C_TEXT_MAIN

    add_card(s1, 6.783, scope_y, 5.75, scope_h, bg_color=RGBColor(254, 242, 242), border_color=RGBColor(254, 202, 202))
    tb_out = s1.shapes.add_textbox(Inches(6.933), Inches(scope_y + 0.1), Inches(5.45), Inches(scope_h - 0.2))
    tf_out = tb_out.text_frame
    tf_out.word_wrap = True
    tf_out.margin_left = tf_out.margin_top = tf_out.margin_right = tf_out.margin_bottom = 0
    p = tf_out.paragraphs[0]
    p.text = "OUT-OF-SCOPE · ĐỂ GIAI ĐOẠN SAU (KÈM LÝ DO KỸ THUẬT)"
    p.font.size = Pt(10.5)
    p.font.bold = True
    p.font.color.rgb = C_RED_TXT

    out_items = [
        "Đọc giá từ ảnh chụp màn hình (OCR): Độ chính xác phụ thuộc độ phân giải và font sàn; nhóm ưu tiên Android Share Sheet chuẩn xác 100%.",
        "Lấy voucher & cào giá tự động từ sàn: Sàn Shopee chặn bot (anti-scraping, Cloudflare); đồng thời app không làm nhiệm vụ săn coupon kích cầu mua thêm.",
        "Thanh toán trực tiếp trong app: Ứng dụng là 'cố vấn tỉnh táo' độc lập, không đóng vai trò cổng thanh toán hay trung gian bán hàng.",
        "Phiên bản iOS: Tập trung hoàn thiện chuyên sâu 100% Android Native trong phạm vi đồ án."
    ]
    for item in out_items:
        p = tf_out.add_paragraph()
        p.text = "• " + item
        p.font.size = Pt(9)
        p.font.color.rgb = C_TEXT_MAIN

    tb_foot = s1.shapes.add_textbox(Inches(0.8), Inches(7.15), Inches(11.733), Inches(0.25))
    p = tb_foot.text_frame.paragraphs[0]
    p.text = "Tránh: Gọi 'AI', 'Cloud' là giá trị khi chưa chỉ ra lợi ích thực tế. AI trong Why I Buy chỉ hỗ trợ diễn đạt trung lập, không phán xét và không quyết định thay người dùng."
    p.font.size = Pt(8.5)
    p.font.italic = True
    p.font.color.rgb = RGBColor(180, 83, 9)

    # =========================================================================
    # VERSION 2: STYLE NHẬN DIỆN THƯƠNG HIỆU WHY I BUY VỚI CHECKMARK (IMAGE 1 + IMAGE 2)
    # =========================================================================
    s2 = prs.slides.add_slide(blank_layout)

    C_YELLOW_BRAND = RGBColor(255, 222, 2)    # #FFDE02
    C_DARK_BRAND = RGBColor(7, 14, 32)        # #070E20
    C_AMBER_BORDER = RGBColor(245, 158, 11)   # #F59E0B
    C_CARD_YELLOW = RGBColor(254, 243, 199)   # Amber 100 / Warm yellow

    bg2 = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
    bg2.fill.solid()
    bg2.fill.fore_color.rgb = RGBColor(255, 255, 255)
    bg2.line.color.rgb = RGBColor(255, 255, 255)

    # Yellow top accent banner
    top_bar = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(0.1))
    top_bar.fill.solid()
    top_bar.fill.fore_color.rgb = C_YELLOW_BRAND
    top_bar.line.color.rgb = C_YELLOW_BRAND

    # Pill Header like Image 1 (Bold black rounded border)
    pill_card = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(4.166), Inches(0.35), Inches(5.0), Inches(0.65))
    pill_card.fill.solid()
    pill_card.fill.fore_color.rgb = RGBColor(255, 255, 255)
    pill_card.line.color.rgb = RGBColor(0, 0, 0)
    pill_card.line.width = Pt(2.5)

    tb_p2 = s2.shapes.add_textbox(Inches(4.166), Inches(0.45), Inches(5.0), Inches(0.45))
    p = tb_p2.text_frame.paragraphs[0]
    p.text = "04 · PROPOSED SOLUTION"
    p.alignment = PP_ALIGN.CENTER
    p.font.size = Pt(16)
    p.font.bold = True
    p.font.color.rgb = RGBColor(0, 0, 0)

    # Subtitle
    tb_sub2 = s2.shapes.add_textbox(Inches(1.0), Inches(1.15), Inches(11.333), Inches(0.35))
    p = tb_sub2.text_frame.paragraphs[0]
    p.text = "Mỗi pain point có một câu trả lời trong app · Ánh xạ Pain point → Solution → Expected Value"
    p.alignment = PP_ALIGN.CENTER
    p.font.size = Pt(12)
    p.font.color.rgb = C_TEXT_MUTED

    # 3 Solution Highlight Cards with Big Checkmarks (Combining Image 1 & 2 content)
    cards_data = [
        (
            "P1 → WISHLIST CÓ NGỮ CẢNH & HOÃN MUA",
            "Pain point giải quyết: [Chậm xử lý & Mua theo cảm xúc] do lướt sàn ban đêm & sale.",
            "Tính năng trong app: Lưu tên, động cơ, mức giá, thời gian hoãn 3 ngày (Cooling-off) & bong bóng nhắc nhở.",
            "Giá trị kỳ vọng: Tạo khoảng dừng tâm lý trước khi thanh toán, giảm tối đa Impulse Buying."
        ),
        (
            "P2 → DECISION SUPPORT & CỐ VẤN TỈNH TÁO",
            "Pain point giải quyết: [Khó truy vết & Không rõ lý do] mua xong tiếc nuối và hối hận.",
            "Tính năng trong app: Gắn 8 động cơ mua; Thẻ quan sát AI khách quan; Quyết định Mua · Chờ (Lịch sale) · Bỏ qua.",
            "Giá trị kỳ vọng: Nhìn rõ thói quen chi tiêu; AI diễn đạt trung lập, không phán xét, đúng hạn mức ngân sách."
        ),
        (
            "P3 → REFLECTION, BÁO CÁO & LƯU TẬP TRUNG",
            "Pain point giải quyết: [Dữ liệu rời rạc & Trôi giá] món nằm rải rác giỏ hàng, tin nhắn, ảnh chụp.",
            "Tính năng trong app: Lưu 1-chạm qua Android Share Sheet + Tiện ích Chrome + Chiêm nghiệm & xuất PDF cuối tháng.",
            "Giá trị kỳ vọng: Tập trung toàn bộ món đồ tại một nơi duy nhất; minh bạch lịch sử giá và báo cáo tài chính."
        )
    ]

    for idx, (head, pp, sol, val) in enumerate(cards_data):
        y_pos = 1.65 + idx * 1.55
        
        # Checkmark Icon Square (Orange / Yellow with White Check)
        chk_box = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.9), Inches(y_pos + 0.15), Inches(0.95), Inches(0.95))
        chk_box.fill.solid()
        chk_box.fill.fore_color.rgb = RGBColor(255, 255, 255)
        chk_box.line.color.rgb = RGBColor(234, 88, 12) # Orange 600
        chk_box.line.width = Pt(3)

        # Draw checkmark inside chk_box
        tb_chk = s2.shapes.add_textbox(Inches(0.9), Inches(y_pos + 0.18), Inches(0.95), Inches(0.9))
        p = tb_chk.text_frame.paragraphs[0]
        p.text = "✔"
        p.alignment = PP_ALIGN.CENTER
        p.font.size = Pt(30)
        p.font.bold = True
        p.font.color.rgb = RGBColor(234, 88, 12)

        # Yellow rounded card
        card_main = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(2.05), Inches(y_pos), Inches(10.35), Inches(1.3))
        card_main.fill.solid()
        card_main.fill.fore_color.rgb = RGBColor(254, 215, 0) # Rich bright yellow like Image 1
        card_main.line.color.rgb = RGBColor(245, 158, 11)
        card_main.line.width = Pt(1.5)

        tb_c = s2.shapes.add_textbox(Inches(2.25), Inches(y_pos + 0.08), Inches(9.95), Inches(1.15))
        tf_c = tb_c.text_frame
        tf_c.word_wrap = True
        tf_c.margin_left = tf_c.margin_top = tf_c.margin_right = tf_c.margin_bottom = 0

        p = tf_c.paragraphs[0]
        p.text = head
        p.font.size = Pt(12)
        p.font.bold = True
        p.font.color.rgb = RGBColor(0, 0, 0)

        p1 = tf_c.add_paragraph()
        p1.text = "• " + pp
        p1.font.size = Pt(10)
        p1.font.color.rgb = RGBColor(30, 41, 59)

        p2 = tf_c.add_paragraph()
        p2.text = "• " + sol + " → " + val
        p2.font.size = Pt(10)
        p2.font.color.rgb = RGBColor(15, 23, 42)

    # Bottom Scope Split (In-scope vs Out-of-scope)
    bottom_y = 6.25
    bottom_h = 1.05

    # In-Scope Card
    card_in = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.9), Inches(bottom_y), Inches(5.6), Inches(bottom_h))
    card_in.fill.solid()
    card_in.fill.fore_color.rgb = RGBColor(240, 253, 244)
    card_in.line.color.rgb = RGBColor(134, 239, 172)
    card_in.line.width = Pt(1)

    tb_bin = s2.shapes.add_textbox(Inches(1.05), Inches(bottom_y + 0.05), Inches(5.3), Inches(bottom_h - 0.1))
    tf_bin = tb_bin.text_frame
    tf_bin.word_wrap = True
    p = tf_bin.paragraphs[0]
    p.text = "IN-SCOPE (MVP) · 3 WORKFLOW DEMO"
    p.font.size = Pt(9.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(21, 128, 61)
    p2 = tf_bin.add_paragraph()
    p2.text = "WF-01 Lưu & hoãn mua (Share Sheet, Extension) · WF-02 Quyết định & ghi chi (Hạ nhiệt 3 ngày) · WF-03 Nhìn lại cuối tháng & xuất PDF."
    p2.font.size = Pt(8.5)
    p2.font.color.rgb = C_TEXT_MAIN

    # Out-of-Scope Card
    card_out = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.8), Inches(bottom_y), Inches(5.6), Inches(bottom_h))
    card_out.fill.solid()
    card_out.fill.fore_color.rgb = RGBColor(254, 242, 242)
    card_out.line.color.rgb = RGBColor(254, 202, 202)
    card_out.line.width = Pt(1)

    tb_bout = s2.shapes.add_textbox(Inches(6.95), Inches(bottom_y + 0.05), Inches(5.3), Inches(bottom_h - 0.1))
    tf_bout = tb_bout.text_frame
    tf_bout.word_wrap = True
    p = tf_bout.paragraphs[0]
    p.text = "OUT-OF-SCOPE · ĐỂ GIAI ĐOẠN SAU"
    p.font.size = Pt(9.5)
    p.font.bold = True
    p.font.color.rgb = RGBColor(185, 28, 28)
    p2 = tf_bout.add_paragraph()
    p2.text = "OCR đọc giá (ưu tiên Share Sheet chuẩn 100%) · Tự động cào voucher (sàn chặn bot) · Thanh toán trực tiếp sàn · Phiên bản iOS."
    p2.font.size = Pt(8.5)
    p2.font.color.rgb = C_TEXT_MAIN

    out_file = r"d:\Ky_8_FA26\PRM393\PRM393_LAB3\Slide4_Proposed_Solution_Redesign.pptx"
    prs.save(out_file)
    print(f"File saved successfully to {out_file} with {len(prs.slides)} slides!")

if __name__ == "__main__":
    build_slide4_variations()

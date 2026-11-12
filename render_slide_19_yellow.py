import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#FDFBF7')  # warm light cream
draw = ImageDraw.Draw(img)

# Fonts
font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_desc = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 20)
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 22)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 16)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 16)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 14)
f_code = ImageFont.truetype(os.path.join(font_dir, 'calibri.ttf'), 15)

# Brand Colors (Why I Buy Yellow Theme)
BRAND_YELLOW = '#FFDE02'       # Vàng thương hiệu chủ đạo
BORDER_YELLOW = '#EAB308'      # Viền vàng đậm sắc nét
BG_YELLOW_LIGHT = '#FEFCE8'    # Nền vàng kem nhạt
TXT_DARK = '#070E20'           # Chữ đen than chuẩn brand

# Background Grid
grid_color = '#EDE8DF'
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill=grid_color, width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill=grid_color, width=1)

# Header Badge (Lưu ý chuẩn: WF-01 là slide 18 thì WF-02 là Slide 19)
bx, by = 60, 36
badge_w, badge_h = 420, 52
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=26, fill='#0F172A', outline=BORDER_YELLOW, width=2)
draw.text((bx + 32, by + 8), '19 · DEMO WF-02', font=f_title, fill=BRAND_YELLOW)

# Right title
sub_txt = 'PRM393 · Final Assignment · One Complete System on Firebase'
draw.text((W - 680, by + 16), sub_txt, font=f_sub, fill='#475569')

# Subtitle / Goal
desc_txt = 'Demo WF-02 · Trước Khi Mua, Thẻ Quan Sát AI Gemini Và Phân Nhánh Quyết Định'
draw.text((bx, by + 68), desc_txt, font=f_desc, fill=TXT_DARK)

# ----------------- ROW 1: 5 FLOW BLOCKS (THEME VÀNG CHỦ ĐẠO) -----------------
flow_y = 175
flow_h = 220
bw = 310
gap = 62

blocks = [
    (
        'Trigger', 'Đến hẹn xem lại', 'Mở món "Tai nghe..." • Hết hoãn',
        BRAND_YELLOW, BORDER_YELLOW, TXT_DARK, True
    ),
    (
        'Trước khi mua', 'Tự vấn 3 câu hỏi', 'Lý do muốn mua, tần suất • UI-05',
        BG_YELLOW_LIGHT, BORDER_YELLOW, '#854D0E', False
    ),
    (
        'Thẻ quan sát AI', 'Gemini gợi mở trung lập', 'Không phán xét • Fallback câu mẫu • BR-07',
        BG_YELLOW_LIGHT, BORDER_YELLOW, '#854D0E', False
    ),
    (
        'Rẽ nhánh quyết định', 'Tự chọn 1 trong 3', 'Mua (WF-03) · Chờ (hẹn) · Bỏ qua',
        BG_YELLOW_LIGHT, BORDER_YELLOW, '#854D0E', False
    ),
    (
        'Kết quả', 'GHI NHẬN DECISION', 'Lưu vết decisions • Hoàn tác 5s',
        BRAND_YELLOW, BORDER_YELLOW, TXT_DARK, True
    )
]

for i, (title, sub1, sub2, bg_c, border_c, txt_title_c, is_highlight) in enumerate(blocks):
    cur_x = bx + i * (bw + gap)
    
    if is_highlight:
        # Highlight Blocks (Trigger & Kết quả): Vàng thương hiệu nổi bật
        draw.rounded_rectangle([cur_x, flow_y, cur_x + bw, flow_y + flow_h], radius=14, fill=bg_c, outline=border_c, width=3)
        draw.text((cur_x + 24, flow_y + 35), title, font=f_h1, fill=TXT_DARK)
        draw.text((cur_x + 24, flow_y + 85), sub1, font=f_bold, fill='#78350F')
        draw.text((cur_x + 24, flow_y + 125), sub2, font=f_body, fill='#92400E')
    else:
        # Step Blocks: Nền kem vàng dịu mắt với viền vàng nổi bật
        draw.rounded_rectangle([cur_x, flow_y, cur_x + bw, flow_y + flow_h], radius=14, fill=bg_c, outline=border_c, width=2)
        draw.text((cur_x + 24, flow_y + 35), title, font=f_h1, fill=txt_title_c)
        draw.text((cur_x + 24, flow_y + 85), sub1, font=f_bold, fill=TXT_DARK)
        draw.text((cur_x + 24, flow_y + 125), sub2, font=f_body, fill='#475569')

    # Draw arrow to next block (Mũi tên vàng đậm)
    if i < 4:
        arr_x = cur_x + bw + 12
        arr_y = flow_y + flow_h // 2
        draw.line([(arr_x, arr_y), (arr_x + 36, arr_y)], fill='#D97706', width=4)
        draw.polygon([(arr_x + 36, arr_y), (arr_x + 24, arr_y - 8), (arr_x + 24, arr_y + 8)], fill='#D97706')


# ----------------- ROW 2: FULL-WIDTH BAR 1 (TRẠNG THÁI - TONE VÀNG) -----------------
bar1_y = flow_y + flow_h + 35
bar1_h = 100
draw.rounded_rectangle([bx, bar1_y, bx + 1800, bar1_y + bar1_h], radius=12, fill='#FFFBEB', outline=BORDER_YELLOW, width=2)

draw.rounded_rectangle([bx + 20, bar1_y + 20, bx + 200, bar1_y + 80], radius=8, fill=BRAND_YELLOW, outline=BORDER_YELLOW, width=2)
draw.text((bx + 38, bar1_y + 35), 'TRẠNG THÁI', font=f_h2, fill=TXT_DARK)

draw.text((bx + 225, bar1_y + 24), 'CONSIDERING  →  VẪN MUA (chuyển WF-03)  |  CHỜ (đặt reviewAt)  |  SKIPPED (Bỏ qua)', font=f_h1, fill=TXT_DARK)
draw.text((bx + 225, bar1_y + 58), 'Mọi quyết định đều được lưu vết Append-only vào subcollection users/{uid}/decisions (choice: buy | wait | skip | undo)', font=f_body, fill='#713F12')


# ----------------- ROW 3: FULL-WIDTH BAR 2 (EXCEPTION - VIỀN VÀNG & ACCENT ĐỎ) -----------------
bar2_y = bar1_y + bar1_h + 25
bar2_h = 190
draw.rounded_rectangle([bx, bar2_y, bx + 1800, bar2_y + bar2_h], radius=12, fill='#FFFDF5', outline=BORDER_YELLOW, width=2)

draw.rounded_rectangle([bx + 20, bar2_y + 20, bx + 200, bar2_y + 70], radius=8, fill='#FEE2E2', outline='#EF4444', width=2)
draw.text((bx + 48, bar2_y + 32), 'EXCEPTION', font=f_h2, fill='#991B1B')

exceptions_txt = [
    ('• Bấm nhầm Bỏ qua món đồ:', 'Hiển thị ngay thanh thông báo có nút \"Hoàn tác\" trong vòng 5 giây để khôi phục về CONSIDERING (BR-06).'),
    ('• AI lỗi / vi phạm từ cấm / offline:', 'Tự động hủy kết quả AI và hiển thị Câu mẫu chuẩn của hệ thống, gắn chip [Câu mẫu] (BR-07).'),
    ('• Món đồ chưa cập nhật giá mới:', 'Hệ thống hiển thị nhãn cảnh báo \"Cần giá gần đây\" để người dùng xác nhận lại trước khi ra quyết định.')
]

ey = bar2_y + 26
for tag_e, desc_e in exceptions_txt:
    draw.text((bx + 225, ey), tag_e, font=f_bold, fill='#B91C1C')
    draw.text((bx + 510, ey), desc_e, font=f_body, fill='#78350F')
    ey += 50


# ----------------- ROW 4: FULL-WIDTH BAR 3 (EVIDENCE - VIỀN VÀNG & ACCENT XANH) -----------------
bar3_y = bar2_y + bar2_h + 25
bar3_h = 120
draw.rounded_rectangle([bx, bar3_y, bx + 1800, bar3_y + bar3_h], radius=12, fill='#FFFBEB', outline=BORDER_YELLOW, width=2)

draw.rounded_rectangle([bx + 20, bar3_y + 20, bx + 200, bar3_y + 70], radius=8, fill='#DCFCE7', outline='#22C55E', width=2)
draw.text((bx + 52, bar3_y + 32), 'EVIDENCE', font=f_h2, fill='#166534')

draw.text((bx + 225, bar3_y + 22), 'Bản ghi Decision mới được tạo • Thẻ quan sát AI hiển thị chip [AI] • Nút Hoàn tác 5s chạy thật', font=f_h1, fill='#15803D')
draw.text((bx + 225, bar3_y + 58), '• Khớp kiểm thử tự động TC-03, TC-04, TC-05, TC-08 • Bảo chứng dữ liệu quyết định không bao giờ bị xóa/sửa trái phép.', font=f_body, fill='#713F12')


# Save Image
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_19_demo_wf02_yellow.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_19_demo_wf02_yellow.png')
img.save(art_path, 'PNG')

print('Successfully generated Slide 19 Demo WF-02 Yellow Brand image to:', out_path)

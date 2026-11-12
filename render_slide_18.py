import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
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

# Background Grid
grid_color = '#EDE8DF'
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill=grid_color, width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill=grid_color, width=1)

# Header Badge
bx, by = 60, 36
badge_w, badge_h = 420, 52
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=26, fill='#0F172A')
draw.text((bx + 32, by + 8), '18 · DEMO WF-01', font=f_title, fill='#FFFFFF')

# Right title
sub_txt = 'PRM393 · Final Assignment · One Complete System on Firebase'
draw.text((W - 680, by + 16), sub_txt, font=f_sub, fill='#475569')

# Subtitle / Goal
desc_txt = 'Demo WF-01 · Lưu Món Vào Danh Sách Cân Nhắc Và Kích Hoạt Hoãn 3 Ngày Qua Share Sheet'
draw.text((bx, by + 68), desc_txt, font=f_desc, fill='#1E293B')

# ----------------- ROW 1: 5 FLOW BLOCKS -----------------
# 5 blocks across w = 1800 (from x = 60 to x = 1860)
# w_block = 310, gap = 62 (with arrows inside gaps)
flow_y = 175
flow_h = 220

blocks = [
    (
        'Trigger', 'Thấy món trên Shopee', '(Bấm nút Chia sẻ link)',
        '#1D4ED8', '#EFF6FF', '#1E40AF', True
    ),
    (
        'Bắt link (Share Sheet)', 'Trồi Bottom Sheet < 2s', 'Tự điền tên, link gốc • UI-03',
        '#2563EB', '#F0F9FF', '#0369A1', False
    ),
    (
        'Kiểm tra dữ liệu', 'Bóc tách shopId/itemId', 'Chống trùng • Tự điền giá • BR-05',
        '#2563EB', '#F0F9FF', '#0369A1', False
    ),
    (
        'Xác nhận & Hoãn', 'Chọn 1/8 động cơ', 'Gợi ý đợt sale 11.11 • Hoãn 3d • UI-04',
        '#2563EB', '#F0F9FF', '#0369A1', False
    ),
    (
        'Kết quả', 'CONSIDERING', 'Món xuất hiện trong Wishlist',
        '#1D4ED8', '#EFF6FF', '#1E40AF', True
    )
]

bw = 310
gap = 62

for i, (title, sub1, sub2, clr_main, clr_bg, clr_txt, is_dark) in enumerate(blocks):
    cur_x = bx + i * (bw + gap)
    
    if is_dark:
        # Dark Blue Block
        draw.rounded_rectangle([cur_x, flow_y, cur_x + bw, flow_y + flow_h], radius=14, fill=clr_main, outline='#1E40AF', width=2)
        draw.text((cur_x + 24, flow_y + 35), title, font=f_h1, fill='#FFFFFF')
        draw.text((cur_x + 24, flow_y + 85), sub1, font=f_bold, fill='#93C5FD')
        draw.text((cur_x + 24, flow_y + 125), sub2, font=f_body, fill='#E0F2FE')
    else:
        # Light Blue Block
        draw.rounded_rectangle([cur_x, flow_y, cur_x + bw, flow_y + flow_h], radius=14, fill=clr_bg, outline='#93C5FD', width=2)
        draw.text((cur_x + 24, flow_y + 35), title, font=f_h1, fill=clr_txt)
        draw.text((cur_x + 24, flow_y + 85), sub1, font=f_bold, fill='#0F172A')
        draw.text((cur_x + 24, flow_y + 125), sub2, font=f_body, fill='#475569')

    # Draw arrow to next block
    if i < 4:
        arr_x = cur_x + bw + 12
        arr_y = flow_y + flow_h // 2
        draw.line([(arr_x, arr_y), (arr_x + 36, arr_y)], fill='#2563EB', width=4)
        draw.polygon([(arr_x + 36, arr_y), (arr_x + 24, arr_y - 8), (arr_x + 24, arr_y + 8)], fill='#2563EB')


# ----------------- ROW 2: FULL-WIDTH GREY BAR (TRẠNG THÁI) -----------------
bar1_y = flow_y + flow_h + 35
bar1_h = 100
draw.rounded_rectangle([bx, bar1_y, bx + 1800, bar1_y + bar1_h], radius=12, fill='#F1F5F9', outline='#CBD5E1', width=2)

draw.rounded_rectangle([bx + 20, bar1_y + 20, bx + 200, bar1_y + 80], radius=8, fill='#E2E8F0', outline='#94A3B8', width=1)
draw.text((bx + 38, bar1_y + 35), 'TRẠNG THÁI', font=f_h2, fill='#1E293B')

draw.text((bx + 225, bar1_y + 24), '(Khởi tạo)  →  CONSIDERING (Đang cân nhắc)', font=f_h1, fill='#0F172A')
draw.text((bx + 225, bar1_y + 58), 'cooldownUntil = +3 ngày (áp dụng theo BR-01; trừ động cơ Nhu cầu) • Gợi ý đợt sale gần nhất trong Lịch sale (11.11)', font=f_body, fill='#475569')


# ----------------- ROW 3: FULL-WIDTH PINK BAR (EXCEPTION) -----------------
bar2_y = bar1_y + bar1_h + 25
bar2_h = 190
draw.rounded_rectangle([bx, bar2_y, bx + 1800, bar2_y + bar2_h], radius=12, fill='#FEF2F2', outline='#F87171', width=2)

draw.rounded_rectangle([bx + 20, bar2_y + 20, bx + 200, bar2_y + 70], radius=8, fill='#FEE2E2', outline='#EF4444', width=1)
draw.text((bx + 48, bar2_y + 32), 'EXCEPTION', font=f_h2, fill='#991B1B')

exceptions_txt = [
    ('• Link không lộ giá tiền:', 'Để trống ô giá, hiển thị bàn phím số để nhập nhanh, tuyệt đối không tự điền 0 ₫ (BR-02).'),
    ('• Link sản phẩm đã lưu:', 'Hệ thống báo \"Đã có trong Wishlist\", tự động mở món cũ để người dùng cập nhật giá mới (BR-05).'),
    ('• Mất mạng Internet (Offline):', 'Bộ đệm Firestore lưu an toàn tại máy; thanh trạng thái hiển thị \"Đang chờ mạng\" và tự đồng bộ khi có lại mạng.')
]

ey = bar2_y + 26
for tag_e, desc_e in exceptions_txt:
    draw.text((bx + 225, ey), tag_e, font=f_bold, fill='#B91C1C')
    draw.text((bx + 440, ey), desc_e, font=f_body, fill='#7F1D1D')
    ey += 50


# ----------------- ROW 4: FULL-WIDTH GREEN BAR (EVIDENCE) -----------------
bar3_y = bar2_y + bar2_h + 25
bar3_h = 120
draw.rounded_rectangle([bx, bar3_y, bx + 1800, bar3_y + bar3_h], radius=12, fill='#F0FDF4', outline='#86EFAC', width=2)

draw.rounded_rectangle([bx + 20, bar3_y + 20, bx + 200, bar3_y + 70], radius=8, fill='#DCFCE7', outline='#22C55E', width=1)
draw.text((bx + 52, bar3_y + 32), 'EVIDENCE', font=f_h2, fill='#166534')

draw.text((bx + 225, bar3_y + 22), 'Món \"Tai nghe Sony\" (450.000 ₫) • Trạng thái CONSIDERING (+3 ngày) trên Firestore', font=f_h1, fill='#14532D')
draw.text((bx + 225, bar3_y + 58), '• Document tạo thành công tại: users/{uid}/wishlistItems/{itemId} • Đồng hồ đếm ngược chạy thật trên app • Khớp test suite TC-01, TC-02, TC-09, TC-11.', font=f_body, fill='#15803D')


# Save Image
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_18_demo_wf01.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_18_demo_wf01.png')
img.save(art_path, 'PNG')

print('Successfully generated Slide 18 Demo WF-01 image to:', out_path)

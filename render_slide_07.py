import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
draw = ImageDraw.Draw(img)

# Fonts
font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 23)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 19)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 16)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 16)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 14)
f_small_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 14)

# Subtle background grid
grid_color = '#EDE8DF'
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill=grid_color, width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill=grid_color, width=1)

# Header Badge
badge_w, badge_h = 420, 52
bx, by = 60, 36
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=26, fill='#0F172A')
draw.text((bx + 32, by + 8), '07 · BUSINESS FLOW', font=f_title, fill='#FFFFFF')

# Right title
sub_txt = 'PRM393 · Final Assignment · One Complete System on Firebase'
draw.text((W - 680, by + 16), sub_txt, font=ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 19), fill='#475569')

# Main Table Dimensions
tbl_x = 60
tbl_y = 115
tbl_w = 1800
col_w_lane = 230
col_w_wf = (tbl_w - col_w_lane) // 3  # ~ 523px each

col_x = [
    tbl_x,
    tbl_x + col_w_lane,
    tbl_x + col_w_lane + col_w_wf,
    tbl_x + col_w_lane + 2 * col_w_wf,
    tbl_x + tbl_w
]

# Column Header Bar
hdr_h = 48
wf_headers = [
    ('LÀN (SWIMLANE)', '#1E293B', '#F1F5F9', '#334155'),
    ('WF-01: LƯU MÓN & HẸN SALE', '#1D4ED8', '#EFF6FF', '#1E40AF'),
    ('WF-02: TRƯỚC KHI MUA & QUYẾT ĐỊNH', '#0F766E', '#F0FDFA', '#115E59'),
    ('WF-03: GHI CHI & CHIÊM NGHIỆM', '#C2410C', '#FFF7ED', '#9A3412')
]

for i in range(4):
    x1, x2 = col_x[i], col_x[i+1]
    title, border_c, bg_c, txt_c = wf_headers[i]
    draw.rounded_rectangle([x1 + 4, tbl_y, x2 - 4, tbl_y + hdr_h], radius=8, fill=bg_c, outline=border_c, width=2)
    bbox = draw.textbbox((0, 0), title, font=f_h2)
    tw = bbox[2] - bbox[0]
    draw.text((x1 + 4 + (x2 - x1 - 8 - tw) / 2, tbl_y + 12), title, font=f_h2, fill=txt_c)

# Rows (Swimlanes)
row_h = 222
lanes = [
    ('NGƯỜI DÙNG', '(Mobile App)', '#2563EB', '#EFF6FF'),
    ('HỆ THỐNG', '(App + Firebase + AI)', '#0D9488', '#F0FDFA'),
    ('STAFF / ADMIN', '(Web Admin)', '#EA580C', '#FFF7ED')
]

cards = [
    # WF-01 Row 1
    (1, 0, '① Bắt link & Chọn động cơ', [
        '• Bấm Chia sẻ link từ Shopee (Share Sheet) hoặc lưu từ Web Extension qua mã QR.',
        '• Chọn 1 trong 8 động cơ tiêu dùng (Mặc định: Cảm xúc).',
        '• Bấm [Lưu vào Wishlist] để bắt đầu chu trình cân nhắc.'
    ]),
    # WF-01 Row 2
    (1, 1, 'Xử lý dữ liệu & Hoãn mua', [
        '• Bóc tách link gốc, kiểm tra chống trùng sản phẩm (BR-05).',
        '• Tự điền giá (nếu bị sàn ẩn thì để trống, không tự điền 0 ₫ - BR-02).',
        '• Lưu món: trạng thái considering + mốc hoãn 3 ngày (BR-03).'
    ]),
    # WF-01 Row 3
    (1, 2, 'Quản lý Lịch Sale định kỳ', [
        '• Staff cập nhật lịch Siêu Sale (ngày đôi, 15, 25) trên Web Admin.',
        '• App tự động đồng bộ để gợi ý người dùng hoãn mua đến ngày sale.'
    ]),

    # WF-02 Row 1
    (2, 0, '② Tự vấn & Ra quyết định', [
        '• Mở món khi hết thời gian hoãn hoặc đến hẹn.',
        '• Trả lời nhanh 3 câu hỏi tự vấn ở màn hình Trước khi mua.',
        '• Tự chọn: VẪN MUA · CHỜ · BỎ QUA (không bị ép buộc, không gắn nhãn Nên mua).'
    ]),
    # WF-02 Row 2
    (2, 1, 'Thẻ quan sát AI & Phân nhánh', [
        '• Đối chiếu ngân sách khả dụng và lịch sử chi tiêu.',
        '• AI Gemini sinh Thẻ quan sát trung lập (BR-07: loại bỏ từ phán xét, không bịa số).',
        '• Chờ: đặt reviewAt (BR-03); Bỏ qua: thanh Hoàn tác 5s (BR-06).'
    ]),
    # WF-02 Row 3
    (2, 2, 'Bảo mật quyền riêng tư', [
        '• Staff/Admin tuyệt đối KHÔNG đọc và KHÔNG can thiệp vào các quyết định riêng tư của User (Bảo vệ bởi Security Rules).'
    ]),

    # WF-03 Row 1
    (3, 0, '③ Ghi khoản chi & Đánh giá', [
        '• Khi chọn Vẫn mua → Chuyển sang form ghi chi 2 bước.',
        '• Cuối tháng: Mở tab Góc nhìn & Chiêm nghiệm.',
        '• Chấm mức độ hài lòng 1–5 sao (BR-14) và đặt mục tiêu tháng mới.'
    ]),
    # WF-03 Row 2
    (3, 1, 'Đồng bộ Batch & Báo cáo PDF', [
        '• 1 WriteBatch: Tạo purchases + Đổi món sang PURCHASED (BR-01, BR-02).',
        '• Code tính số liệu, AI viết nhận xét tổng quan tháng.',
        '• Tạo file PDF On-device tại máy (không đưa file lên Cloud Storage - D7).'
    ]),
    # WF-03 Row 3
    (3, 2, 'Dashboard Giám sát tổng quan', [
        '• Admin Web: Xem Dashboard tổng hợp toàn hệ thống qua truy vấn count() và sum(), không xem từng khoản mua cá nhân.'
    ])
]

# Draw Swimlanes and Cards
start_y = tbl_y + hdr_h + 10
for r_idx in range(3):
    ry1 = start_y + r_idx * (row_h + 8)
    ry2 = ry1 + row_h
    
    # Draw Lane Label Card (Col 0)
    lx1, lx2 = col_x[0], col_x[1]
    name, sub, clr, bg = lanes[r_idx]
    draw.rounded_rectangle([lx1 + 4, ry1, lx2 - 4, ry2], radius=10, fill=bg, outline=clr, width=2)
    draw.text((lx1 + 20, ry1 + 78), name, font=f_h1, fill=clr)
    draw.text((lx1 + 20, ry1 + 115), sub, font=f_small_bold, fill='#64748B')

    # Draw WF cards
    for (c_idx, row_i, title, bullets) in cards:
        if row_i == r_idx:
            cx1, cx2 = col_x[c_idx], col_x[c_idx+1]
            if c_idx == 1:
                card_bg = '#FEFCE8'
                card_border = '#FACC15'
            elif c_idx == 2:
                card_bg = '#F0FDFA'
                card_border = '#5EEAD4'
            else:
                card_bg = '#FFF7ED'
                card_border = '#FDBA74'

            draw.rounded_rectangle([cx1 + 4, ry1, cx2 - 4, ry2], radius=10, fill=card_bg, outline=card_border, width=2)
            
            # Card Header Title
            draw.text((cx1 + 18, ry1 + 14), title, font=f_h2, fill='#0F172A')
            draw.line([(cx1 + 18, ry1 + 44), (cx2 - 18, ry1 + 44)], fill=card_border, width=1)
            
            # Bullets
            cur_y = ry1 + 54
            for b in bullets:
                words = b.split(' ')
                line = ''
                for w in words:
                    test_line = line + (' ' if line else '') + w
                    bbox = draw.textbbox((0, 0), test_line, font=f_body)
                    if bbox[2] - bbox[0] > (cx2 - cx1 - 42):
                        draw.text((cx1 + 18, cur_y), line, font=f_body, fill='#334155')
                        cur_y += 24
                        line = '  ' + w
                    else:
                        line = test_line
                if line:
                    draw.text((cx1 + 18, cur_y), line, font=f_body, fill='#334155')
                    cur_y += 26

# Draw Exception Handling Box at Bottom
exp_y1 = start_y + 3 * (row_h + 8) + 6
exp_y2 = exp_y1 + 114
draw.rounded_rectangle([tbl_x + 4, exp_y1, tbl_x + tbl_w - 4, exp_y2], radius=10, fill='#FEF08A', outline='#EAB308', width=2)
draw.text((tbl_x + 22, exp_y1 + 12), 'NGOẠI LỆ ĐƯỢC XỬ LÝ (EXCEPTION HANDLING)', font=f_h2, fill='#854D0E')

exceptions = [
    '• WF-01: Link không lộ giá → Để trống ô giá, tuyệt đối không tự điền 0 ₫ (BR-02) • Link trùng → Báo đã có trong Wishlist (BR-05).',
    '• WF-02: AI lỗi / mất mạng / hết quota → Tự động chuyển Câu mẫu hệ thống (BR-07) • Bấm nhầm Bỏ qua → Thanh Hoàn tác trong 5 giây (BR-06).',
    '• WF-03 & Vận hành: Vượt ngân sách → Thanh trạng thái chuyển xám (không phán xét) • Role User vào Web Admin → Bị chặn tự động.'
]
ey = exp_y1 + 42
for exp in exceptions:
    draw.text((tbl_x + 22, ey), exp, font=f_body, fill='#713F12')
    ey += 22

# Save outputs
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_07_business_flow.png'
img.save(out_path, 'PNG')

# Also save to conversation artifacts directory
art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_07_business_flow.png')
img.save(art_path, 'PNG')

print('Successfully saved image to:', out_path)
print('Artifact saved to:', art_path)

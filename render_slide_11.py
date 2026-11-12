import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
draw = ImageDraw.Draw(img)

font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_desc = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 20)

f_step_tag = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_step_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 20)
f_step_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 15)

f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 15)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 14)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 13)

f_state_tag = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 16)
f_state_desc = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 13)

BRAND_YELLOW = '#FFDE02'
BORDER_YELLOW = '#EAB308'
BG_YELLOW_LIGHT = '#FEFCE8'
TXT_DARK = '#070E20'

# Grid
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill='#EDE8DF', width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill='#EDE8DF', width=1)

# Header
bx, by = 60, 36
badge_w, badge_h = 420, 52
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=26, fill='#0F172A', outline=BORDER_YELLOW, width=2)
draw.text((bx + 32, by + 8), '11 · UI / UX DESIGN', font=f_title, fill=BRAND_YELLOW)

draw.text((W - 680, by + 16), 'PRM393 · Final Assignment · One Complete System on Firebase', font=f_sub, fill='#475569')
draw.text((bx, by + 68), 'Tiến Trình Thiết Kế Giao Diện: Từ Wireframe Đến Final Figma, Chuẩn Hóa 4 Trạng Thái & Cải Tiến Sau Góp Ý', font=f_desc, fill=TXT_DARK)

def wrap_text(text, font, max_w):
    words = text.split(' ')
    lines = []
    cur_line = ''
    for w in words:
        test_line = cur_line + (' ' if cur_line else '') + w
        if draw.textlength(test_line, font=font) <= max_w:
            cur_line = test_line
        else:
            if cur_line:
                lines.append(cur_line)
            cur_line = w
    if cur_line:
        lines.append(cur_line)
    return lines

# ----------------- ROW 1: 3 DESIGN EVOLUTION STAGES (WIREFRAME -> MOCKUP -> FINAL FIGMA) -----------------
y_r1 = 150
h_r1 = 380
w_card = 540
gap_r1 = 90

stages = [
    {
        'tag': 'WIREFRAME',
        'phase': 'Low-fi (Phác thảo cấu trúc)',
        'pill_bg': '#F1F5F9',
        'pill_c': '#475569',
        'border_c': '#CBD5E1',
        'header_bg': '#F8FAFC',
        'mockup_type': 'wireframe',
        'points': [
            '• Định hình bố cục luồng: Bắt link Shopee → Màn hình tự vấn.',
            '• Xác lập vị trí 3 nút bấm cốt lõi: Mua • Chờ • Bỏ qua.',
            '• Phác thảo khung thông tin giá, mốc thời gian làm nguội 3 ngày.'
        ]
    },
    {
        'tag': 'MOCKUP',
        'phase': 'Hi-fi (Thiết kế chi tiết)',
        'pill_bg': '#EFF6FF',
        'pill_c': '#2563EB',
        'border_c': '#93C5FD',
        'header_bg': '#F0F9FF',
        'mockup_type': 'mockup',
        'points': [
            '• Áp dụng Design System màu vàng chủ đạo #FFDE02 & đen than #070E20.',
            '• Hiển thị Thẻ Quyết Định với màu sắc đại diện cho 8 động cơ tiêu dùng.',
            '• Tích hợp khối câu hỏi gợi mở từ Gemini AI & cảnh báo ngân sách.'
        ]
    },
    {
        'tag': 'FINAL FIGMA',
        'phase': 'Đã chốt (Production Ready)',
        'pill_bg': '#FEFCE8',
        'pill_c': '#A16207',
        'border_c': BORDER_YELLOW,
        'header_bg': '#FFFDF0',
        'mockup_type': 'final',
        'points': [
            '• Chuẩn hóa độ tương phản WCAG (chữ/nền ≥ 4.5:1, touch target ≥ 48dp).',
            '• Tối ưu hóa Responsive trên nhiều cỡ màn hình (360x640 đến 412x915).',
            '• Khớp 100% với giao diện Flutter code thực tế và Flutter Web Admin.'
        ]
    }
]

for idx, s in enumerate(stages):
    cx = bx + idx * (w_card + gap_r1)
    
    # Outer Card
    draw.rounded_rectangle([cx, y_r1, cx + w_card, y_r1 + h_r1], radius=14, fill='#FFFFFF', outline=s['border_c'], width=2)
    
    # Header Area
    hdr_h = 70
    draw.rounded_rectangle([cx + 2, y_r1 + 2, cx + w_card - 2, y_r1 + hdr_h], radius=12, fill=s['header_bg'])
    
    # Tag Pill
    tag_w = draw.textlength(s['tag'], font=f_step_tag)
    draw.rounded_rectangle([cx + 24, y_r1 + 18, cx + 24 + tag_w + 24, y_r1 + 52], radius=8, fill=s['pill_bg'], outline=s['border_c'], width=1)
    draw.text((cx + 36, y_r1 + 24), s['tag'], font=f_step_tag, fill=s['pill_c'])
    
    draw.text((cx + tag_w + 64, y_r1 + 24), s['phase'], font=f_step_sub, fill='#334155')
    draw.line([(cx, y_r1 + hdr_h), (cx + w_card, y_r1 + hdr_h)], fill='#E2E8F0', width=1)
    
    # Simulated UI Wireframe / Mockup Graphic Box
    box_x = cx + 24
    box_y = y_r1 + hdr_h + 16
    box_w = w_card - 48
    box_h = 135
    draw.rounded_rectangle([box_x, box_y, box_x + box_w, box_y + box_h], radius=10, fill='#F8FAFC', outline='#E2E8F0', width=1)
    
    # Draw mini UI preview inside
    if s['mockup_type'] == 'wireframe':
        draw.rounded_rectangle([box_x + 16, box_y + 14, box_x + box_w - 16, box_y + 36], radius=4, fill='#E2E8F0')
        draw.rounded_rectangle([box_x + 16, box_y + 44, box_x + 220, box_y + 60], radius=4, fill='#CBD5E1')
        draw.rounded_rectangle([box_x + 16, box_y + 68, box_x + 360, box_y + 84], radius=4, fill='#E2E8F0')
        btn_w = (box_w - 32 - 16) // 3
        for b_i in range(3):
            bx_btn = box_x + 16 + b_i * (btn_w + 8)
            draw.rounded_rectangle([bx_btn, box_y + 94, bx_btn + btn_w, box_y + 122], radius=6, fill='#E2E8F0')
            draw.text((bx_btn + 15, box_y + 100), ['MUA', 'CHỜ', 'BỎ'][b_i], font=f_small, fill='#64748B')
            
    elif s['mockup_type'] == 'mockup':
        draw.rounded_rectangle([box_x + 16, box_y + 14, box_x + box_w - 16, box_y + 36], radius=6, fill='#EFF6FF', outline='#3B82F6', width=1)
        draw.text((box_x + 24, box_y + 17), 'Thẻ Quyết Định: Trong ngân sách', font=f_small, fill='#1D4ED8')
        draw.text((box_x + 16, box_y + 45), 'Bạn sẽ dùng món này ra sao trong 30 ngày tới?', font=f_small, fill='#0F172A')
        draw.rounded_rectangle([box_x + 16, box_y + 68, box_x + 300, box_y + 84], radius=4, fill='#FEF08A')
        draw.text((box_x + 24, box_y + 69), 'AI: Tiết kiệm 450.000 đ', font=f_small, fill='#854D0E')
        btn_w = (box_w - 32 - 16) // 3
        draw.rounded_rectangle([box_x + 16, box_y + 94, box_x + 16 + btn_w, box_y + 122], radius=6, fill='#22C55E')
        draw.text((box_x + 35, box_y + 100), 'Mua ngay', font=f_small, fill='#FFFFFF')
        draw.rounded_rectangle([box_x + 16 + btn_w + 8, box_y + 94, box_x + 16 + btn_w*2 + 8, box_y + 122], radius=6, fill=BRAND_YELLOW, outline=BORDER_YELLOW, width=1)
        draw.text((box_x + btn_w + 40, box_y + 100), 'Chờ 3 ngày', font=f_small, fill=TXT_DARK)
        draw.rounded_rectangle([box_x + 16 + (btn_w + 8)*2, box_y + 94, box_x + box_w - 16, box_y + 122], radius=6, fill='#F1F5F9')
        draw.text((box_x + (btn_w + 8)*2 + 38, box_y + 100), 'Bỏ qua', font=f_small, fill='#64748B')
        
    else:
        draw.rounded_rectangle([box_x + 16, box_y + 14, box_x + box_w - 16, box_y + 40], radius=8, fill='#FEFCE8', outline=BORDER_YELLOW, width=2)
        draw.text((box_x + 26, box_y + 19), 'Tai nghe Sony WH-1000XM4 • 450.000 ₫', font=f_bold, fill=TXT_DARK)
        draw.text((box_x + 16, box_y + 48), 'Động cơ: Học tập • Mốc cân nhắc: 20:00 ngày 15/11', font=f_small, fill='#78350F')
        draw.rounded_rectangle([box_x + 16, box_y + 70, box_x + 360, box_y + 88], radius=4, fill='#DCFCE7')
        draw.text((box_x + 24, box_y + 71), 'Đạt chuẩn tiếp cận WCAG AA (Tương phản 5.2:1)', font=f_small, fill='#15803D')
        btn_w = (box_w - 32 - 16) // 3
        draw.rounded_rectangle([box_x + 16, box_y + 94, box_x + 16 + btn_w, box_y + 124], radius=6, fill=BRAND_YELLOW, outline=BORDER_YELLOW, width=2)
        draw.text((box_x + 36, box_y + 101), 'Mua thật', font=f_bold, fill=TXT_DARK)
        draw.rounded_rectangle([box_x + 16 + btn_w + 8, box_y + 94, box_x + 16 + btn_w*2 + 8, box_y + 124], radius=6, fill='#0F172A')
        draw.text((box_x + btn_w + 35, box_y + 101), 'Chờ 3 ngày', font=f_bold, fill='#FFFFFF')
        draw.rounded_rectangle([box_x + 16 + (btn_w + 8)*2, box_y + 94, box_x + box_w - 16, box_y + 124], radius=6, fill='#F8FAFC', outline='#CBD5E1', width=1)
        draw.text((box_x + (btn_w + 8)*2 + 35, box_y + 101), 'Bỏ qua (5s)', font=f_bold, fill='#64748B')

    # Bullet points
    py = box_y + box_h + 16
    for p in s['points']:
        draw.text((cx + 20, py), p, font=f_body, fill='#334155')
        py += 22

    # Horizontal Arrow between stages
    if idx < 2:
        arr_x = cx + w_card + 18
        arr_y = y_r1 + h_r1 // 2
        draw.line([(arr_x, arr_y), (arr_x + 50, arr_y)], fill='#D97706', width=3)
        draw.polygon([(arr_x + 50, arr_y), (arr_x + 38, arr_y - 6), (arr_x + 38, arr_y + 6)], fill='#D97706')

# ----------------- ROW 2: 4 UI STATES (EMPTY | LOADING | ERROR | SUCCESS) -----------------
y_r2 = y_r1 + h_r1 + 25
h_r2 = 95
w_state = 415
gap_state = 46

states_data = [
    ('Empty', 'Danh sách trống', 'Hình minh họa thân thiện + câu gợi ý Bắt link Shopee', '#F1F5F9', '#475569', '#E2E8F0'),
    ('Loading', 'Đang tải dữ liệu', 'Hiệu ứng Shimmer Skeleton mượt mà, không khóa giao diện', '#EFF6FF', '#2563EB', '#93C5FD'),
    ('Error', 'Sự cố / Mất mạng', 'Thông báo tiếng Việt rõ ràng + Nút Thử lại (Retry)', '#FEF2F2', '#DC2626', '#FCA5A5'),
    ('Success', 'Hiển thị trọn vẹn', 'Giao diện đầy đủ, phân loại 8 động cơ & tiến độ ngân sách', '#F0FDF4', '#16A34A', '#86EFAC')
]

for idx, (s_tag, s_title, s_desc, s_bg, s_txt, s_border) in enumerate(states_data):
    sx = bx + idx * (w_state + gap_state)
    draw.rounded_rectangle([sx, y_r2, sx + w_state, y_r2 + h_r2], radius=12, fill=s_bg, outline=s_border, width=2)
    
    # Tag Pill
    draw.rounded_rectangle([sx + 16, y_r2 + 16, sx + 110, y_r2 + 48], radius=6, fill='#FFFFFF', outline=s_border, width=1)
    draw.text((sx + 28, y_r2 + 22), s_tag, font=f_state_tag, fill=s_txt)
    
    draw.text((sx + 125, y_r2 + 22), s_title, font=f_bold, fill='#0F172A')
    
    # Description
    wrapped_s = wrap_text(s_desc, f_state_desc, w_state - 32)
    sy = y_r2 + 56
    for line in wrapped_s:
        draw.text((sx + 16, sy), line, font=f_state_desc, fill='#475569')
        sy += 18

# ----------------- ROW 3: FULL-WIDTH BOTTOM BAR: SAU GÓP Ý (FEEDBACK ITERATION) -----------------
y_r3 = y_r2 + h_r2 + 25
h_r3 = 165
draw.rounded_rectangle([bx, y_r3, bx + 1800, y_r3 + h_r3], radius=14, fill='#FFFBEB', outline=BORDER_YELLOW, width=2)

draw.rounded_rectangle([bx + 20, y_r3 + 20, bx + 190, y_r3 + 70], radius=8, fill=BRAND_YELLOW, outline=BORDER_YELLOW, width=2)
draw.text((bx + 35, y_r3 + 32), 'SAU GÓP Ý', font=f_step_tag, fill=TXT_DARK)

feedbacks = [
    ('• Đổi tên khái niệm trừu tượng:', 'Thay thuật ngữ kỹ thuật "Decision Card" thành "Thẻ Quyết Định" bằng tiếng Việt thân thiện, gần gũi.'),
    ('• Giảm áp lực thời gian tâm lý:', 'Bỏ đồng hồ đếm ngược giây hối thúc; chuyển thành "Mốc cân nhắc: 20:00 ngày..." giúp tâm trí người mua bình tĩnh.'),
    ('• Bổ sung câu hỏi tự vấn trực diện:', 'Thêm câu hỏi cốt lõi "Bạn sẽ dùng nó ra sao?" và câu hỏi mở từ AI Gemini trước khi cho phép bấm nút Mua.'),
    ('• Đánh giá trải nghiệm (UX Audit):', 'Rà soát 29 vấn đề theo 10 nguyên lý Nielsen; kiểm tra vùng chạm nút ≥ 48dp bảo đảm không bị bấm nhầm.')
]

fy = y_r3 + 22
for f_tag, f_desc in feedbacks:
    draw.text((bx + 215, fy), f_tag, font=f_bold, fill='#854D0E')
    draw.text((bx + 540, fy), f_desc, font=f_body, fill='#0F172A')
    fy += 34

# Save
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_11_ui_ux.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_11_ui_ux.png')
img.save(art_path, 'PNG')

print('Successfully generated Slide 11 UI/UX Design image to:', out_path)

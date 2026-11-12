import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
draw = ImageDraw.Draw(img)

# Fonts
font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 19)
f_num = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 36)
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 26)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 20)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 18)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 15)

# Background Grid
grid_color = '#EDE8DF'
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill=grid_color, width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill=grid_color, width=1)

# Header Badge
bx, by = 60, 40
badge_w, badge_h = 420, 52
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=26, fill='#0F172A')
draw.text((bx + 35, by + 8), '17 · DEMO PLAN', font=f_title, fill='#FFFFFF')

# Right title
sub_txt = 'PRM393 · Storyboard Kịch Bản Demo Liền Mạch Cho Duy Nhất Một Món Đồ'
draw.text((W - 740, by + 16), sub_txt, font=f_sub, fill='#475569')

# 3 Storyboard Cards
# Card 1: x = 60 -> 600 (w = 540)
# Arrow 1: x = 600 -> 660 (w = 60)
# Card 2: x = 660 -> 1200 (w = 540)
# Arrow 2: x = 1200 -> 1260 (w = 60)
# Card 3: x = 1260 -> 1800 (w = 540)
# Top: y = 140, Height = 640

cards_data = [
    (
        60, '01', 'Lưu món & Hẹn sale', 'Người dùng Android',
        '#2563EB', '#EFF6FF', '#DBEAFE',
        'Món "Tai nghe..." ở CONSIDERING',
        '• Bắt link Shopee qua Share Sheet; tự điền thông tin\n• Chọn động cơ "Cảm xúc" → Đếm ngược hoãn 3 ngày\n• Món xuất hiện trong Wishlist; gợi ý hẹn sale 11.11',
        'Màn hình Shopee → Share Sheet → Wishlist'
    ),
    (
        690, '02', 'Trước khi mua & Quyết định', 'Người dùng + AI Gemini',
        '#0D9488', '#F0FDFA', '#CCFBF1',
        '"Tai nghe..."  →  VẪN MUA',
        '• Mở món khi đến hẹn; trả lời nhanh 3 câu tự vấn\n• AI Gemini sinh Thẻ quan sát gợi mở trung lập\n• Tự chọn "Vẫn mua" (nhánh phụ: Bỏ qua → Hoàn tác 5s)',
        '3 câu hỏi tự vấn → Thẻ AI → Nhánh quyết định'
    ),
    (
        1320, '03', 'Ghi chi & Chiêm nghiệm', 'Người dùng + Máy in PDF',
        '#EA580C', '#FFF7ED', '#FFEDD5',
        '"Tai nghe..."  →  PURCHASED',
        '• 1 WriteBatch: Tạo purchases + Đổi món sang purchased\n• Mở tab Góc nhìn: Phân bổ chi tiêu theo 8 động cơ\n• Chấm hài lòng 1–5 sao, đặt mục tiêu → Xuất file PDF',
        'Form ghi chi 2 bước → Biểu đồ 8 động cơ → PDF'
    )
]

card_y = 135
card_w = 540
card_h = 670

for (cx, num, title, actor, theme_clr, bg_clr, res_bg, res_title, res_desc, quay_desc) in cards_data:
    # Outer white card with subtle shadow/border
    draw.rounded_rectangle([cx, card_y, cx + card_w, card_y + card_h], radius=16, fill='#FFFFFF', outline='#CBD5E1', width=2)
    
    # Circle Avatar with number
    cir_x, cir_y = cx + 45, card_y + 45
    draw.ellipse([cir_x - 32, cir_y - 32, cir_x + 32, cir_y + 32], fill=theme_clr)
    bbox = draw.textbbox((0, 0), num, font=f_num)
    nw = bbox[2] - bbox[0]
    draw.text((cir_x - nw / 2, cir_y - 25), num, font=f_num, fill='#FFFFFF')
    
    # Header Title & Actor
    draw.text((cx + 95, card_y + 24), title, font=f_h1, fill='#0F172A')
    draw.text((cx + 95, card_y + 60), actor, font=f_h2, fill='#64748B')
    
    # Separator
    draw.line([(cx + 30, card_y + 95), (cx + card_w - 30, card_y + 95)], fill='#E2E8F0', width=1)
    
    # KẾT QUẢ Box (Storyboard highlight)
    kb_y = card_y + 115
    kb_h = 360
    draw.rounded_rectangle([cx + 25, kb_y, cx + card_w - 25, kb_y + kb_h], radius=12, fill=bg_clr, outline=theme_clr, width=2)
    
    # Label KẾT QUẢ
    draw.text((cx + 45, kb_y + 18), 'KẾT QUẢ NGHIỆP VỤ', font=f_bold, fill=theme_clr)
    draw.text((cx + 45, kb_y + 46), res_title, font=f_h1, fill='#0F172A')
    draw.line([(cx + 45, kb_y + 88), (cx + card_w - 45, kb_y + 88)], fill=res_bg, width=2)
    
    # Bullet points of results
    cur_y = kb_y + 102
    for line in res_desc.split('\n'):
        draw.text((cx + 45, cur_y), line, font=f_body, fill='#334155')
        cur_y += 34
        
    # CẦN QUAY BOX (Dưới khung kết quả)
    qw_y = kb_y + kb_h + 18
    qw_h = 135
    draw.rounded_rectangle([cx + 25, qw_y, cx + card_w - 25, qw_y + qw_h], radius=10, fill='#F8FAFC', outline='#E2E8F0', width=1)
    draw.text((cx + 40, qw_y + 12), 'MINH CHỨNG CẦN QUAY / CHIẾU:', font=f_bold, fill='#475569')
    draw.text((cx + 40, qw_y + 40), quay_desc, font=f_body, fill='#0F172A')
    
    # Sub-item tag
    draw.rounded_rectangle([cx + 40, qw_y + 75, cx + card_w - 40, qw_y + 115], radius=6, fill='#FFFFFF', outline='#CBD5E1', width=1)
    draw.text((cx + 52, qw_y + 86), 'Seed: Tai nghe Sony · 450.000 ₫ · Cảm xúc', font=f_small, fill='#64748B')

# Draw Arrows between Card 1 -> 2 and Card 2 -> 3
def draw_arrow(ax, ay):
    draw.line([(ax, ay), (ax + 40, ay)], fill='#EA580C', width=4)
    draw.polygon([(ax + 40, ay), (ax + 28, ay - 8), (ax + 28, ay + 8)], fill='#EA580C')

draw_arrow(620, card_y + 240)
draw_arrow(1250, card_y + 240)

# Bottom Full-width Box: CHUẨN BỊ (STORYBOARD FOOTER)
bot_x = 60
bot_y = 835
bot_w = 1800
bot_h = 195

draw.rounded_rectangle([bot_x, bot_y, bot_x + bot_w, bot_y + bot_h], radius=14, fill='#FFFBEB', outline='#F59E0B', width=2)

draw.rounded_rectangle([bot_x + 20, bot_y + 18, bot_x + 180, bot_y + 54], radius=8, fill='#FEF3C7', outline='#D97706', width=1)
draw.text((bot_x + 36, bot_y + 24), 'CHUẨN BỊ DEMO', font=f_h2, fill='#B45309')

b_bullets = [
    '• Seed Data: Món "Tai nghe Bluetooth Sony" (450.000 ₫, động cơ Cảm xúc); hạn mức ngân sách tháng đã thiết lập sẵn.',
    '• Môi trường & Thiết bị: Điện thoại Android thật kết nối máy chiếu; tài khoản Demo User độc lập; video quay sẵn 1080p dự phòng khi rớt mạng.',
    '• Script khôi phục (Reset Data): Tích hợp nút Reset dữ liệu 1 chạm qua DemoDataService để quay lại trạng thái ban đầu bất cứ lúc nào.',
    '• Luồng phụ (Cross-role): Mở song song Web Admin (prm393-34056.web.app) duyệt đề xuất đợt sale nếu Hội đồng yêu cầu kiểm tra tương tác.'
]

cur_by = bot_y + 64
for line in b_bullets:
    draw.text((bot_x + 30, cur_by), line, font=f_body, fill='#78350F')
    cur_by += 28

# Save image
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_17_demo_plan.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_17_demo_plan.png')
img.save(art_path, 'PNG')

print('Successfully generated Slide 17 Storyboard image to:', out_path)

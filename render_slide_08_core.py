import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
draw = ImageDraw.Draw(img)

# Fonts
font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_badge = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 17)
f_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 19)
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 23)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 15)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 15)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 13)
f_code = ImageFont.truetype(os.path.join(font_dir, 'calibri.ttf'), 14)

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
draw.text((bx + 32, by + 8), '08 · STATE MACHINE', font=f_title, fill='#FFFFFF')

# Right title
sub_txt = 'PRM393 · Final Assignment · One Complete System on Firebase'
draw.text((W - 680, by + 16), sub_txt, font=f_sub, fill='#475569')

# Top entity pill
pill_x = bx + badge_w + 30
draw.rounded_rectangle([pill_x, by + 8, pill_x + 400, by + 44], radius=18, fill='#EFF6FF', outline='#3B82F6', width=2)
draw.text((pill_x + 22, by + 13), 'CORE ENTITY: wishlistItems.status (Món Hàng)', font=f_badge, fill='#1D4ED8')

# Main Layout
diag_x = 60
diag_y = 115
diag_w = 1200
diag_h = 790

# ----------------- LEFT: CORE STATE MACHINE DIAGRAM -----------------
draw.rounded_rectangle([diag_x, diag_y, diag_x + diag_w, diag_y + diag_h], radius=14, fill='#FFFFFF', outline='#CBD5E1', width=2)

# Diagram Header
draw.rounded_rectangle([diag_x + 24, diag_y + 20, diag_x + 480, diag_y + 60], radius=8, fill='#FEFCE8', outline='#EAB308', width=1)
draw.text((diag_x + 36, diag_y + 26), 'VÒNG ĐỜI MÓN HÀNG MONG MUỐN (wishlistItems)', font=f_h2, fill='#854D0E')

# Start Node ●
s_dot_x, s_dot_y = diag_x + 80, diag_y + 260
draw.ellipse([s_dot_x - 14, s_dot_y - 14, s_dot_x + 14, s_dot_y + 14], fill='#1E293B')

# Arrow Start -> CONSIDERING
draw.line([(s_dot_x + 14, s_dot_y), (s_dot_x + 100, s_dot_y)], fill='#475569', width=3)
draw.polygon([(s_dot_x + 100, s_dot_y), (s_dot_x + 88, s_dot_y - 7), (s_dot_x + 88, s_dot_y + 7)], fill='#475569')
draw.text((s_dot_x - 20, s_dot_y - 65), 'Thêm món từ Shopee', font=f_bold, fill='#1E293B')
draw.text((s_dot_x - 20, s_dot_y - 42), '[tên, giá, động cơ]', font=f_code, fill='#64748B')

# State 1: CONSIDERING Box (Center-Left)
c_w, c_h = 320, 160
c_x = s_dot_x + 100
c_y = s_dot_y - 80
draw.rounded_rectangle([c_x, c_y, c_x + c_w, c_y + c_h], radius=14, fill='#EFF6FF', outline='#2563EB', width=3)
draw.text((c_x + 24, c_y + 18), 'CONSIDERING', font=f_h1, fill='#1E40AF')
draw.text((c_x + 24, c_y + 54), 'Đang cân nhắc · Đang hoãn', font=f_bold, fill='#1E3A8A')
draw.text((c_x + 24, c_y + 84), '• cooldownUntil = +3 ngày (BR-01)', font=f_body, fill='#3B82F6')
draw.text((c_x + 24, c_y + 108), '• Trừ động cơ Nhu cầu (hoãn = 0)', font=f_body, fill='#64748B')
draw.text((c_x + 24, c_y + 130), '• Hoãn chỉ là nhắc, không chặn Mua', font=f_small, fill='#1E40AF')

# Self-loop on CONSIDERING (Wait / Chờ)
l_top = c_y - 85
draw.arc([c_x + 70, l_top, c_x + 250, c_y + 25], 180, 0, fill='#D97706', width=3)
draw.polygon([(c_x + 250, c_y), (c_x + 243, c_y - 12), (c_x + 257, c_y - 12)], fill='#D97706')
draw.text((c_x + 20, l_top - 18), 'Chờ [đặt reviewAt, status không đổi] (BR-03)', font=f_bold, fill='#B45309')
draw.text((c_x + 40, l_top + 8), 'Hẹn nhắc đợt sale / xem lại 09:00', font=f_small, fill='#D97706')

# State 2: PURCHASED Box (Center-Right)
p_w, p_h = 320, 160
p_x = c_x + 420
p_y = c_y
draw.rounded_rectangle([p_x, p_y, p_x + p_w, p_y + p_h], radius=14, fill='#F0FDF4', outline='#16A34A', width=3)
draw.text((p_x + 24, p_y + 18), 'PURCHASED', font=f_h1, fill='#15803D')
draw.text((p_x + 24, p_y + 54), 'Đã mua · Trạng thái cuối', font=f_bold, fill='#14532D')
draw.text((p_x + 24, p_y + 84), '• Bắt buộc có purchaseId (BR-02)', font=f_body, fill='#16A34A')
draw.text((p_x + 24, p_y + 108), '• Thực thi 1 WriteBatch đồng bộ', font=f_body, fill='#15803D')
draw.text((p_x + 24, p_y + 130), '• Ghi nhận vào Lịch sử chi tiêu', font=f_small, fill='#475569')

# End Dot inside Purchased
draw.ellipse([p_x + p_w - 44, p_y + 20, p_x + p_w - 18, p_y + 46], outline='#16A34A', width=2)
draw.ellipse([p_x + p_w - 37, p_y + 27, p_x + p_w - 25, p_y + 39], fill='#16A34A')

# Arrow CONSIDERING -> PURCHASED
draw.line([(c_x + c_w, s_dot_y), (p_x, s_dot_y)], fill='#16A34A', width=4)
draw.polygon([(p_x, s_dot_y), (p_x - 14, s_dot_y - 8), (p_x - 14, s_dot_y + 8)], fill='#16A34A')
draw.text((c_x + c_w + 20, s_dot_y - 42), 'Quyết định Mua', font=f_h2, fill='#15803D')
draw.text((c_x + c_w + 10, s_dot_y - 14), '[kèm purchaseId, 1 batch]', font=f_code, fill='#166534')

# State 3: SKIPPED Box (Bottom-Left)
sk_w, sk_h = 320, 145
sk_x = c_x
sk_y = c_y + 260
draw.rounded_rectangle([sk_x, sk_y, sk_x + sk_w, sk_y + sk_h], radius=14, fill='#F8FAFC', outline='#64748B', width=2)
draw.text((sk_x + 24, sk_y + 16), 'SKIPPED', font=f_h1, fill='#334155')
draw.text((sk_x + 24, sk_y + 50), 'Bỏ qua (Không mua)', font=f_bold, fill='#475569')
draw.text((sk_x + 24, sk_y + 78), '• Ghi log vào decisions (choice: skip)', font=f_body, fill='#64748B')
draw.text((sk_x + 24, sk_y + 102), '• Ẩn khỏi danh sách cân nhắc chính', font=f_small, fill='#64748B')

# Down arrow (Bỏ qua)
draw.line([(c_x + 80, c_y + c_h), (c_x + 80, sk_y)], fill='#64748B', width=3)
draw.polygon([(c_x + 80, sk_y), (c_x + 73, sk_y - 12), (c_x + 87, sk_y - 12)], fill='#64748B')
draw.text((c_x - 120, c_y + c_h + 45), 'Bỏ qua (BR-04)', font=f_bold, fill='#475569')

# Up arrow (Hoàn tác <= 5s)
draw.line([(c_x + 230, sk_y), (c_x + 230, c_y + c_h)], fill='#0284C7', width=3)
draw.polygon([(c_x + 230, c_y + c_h), (c_x + 223, c_y + c_h + 12), (c_x + 237, c_y + c_h + 12)], fill='#0284C7')
draw.text((c_x + 245, c_y + c_h + 45), 'Hoàn tác ≤ 5s (BR-06)', font=f_bold, fill='#0284C7')

# Decision Audit Card (Bottom-Right of Left Panel)
dec_x = p_x
dec_y = sk_y
dec_w = p_w
dec_h = sk_h
draw.rounded_rectangle([dec_x, dec_y, dec_x + dec_w, dec_y + dec_h], radius=14, fill='#FEFCE8', outline='#FACC15', width=2)
draw.text((dec_x + 20, dec_y + 16), 'SỔ GHI QUYẾT ĐỊNH (decisions)', font=f_bold, fill='#854D0E')
draw.text((dec_x + 20, dec_y + 44), 'Mọi hành vi đều lưu vết Append-only:', font=f_small, fill='#713F12')
draw.text((dec_x + 20, dec_y + 68), '• choice: buy | wait | skip | undo', font=f_code, fill='#B45309')
draw.text((dec_x + 20, dec_y + 90), '• Không bao giờ xóa lịch sử suy nghĩ', font=f_body, fill='#A16207')
draw.text((dec_x + 20, dec_y + 114), '• Dùng làm số liệu cho tab Góc nhìn AI', font=f_small, fill='#854D0E')


# ----------------- RIGHT COLUMN: FORBIDDEN TRANSITIONS -----------------
fb_x = 1290
fb_y = 115
fb_w = 570
fb_h = diag_h

draw.rounded_rectangle([fb_x, fb_y, fb_x + fb_w, fb_y + fb_h], radius=14, fill='#FFFBEB', outline='#F59E0B', width=2)

# Card Header
draw.rounded_rectangle([fb_x + 20, fb_y + 20, fb_x + fb_w - 20, fb_y + 70], radius=10, fill='#FEF3C7', outline='#D97706', width=1)
draw.text((fb_x + 130, fb_y + 32), 'CHUYỂN BỊ CẤM (RULES GUARDS)', font=f_h1, fill='#92400E')

forbidden_items = [
    ('✕ Chuyển sang purchased thiếu purchaseId', 'Rules chặn đứng: Mua bắt buộc phải kèm purchaseId hợp lệ (TC-07 / R-84).'),
    ('✕ Sửa lịch sử giá đã ghi (priceSnapshots)', 'Chỉ cho phép Append-only; cấm tuyệt đối sửa hoặc xóa giá cũ (TC-08 / R-96).'),
    ('✕ Gán status ngoài 3 giá trị chuẩn', 'Status lạ như \"waiting\", \"processing\" bị Rules từ chối ngay lập tức.'),
    ('✕ Xóa món của người dùng khác', 'Chỉ chủ tài khoản mới có quyền xóa (request.auth.uid == uid).'),
    ('✕ Sửa quyết định trong subcollection decisions', 'Decisions là append-only, ghi nhận trung thực mọi quyết định.'),
    ('✕ Tạo món hàng với giá tiền âm (< 0)', 'Rules kiểm tra số tiền phải hợp lệ (latestPriceVnd >= 0 hoặc null).')
]

fy = fb_y + 95
for (f_t, f_d) in forbidden_items:
    draw.text((fb_x + 26, fy), f_t, font=f_bold, fill='#B91C1C')
    draw.text((fb_x + 44, fy + 24), f_d, font=f_body, fill='#475569')
    fy += 64

# Verification Badge at bottom of Right Card
draw.rounded_rectangle([fb_x + 20, fb_y + fb_h - 145, fb_x + fb_w - 20, fb_y + fb_h - 20], radius=10, fill='#ECFDF5', outline='#10B981', width=2)
draw.text((fb_x + 36, fb_y + fb_h - 132), '✓ BẢO CHỨNG BẰNG TEST SECURITY RULES', font=f_bold, fill='#065F46')
draw.text((fb_x + 36, fb_y + fb_h - 102), '• 298 / 298 ca test Security Rules đạt 100% trên Firebase Emulator.', font=f_body, fill='#047857')
draw.text((fb_x + 36, fb_y + fb_h - 78), '• Mọi chuyển bị cấm đều có test case kỳ vọng permission-denied.', font=f_body, fill='#047857')
draw.text((fb_x + 36, fb_y + fb_h - 54), '• Đảm bảo tuyệt đối tính toàn vẹn dữ liệu tài chính.', font=f_small, fill='#059669')


# ----------------- BOTTOM STRIP: BUSINESS VS UI STATE -----------------
bot_x = 60
bot_y = 920
bot_w = 1800
bot_h = 120

draw.rounded_rectangle([bot_x, bot_y, bot_x + bot_w, bot_y + bot_h], radius=12, fill='#FEF08A', outline='#EAB308', width=2)
draw.text((bot_x + 24, bot_y + 14), 'NGUYÊN TẮC THIẾT KẾ: TRẠNG THÁI NGHIỆP VỤ  ≠  TRẠNG THÁI GIAO DIỆN (UI)', font=f_h2, fill='#854D0E')

notes = [
    '• Trạng thái nghiệp vụ (Business State): Lưu trên Firestore, kiểm soát bởi Security Rules: considering ↔ purchased (có purchaseId) hoặc skipped.',
    '• Trạng thái giao diện (UI State): Chỉ tồn tại tạm thời ở ViewModel (UiLoading, UiEmpty, UiError, UiSuccess), tuyệt đối không lưu vào Database.',
    '• Tính năng \"Chờ\" (Wait): KHÔNG tạo thêm trạng thái mới mà chỉ cập nhật reviewAt và lưu lịch sử vào decisions, giúp hệ thống tinh gọn và không bị phân mảnh dữ liệu.'
]
ny = bot_y + 44
for n in notes:
    draw.text((bot_x + 24, ny), n, font=f_body, fill='#713F12')
    ny += 23

# Save output
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_08_state_machine_core.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_08_state_machine_core.png')
img.save(art_path, 'PNG')

print('Successfully generated Slide 08 Core State Machine diagram to:', out_path)

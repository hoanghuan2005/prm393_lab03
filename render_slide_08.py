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
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 22)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 15)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 15)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 13)
f_code = ImageFont.truetype(os.path.join(font_dir, 'calibri.ttf'), 15)

# Subtle background grid
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
draw.rounded_rectangle([pill_x, by + 8, pill_x + 360, by + 44], radius=18, fill='#EFF6FF', outline='#3B82F6', width=2)
draw.text((pill_x + 20, by + 13), 'CORE ENTITY: wishlistItems.status', font=f_badge, fill='#1D4ED8')

# Layout Areas
# Left Area: State Machine Diagram (x: 60 -> 1260, w: 1200)
# Right Area: Forbidden Transitions Card (x: 1290 -> 1860, w: 570)
# Bottom Area: Business State vs UI State note (y: 930 -> 1030)

diag_x = 60
diag_y = 115
diag_w = 1200
diag_h = 790

# Draw Diagram Container
draw.rounded_rectangle([diag_x, diag_y, diag_x + diag_w, diag_y + diag_h], radius=14, fill='#FFFFFF', outline='#CBD5E1', width=2)

# Diagram Section Header
draw.rounded_rectangle([diag_x + 20, diag_y + 18, diag_x + 460, diag_y + 54], radius=8, fill='#FEFCE8', outline='#EAB308', width=1)
draw.text((diag_x + 32, diag_y + 24), '1. VÒNG ĐỜI MÓN HÀNG (wishlistItems)', font=f_h2, fill='#854D0E')

# ----------------- SECTION 1: WISHLIST STATE MACHINE -----------------
# Start Node ●
s_dot_x, s_dot_y = diag_x + 60, diag_y + 180
draw.ellipse([s_dot_x - 12, s_dot_y - 12, s_dot_x + 12, s_dot_y + 12], fill='#1E293B')

# Transition Start -> CONSIDERING
draw.line([(s_dot_x + 12, s_dot_y), (s_dot_x + 90, s_dot_y)], fill='#475569', width=3)
# Arrow head
draw.polygon([(s_dot_x + 90, s_dot_y), (s_dot_x + 80, s_dot_y - 6), (s_dot_x + 80, s_dot_y + 6)], fill='#475569')

# State 1: CONSIDERING Box
c_w, c_h = 280, 130
c_x = s_dot_x + 90
c_y = s_dot_y - 65
draw.rounded_rectangle([c_x, c_y, c_x + c_w, c_y + c_h], radius=12, fill='#EFF6FF', outline='#2563EB', width=3)
draw.text((c_x + 24, c_y + 16), 'CONSIDERING', font=f_h1, fill='#1E40AF')
draw.text((c_x + 24, c_y + 48), 'Đang cân nhắc · Đang hoãn', font=f_bold, fill='#1E3A8A')
draw.text((c_x + 24, c_y + 74), 'cooldownUntil = +3 ngày (BR-01)', font=f_small, fill='#3B82F6')
draw.text((c_x + 24, c_y + 96), 'Trừ động cơ Nhu cầu (cooldown = 0)', font=f_small, fill='#64748B')

# State 2: PURCHASED Box (Green)
p_w, p_h = 280, 130
p_x = c_x + 460
p_y = c_y
draw.rounded_rectangle([p_x, p_y, p_x + p_w, p_y + p_h], radius=12, fill='#F0FDF4', outline='#16A34A', width=3)
draw.text((p_x + 24, p_y + 16), 'PURCHASED', font=f_h1, fill='#15803D')
draw.text((p_x + 24, p_y + 48), 'Đã mua · Trạng thái cuối', font=f_bold, fill='#14532D')
draw.text((p_x + 24, p_y + 74), 'Bắt buộc có purchaseId (BR-02)', font=f_small, fill='#16A34A')
draw.text((p_x + 24, p_y + 96), 'Thực thi 1 WriteBatch đồng bộ', font=f_small, fill='#475569')

# End Dot inside Purchased
draw.ellipse([p_x + p_w - 40, p_y + 20, p_x + p_w - 16, p_y + 44], outline='#16A34A', width=2)
draw.ellipse([p_x + p_w - 34, p_y + 26, p_x + p_w - 22, p_y + 38], fill='#16A34A')

# Arrow CONSIDERING -> PURCHASED
draw.line([(c_x + c_w, s_dot_y), (p_x, s_dot_y)], fill='#16A34A', width=3)
draw.polygon([(p_x, s_dot_y), (p_x - 12, s_dot_y - 6), (p_x - 12, s_dot_y + 6)], fill='#16A34A')
# Label
draw.text((c_x + c_w + 30, s_dot_y - 34), 'Quyết định Mua', font=f_bold, fill='#15803D')
draw.text((c_x + c_w + 15, s_dot_y - 12), '[kèm purchaseId, 1 batch]', font=f_code, fill='#166534')

# Self-loop on CONSIDERING (Wait / Chờ)
# Loop up and back down
l_top = c_y - 55
draw.arc([c_x + 60, l_top, c_x + 220, c_y + 20], 180, 0, fill='#D97706', width=3)
draw.polygon([(c_x + 220, c_y), (c_x + 214, c_y - 12), (c_x + 226, c_y - 12)], fill='#D97706')
draw.text((c_x + 40, l_top - 18), 'Chờ [đặt reviewAt, status không đổi] (BR-03)', font=f_bold, fill='#B45309')

# State 3: SKIPPED Box (Bottom)
s_w, s_h = 280, 115
sk_x = c_x
sk_y = c_y + 210
draw.rounded_rectangle([sk_x, sk_y, sk_x + s_w, sk_y + s_h], radius=12, fill='#F8FAFC', outline='#64748B', width=2)
draw.text((sk_x + 24, sk_y + 14), 'SKIPPED', font=f_h1, fill='#334155')
draw.text((sk_x + 24, sk_y + 44), 'Bỏ qua (không mua)', font=f_bold, fill='#475569')
draw.text((sk_x + 24, sk_y + 70), 'Ghi log vào decisions (choice: skip)', font=f_small, fill='#64748B')
draw.text((sk_x + 24, sk_y + 90), 'Có thể phục hồi bằng Hoàn tác', font=f_small, fill='#0284C7')

# Arrows CONSIDERING <-> SKIPPED
# Down arrow: Bỏ qua
draw.line([(c_x + 80, c_y + c_h), (c_x + 80, sk_y)], fill='#64748B', width=3)
draw.polygon([(c_x + 80, sk_y), (c_x + 74, sk_y - 10), (c_x + 86, sk_y - 10)], fill='#64748B')
draw.text((c_x - 110, c_y + c_h + 35), 'Bỏ qua (BR-04)', font=f_bold, fill='#475569')

# Up arrow (dashed/curved): Hoàn tác <= 5s
draw.line([(c_x + 190, sk_y), (c_x + 190, c_y + c_h)], fill='#0284C7', width=3)
draw.polygon([(c_x + 190, c_y + c_h), (c_x + 184, c_y + c_h + 10), (c_x + 196, c_y + c_h + 10)], fill='#0284C7')
draw.text((c_x + 205, c_y + c_h + 35), 'Hoàn tác ≤ 5s (BR-06)', font=f_bold, fill='#0284C7')


# ----------------- SECTION 2: SALE SUGGESTIONS (CROSS-ROLE) -----------------
sec2_y = diag_y + 440
draw.line([(diag_x + 20, sec2_y), (diag_x + diag_w - 20, sec2_y)], fill='#E2E8F0', width=2)

draw.rounded_rectangle([diag_x + 20, sec2_y + 18, diag_x + 480, sec2_y + 54], radius=8, fill='#F0FDFA', outline='#0D9488', width=1)
draw.text((diag_x + 32, sec2_y + 24), '2. ĐỀ XUẤT ĐỢT SALE (saleSuggestions · Cross-role)', font=f_h2, fill='#0F766E')

# Start dot for suggestions
s2_dot_x, s2_dot_y = diag_x + 60, sec2_y + 175
draw.ellipse([s2_dot_x - 10, s2_dot_y - 10, s2_dot_x + 10, s2_dot_y + 10], fill='#1E293B')

# Arrow -> PENDING
draw.line([(s2_dot_x + 10, s2_dot_y), (s2_dot_x + 70, s2_dot_y)], fill='#475569', width=2)
draw.polygon([(s2_dot_x + 70, s2_dot_y), (s2_dot_x + 62, s2_dot_y - 5), (s2_dot_x + 62, s2_dot_y + 5)], fill='#475569')

# PENDING Box
pnd_x, pnd_y = s2_dot_x + 70, s2_dot_y - 55
pnd_w, pnd_h = 240, 110
draw.rounded_rectangle([pnd_x, pnd_y, pnd_x + pnd_w, pnd_y + pnd_h], radius=10, fill='#FFFBEB', outline='#D97706', width=2)
draw.text((pnd_x + 16, pnd_y + 14), 'PENDING', font=f_h1, fill='#B45309')
draw.text((pnd_x + 16, pnd_y + 42), 'Đề xuất đang chờ duyệt', font=f_bold, fill='#78350F')
draw.text((pnd_x + 16, pnd_y + 66), 'User mobile gửi báo đợt sale', font=f_small, fill='#92400E')
draw.text((pnd_x + 16, pnd_y + 86), 'createdAt = request.time', font=f_code, fill='#64748B')

# APPROVED Box
app_x, app_y = pnd_x + 420, pnd_y - 45
app_w, app_h = 240, 95
draw.rounded_rectangle([app_x, app_y, app_x + app_w, app_y + app_h], radius=10, fill='#F0FDF4', outline='#16A34A', width=2)
draw.text((app_x + 16, app_y + 12), 'APPROVED', font=f_h1, fill='#15803D')
draw.text((app_x + 16, app_y + 40), 'Đã duyệt (Trạng thái cuối)', font=f_bold, fill='#14532D')
draw.text((app_x + 16, app_y + 64), 'Staff tạo saleEvents + Hộp thư', font=f_small, fill='#166534')

# REJECTED Box
rej_x, rej_y = app_x, pnd_y + 65
rej_w, rej_h = 240, 95
draw.rounded_rectangle([rej_x, rej_y, rej_x + rej_w, rej_y + rej_h], radius=10, fill='#FEF2F2', outline='#DC2626', width=2)
draw.text((rej_x + 16, rej_y + 12), 'REJECTED', font=f_h1, fill='#B91C1C')
draw.text((rej_x + 16, rej_y + 40), 'Từ chối (Trạng thái cuối)', font=f_bold, fill='#7F1D1D')
draw.text((rej_x + 16, rej_y + 64), 'Bắt buộc lý do 1–200 ký tự', font=f_small, fill='#991B1B')

# Arrows PENDING -> APPROVED / REJECTED
draw.line([(pnd_x + pnd_w, pnd_y + 35), (app_x, app_y + 45)], fill='#16A34A', width=2)
draw.polygon([(app_x, app_y + 45), (app_x - 10, app_y + 40), (app_x - 10, app_y + 50)], fill='#16A34A')
draw.text((pnd_x + pnd_w + 20, pnd_y - 25), 'Staff duyệt (1 batch)', font=f_bold, fill='#15803D')

draw.line([(pnd_x + pnd_w, pnd_y + 75), (rej_x, rej_y + 45)], fill='#DC2626', width=2)
draw.polygon([(rej_x, rej_y + 45), (rej_x - 10, rej_y + 40), (rej_x - 10, rej_y + 50)], fill='#DC2626')
draw.text((pnd_x + pnd_w + 20, rej_y + 45), 'Staff từ chối (kèm lý do)', font=f_bold, fill='#B91C1C')


# ----------------- RIGHT COLUMN: FORBIDDEN TRANSITIONS -----------------
fb_x = 1290
fb_y = 115
fb_w = 570
fb_h = diag_h

draw.rounded_rectangle([fb_x, fb_y, fb_x + fb_w, fb_y + fb_h], radius=14, fill='#FFFBEB', outline='#F59E0B', width=2)

# Card Header
draw.rounded_rectangle([fb_x + 20, fb_y + 20, fb_x + fb_w - 20, fb_y + 68], radius=10, fill='#FEF3C7', outline='#D97706', width=1)
draw.text((fb_x + 140, fb_y + 30), 'CHUYỂN BỊ CẤM (RULES GUARDS)', font=f_h1, fill='#92400E')

forbidden_items = [
    ('✕ Món: purchased thiếu purchaseId', 'Firestore Rules chặn đứng (bắt buộc purchaseId hợp lệ).'),
    ('✕ Món: Sửa lịch sử giá cũ (priceSnapshots)', 'Chỉ cho phép Append-only, cấm tuyệt đối update / delete.'),
    ('✕ Món: Gán status ngoài 3 giá trị', 'Gán status = \"waiting\" hoặc khác bị Rules từ chối ngay.'),
    ('✕ Đề xuất: User tự gán status = approved', 'Chỉ tài khoản role = staff/admin mới có quyền đổi status.'),
    ('✕ Đề xuất: Staff duyệt lần hai', 'Trạng thái approved hoặc rejected là cuối cùng, không thể đổi lại.'),
    ('✕ Đề xuất: Từ chối mà không có lý do', 'Rules bắt buộc trường reason từ 1–200 ký tự.'),
    ('✕ Khách (ẩn danh) tạo đề xuất sale', 'Chỉ tài khoản đăng nhập Google / email mới được gửi đề xuất.')
]

fy = fb_y + 90
for (f_title_txt, f_sub_txt) in forbidden_items:
    draw.text((fb_x + 24, fy), f_title_txt, font=f_bold, fill='#B91C1C')
    draw.text((fb_x + 42, fy + 22), f_sub_txt, font=f_body, fill='#475569')
    fy += 56

# Verification Badge at bottom of Right Card
draw.rounded_rectangle([fb_x + 20, fb_y + fb_h - 130, fb_x + fb_w - 20, fb_y + fb_h - 20], radius=10, fill='#ECFDF5', outline='#10B981', width=2)
draw.text((fb_x + 36, fb_y + fb_h - 118), '✓ BẢO CHỨNG BẰNG TEST TỰ ĐỘNG THỰC TẾ', font=f_bold, fill='#065F46')
draw.text((fb_x + 36, fb_y + fb_h - 90), '• 298/298 ca test Security Rules đạt 100% trên Firebase Emulator.', font=f_body, fill='#047857')
draw.text((fb_x + 36, fb_y + fb_h - 66), '• Mọi chuyển bị cấm đều có test case kỳ vọng permission-denied.', font=f_body, fill='#047857')
draw.text((fb_x + 36, fb_y + fb_h - 44), '• Chạy kiểm thử tự động 3 lần liên tiếp (11/11/2026).', font=f_small, fill='#059669')


# ----------------- BOTTOM STRIP: BUSINESS VS UI STATE -----------------
bot_x = 60
bot_y = 920
bot_w = 1800
bot_h = 120

draw.rounded_rectangle([bot_x, bot_y, bot_x + bot_w, bot_y + bot_h], radius=12, fill='#FEF08A', outline='#EAB308', width=2)
draw.text((bot_x + 24, bot_y + 14), 'NGUYÊN TẮC THIẾT KẾ: TRẠNG THÁI NGHIỆP VỤ  ≠  TRẠNG THÁI GIAO DIỆN (UI)', font=f_h2, fill='#854D0E')

notes = [
    '• Trạng thái nghiệp vụ (Business State): Lưu trên Firestore, kiểm soát bởi Security Rules (considering, purchased, skipped, pending, approved, rejected).',
    '• Trạng thái giao diện (UI State): Chỉ tồn tại tạm thời ở ViewModel (UiLoading, UiEmpty, UiError, UiSuccess), tuyệt đối không lưu vào Database.',
    '• Tính năng \"Chờ\" (Wait): KHÔNG tạo thêm trạng thái mới mà chỉ cập nhật reviewAt và lưu lịch sử vào decisions, giúp hệ thống tinh gọn và toàn vẹn dữ liệu.'
]
ny = bot_y + 44
for n in notes:
    draw.text((bot_x + 24, ny), n, font=f_body, fill='#713F12')
    ny += 23

# Save image
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_08_state_machine.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_08_state_machine.png')
img.save(art_path, 'PNG')

print('Successfully saved image to:', out_path)
print('Artifact saved to:', art_path)

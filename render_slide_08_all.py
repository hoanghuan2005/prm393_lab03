import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
img = Image.new('RGB', (W, H), '#F8FAFC')
draw = ImageDraw.Draw(img)

# Fonts
font_dir = r'C:\Windows\Fonts'
f_title = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 34)
f_sub = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 18)
f_h1 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 20)
f_h2 = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 17)
f_body = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 14)
f_bold = ImageFont.truetype(os.path.join(font_dir, 'segoeuib.ttf'), 14)
f_small = ImageFont.truetype(os.path.join(font_dir, 'segoeui.ttf'), 12)
f_code = ImageFont.truetype(os.path.join(font_dir, 'calibri.ttf'), 13)

# Background Grid
grid_color = '#EDE8DF'
for x in range(0, W, 40):
    draw.line([(x, 0), (x, H)], fill=grid_color, width=1)
for y in range(0, H, 40):
    draw.line([(0, y), (W, y)], fill=grid_color, width=1)

# Header Badge
bx, by = 60, 32
badge_w, badge_h = 420, 50
draw.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=25, fill='#0F172A')
draw.text((bx + 30, by + 8), '08 · STATE MACHINES', font=f_title, fill='#FFFFFF')

# Right title
sub_txt = 'PRM393 · Bốn Máy Trạng Thái Cốt Lõi Trên Toàn Hệ Thống Firebase'
draw.text((W - 680, by + 14), sub_txt, font=f_sub, fill='#475569')

# Grid of 4 Quadrants:
# Left Column: x = 60 -> 940 (w = 880)
# Right Column: x = 980 -> 1860 (w = 880)
# Top Row: y = 100 -> 540 (h = 440)
# Bottom Row: y = 560 -> 930 (h = 370)
# Bottom Bar: y = 945 -> 1050 (h = 105)

# ==============================================================================
# 1. TOP-LEFT: WISHLIST ITEM STATE MACHINE (TRỌNG TÂM SỐ 1)
# ==============================================================================
b1_x, b1_y, b1_w, b1_h = 60, 100, 880, 440
draw.rounded_rectangle([b1_x, b1_y, b1_x + b1_w, b1_y + b1_h], radius=14, fill='#FFFFFF', outline='#3B82F6', width=2)

# Card Title
draw.rounded_rectangle([b1_x + 16, b1_y + 14, b1_x + 480, b1_y + 46], radius=8, fill='#EFF6FF', outline='#60A5FA', width=1)
draw.text((b1_x + 28, b1_y + 18), '1. MÓN HÀNG MONG MUỐN (wishlistItems.status)', font=f_h1, fill='#1D4ED8')

# Start dot
w_dot_x, w_dot_y = b1_x + 50, b1_y + 160
draw.ellipse([w_dot_x - 10, w_dot_y - 10, w_dot_x + 10, w_dot_y + 10], fill='#1E293B')

# Arrow -> CONSIDERING
draw.line([(w_dot_x + 10, w_dot_y), (w_dot_x + 65, w_dot_y)], fill='#475569', width=2)
draw.polygon([(w_dot_x + 65, w_dot_y), (w_dot_x + 57, w_dot_y - 5), (w_dot_x + 57, w_dot_y + 5)], fill='#475569')

# CONSIDERING Box
cw, ch = 230, 115
cx, cy = w_dot_x + 65, w_dot_y - 57
draw.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=10, fill='#EFF6FF', outline='#2563EB', width=2)
draw.text((cx + 16, cy + 12), 'CONSIDERING', font=f_h1, fill='#1E40AF')
draw.text((cx + 16, cy + 38), 'Đang hoãn mặc định +3d', font=f_bold, fill='#1E3A8A')
draw.text((cx + 16, cy + 62), '• Trừ Nhu cầu (hoãn = 0)', font=f_small, fill='#3B82F6')
draw.text((cx + 16, cy + 82), '• Bấm Chờ: đặt reviewAt', font=f_small, fill='#1D4ED8')

# Loop arrow Chờ
draw.arc([cx + 50, cy - 45, cx + 180, cy + 15], 180, 0, fill='#D97706', width=2)
draw.polygon([(cx + 180, cy), (cx + 175, cy - 8), (cx + 185, cy - 8)], fill='#D97706')
draw.text((cx + 35, cy - 48), 'Chờ [giữ status, hẹn ngày sale]', font=f_small, fill='#B45309')

# PURCHASED Box
pw, ph = 230, 115
px, py = cx + 330, cy
draw.rounded_rectangle([px, py, px + pw, py + ph], radius=10, fill='#F0FDF4', outline='#16A34A', width=2)
draw.text((px + 16, py + 12), 'PURCHASED', font=f_h1, fill='#15803D')
draw.text((px + 16, py + 38), 'Đã mua (Trạng thái cuối)', font=f_bold, fill='#14532D')
draw.text((px + 16, py + 62), '• Bắt buộc có purchaseId', font=f_small, fill='#16A34A')
draw.text((px + 16, py + 82), '• Ghi 1 batch cùng purchases', font=f_small, fill='#15803D')
# End dot
draw.ellipse([px + pw - 30, py + 14, px + pw - 12, py + 32], outline='#16A34A', width=2)
draw.ellipse([px + pw - 25, py + 19, px + pw - 17, py + 27], fill='#16A34A')

# Arrow CONSIDERING -> PURCHASED
draw.line([(cx + cw, w_dot_y), (px, w_dot_y)], fill='#16A34A', width=3)
draw.polygon([(px, w_dot_y), (px - 10, w_dot_y - 6), (px - 10, w_dot_y + 6)], fill='#16A34A')
draw.text((cx + cw + 25, w_dot_y - 30), 'Mua (BR-02)', font=f_bold, fill='#15803D')
draw.text((cx + cw + 10, w_dot_y - 10), '[1 batch + purchaseId]', font=f_code, fill='#166534')

# SKIPPED Box
sw, sh = 230, 95
sx, sy = cx, cy + 180
draw.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=10, fill='#F8FAFC', outline='#64748B', width=2)
draw.text((sx + 16, sy + 10), 'SKIPPED', font=f_h1, fill='#334155')
draw.text((sx + 16, sy + 34), 'Bỏ qua (Không mua)', font=f_bold, fill='#475569')
draw.text((sx + 16, sy + 58), 'Ghi log vào decisions', font=f_small, fill='#64748B')

# Down arrow (Bỏ qua)
draw.line([(cx + 60, cy + ch), (cx + 60, sy)], fill='#64748B', width=2)
draw.polygon([(cx + 60, sy), (cx + 55, sy - 8), (cx + 65, sy - 8)], fill='#64748B')
draw.text((cx - 80, cy + ch + 25), 'Bỏ qua (BR-04)', font=f_small, fill='#64748B')

# Up arrow (Hoàn tác 5s)
draw.line([(cx + 160, sy), (cx + 160, cy + ch)], fill='#0284C7', width=2)
draw.polygon([(cx + 160, cy + ch), (cx + 155, cy + ch + 8), (cx + 165, cy + ch + 8)], fill='#0284C7')
draw.text((cx + 175, cy + ch + 25), 'Hoàn tác ≤ 5s (BR-06)', font=f_small, fill='#0284C7')

# Guards note box inside
draw.rounded_rectangle([b1_x + 360, sy, b1_x + b1_w - 20, sy + sh], radius=8, fill='#FEF2F2', outline='#F87171', width=1)
draw.text((b1_x + 375, sy + 10), 'RÀNG BUỘC RULES (GUARDS):', font=f_bold, fill='#991B1B')
draw.text((b1_x + 375, sy + 32), '• purchased thiếu purchaseId → BỊ CHẶN (TC-07)', font=f_small, fill='#B91C1C')
draw.text((b1_x + 375, sy + 52), '• Sửa snapshot giá cũ → BỊ CẤM (chỉ append-only)', font=f_small, fill='#B91C1C')
draw.text((b1_x + 375, sy + 72), '• Status ngoài 3 giá trị chuẩn → TỪ CHỐI NGAY', font=f_small, fill='#B91C1C')


# ==============================================================================
# 2. TOP-RIGHT: CHROME EXTENSION QR SESSION (TIỆN ÍCH TRÌNH DUYỆT)
# ==============================================================================
b2_x, b2_y, b2_w, b2_h = 980, 100, 880, 440
draw.rounded_rectangle([b2_x, b2_y, b2_x + b2_w, b2_y + b2_h], radius=14, fill='#FFFFFF', outline='#9333EA', width=2)

draw.rounded_rectangle([b2_x + 16, b2_y + 14, b2_x + 520, b2_y + 46], radius=8, fill='#FAF5FF', outline='#C084FC', width=1)
draw.text((b2_x + 28, b2_y + 18), '2. PHIÊN GHÉP ĐÔI EXTENSION (extensionSessions)', font=f_h1, fill='#7E22CE')

# Start dot
e_dot_x, e_dot_y = b2_x + 50, b2_y + 160
draw.ellipse([e_dot_x - 10, e_dot_y - 10, e_dot_x + 10, e_dot_y + 10], fill='#1E293B')

# Arrow -> PENDING
draw.line([(e_dot_x + 10, e_dot_y), (e_dot_x + 65, e_dot_y)], fill='#475569', width=2)
draw.polygon([(e_dot_x + 65, e_dot_y), (e_dot_x + 57, e_dot_y - 5), (e_dot_x + 57, e_dot_y + 5)], fill='#475569')

# PENDING Box
ew, eh = 230, 115
ex, ey = e_dot_x + 65, e_dot_y - 57
draw.rounded_rectangle([ex, ey, ex + ew, ey + eh], radius=10, fill='#FFFBEB', outline='#D97706', width=2)
draw.text((ex + 16, ey + 12), 'PENDING', font=f_h1, fill='#B45309')
draw.text((ex + 16, ey + 38), 'Chờ quét mã QR', font=f_bold, fill='#78350F')
draw.text((ex + 16, ey + 62), '• Hiển thị mã QR 5 phút', font=f_small, fill='#92400E')
draw.text((ex + 16, ey + 82), '• expiresAt = +5 phút', font=f_code, fill='#64748B')

# APPROVED Box
apw, aph = 230, 115
apx, apy = ex + 330, ey
draw.rounded_rectangle([apx, apy, apx + apw, apy + aph], radius=10, fill='#F0FDF4', outline='#16A34A', width=2)
draw.text((apx + 16, apy + 12), 'APPROVED', font=f_h1, fill='#15803D')
draw.text((apx + 16, apy + 38), 'Đã liên kết thành công', font=f_bold, fill='#14532D')
draw.text((apx + 16, apy + 62), '• Extension bắt link Shopee', font=f_small, fill='#16A34A')
draw.text((apx + 16, apy + 82), '• Ghi thẳng vào Firestore', font=f_small, fill='#15803D')

# Arrow PENDING -> APPROVED
draw.line([(ex + ew, e_dot_y), (apx, e_dot_y)], fill='#16A34A', width=3)
draw.polygon([(apx, e_dot_y), (apx - 10, e_dot_y - 6), (apx - 10, e_dot_y + 6)], fill='#16A34A')
draw.text((ex + ew + 15, e_dot_y - 30), 'User quét QR', font=f_bold, fill='#15803D')
draw.text((ex + ew + 10, e_dot_y - 10), '[bấm Đồng ý trên app]', font=f_small, fill='#166534')

# EXPIRED Box (Bottom Left)
xpw, xph = 230, 95
xpx, xpy = ex, ey + 180
draw.rounded_rectangle([xpx, xpy, xpx + xpw, xpy + xph], radius=10, fill='#FEF2F2', outline='#DC2626', width=2)
draw.text((xpx + 16, xpy + 10), 'EXPIRED', font=f_h1, fill='#B91C1C')
draw.text((xpx + 16, xpy + 34), 'Hết hạn mã QR', font=f_bold, fill='#7F1D1D')
draw.text((xpx + 16, xpy + 58), 'Quá 5 phút không duyệt', font=f_small, fill='#991B1B')

# Down arrow PENDING -> EXPIRED
draw.line([(ex + 60, ey + eh), (ex + 60, xpy)], fill='#DC2626', width=2)
draw.polygon([(ex + 60, xpy), (ex + 55, xpy - 8), (ex + 65, xpy - 8)], fill='#DC2626')
draw.text((ex - 90, ey + eh + 25), 'Quá hạn 5p', font=f_small, fill='#DC2626')

# REVOKED Box (Bottom Right)
rvw, rvh = 230, 95
rvx, rvy = apx, xpy
draw.rounded_rectangle([rvx, rvy, rvx + rvw, rvy + rvh], radius=10, fill='#F8FAFC', outline='#64748B', width=2)
draw.text((rvx + 16, rvy + 10), 'REVOKED', font=f_h1, fill='#334155')
draw.text((rvx + 16, rvy + 34), 'Đã hủy liên kết', font=f_bold, fill='#475569')
draw.text((rvx + 16, rvy + 58), 'User hủy trong Cài đặt', font=f_small, fill='#64748B')

# Down arrow APPROVED -> REVOKED
draw.line([(apx + 115, apy + aph), (apx + 115, rvy)], fill='#64748B', width=2)
draw.polygon([(apx + 115, rvy), (apx + 110, rvy - 8), (apx + 120, rvy - 8)], fill='#64748B')
draw.text((apx + 130, apy + aph + 25), 'Hủy liên kết', font=f_small, fill='#64748B')


# ==============================================================================
# 3. BOTTOM-LEFT: SALE SUGGESTIONS (CROSS-ROLE FLOW)
# ==============================================================================
b3_x, b3_y, b3_w, b3_h = 60, 560, 880, 365
draw.rounded_rectangle([b3_x, b3_y, b3_x + b3_w, b3_y + b3_h], radius=14, fill='#FFFFFF', outline='#0D9488', width=2)

draw.rounded_rectangle([b3_x + 16, b3_y + 14, b3_x + 500, b3_y + 46], radius=8, fill='#F0FDFA', outline='#5EEAD4', width=1)
draw.text((b3_x + 28, b3_y + 18), '3. ĐỀ XUẤT ĐỢT SALE (saleSuggestions · Cross-role)', font=f_h1, fill='#0F766E')

# Start dot
sg_dot_x, sg_dot_y = b3_x + 50, b3_y + 175
draw.ellipse([sg_dot_x - 10, sg_dot_y - 10, sg_dot_x + 10, sg_dot_y + 10], fill='#1E293B')

# Arrow -> PENDING
draw.line([(sg_dot_x + 10, sg_dot_y), (sg_dot_x + 65, sg_dot_y)], fill='#475569', width=2)
draw.polygon([(sg_dot_x + 65, sg_dot_y), (sg_dot_x + 57, sg_dot_y - 5), (sg_dot_x + 57, sg_dot_y + 5)], fill='#475569')

# PENDING Box
gw, gh = 230, 110
gx, gy = sg_dot_x + 65, sg_dot_y - 55
draw.rounded_rectangle([gx, gy, gx + gw, gy + gh], radius=10, fill='#FFFBEB', outline='#D97706', width=2)
draw.text((gx + 16, gy + 12), 'PENDING', font=f_h1, fill='#B45309')
draw.text((gx + 16, gy + 38), 'Chờ Staff Web duyệt', font=f_bold, fill='#78350F')
draw.text((gx + 16, gy + 62), 'User mobile báo đợt sale', font=f_small, fill='#92400E')
draw.text((gx + 16, gy + 82), 'createdAt = request.time', font=f_code, fill='#64748B')

# APPROVED Box
agw, agh = 230, 85
agx, agy = gx + 330, gy - 25
draw.rounded_rectangle([agx, agy, agx + agw, agy + agh], radius=10, fill='#F0FDF4', outline='#16A34A', width=2)
draw.text((agx + 16, agy + 10), 'APPROVED', font=f_h1, fill='#15803D')
draw.text((agx + 16, agy + 34), 'Đã duyệt (Trạng thái cuối)', font=f_bold, fill='#14532D')
draw.text((agx + 16, agy + 58), 'Staff tạo saleEvent + Hộp thư', font=f_small, fill='#15803D')

# REJECTED Box
rgw, rgh = 230, 85
rgx, rgy = agx, gy + 80
draw.rounded_rectangle([rgx, rgy, rgx + rgw, rgy + rgh], radius=10, fill='#FEF2F2', outline='#DC2626', width=2)
draw.text((rgx + 16, rgy + 10), 'REJECTED', font=f_h1, fill='#B91C1C')
draw.text((rgx + 16, rgy + 34), 'Từ chối (Trạng thái cuối)', font=f_bold, fill='#7F1D1D')
draw.text((rgx + 16, rgy + 58), 'Bắt buộc nhập lý do 1–200 ký tự', font=f_small, fill='#991B1B')

# Arrows PENDING -> APPROVED / REJECTED
draw.line([(gx + gw, gy + 30), (agx, agy + 42)], fill='#16A34A', width=2)
draw.polygon([(agx, agy + 42), (agx - 10, agy + 37), (agx - 10, agy + 47)], fill='#16A34A')
draw.text((gx + gw + 20, gy - 10), 'Staff duyệt (1 batch)', font=f_small, fill='#15803D')

draw.line([(gx + gw, gy + 75), (rgx, rgy + 42)], fill='#DC2626', width=2)
draw.polygon([(rgx, rgy + 42), (rgx - 10, rgy + 37), (rgx - 10, rgy + 47)], fill='#DC2626')
draw.text((gx + gw + 20, rgy + 45), 'Staff từ chối (kèm lý do)', font=f_small, fill='#B91C1C')


# ==============================================================================
# 4. BOTTOM-RIGHT: SALE EVENTS (SỰ KIỆN SALE HỆ THỐNG DO STAFF QUẢN LÝ)
# ==============================================================================
b4_x, b4_y, b4_w, b4_h = 980, 560, 880, 365
draw.rounded_rectangle([b4_x, b4_y, b4_x + b4_w, b4_y + b4_h], radius=14, fill='#FFFFFF', outline='#EA580C', width=2)

draw.rounded_rectangle([b4_x + 16, b4_y + 14, b4_x + 500, b4_y + 46], radius=8, fill='#FFF7ED', outline='#FDBA74', width=1)
draw.text((b4_x + 28, b4_y + 18), '4. SỰ KIỆN SALE TOÀN HỆ THỐNG (saleEvents.status)', font=f_h1, fill='#C2410C')

# Start dot
se_dot_x, se_dot_y = b4_x + 40, b4_y + 185
draw.ellipse([se_dot_x - 10, se_dot_y - 10, se_dot_x + 10, se_dot_y + 10], fill='#1E293B')

# Arrow -> DRAFT
draw.line([(se_dot_x + 10, se_dot_y), (se_dot_x + 55, se_dot_y)], fill='#475569', width=2)
draw.polygon([(se_dot_x + 55, se_dot_y), (se_dot_x + 47, se_dot_y - 5), (se_dot_x + 47, se_dot_y + 5)], fill='#475569')

# DRAFT Box
dw, dh = 200, 105
dx, dy = se_dot_x + 55, se_dot_y - 52
draw.rounded_rectangle([dx, dy, dx + dw, dy + dh], radius=10, fill='#F8FAFC', outline='#64748B', width=2)
draw.text((dx + 16, dy + 10), 'DRAFT', font=f_h1, fill='#334155')
draw.text((dx + 16, dy + 34), 'Bản nháp', font=f_bold, fill='#475569')
draw.text((dx + 16, dy + 56), 'Staff soạn thảo', font=f_small, fill='#64748B')
draw.text((dx + 16, dy + 76), 'Chỉ Staff thấy', font=f_small, fill='#64748B')

# PUBLISHED Box
pbw, pbh = 220, 105
pbx, pby = dx + 260, dy
draw.rounded_rectangle([pbx, pby, pbx + pbw, pby + pbh], radius=10, fill='#F0FDF4', outline='#16A34A', width=2)
draw.text((pbx + 16, pby + 10), 'PUBLISHED', font=f_h1, fill='#15803D')
draw.text((pbx + 16, pby + 34), 'Công bố toàn sàn', font=f_bold, fill='#14532D')
draw.text((pbx + 16, pby + 56), 'App mobile đọc realtime', font=f_small, fill='#16A34A')
draw.text((pbx + 16, pby + 76), 'Đồng bộ Lịch sale', font=f_small, fill='#15803D')

# ARCHIVED Box
arw, arh = 210, 105
arx, ary = pbx + 280, dy
draw.rounded_rectangle([arx, ary, arx + arw, arx + arh], radius=10, fill='#F1F5F9', outline='#94A3B8', width=2)
draw.text((arx + 16, ary + 10), 'ARCHIVED', font=f_h1, fill='#475569')
draw.text((arx + 16, ary + 34), 'Lưu trữ (Đã xong)', font=f_bold, fill='#334155')
draw.text((arx + 16, ary + 56), 'Đợt sale đã kết thúc', font=f_small, fill='#64748B')
draw.text((arx + 16, ary + 76), 'Không thể khôi phục', font=f_small, fill='#64748B')

# Arrow DRAFT -> PUBLISHED
draw.line([(dx + dw, se_dot_y), (pbx, se_dot_y)], fill='#16A34A', width=2)
draw.polygon([(pbx, se_dot_y), (pbx - 8, se_dot_y - 5), (pbx - 8, se_dot_y + 5)], fill='#16A34A')
draw.text((dx + dw + 10, se_dot_y - 20), 'Staff xuất bản', font=f_small, fill='#15803D')

# Arrow PUBLISHED -> ARCHIVED
draw.line([(pbx + pbw, se_dot_y), (arx, se_dot_y)], fill='#475569', width=2)
draw.polygon([(arx, se_dot_y), (arx - 8, se_dot_y - 5), (arx - 8, se_dot_y + 5)], fill='#475569')
draw.text((pbx + pbw + 10, se_dot_y - 20), 'Hết đợt sale', font=f_small, fill='#475569')


# ==============================================================================
# BOTTOM STRIP: RULES & TEST PROOF
# ==============================================================================
bot_x, bot_y = 60, 945
bot_w, bot_h = 1800, 105
draw.rounded_rectangle([bot_x, bot_y, bot_x + bot_w, bot_y + bot_h], radius=10, fill='#FEF08A', outline='#EAB308', width=2)
draw.text((bot_x + 24, bot_y + 12), 'TOÀN VẸN DỮ LIỆU: MỌI CHUYỂN TRẠNG THÁI ĐỀU ĐƯỢC BẢO CHỨNG BẰNG SECURITY RULES & TEST EMULATOR', font=f_h2, fill='#854D0E')

b_bullets = [
    '• Trạng thái hợp lệ kiểm soát bởi firestore.rules: Bắt buộc purchaseId khi mua; bắt buộc reason 1-200 ký tự khi từ chối; QR hết hạn sau 5 phút.',
    '• Minh chứng kiểm thử thực nghiệm: 298/298 ca test Security Rules đạt 100% trên Firebase Local Emulator Suite (chạy lại 11/11/2026).'
]
by_txt = bot_y + 40
for b_line in b_bullets:
    draw.text((bot_x + 24, by_txt), b_line, font=f_body, fill='#713F12')
    by_txt += 24

# Save Image
out_path = r'd:\Ky_8_FA26\PRM393\PRM393_LAB3\slide_08_all_state_machines.png'
img.save(out_path, 'PNG')

art_dir = r'C:\Users\SUPPER LOQ\.gemini\antigravity\brain\a0f634f7-6136-413a-8af5-a2e31eb79a98'
art_path = os.path.join(art_dir, 'slide_08_all_state_machines.png')
img.save(art_path, 'PNG')

print('Successfully generated comprehensive state machines diagram to:', out_path)

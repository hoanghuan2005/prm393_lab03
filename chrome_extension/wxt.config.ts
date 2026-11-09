import { defineConfig } from 'wxt';
import { EXTENSION_KEY } from './lib/extensionKey';

// Hai bản build:
//  - `npm run build`      → MVP đúng Build Plan mục 6.5: chỉ activeTab + storage (+ sidePanel cho Decision Card).
//                           Đọc URL và tiêu đề tab khi người dùng bấm icon; tên/giá do người dùng nhập hoặc xác nhận.
//  - `npm run build:lab`  → thêm `scripting` cho thử nghiệm EX-10 (đọc tên/ảnh/giá, voucher hiển thị),
//                           mặc định TẮT trong Cài đặt; chỉ dùng nội bộ, chưa qua cổng 6.3.
// WXT_BACKEND=firebase (.env): liên kết bằng mã QR quét từ app (đăng nhập ẩn danh, không cần Google).
const isLab = process.argv.includes('lab');

export default defineConfig({
  modules: ['@wxt-dev/module-react'],
  outDirTemplate: isLab ? 'chrome-mv3-lab' : 'chrome-mv3',
  manifest: ({ mode }) => {
    const base = mode === 'lab' ? ['activeTab', 'storage', 'sidePanel', 'scripting', 'alarms', 'notifications'] : ['activeTab', 'storage', 'sidePanel'];
    return {
      name: mode === 'lab' ? 'Why I Buy? – Save & Decide (Lab EX-10)' : 'Why I Buy? – Save & Decide',
      description: 'Lưu món đang cân nhắc trên Shopee, xem lại trước khi mua. Bạn luôn là người quyết định.',
      key: EXTENSION_KEY,
      // Bản Firebase liên kết bằng QR + đăng nhập ẩn danh → không cần `identity`/oauth2 (chạy được cả Edge)
      permissions: base,
      // Bản Lab: cào voucher từ trang chủ cần chèn script vào các tab sản phẩm Shopee do extension tự mở
      ...(mode === 'lab' ? { host_permissions: ['https://shopee.vn/*', 'https://*.shopee.vn/*'] } : {}),
      action: { default_title: 'Why I Buy?' },
      icons: { 16: 'icon/16.png', 32: 'icon/32.png', 48: 'icon/48.png', 128: 'icon/128.png' },
    };
  },
});

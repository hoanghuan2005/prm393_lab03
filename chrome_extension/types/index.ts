// Hợp đồng dữ liệu theo handoff mục 9.1 (dùng chung app Flutter ↔ extension).
// Các trường đánh dấu [client] chỉ có ở extension (không gửi lên, hoặc gửi kèm để hiển thị).
export type WishlistStatus = 'considering' | 'purchased' | 'skipped';
export type SaveChannel = 'share' | 'extension' | 'manual';
// sale = giá trong một đợt giảm / mã giảm giá (kèm saleLabel); lưu song song với giá gốc 'single' như SteamDB.
export type PriceType = 'single' | 'range' | 'flash' | 'afterVoucher' | 'sale';
export type PriceSource = 'manual' | 'shareText' | 'ocr' | 'extensionPage' | 'affiliateApi' | 'demo';
export type Confirmation = 'unconfirmed' | 'userConfirmed';
export type DecisionChoice = 'buy' | 'wait' | 'skip' | 'undo';
export type SyncState = 'local' | 'pending' | 'synced' | 'error'; // [client]

export interface WishlistItem {
  id: string;                 // = hash(uid, productKey, modelId ?? variantLabel ?? url) → chống trùng
  title: string;              // bắt buộc, tối đa 60 ký tự
  url?: string;               // shopee.vn/product/<shopId>/<itemId>
  productKey?: string;        // shopee:<shopId>:<itemId>
  modelId?: string;           // phân loại (extension thường không biết modelId → dùng variantLabel)
  variantLabel?: string;      // [client] tên phân loại đang chọn, vd "Cá Chép"
  shopName?: string;          // tên shop bán, đọc từ trang (≤60)
  vouchers?: string[];        // chữ voucher đọc từ trang lúc lưu (≤20 mã, mỗi mã ≤240 ký tự); phân tích lại khi hiển thị
  vouchersAt?: string;        // lúc lưu voucher
  motive?: string;
  budgetGroupId?: string;
  priority: number;           // 1–5 sao, mặc định 3
  status: WishlistStatus;
  reviewAt?: string;          // "Chờ" chỉ đặt trường này, không đổi status
  saveChannel: SaveChannel;
  purchaseId?: string;        // bắt buộc khi status == purchased (do app ghi)
  revision: number;
  createdAt: string;
  updatedAt: string;
  // [client]
  originalUrl?: string;       // link đầy đủ để mở lại trang
  imageUrl?: string;
  buyIntentAt?: string;       // đã bấm "Mua · mở form trên điện thoại", chờ app ghi khoản mua
  saleEvent?: { label: string; startsAt: string; capturedAt: string };
  productRating?: number;      // số sao sản phẩm đọc từ trang (0–5)
  productRatingCount?: number; // số lượt đánh giá sản phẩm, đã đổi "2,3k" → 2300
  shopRating?: number;         // số sao của shop trong khung "Xem Shop" (0–5)
  syncState: SyncState;
  deleted?: boolean;          // tombstone
}

export interface PriceSnapshot {
  id: string; itemId: string;
  priceType: PriceType;
  amountVnd?: number;          // giá đơn hoặc Flash Sale; > 0
  minVnd?: number; maxVnd?: number; // khoảng giá
  originalVnd?: number;        // giá gạch ngang
  saleLabel?: string;          // tên đợt giảm hoặc mã giảm giá, vd "11.11", "Flash Sale", "Mã SALE50" (≤40)
  modelId?: string; variantLabel?: string;
  shopName?: string;           // shop và đánh giá lúc ghi giá này
  productRating?: number; productRatingCount?: number; shopRating?: number;
  source: PriceSource;
  confirmation: Confirmation;
  observedAt: string;
  syncState: SyncState;        // [client]
}

export interface Decision { id: string; itemId: string; choice: DecisionChoice; at: string; reviewAt?: string; syncState: SyncState; } // chỉ thêm, không sửa

export interface BudgetLine { groupId: string; month: string; limitVnd: number; spentVnd: number; dailyAvgVnd?: number; hasEnoughHistory?: boolean; }
export interface SaleDay { date: string; label: string; verified: boolean; }
export interface OwnedLine { budgetGroupId: string; name: string; count: number; }

export interface PairingState {
  linked: boolean; token?: string; accountName?: string; deviceLabel?: string; linkedAt?: string;
  revokedNotice?: boolean;    // EXT-8: vừa bị huỷ liên kết (401)
}

export interface Settings { syncOn: boolean; saveImages: boolean; hideLinkBanner: boolean; ex10AutoFill: boolean; ex10Vouchers: boolean; }

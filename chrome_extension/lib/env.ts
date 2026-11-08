// Chọn backend khi build (đặt trong .env, xem .env.example):
//  - WXT_BACKEND=firebase → đăng nhập Google + Firestore của app Why I Buy? (lib/firebaseApi.ts).
//  - WXT_API_BASE=<url>   → REST theo Build Plan mục 08 (HttpApi).
//  - không đặt gì         → chế độ DEMO (máy chủ giả trong extension, nhãn "Dữ liệu mô phỏng").
const env = ((import.meta as any).env ?? {}) as Record<string, string | undefined>;
export const API_BASE: string = env.WXT_API_BASE ?? '';
export const BACKEND: 'firebase' | 'http' | 'demo' = env.WXT_BACKEND === 'firebase' ? 'firebase' : API_BASE ? 'http' : 'demo';
export const IS_FIREBASE = BACKEND === 'firebase';
export const IS_DEMO = BACKEND === 'demo';
export const IS_LAB = env.MODE === 'lab';

// Chép ảnh sản phẩm (link CDN của Shopee, có thể hết hạn) sang Cloudinary trước khi lưu món.
// Upload kiểu unsigned: extension không giữ API secret. Lỗi/quá thời gian thì giữ link gốc,
// nên việc lưu món không bao giờ bị chặn. Ghi đè bằng WXT_CLOUDINARY_* trong .env nếu cần.
const env = ((import.meta as any).env ?? {}) as Record<string, string | undefined>;
export const CLOUDINARY_CLOUD = env.WXT_CLOUDINARY_CLOUD_NAME ?? 'de2g3a3hr';
export const CLOUDINARY_PRESET = env.WXT_CLOUDINARY_UPLOAD_PRESET ?? 'prm393neww';

export async function copyImageToCloudinary(url: string, timeoutMs = 10_000): Promise<string> {
  if (!/^https?:\/\//i.test(url) || /^https:\/\/res\.cloudinary\.com\//i.test(url)) return url;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const body = new FormData();
    body.append('file', url);
    body.append('upload_preset', CLOUDINARY_PRESET);
    const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`, { method: 'POST', body, signal: ctrl.signal });
    if (!res.ok) return url;
    const json = await res.json();
    return typeof json?.secure_url === 'string' && json.secure_url ? json.secure_url : url;
  } catch {
    return url;
  } finally {
    clearTimeout(timer);
  }
}

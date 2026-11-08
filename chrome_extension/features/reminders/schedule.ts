// Quy tắc thông báo (handoff, Push notification): không gửi 22:00–08:00 và 0:00; không emoji, không "!".
// Nhắc trước giờ mở bán LEAD_MIN phút; nếu rơi vào giờ yên lặng thì chuyển về 21:00 tối hôm trước / cùng ngày.
export const LEAD_MIN = 5;
export const QUIET_START = 22, QUIET_END = 8, EVENING = 21;

export function reminderTime(startsAtIso: string, now = new Date()): { fireAt: Date; shifted: boolean } | null {
  const start = new Date(startsAtIso);
  if (isNaN(start.getTime()) || start.getTime() <= now.getTime()) return null;
  const fire = new Date(start.getTime() - LEAD_MIN * 60_000);
  let shifted = false;
  const h = fire.getHours();
  if (h >= QUIET_START) { fire.setHours(EVENING, 0, 0, 0); shifted = true; }
  else if (h < QUIET_END) { fire.setDate(fire.getDate() - 1); fire.setHours(EVENING, 0, 0, 0); shifted = true; }
  if (fire.getTime() <= now.getTime()) {
    // đã quá giờ nhắc: nhắc ngay nếu chưa vào giờ yên lặng, nếu không thì bỏ
    const nh = now.getHours();
    if (nh >= QUIET_START || nh < QUIET_END) return null;
    return { fireAt: new Date(now.getTime() + 60_000), shifted: true };
  }
  return { fireAt: fire, shifted };
}

export const hhmm = (d: Date) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
export const dm = (d: Date) => `${d.getDate()}/${d.getMonth() + 1}`;
export const whenText = (d: Date) => `${hhmm(d)}, ${dm(d)}`;

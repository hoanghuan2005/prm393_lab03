// Lưu lịch nhắc và hẹn giờ bằng chrome.alarms (chỉ bản Lab có quyền alarms + notifications).
import { kv } from '../../lib/kv';
import { reminderTime } from './schedule';

export interface Reminder { id: string; itemId: string; title: string; url: string; startsAt: string; fireAt: string; sent?: boolean; suppressed?: boolean; }
const KEY = 'wib_reminders';
export const ALARM_PREFIX = 'wib-rem:';

export async function listReminders(): Promise<Reminder[]> { return (await kv()).get<Reminder[]>(KEY, []); }
export async function saveReminders(r: Reminder[]) { await (await kv()).set(KEY, r); }

function alarmsApi(): any { const b = (globalThis as any).browser ?? (globalThis as any).chrome; return b?.alarms; }

export async function scheduleFlashReminder(item: { id: string; title: string; originalUrl?: string; url?: string }, startsAt: string): Promise<Reminder | null> {
  const t = reminderTime(startsAt);
  if (!t) return null;
  const r: Reminder = { id: `${item.id}:${startsAt}`, itemId: item.id, title: item.title, url: item.originalUrl ?? item.url ?? 'https://shopee.vn', startsAt, fireAt: t.fireAt.toISOString() };
  const rows = (await listReminders()).filter((x) => x.itemId !== item.id || x.sent); // mỗi món một lịch nhắc đang chờ
  await saveReminders([...rows, r]);
  try { await alarmsApi()?.create(`${ALARM_PREFIX}${t.fireAt.getTime()}`, { when: t.fireAt.getTime() }); } catch { /* bản không có quyền alarms */ }
  return r;
}

export async function cancelReminders(itemId: string) {
  await saveReminders((await listReminders()).filter((x) => x.itemId !== itemId || x.sent));
}

export async function reminderFor(itemId: string) {
  return (await listReminders()).find((r) => r.itemId === itemId && !r.sent) ?? null;
}

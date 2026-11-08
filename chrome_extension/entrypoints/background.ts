// Gửi thông báo nhắc Flash Sale (chỉ chạy khi có quyền alarms + notifications, tức bản Lab).
// Quy tắc: gom nhiều món đến hạn cùng lúc vào MỘT thông báo; tối đa 3 thông báo/ngày; không emoji, không "!".
import { browser } from 'wxt/browser';
import { ALARM_PREFIX, listReminders, saveReminders } from '../features/reminders/reminders';
import { whenText } from '../features/reminders/schedule';
import { getItem } from '../features/items/repo';
import { kv } from '../lib/kv';
import { requestStop, resetStaleCrawl, startCrawl } from '../features/admin/homeCrawlWorker';

const DAILY_CAP = 3;

async function fireDue() {
  const now = Date.now();
  const rows = await listReminders();
  const due = rows.filter((r) => !r.sent && new Date(r.fireAt).getTime() <= now + 60_000);
  if (!due.length) return;
  const live: typeof due = [];
  for (const r of due) { const it = await getItem(r.itemId); if (it && it.status === 'considering') live.push(r); }
  const k = await kv();
  const today = new Date().toDateString();
  const count = await k.get<{ day: string; n: number }>('wib_notif_count', { day: today, n: 0 });
  const n = count.day === today ? count.n : 0;
  const ids = new Set(due.map((r) => r.id));
  if (live.length && n < DAILY_CAP) {
    const first = live[0];
    const title = live.length === 1 ? 'Flash Sale sắp bắt đầu' : `${live.length} món sắp vào Flash Sale`;
    const message = live.length === 1
      ? `${first.title} · bắt đầu lúc ${whenText(new Date(first.startsAt))}. Mở trang để xem giá.`
      : live.slice(0, 3).map((r) => `${r.title} · ${whenText(new Date(r.startsAt))}`).join('\n');
    const nid = `wib-${now}`;
    await browser.notifications.create(nid, { type: 'basic', iconUrl: browser.runtime.getURL('/icon/128.png'), title, message, priority: 0 });
    const map = await k.get<Record<string, string>>('wib_notif_map', {});
    map[nid] = live.length === 1 ? first.url : browser.runtime.getURL('/options.html#wishlist');
    await k.set('wib_notif_map', map);
    await k.set('wib_notif_count', { day: today, n: n + 1 });
    await saveReminders(rows.map((r) => (ids.has(r.id) ? { ...r, sent: true } : r)));
  } else {
    await saveReminders(rows.map((r) => (ids.has(r.id) ? { ...r, sent: true, suppressed: true } : r)));
  }
}

async function reschedule() {
  for (const r of await listReminders()) {
    if (r.sent) continue;
    const when = new Date(r.fireAt).getTime();
    await browser.alarms.create(`${ALARM_PREFIX}${when}`, { when: Math.max(when, Date.now() + 5_000) });
  }
}

export default defineBackground(() => {
  if (!(browser as any).alarms || !(browser as any).notifications) return; // bản MVP: không có quyền, không làm gì
  // Cào voucher từ trang chủ (Admin, bản Lab có `scripting`): popup gửi lệnh, background chạy để popup đóng vẫn tiếp tục
  if ((browser as any).scripting) {
    resetStaleCrawl();
    browser.runtime.onMessage.addListener((msg: any) => {
      if (msg?.type === 'voucherCrawl:start' && typeof msg.tabId === 'number' && typeof msg.ownerUid === 'string') startCrawl(msg.tabId, msg.ownerUid);
      else if (msg?.type === 'voucherCrawl:stop') requestStop();
    });
  }
  browser.alarms.onAlarm.addListener((a) => { if (a.name.startsWith(ALARM_PREFIX)) fireDue(); });
  browser.notifications.onClicked.addListener(async (nid) => {
    const k = await kv();
    const map = await k.get<Record<string, string>>('wib_notif_map', {});
    if (map[nid]) await browser.tabs.create({ url: map[nid] });
    browser.notifications.clear(nid);
  });
  browser.runtime.onStartup.addListener(() => { reschedule(); fireDue(); });
  browser.runtime.onInstalled.addListener(() => { reschedule(); });
});

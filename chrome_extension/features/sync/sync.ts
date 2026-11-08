// Đồng bộ hai chiều (EX-07): đẩy thay đổi chưa đồng bộ (Idempotency-Key), rồi kéo thay đổi từ server.
// Lỗi mạng / 5xx / 429 → thử lại giãn dần 1 s, 2 s, 4 s… tối đa 5 phút; 401 → về chưa liên kết (E06).
import { allDecisions, allItems, allPrices, dropSyncedExcept, getSettings, mergeDecisions, mergePrices, replaceItem, setSyncState } from '../items/repo';
import { AuthError, isRetryable } from '../../lib/api';
import { kv } from '../../lib/kv';
import { fmtTime, stableHash } from '../../lib/format';

const STATE = 'wib_sync_state';
export interface SyncMeta { attempt: number; nextRetryAt?: string; lastError?: string; cursor?: string; lastSyncedAt?: string; conflict?: string; }
export const getSyncMeta = async () => (await kv()).get<SyncMeta>(STATE, { attempt: 0 });
const setMeta = async (m: SyncMeta) => (await kv()).set(STATE, m);
// Chữ cho banner khi đồng bộ đang lỗi (đã liên kết, bật đồng bộ, có lần thử thất bại); không lỗi → null
export function syncProblemText(meta: SyncMeta, linked: boolean, syncOn: boolean): string | null {
  if (!linked || !syncOn || meta.attempt <= 0) return null;
  return `Chưa đồng bộ được, sẽ thử lại${meta.nextRetryAt ? ` lúc ${fmtTime(meta.nextRetryAt)}` : ' khi bạn mở lại extension'}. Món vẫn được giữ trên máy này.`;
}
export const backoffMs = (attempt: number) => Math.min(1000 * 2 ** Math.max(0, attempt - 1), 5 * 60_000);

export interface SyncResult {
  skipped: 'not-linked' | 'sync-off' | 'offline' | 'backoff' | null;
  pushedItems: number; pulled: number; failed: boolean; revoked?: boolean; nextRetryAt?: string; conflict?: string;
}
const none = (skipped: SyncResult['skipped'], extra: Partial<SyncResult> = {}): SyncResult => ({ skipped, pushedItems: 0, pulled: 0, failed: false, ...extra });

export async function syncNow(opts: { force?: boolean; online?: boolean } = {}): Promise<SyncResult> {
  const { getPairing, api, handleRevoked } = await import('../pairing/pairing');
  const p = await getPairing();
  if (!p.linked || !p.token) return none('not-linked');
  if (!(await getSettings()).syncOn) return none('sync-off');
  const meta = await getSyncMeta();
  const [items, prices, decisions] = await Promise.all([allItems(), allPrices(), allDecisions()]);
  const todo = { items: items.filter((i) => i.syncState !== 'synced'), prices: prices.filter((x) => x.syncState !== 'synced'), decisions: decisions.filter((d) => d.syncState !== 'synced') };
  const online = opts.online ?? globalThis.navigator?.onLine ?? true;
  if (!online) {
    await setSyncState('items', todo.items.map((i) => i.id), 'pending');
    await setSyncState('prices', todo.prices.map((i) => i.id), 'pending');
    await setSyncState('decisions', todo.decisions.map((i) => i.id), 'pending');
    return none('offline');
  }
  if (!opts.force && meta.nextRetryAt && Date.now() < new Date(meta.nextRetryAt).getTime()) return none('backoff', { nextRetryAt: meta.nextRetryAt });
  try {
    if (todo.items.length || todo.prices.length || todo.decisions.length) {
      const opId = `op_${stableHash([...todo.items.map((i) => `${i.id}:${i.revision}`), ...todo.prices.map((x) => x.id), ...todo.decisions.map((d) => d.id)].join(','))}`;
      await api().push(p.token, todo, opId);
      await setSyncState('items', todo.items.map((i) => i.id), 'synced');
      await setSyncState('prices', todo.prices.map((i) => i.id), 'synced');
      await setSyncState('decisions', todo.decisions.map((i) => i.id), 'synced');
    }
    // Kéo về: bản server mới hơn (revision lớn hơn) thắng; giữ trường chỉ có ở máy (link gốc, ảnh, Flash Sale)
    const pull = await api().pull(p.token, meta.cursor);
    const local = new Map((await allItems()).map((i) => [i.id, i]));
    let conflict: string | undefined;
    for (const s of pull.items) {
      const l = local.get(s.id);
      if (l && l.revision > s.revision) continue;
      if (l && l.syncState !== 'synced' && s.revision > l.revision) conflict = 'Món đã được cập nhật trên thiết bị khác.'; // E11
      await replaceItem({ ...s, originalUrl: l?.originalUrl ?? s.originalUrl, imageUrl: l?.imageUrl ?? s.imageUrl, saleEvent: l?.saleEvent ?? s.saleEvent,
        productRating: l?.productRating ?? s.productRating, productRatingCount: l?.productRatingCount ?? s.productRatingCount, shopRating: l?.shopRating ?? s.shopRating, syncState: 'synced' });
    }
    await mergePrices(pull.prices);
    await mergeDecisions(pull.decisions);
    if (pull.allIds) await dropSyncedExcept(new Set(pull.allIds)); // món đã bị xoá trên app
    await setMeta({ attempt: 0, cursor: pull.cursor, lastSyncedAt: new Date().toISOString(), conflict });
    return { skipped: null, pushedItems: todo.items.length, pulled: pull.items.length, failed: false, conflict };
  } catch (e) {
    if (e instanceof AuthError) { await handleRevoked(); return none(null, { failed: true, revoked: true }); }
    const attempt = meta.attempt + 1;
    const nextRetryAt = isRetryable(e) ? new Date(Date.now() + backoffMs(attempt)).toISOString() : undefined;
    await setSyncState('items', todo.items.map((i) => i.id), 'error');
    await setMeta({ ...meta, attempt, nextRetryAt, lastError: String((e as Error).message ?? e) });
    return none(null, { failed: true, nextRetryAt });
  }
}

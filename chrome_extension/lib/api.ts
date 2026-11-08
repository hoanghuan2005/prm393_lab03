// Hợp đồng client–server cho extension (handoff X4/X2a, Build Plan 08). Backend chưa chốt (Firebase hay REST):
// HttpApi là bản REST ĐỀ XUẤT; MockApi là máy chủ giả trong extension để demo (nhãn "Dữ liệu mô phỏng").
import type { BudgetLine, Decision, OwnedLine, PriceSnapshot, SaleDay, WishlistItem } from '../types';
import { kv } from './kv';
import { uuid } from './format';

// reason 'signin': bản Firebase, đăng nhập Google bị huỷ hoặc lỗi ([message] để hiện cho người dùng).
export type PairStart = { ok: true; pairingId: string; expiresAt: string } | { ok: false; reason: 'invalid' | 'locked' | 'network' | 'signin'; attemptsLeft?: number; message?: string };
export type PairStatus = { state: 'pending' } | { state: 'approved'; token: string; accountName: string } | { state: 'rejected' } | { state: 'expired' };
export interface SyncBundle { items: WishlistItem[]; prices: PriceSnapshot[]; decisions: Decision[]; }
// allIds: mọi id món còn trên server (bản Firebase). App xoá hẳn document nên máy dựa vào đây để xoá theo.
export interface PullResult extends SyncBundle { cursor: string; allIds?: string[]; }

export class AuthError extends Error { constructor() { super('401'); } }
export class HttpError extends Error { constructor(public status: number) { super(String(status)); } }
// Server từ chối ghi/đọc dữ liệu nhưng phiên vẫn còn hiệu lực: không huỷ liên kết, không thử lại giãn dần.
export class RejectedError extends Error { constructor() { super('rejected'); } }
export const isRetryable = (e: unknown) => e instanceof TypeError || (e instanceof HttpError && (e.status >= 500 || e.status === 429));

export interface Api {
  pairStart(code: string, deviceLabel: string): Promise<PairStart>;
  pairStatus(pairingId: string): Promise<PairStatus>;
  revoke(token: string): Promise<void>;
  push(token: string, body: SyncBundle, opId: string): Promise<void>;
  pull(token: string, cursor?: string): Promise<PullResult>;
  budgets(token: string): Promise<BudgetLine[]>;
  saleCalendar(token: string): Promise<SaleDay[]>;
  owned(token: string): Promise<OwnedLine[]>;
}

export class HttpApi implements Api {
  constructor(private base: string) {}
  private async req(path: string, o: { method?: string; token?: string; idem?: string; body?: unknown } = {}) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (o.token) headers.Authorization = `Bearer ${o.token}`;
    if (o.idem) headers['Idempotency-Key'] = o.idem;
    const res = await fetch(this.base.replace(/\/$/, '') + path, { method: o.method ?? 'GET', headers, body: o.body ? JSON.stringify(o.body) : undefined });
    if (res.status === 401) throw new AuthError();
    if (!res.ok) throw new HttpError(res.status);
    return res.status === 204 ? null : res.json();
  }
  async pairStart(code: string, deviceLabel: string): Promise<PairStart> {
    try { const j = await this.req('/v1/extension/pair', { method: 'POST', body: { code, deviceLabel } }); return { ok: true, pairingId: j.id, expiresAt: j.expiresAt }; }
    catch (e) {
      if (e instanceof HttpError && (e.status === 400 || e.status === 403 || e.status === 423)) return { ok: false, reason: e.status === 423 ? 'locked' : 'invalid' };
      return { ok: false, reason: 'network' };
    }
  }
  async pairStatus(id: string) { return (await this.req(`/v1/extension/pair/${encodeURIComponent(id)}`)) as PairStatus; }
  async revoke(token: string) { await this.req('/v1/extension/sessions/current', { method: 'DELETE', token }); }
  async push(token: string, body: SyncBundle, opId: string) { await this.req('/v1/sync/push', { method: 'POST', token, idem: opId, body }); }
  async pull(token: string, cursor?: string) { return (await this.req(`/v1/sync/pull${cursor ? `?since=${encodeURIComponent(cursor)}` : ''}`, { token })) as PullResult; }
  async budgets(token: string) { return (await this.req('/v1/budgets/summary', { token })) as BudgetLine[]; }
  async saleCalendar(token: string) { return (await this.req('/v1/sale-calendar', { token })) as SaleDay[]; }
  async owned(token: string) { return (await this.req('/v1/owned-items/summary', { token })) as OwnedLine[]; }
}

// ---------------- Máy chủ giả (demo) ----------------
export const DEMO_CODE = '482913';   // mã mẫu ở Figma màn 25
export const PAIR_TTL_MS = 5 * 60_000;
interface Pairing { id: string; state: 'pending' | 'approved' | 'rejected'; expiresAt: string; deviceLabel: string; token?: string; }
interface MockState {
  attemptsLeft: number; locked: boolean; pairings: Record<string, Pairing>; tokens: string[];
  items: Record<string, WishlistItem>; prices: Record<string, PriceSnapshot>; decisions: Record<string, Decision>;
  seq: number; changed: Record<string, number>; failNext: number[]; seenOps: string[];
}
const MOCK = 'wib_mock_server';
const empty = (): MockState => ({ attemptsLeft: 5, locked: false, pairings: {}, tokens: [], items: {}, prices: {}, decisions: {}, seq: 0, changed: {}, failNext: [], seenOps: [] });

export class MockApi implements Api {
  async st(): Promise<MockState> { return { ...empty(), ...(await (await kv()).get<Partial<MockState>>(MOCK, {})) }; }
  async put(s: MockState) { await (await kv()).set(MOCK, s); }
  private async auth(token: string) {
    const s = await this.st();
    if (s.failNext.length) { const code = s.failNext.shift()!; await this.put(s); if (code === 0) throw new TypeError('network'); throw new HttpError(code); }
    if (!s.tokens.includes(token)) throw new AuthError();
    return s;
  }
  async pairStart(code: string, deviceLabel: string): Promise<PairStart> {
    const s = await this.st();
    if (s.locked) return { ok: false, reason: 'locked', attemptsLeft: 0 };
    if (code !== DEMO_CODE) {
      const left = s.attemptsLeft - 1;
      await this.put({ ...s, attemptsLeft: Math.max(0, left), locked: left <= 0 });
      return left <= 0 ? { ok: false, reason: 'locked', attemptsLeft: 0 } : { ok: false, reason: 'invalid', attemptsLeft: left };
    }
    const id = `pair-${uuid()}`;
    const expiresAt = new Date(Date.now() + PAIR_TTL_MS).toISOString();
    s.pairings[id] = { id, state: 'pending', expiresAt, deviceLabel };
    await this.put({ ...s, attemptsLeft: 5 });
    return { ok: true, pairingId: id, expiresAt };
  }
  async pairStatus(id: string): Promise<PairStatus> {
    const s = await this.st();
    const p = s.pairings[id];
    if (!p) return { state: 'expired' };
    if (p.state === 'approved' && p.token) return { state: 'approved', token: p.token, accountName: 'Tâm' };
    if (p.state === 'rejected') return { state: 'rejected' };
    if (Date.now() > new Date(p.expiresAt).getTime()) return { state: 'expired' };
    return { state: 'pending' };
  }
  // Giả lập thao tác trên điện thoại ở màn 25f (chỉ dùng trong demo)
  async phone(pairingId: string, action: 'approve' | 'reject') {
    const s = await this.st();
    const p = s.pairings[pairingId];
    if (!p) return;
    if (action === 'approve') { p.state = 'approved'; p.token = `demo-${uuid()}`; s.tokens.push(p.token); } else p.state = 'rejected';
    await this.put(s);
  }
  async revoke(token: string) { const s = await this.st(); await this.put({ ...s, tokens: s.tokens.filter((t) => t !== token) }); }
  async revokeAll() { const s = await this.st(); await this.put({ ...s, tokens: [] }); } // giả lập "Huỷ liên kết" từ app → 401
  async push(token: string, body: SyncBundle, opId: string) {
    const s = await this.auth(token);
    if (s.seenOps.includes(opId)) return; // Idempotency-Key: gửi lại không ghi hai lần
    const bump = (id: string) => { s.seq++; s.changed[id] = s.seq; };
    for (const it of body.items) { const prev = s.items[it.id]; if (!prev || prev.revision <= it.revision) { s.items[it.id] = { ...it, syncState: 'synced' }; bump(it.id); } }
    for (const p of body.prices) if (!s.prices[p.id]) { s.prices[p.id] = { ...p, syncState: 'synced' }; bump(p.itemId); }
    for (const d of body.decisions) if (!s.decisions[d.id]) { s.decisions[d.id] = { ...d, syncState: 'synced' }; bump(d.itemId); }
    s.seenOps = [...s.seenOps.slice(-200), opId];
    await this.put(s);
  }
  async pull(token: string, cursor?: string): Promise<PullResult> {
    const s = await this.auth(token);
    const since = cursor ? parseInt(cursor, 10) : 0;
    const ids = new Set(Object.entries(s.changed).filter(([, n]) => n > since).map(([id]) => id));
    return {
      items: Object.values(s.items).filter((i) => ids.has(i.id)),
      prices: Object.values(s.prices).filter((p) => ids.has(p.itemId)),
      decisions: Object.values(s.decisions).filter((d) => ids.has(d.itemId)),
      cursor: String(s.seq),
    };
  }
  // Giả lập app Android ghi khoản mua từ ý định "Mua": Purchase + Decision(buy) + status purchased (một WriteBatch)
  async appRecordsPurchase(itemId: string) {
    const s = await this.st();
    const it = s.items[itemId];
    if (!it) return false;
    const now = new Date().toISOString();
    s.items[itemId] = { ...it, status: 'purchased', purchaseId: `p_${uuid()}`, buyIntentAt: undefined, revision: it.revision + 1, updatedAt: now };
    const d: Decision = { id: uuid(), itemId, choice: 'buy', at: now, syncState: 'synced' };
    s.decisions[d.id] = d;
    s.seq++; s.changed[itemId] = s.seq;
    await this.put(s);
    return true;
  }
  async failNext(codes: number[]) { const s = await this.st(); await this.put({ ...s, failNext: codes }); }
  async budgets(token: string): Promise<BudgetLine[]> {
    await this.auth(token);
    const month = new Date().toISOString().slice(0, 7);
    // Khớp Figma 31c: Công nghệ 1.000.000, đã chi 40.000, chưa đủ 30 ngày lịch sử → dự phòng 0 → khả dụng 864.000.
    return [
      { groupId: 'cong-nghe', month, limitVnd: 1_000_000, spentVnd: 40_000, hasEnoughHistory: false },
      { groupId: 'thoi-trang', month, limitVnd: 800_000, spentVnd: 310_000, hasEnoughHistory: false },
      { groupId: 'an-uong', month, limitVnd: 2_500_000, spentVnd: 1_450_000, hasEnoughHistory: false },
      { groupId: 'lam-dep', month, limitVnd: 600_000, spentVnd: 120_000, hasEnoughHistory: false },
    ];
  }
  async saleCalendar(token: string): Promise<SaleDay[]> {
    await this.auth(token);
    const y = new Date().getFullYear();
    return [{ date: `${y}-11-11T00:00:00`, label: '11.11', verified: true }, { date: `${y}-12-12T00:00:00`, label: '12.12', verified: true }, { date: `${y + 1}-01-01T00:00:00`, label: '1.1', verified: true }];
  }
  async owned(token: string): Promise<OwnedLine[]> { await this.auth(token); return [{ budgetGroupId: 'cong-nghe', name: 'tai nghe', count: 1 }]; }
  async resetLock() { const s = await this.st(); await this.put({ ...s, attemptsLeft: 5, locked: false }); }
}

// Liên kết thiết bị (handoff X4): POST mã → CHỜ DUYỆT TRÊN ĐIỆN THOẠI (25f) → nhận token một lần.
// Bản Firebase: đăng nhập Google thay cho mã, vẫn chờ duyệt trên điện thoại (lib/firebaseApi.ts).
import type { PairingState } from '../../types';
import { kv } from '../../lib/kv';
import { API_BASE, IS_FIREBASE } from '../../lib/env';
import { HttpApi, MockApi, type Api, type PairStart, type PairStatus } from '../../lib/api';
import { FirestoreApi } from '../../lib/firebaseApi';
import { deviceLabel } from '../../lib/format';
import { clearLocalData, markAll } from '../items/repo';

const PAIR = 'wib_pairing';
let apiSingleton: Api | null = null;
export function api(): Api { return (apiSingleton ??= IS_FIREBASE ? new FirestoreApi() : API_BASE ? new HttpApi(API_BASE) : new MockApi()); }
export function setApi(a: Api) { apiSingleton = a; }
export const mockApi = () => (api() instanceof MockApi ? (api() as MockApi) : null);

export async function getPairing(): Promise<PairingState> { return (await kv()).get<PairingState>(PAIR, { linked: false }); }
async function setPairing(p: PairingState) { await (await kv()).set(PAIR, p); }

export async function startPairing(code: string): Promise<PairStart> {
  if (!IS_FIREBASE && !/^\d{6}$/.test(code)) return { ok: false, reason: 'invalid' };
  return api().pairStart(code, deviceLabel());
}

export async function checkPairing(pairingId: string): Promise<PairStatus & { synced?: number }> {
  const st = await api().pairStatus(pairingId);
  if (st.state !== 'approved') return st;
  await setPairing({ linked: true, token: st.token, accountName: st.accountName, deviceLabel: deviceLabel(), linkedAt: new Date().toISOString() });
  await markAll('pending');                       // hoà giải: đẩy món trên máy lên tài khoản (id ổn định → không trùng)
  const { syncNow } = await import('../sync/sync');
  const r = await syncNow({ force: true });
  return { ...st, synced: r.pushedItems };
}

export async function unpair(opts: { keepLocal: boolean }) {
  const p = await getPairing();
  if (p.token) { try { await api().revoke(p.token); } catch { /* vẫn xoá phiên phía máy */ } }
  await setPairing({ linked: false });
  if (opts.keepLocal) await markAll('local', false); else await clearLocalData();
}

// E06 / EXT-8: token bị thu hồi (401) → về chưa liên kết, giữ dữ liệu chưa đồng bộ, hiện thông báo một lần.
export async function handleRevoked() { await setPairing({ linked: false, revokedNotice: true }); await markAll('local', false); }
export async function clearRevokedNotice() { const p = await getPairing(); if (p.revokedNotice) await setPairing({ ...p, revokedNotice: false }); }

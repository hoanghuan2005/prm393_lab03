// Api trên Firebase (WXT_BACKEND=firebase): extension đọc/ghi thẳng users/{uid}/… trong Firestore,
// không cần máy chủ riêng (gói Spark).
// Liên kết bằng QR: extension đăng nhập ẩn danh → tạo extensionPairings/{pairingId} 'pending' → hiện QR
// chứa pairingId → app quét, chọn Đồng ý → ghi users/{uid}/extensionSessions/{uid ẩn danh} 'approved'
// và extensionPairings/{pairingId} 'approved' + ownerUid. App huỷ liên kết = 'revoked' → AuthError (E06 / EXT-8).
// token là "<uid tài khoản>:<uid ẩn danh của extension>" (sid = uid ẩn danh).
import type { Api, PairStart, PairStatus, PullResult, SyncBundle } from './api';
import { AuthError, HttpError, PAIR_TTL_MS, RejectedError } from './api';
import type { BudgetLine, OwnedLine, PriceSnapshot, SaleDay } from '../types';
import {
  budgetLines, cooldownFor, decisionToDoc, docToDecision, docToItem, docToPrice, docToPurchase,
  itemToDoc, latestPriceOf, ownedLines, parseSaleCalendar, priceToDoc, toIso, type PurchaseRow,
} from './firebaseMap';

const fb = () => import('./firebase');
const fs = () => import('firebase/firestore');
const DEFAULT_COOLING_OFF_DAYS = 3; // = Remote Config cooling_off_days mặc định của app
const SESSION_CHECK_MS = 30_000;

// Lỗi Firestore → lỗi mà sync.ts hiểu: hết quyền → AuthError; mất mạng → TypeError (thử lại giãn dần).
// permission-denied chỉ là hết quyền khi đọc phiên/mã liên kết (session = true); khi ghi dữ liệu → RejectedError.
function mapError(e: unknown, session = false): never {
  if (e instanceof AuthError || e instanceof HttpError || e instanceof RejectedError || e instanceof TypeError) throw e;
  const code = String((e as any)?.code ?? '');
  if (code === 'unauthenticated' || (session && code === 'permission-denied')) throw new AuthError();
  if (code === 'permission-denied') throw new RejectedError();
  if (code === 'unavailable' || code === 'deadline-exceeded') throw new TypeError('network');
  if (code === 'resource-exhausted') throw new HttpError(429);
  if (code === 'aborted' || code === 'internal' || code === 'unknown') throw new HttpError(503);
  throw new HttpError(400);
}

const split = (token: string) => {
  const i = token.indexOf(':');
  return i > 0 ? { uid: token.slice(0, i), sid: token.slice(i + 1) } : null;
};

export class FirestoreApi implements Api {
  private checked: { token: string; at: number } | null = null;

  // Phiên còn hiệu lực: đúng người đăng nhập và app chưa huỷ liên kết.
  private async session(token: string) {
    const ids = split(token);
    if (!ids) throw new AuthError();
    const { currentUser, db } = await fb();
    const user = await currentUser();
    if (!user || user.uid !== ids.sid) throw new AuthError();
    if (this.checked?.token === token && Date.now() - this.checked.at < SESSION_CHECK_MS) return { ...ids, db };
    const { doc, getDoc } = await fs();
    const snap = await getDoc(doc(db, 'users', ids.uid, 'extensionSessions', ids.sid)).catch((e) => mapError(e, true));
    if (!snap.exists() || snap.data().status !== 'approved') { this.checked = null; throw new AuthError(); }
    this.checked = { token, at: Date.now() };
    return { ...ids, db };
  }

  // permission-denied khi đọc/ghi dữ liệu: kiểm tra lại phiên (bị huỷ → AuthError), còn phiên thì là RejectedError.
  private async denied(token: string, e: unknown): Promise<never> {
    if (String((e as any)?.code ?? '') === 'permission-denied') { this.checked = null; await this.session(token); }
    return mapError(e);
  }

  async pairStart(_code: string, deviceLabel: string): Promise<PairStart> {
    let user;
    try {
      user = await (await fb()).signInAnon();
    } catch (e) {
      console.error('[WIB] signInAnon failed', e);
      const code = String((e as any)?.code ?? '');
      if (code === 'auth/network-request-failed') return { ok: false, reason: 'network' };
      // auth/admin-restricted-operation = chưa bật Anonymous trong Firebase Console → Authentication
      return { ok: false, reason: 'signin', message: code || (e as Error)?.message };
    }
    try {
      const { db } = await fb();
      const { addDoc, collection, serverTimestamp } = await fs();
      const ref = await addDoc(collection(db, 'extensionPairings'), {
        anonUid: user.uid, deviceLabel: deviceLabel.slice(0, 60), status: 'pending', createdAt: serverTimestamp(),
      });
      return { ok: true, pairingId: ref.id, expiresAt: new Date(Date.now() + PAIR_TTL_MS).toISOString() };
    } catch (e) {
      console.error('[WIB] create extensionPairing failed', e);
      const code = String((e as any)?.code ?? '');
      // Chỉ lỗi mạng thật mới báo "Không kết nối được"; còn lại (vd permission-denied khi rules chưa deploy) hiện mã lỗi
      if (code === 'unavailable' || code === 'deadline-exceeded') return { ok: false, reason: 'network' };
      return { ok: false, reason: 'signin', message: `${code || 'error'}: ${(e as Error)?.message ?? e}` };
    }
  }

  async pairStatus(pairingId: string): Promise<PairStatus> {
    if (!pairingId || pairingId.includes('/')) return { state: 'expired' };
    const { db, auth } = await fb();
    const { doc, getDoc } = await fs();
    const snap = await getDoc(doc(db, 'extensionPairings', pairingId)).catch((e) => mapError(e, true));
    if (!snap.exists()) return { state: 'expired' };
    const d = snap.data();
    const me = auth.currentUser?.uid;
    if (d.status === 'approved' && typeof d.ownerUid === 'string' && me && d.anonUid === me) {
      return { state: 'approved', token: `${d.ownerUid}:${me}`, accountName: typeof d.ownerName === 'string' && d.ownerName ? d.ownerName : 'bạn' };
    }
    if (d.status === 'rejected' || d.status === 'revoked') return { state: 'rejected' };
    const created = Date.parse(toIso(d.createdAt) ?? '') || Date.now();
    return Date.now() - created > PAIR_TTL_MS ? { state: 'expired' } : { state: 'pending' };
  }

  async revoke(token: string) {
    const ids = split(token);
    const { db, signOut } = await fb();
    if (ids) {
      const { doc, updateDoc, serverTimestamp } = await fs();
      await updateDoc(doc(db, 'users', ids.uid, 'extensionSessions', ids.sid), { status: 'revoked', updatedAt: serverTimestamp() }).catch(() => {});
    }
    this.checked = null;
    await signOut();
  }

  async push(token: string, body: SyncBundle, _opId: string) {
    // Id ổn định (w_…, uuid) nên gửi lại không ghi trùng; Idempotency-Key không cần với Firestore.
    const { uid, db } = await this.session(token);
    const { doc, getDoc, getDocs, collection, writeBatch, serverTimestamp, Timestamp } = await fs();
    try {
      const user = await getDoc(doc(db, 'users', uid));
      const days = user.get('settings.coolingOffDays');
      const coolingOffDays = typeof days === 'number' && days >= 0 ? days : DEFAULT_COOLING_OFF_DAYS;
      const batch = writeBatch(db);
      const itemsOnServer = new Map<string, Record<string, any> | null>();

      for (const it of body.items) {
        const ref = doc(db, 'users', uid, 'wishlistItems', it.id);
        const snap = await getDoc(ref);
        const server = snap.exists() ? snap.data() : null;
        if (it.deleted) {
          if (server) {
            for (const p of (await getDocs(collection(ref, 'priceSnapshots'))).docs) batch.delete(p.ref);
            batch.delete(ref);
          }
          itemsOnServer.set(it.id, null);
          continue;
        }
        // Bản trên server sửa sau lần sửa trên máy → server thắng, lần kéo về sẽ cập nhật máy.
        const serverUpdated = Date.parse(toIso(server?.updatedAt) ?? '') || 0;
        if (server && serverUpdated > Date.parse(it.updatedAt)) { itemsOnServer.set(it.id, server); continue; }
        const data: Record<string, unknown> = { ...itemToDoc(it), updatedAt: serverTimestamp() };
        if (server?.status === 'purchased') { delete data.status; delete data.buyIntentAt; } // chỉ app đổi được món đã mua
        if (!server) data.cooldownUntil = cooldownFor(it, coolingOffDays);
        else delete data.createdAt;
        batch.set(ref, data, { merge: true });
        itemsOnServer.set(it.id, server ?? data);
      }

      const byItem = new Map<string, PriceSnapshot[]>();
      for (const p of body.prices) byItem.set(p.itemId, [...(byItem.get(p.itemId) ?? []), p]);
      for (const [itemId, prices] of byItem) {
        const itemRef = doc(db, 'users', uid, 'wishlistItems', itemId);
        let server = itemsOnServer.get(itemId);
        if (server === undefined) { const s = await getDoc(itemRef); server = s.exists() ? s.data() : null; }
        if (!server) continue; // món đã bị xoá trên app
        const added: PriceSnapshot[] = [];
        for (const p of prices) {
          const data = priceToDoc(p);
          if (!data) continue;
          const ref = doc(itemRef, 'priceSnapshots', p.id);
          if ((await getDoc(ref)).exists()) continue; // lịch sử giá chỉ thêm (rules update: false)
          batch.set(ref, data);
          added.push(p);
        }
        const latest = latestPriceOf(added);
        const serverAt = Date.parse(toIso(server.latestPriceAt) ?? '') || 0;
        if (latest && latest.at.getTime() >= serverAt) {
          batch.set(itemRef, { latestPriceVnd: latest.vnd, latestPriceAt: Timestamp.fromDate(latest.at), updatedAt: serverTimestamp() }, { merge: true });
        }
      }

      for (const d of body.decisions) {
        const data = decisionToDoc(d);
        if (!data) continue;
        const ref = doc(db, 'users', uid, 'decisions', d.id);
        if (!(await getDoc(ref)).exists()) batch.set(ref, data);
      }
      await batch.commit();
    } catch (e) { return this.denied(token, e); }
  }

  async pull(token: string, cursor?: string): Promise<PullResult> {
    const { uid, db } = await this.session(token);
    const { collection, getDocs, query, where } = await fs();
    try {
      const since = cursor ? Number(cursor) || 0 : 0;
      const all = (await getDocs(collection(db, 'users', uid, 'wishlistItems'))).docs.map((d) => docToItem(d.id, d.data()));
      const changed = all.filter((i) => i.revision > since);
      const prices: PriceSnapshot[] = [];
      await Promise.all(changed.map(async (i) => {
        const snaps = await getDocs(collection(db, 'users', uid, 'wishlistItems', i.id, 'priceSnapshots'));
        for (const s of snaps.docs) { const p = docToPrice(s.id, i.id, s.data()); if (p) prices.push(p); }
      }));
      const decisions = [];
      const ids = changed.map((i) => i.id);
      for (let k = 0; k < ids.length; k += 30) {
        const snaps = await getDocs(query(collection(db, 'users', uid, 'decisions'), where('itemId', 'in', ids.slice(k, k + 30))));
        for (const s of snaps.docs) { const d = docToDecision(s.id, s.data()); if (d) decisions.push(d); }
      }
      const max = all.reduce((m, i) => Math.max(m, i.revision), since);
      return { items: changed, prices, decisions, cursor: String(max), allIds: all.map((i) => i.id) };
    } catch (e) { return this.denied(token, e); }
  }

  async budgets(token: string): Promise<BudgetLine[]> {
    const { uid, db } = await this.session(token);
    const { collection, doc, getDoc, getDocs, limit, orderBy, query, where, Timestamp } = await fs();
    try {
      const now = new Date();
      const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
      const budget = await getDoc(doc(db, 'users', uid, 'budgets', month));
      const limits = (budget.exists() ? budget.data().limits : null) ?? {};
      const since = new Date(Math.min(new Date(now.getFullYear(), now.getMonth(), 1).getTime(), now.getTime() - 90 * 86_400_000));
      const purchases = collection(db, 'users', uid, 'purchases');
      const [recent, first] = await Promise.all([
        getDocs(query(purchases, where('occurredAt', '>=', Timestamp.fromDate(since)))),
        getDocs(query(purchases, orderBy('occurredAt'), limit(1))),
      ]);
      const rows = recent.docs.map((d) => docToPurchase(d.data())).filter((r): r is PurchaseRow => !!r);
      return budgetLines(limits, rows, now, first.empty ? undefined : toIso(first.docs[0].data().occurredAt));
    } catch (e) { return this.denied(token, e); }
  }

  async saleCalendar(token: string): Promise<SaleDay[]> {
    await this.session(token);
    try {
      const { app } = await fb();
      const { getRemoteConfig, fetchAndActivate, getValue } = await import('firebase/remote-config');
      const rc = getRemoteConfig(app);
      rc.settings.minimumFetchIntervalMillis = 3_600_000;
      rc.defaultConfig = { sale_calendar: '[]' };
      await fetchAndActivate(rc);
      return parseSaleCalendar(getValue(rc, 'sale_calendar').asString());
    } catch {
      return []; // không đọc được Remote Config → Decision Card dùng lịch ngày đôi mặc định
    }
  }

  async owned(token: string): Promise<OwnedLine[]> {
    const { uid, db } = await this.session(token);
    const { collection, getDocs } = await fs();
    try {
      const snaps = await getDocs(collection(db, 'users', uid, 'ownedItems'));
      return ownedLines(snaps.docs.map((d) => d.data()));
    } catch (e) { return this.denied(token, e); }
  }
}

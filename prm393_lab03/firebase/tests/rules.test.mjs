// Firestore Security Rules tests (Final assignment 6 and Appendix B).
// Every role (user, staff, admin) has at least one allowed and one denied case per collection.
// Run: cd firebase/tests && npm install && npm test   (needs Java 21+ for the Emulator)
// Results are also written to evidence/rules/firestore-rules-results.md.
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, where,
  serverTimestamp, Timestamp, writeBatch, collectionGroup, getCountFromServer,
} from 'firebase/firestore';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

const here = new URL('.', import.meta.url);
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8089').split(':');
const env = await initializeTestEnvironment({
  projectId: 'demo-why-i-buy',
  firestore: { rules: readFileSync(new URL('../../firestore.rules', here), 'utf8'), host, port: Number(port) },
});

// ---------- Actors ----------
// alice: user (role field set) · bob: user from before roles (no role field) · sam: staff · ada: admin
const google = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' } }).firestore();
const alice = google('alice');
const bob = google('bob');
const sam = google('sam');
const ada = google('ada');
const guest = env.authenticatedContext('guest-1', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const nobody = env.unauthenticatedContext().firestore();
const actors = { user: ['alice', alice], staff: ['sam', sam], admin: ['ada', ada] };

const now = () => Timestamp.now();
const key = 'shopee:446089250:44081797761';
const reportId = (uid) => createHash('sha256').update(`${uid}|${key}|none`).digest('hex');

// ---------- Seed (rules off) ----------
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/alice'), { displayName: 'Alice', isAnonymous: false, role: 'user' });
  await setDoc(doc(db, 'users/bob'), { displayName: 'Bob', isAnonymous: false });
  await setDoc(doc(db, 'users/sam'), { displayName: 'Sam', isAnonymous: false, role: 'staff' });
  await setDoc(doc(db, 'users/ada'), { displayName: 'Ada', isAnonymous: false, role: 'admin' });
  for (const [path, data] of privateDocs('bob')) await setDoc(doc(db, path), data);
  await setDoc(doc(db, 'users/alice/inbox/m1'), {
    title: 'Chào bạn', body: 'Cảm ơn góp ý', kind: 'message', createdAt: now(), createdBy: 'sam', readAt: null,
  });
  await setDoc(doc(db, 'users/alice/wishlistItems/w1/priceSnapshots/s0'), { amountVnd: 1, observedAt: now() });
  await setDoc(doc(db, 'announcements/a-pub'), announcement('sam', 'published', now()));
  await setDoc(doc(db, 'announcements/a-old'), announcement('sam', 'archived', now()));
  await setDoc(doc(db, 'saleEvents/s-pub'), saleEvent('sam', 'published', now()));
  await setDoc(doc(db, 'saleEvents/s-draft'), saleEvent('sam', 'draft', now()));
  await setDoc(doc(db, 'saleEvents/s-old'), saleEvent('sam', 'archived', now()));
  for (const [id, uid] of [['sg-1', 'alice'], ['sg-2', 'alice'], ['sg-3', 'alice'], ['sg-bob', 'bob']]) {
    await setDoc(doc(db, `saleSuggestions/${id}`), suggestion(uid));
  }
  await setDoc(doc(db, `priceHistory/${key}`), demoProduct());
  await setDoc(doc(db, 'priceHistory/shopee:1:2'), demoProduct('1', '2'));
  await setDoc(doc(db, `priceHistory/${key}/reports/demo1_none_20261101`), demoReport());
  await setDoc(doc(db, `priceHistory/${key}/reports/demo2_none_20261101`), demoReport());
  await setDoc(doc(db, 'productGroups/g1'), demoGroup());
  await setDoc(doc(db, 'productGroups/g2'), demoGroup());
  await setDoc(doc(db, 'extensionPairings/p1'), {
    anonUid: 'ext-1', deviceLabel: 'Chrome', status: 'pending', createdAt: now(),
  });
});

/** One valid document per private collection under users/{uid} */
function privateDocs(uid) {
  const u = `users/${uid}`;
  return [
    [`${u}/purchases/p1`, { title: 'Tai nghe', amountVnd: 450000, motive: 'want', occurredAt: now() }],
    [`${u}/wishlistItems/w1`, { title: 'Bàn phím', status: 'considering' }],
    [`${u}/wishlistItems/w1/priceSnapshots/s1`, { amountVnd: 450000, observedAt: now(), source: 'manual' }],
    [`${u}/extensionSessions/e1`, { status: 'approved', deviceLabel: 'Chrome' }],
    [`${u}/decisions/d1`, { choice: 'wait' }],
    [`${u}/budgetGroups/tech`, { name: 'Công nghệ' }],
    [`${u}/feedback/f1`, { message: 'Ứng dụng dễ dùng' }],
    [`${u}/ownedItems/o1`, { name: 'Tai nghe cũ', tags: [] }],
    [`${u}/budgets/2026-11`, { limit: 1000000 }],
    [`${u}/reflections/2026-11`, { rating: 4 }],
  ];
}
function announcement(by, status, createdAt) {
  return { title: 'Bảo trì', body: 'App bảo trì tối nay', status, createdAt, createdBy: by, updatedAt: createdAt };
}
function saleEvent(by, status, updatedAt) {
  return { name: '11.11', date: Timestamp.fromDate(new Date('2026-11-11')), type: 'double_day', confirmed: true, status, updatedAt, updatedBy: by };
}
const newAnnouncement = (by, status = 'published') => ({
  title: 'Tính năng mới', body: 'Đã có so sánh giá', status, createdAt: serverTimestamp(), createdBy: by, updatedAt: serverTimestamp(),
});
const newSale = (by, status, extra = {}) => ({ ...saleEvent(by, status, serverTimestamp()), ...extra });
function suggestion(uid, extra = {}) {
  return { uid, name: '12.12', date: Timestamp.fromDate(new Date('2026-12-12')), note: 'Shopee đã công bố', status: 'pending', createdAt: now(), ...extra };
}
const newSuggestion = (uid, extra = {}) => ({ ...suggestion(uid), createdAt: serverTimestamp(), ...extra });
/** The web review queue's approve: publish the event, close the suggestion, tell the user */
function approve(db, by, suggestionId, ownerUid, eventId) {
  const batch = writeBatch(db);
  batch.set(doc(db, `saleEvents/${eventId}`), newSale(by, 'published', { suggestionId }));
  batch.update(doc(db, `saleSuggestions/${suggestionId}`), {
    status: 'approved', saleEventId: eventId, reviewedAt: serverTimestamp(), reviewedBy: by,
  });
  batch.set(doc(db, `users/${ownerUid}/inbox/r-${suggestionId}`), {
    title: 'Đề xuất sale đã được duyệt', body: '"12.12" đã có trong Lịch sale.', kind: 'suggestion_reply',
    refId: suggestionId, createdAt: serverTimestamp(), createdBy: by,
  });
  return batch.commit();
}
const reject = (db, by, id, reason) => updateDoc(doc(db, `saleSuggestions/${id}`), {
  status: 'rejected', reviewedAt: serverTimestamp(), reviewedBy: by, ...(reason ? { reason } : {}),
});
const message = (by, extra = {}) => ({
  title: 'Trả lời góp ý', body: 'Nhóm đã ghi nhận', kind: 'feedback_reply', refId: 'f1',
  createdAt: serverTimestamp(), createdBy: by, readAt: null, ...extra,
});

function demoProduct(shopId = '446089250', itemId = '44081797761', extra = {}) {
  return { title: 'Tai nghe Bluetooth', shopId, itemId, shopName: 'Shop mẫu', isDemo: true, createdAt: now(), ...extra };
}
function demoReport(extra = {}) {
  return {
    amountVnd: 420000, priceType: 'single', modelKey: 'none', observedAt: now(), source: 'demo',
    shopName: 'Shop mẫu', productRating: 4.8, productRatingCount: 120, shopRating: 4.9, ...extra,
  };
}
function demoGroup(extra = {}) {
  return { name: 'Tai nghe Bluetooth', productKeys: [key], isDemo: true, ...extra };
}

// ---------- Cases: [collection, role, operation, allowed, run] ----------
const cases = [];
const add = (collectionName, role, operation, allowed, run) => cases.push({ collectionName, role, operation, allowed, run });
const label = (path) => path.replace(/^users\/[^/]+\//, '').replace(/\/[^/]+$/, '').replace(/\/[^/]+\//g, '/');

// users/{uid}
add('users', 'user', 'read own profile', true, () => getDoc(doc(alice, 'users/alice')));
add('users', 'user', "read another user's profile", false, () => getDoc(doc(alice, 'users/bob')));
add('users', 'user', 'update own settings (role kept)', true, () => setDoc(doc(alice, 'users/alice'), { settings: { reminderHour: 21 } }, { merge: true }));
add('users', 'user', 'update own role to admin', false, () => updateDoc(doc(alice, 'users/alice'), { role: 'admin' }));
add('users', 'user', 'old profile without role: add role staff', false, () => updateDoc(doc(bob, 'users/bob'), { role: 'staff' }));
add('users', 'user', 'first sign-in creates profile with role user', true, () => setDoc(doc(google('carol'), 'users/carol'), { displayName: 'Carol', isAnonymous: false, role: 'user' }));
add('users', 'user', 'first sign-in creates profile with role admin', false, () => setDoc(doc(google('dan'), 'users/dan'), { displayName: 'Dan', isAnonymous: false, role: 'admin' }));
add('users', 'staff', 'list users (web user list)', true, () => getDocs(collection(sam, 'users')));
add('users', 'staff', "change a user's role", false, () => updateDoc(doc(sam, 'users/alice'), { role: 'staff' }));
add('users', 'admin', 'make bob staff', true, () => updateDoc(doc(ada, 'users/bob'), { role: 'staff' }));
add('users', 'admin', 'change own role', false, () => updateDoc(doc(ada, 'users/ada'), { role: 'user' }));
add('users', 'admin', 'change role and display name together', false, () => updateDoc(doc(ada, 'users/alice'), { role: 'staff', displayName: 'X' }));
add('users', 'admin', 'set an unknown role', false, () => updateDoc(doc(ada, 'users/alice'), { role: 'owner' }));
add('users', 'signed out', 'read a profile', false, () => getDoc(doc(nobody, 'users/alice')));

// Private collections: own data allowed for every role; nobody reads bob's (staff and admin included)
for (const [role, [uid, db]] of Object.entries(actors)) {
  for (const [path, data] of privateDocs(uid)) {
    add(label(path), role, 'create own', true, () => setDoc(doc(db, path), data));
  }
  for (const [path] of privateDocs('bob')) {
    const adminCounts = role === 'admin' && ['purchases', 'wishlistItems'].includes(label(path));
    add(label(path), role, adminCounts ? "read bob's (web user list counts)" : "read bob's", adminCounts,
      () => getDoc(doc(db, path)));
  }
}
// Admins only read (counts on the web); they never change a user's data
add('purchases', 'admin', "edit bob's purchase", false, () => updateDoc(doc(ada, 'users/bob/purchases/p1'), { amountVnd: 1 }));
add('wishlistItems', 'admin', "delete bob's item", false, () => deleteDoc(doc(ada, 'users/bob/wishlistItems/w1')));
add('purchases', 'user', 'create with amount 0', false, () => setDoc(doc(alice, 'users/alice/purchases/p2'), { title: 'x', amountVnd: 0, motive: 'want', occurredAt: now() }));
add('wishlistItems', 'user', 'status "waiting" (not in the spec)', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w2'), { title: 'x', status: 'waiting' }));
// The extension saves "Giá đang giảm" as priceType 'sale' (E1)
add('wishlistItems/priceSnapshots', 'user', "save a priceType 'sale' snapshot", true, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-sale'), { amountVnd: 399000, observedAt: now(), source: 'extensionPage', priceType: 'sale' }));
add('wishlistItems/priceSnapshots', 'user', "save an unknown priceType 'coupon'", false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-coupon'), { amountVnd: 399000, observedAt: now(), source: 'extensionPage', priceType: 'coupon' }));
// Shopee ratings from the extension (E3): stars in (0, 5], review count int >= 0, shop name <= 60 on a price
const rated = { productRating: 4.8, productRatingCount: 1200, shopRating: 4.9 };
const wItem = (extra) => ({ title: 'Tai nghe', status: 'considering', ...extra });
const wSnap = (extra) => ({ amountVnd: 399000, observedAt: now(), source: 'extensionPage', priceType: 'single', ...extra });
add('wishlistItems', 'user', 'save an item with Shopee ratings', true, () => setDoc(doc(alice, 'users/alice/wishlistItems/w-rated'), wItem(rated)));
add('wishlistItems', 'user', 'save productRating 6', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w-bad1'), wItem({ productRating: 6 })));
add('wishlistItems', 'user', 'save shopRating 0', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w-bad2'), wItem({ shopRating: 0 })));
add('wishlistItems', 'user', "save productRatingCount as text '1,2k'", false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w-bad3'), wItem({ productRatingCount: '1,2k' })));
add('wishlistItems', 'user', 'save productRatingCount -1', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w-bad4'), wItem({ productRatingCount: -1 })));
add('wishlistItems/priceSnapshots', 'user', 'save a price with shop name and ratings', true, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-rated'), wSnap({ shopName: 'Shop Mây', ...rated })));
add('wishlistItems/priceSnapshots', 'user', 'save a price with a 61-character shop name', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-bad1'), wSnap({ shopName: 'x'.repeat(61) })));
add('wishlistItems/priceSnapshots', 'user', 'save a price with productRating 5.5', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-bad2'), wSnap({ productRating: 5.5 })));
add('wishlistItems/priceSnapshots', 'user', 'save a price with productRatingCount 1.5', false, () => setDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s-bad3'), wSnap({ productRatingCount: 1.5 })));
add('wishlistItems/priceSnapshots', 'user', 'edit a recorded price', false, () => updateDoc(doc(alice, 'users/alice/wishlistItems/w1/priceSnapshots/s0'), { amountVnd: 2 }));
add('decisions', 'user', 'unknown choice', false, () => setDoc(doc(alice, 'users/alice/decisions/d2'), { choice: 'maybe' }));
add('feedback', 'user', 'edit a sent feedback', false, () => updateDoc(doc(bob, 'users/bob/feedback/f1'), { message: 'sửa' }));
add('reflections', 'user', 'rating 6', false, () => setDoc(doc(alice, 'users/alice/reflections/2026-10'), { rating: 6 }));
add('extensionSessions', 'user', 'status "hacked"', false, () => setDoc(doc(alice, 'users/alice/extensionSessions/e2'), { status: 'hacked', deviceLabel: 'x' }));

// users/{uid}/inbox
add('inbox', 'user', 'read own messages', true, () => getDocs(collection(alice, 'users/alice/inbox')));
add('inbox', 'user', 'mark a message read', true, () => updateDoc(doc(alice, 'users/alice/inbox/m1'), { readAt: serverTimestamp() }));
add('inbox', 'user', 'change the text of a message', false, () => updateDoc(doc(alice, 'users/alice/inbox/m1'), { body: 'sửa' }));
add('inbox', 'user', 'write a message to self', false, () => setDoc(doc(alice, 'users/alice/inbox/m2'), message('alice')));
add('inbox', 'user', "read bob's messages", false, () => getDocs(collection(alice, 'users/bob/inbox')));
add('inbox', 'staff', 'send a message to alice', true, () => setDoc(doc(sam, 'users/alice/inbox/m3'), message('sam')));
add('inbox', 'staff', 'send a message signed as someone else', false, () => setDoc(doc(sam, 'users/alice/inbox/m4'), message('ada')));
add('inbox', 'staff', "read alice's messages", false, () => getDocs(collection(sam, 'users/alice/inbox')));
add('inbox', 'admin', 'send a message to bob', true, () => setDoc(doc(ada, 'users/bob/inbox/m5'), message('ada')));
add('inbox', 'admin', 'send a message with an extra field', false, () => setDoc(doc(ada, 'users/bob/inbox/m6'), message('ada', { uid: 'bob' })));

// announcements
add('announcements', 'user', 'list published', true, () => getDocs(query(collection(alice, 'announcements'), where('status', '==', 'published'))));
add('announcements', 'user', 'list without the status filter', false, () => getDocs(collection(alice, 'announcements')));
add('announcements', 'user', 'read an archived one', false, () => getDoc(doc(alice, 'announcements/a-old')));
add('announcements', 'user', 'post an announcement', false, () => setDoc(doc(alice, 'announcements/a1'), newAnnouncement('alice')));
add('announcements', 'staff', 'post an announcement', true, () => setDoc(doc(sam, 'announcements/a2'), newAnnouncement('sam')));
add('announcements', 'staff', 'archive a published one', true, () => updateDoc(doc(sam, 'announcements/a-pub'), { status: 'archived', updatedAt: serverTimestamp() }));
add('announcements', 'staff', 'republish an archived one', false, () => updateDoc(doc(sam, 'announcements/a-old'), { status: 'published', updatedAt: serverTimestamp() }));
add('announcements', 'staff', 'delete one', false, () => deleteDoc(doc(sam, 'announcements/a2')));
add('announcements', 'admin', 'post an announcement', true, () => setDoc(doc(ada, 'announcements/a3'), newAnnouncement('ada')));
add('announcements', 'admin', 'post with a 501-character body', false, () => setDoc(doc(ada, 'announcements/a4'), { ...newAnnouncement('ada'), body: 'x'.repeat(501) }));
add('announcements', 'signed out', 'list published', false, () => getDocs(query(collection(nobody, 'announcements'), where('status', '==', 'published'))));

// saleEvents
add('saleEvents', 'user', 'read a published sale', true, () => getDoc(doc(alice, 'saleEvents/s-pub')));
add('saleEvents', 'user', 'read a draft', false, () => getDoc(doc(alice, 'saleEvents/s-draft')));
add('saleEvents', 'user', 'create a sale', false, () => setDoc(doc(alice, 'saleEvents/s1'), newSale('alice', 'published')));
add('saleEvents', 'staff', 'create a draft', true, () => setDoc(doc(sam, 'saleEvents/s2'), newSale('sam', 'draft')));
add('saleEvents', 'staff', 'publish a draft', true, () => updateDoc(doc(sam, 'saleEvents/s-draft'), { status: 'published', updatedAt: serverTimestamp(), updatedBy: 'sam' }));
add('saleEvents', 'staff', 'republish an archived sale', false, () => updateDoc(doc(sam, 'saleEvents/s-old'), { status: 'published', updatedAt: serverTimestamp(), updatedBy: 'sam' }));
add('saleEvents', 'staff', 'unknown sale type', false, () => setDoc(doc(sam, 'saleEvents/s3'), newSale('sam', 'draft', { type: 'black_friday' })));
add('saleEvents', 'admin', 'archive a published sale', true, () => updateDoc(doc(ada, 'saleEvents/s-pub'), { status: 'archived', updatedAt: serverTimestamp(), updatedBy: 'ada' }));
add('saleEvents', 'admin', 'delete a sale', false, () => deleteDoc(doc(ada, 'saleEvents/s2')));

// saleSuggestions (cross-role flow: app proposes → web approves or rejects with a reason)
add('saleSuggestions', 'user', 'propose a sale (pending)', true, () => setDoc(doc(alice, 'saleSuggestions/n1'), newSuggestion('alice')));
add('saleSuggestions', 'user', 'propose one already approved', false, () => setDoc(doc(alice, 'saleSuggestions/n2'), newSuggestion('alice', { status: 'approved' })));
add('saleSuggestions', 'user', "propose in bob's name", false, () => setDoc(doc(alice, 'saleSuggestions/n3'), newSuggestion('bob')));
add('saleSuggestions', 'user', 'read own suggestion', true, () => getDoc(doc(alice, 'saleSuggestions/sg-1')));
add('saleSuggestions', 'user', "read bob's suggestion", false, () => getDoc(doc(alice, 'saleSuggestions/sg-bob')));
add('saleSuggestions', 'user', 'approve own suggestion', false, () => approve(alice, 'alice', 'sg-2', 'alice', 'ev-alice'));
add('saleSuggestions', 'staff', 'approve (event + suggestion + inbox in one batch)', true, () => approve(sam, 'sam', 'sg-1', 'alice', 'ev-1'));
add('saleSuggestions', 'staff', 'approve the same suggestion again', false, () => approve(sam, 'sam', 'sg-1', 'alice', 'ev-2'));
add('saleSuggestions', 'staff', 'reject without a reason', false, () => reject(sam, 'sam', 'sg-2'));
add('saleSuggestions', 'staff', 'reject with a reason', true, () => reject(sam, 'sam', 'sg-2', 'Chưa có thông báo chính thức từ shop'));
add('saleSuggestions', 'admin', 'list the review queue', true, () => getDocs(query(collection(ada, 'saleSuggestions'), where('status', '==', 'pending'))));
add('saleSuggestions', 'admin', "propose in alice's name", false, () => setDoc(doc(ada, 'saleSuggestions/n4'), newSuggestion('alice')));
add('saleSuggestions', 'admin', 'reject signed as someone else', false, () => reject(ada, 'sam', 'sg-3', 'x'));

// Web dashboard: collection-group count / sum, admins only
const skipped = (db) => getCountFromServer(query(collectionGroup(db, 'wishlistItems'), where('status', '==', 'skipped')));
add('(collection group) wishlistItems', 'admin', 'count skipped items of every user', true, () => skipped(ada));
add('(collection group) wishlistItems', 'staff', 'count skipped items of every user', false, () => skipped(sam));
add('(collection group) wishlistItems', 'user', 'count skipped items of every user', false, () => skipped(alice));
add('(collection group) purchases', 'admin', 'count every purchase', true, () => getCountFromServer(collectionGroup(ada, 'purchases')));
add('(collection group) purchases', 'staff', 'count every purchase', false, () => getCountFromServer(collectionGroup(sam, 'purchases')));

// sharedPrices (anonymous price reports)
const report = { modelKey: 'none', priceType: 'single', amountVnd: 420000, observedAt: now(), source: 'manual' };
for (const [role, [uid, db]] of Object.entries(actors)) {
  add('sharedPrices/reports', role, 'share own price (hashed id)', true, () => setDoc(doc(db, 'sharedPrices', key, 'reports', reportId(uid)), report));
  add('sharedPrices/reports', role, "write under bob's id", false, () => setDoc(doc(db, 'sharedPrices', key, 'reports', reportId('bob')), report));
}
add('sharedPrices/reports', 'user', 'add a uid field', false, () => setDoc(doc(alice, 'sharedPrices', key, 'reports', reportId('alice')), { ...report, uid: 'alice' }));
add('sharedPrices/reports', 'guest', 'share a price', false, () => setDoc(doc(guest, 'sharedPrices', key, 'reports', reportId('guest-1')), report));
add('sharedPrices/reports', 'guest', 'read prices', true, () => getDocs(collection(guest, 'sharedPrices', key, 'reports')));

// priceHistory, priceHistory/reports, productGroups ("Biểu đồ giá tham khảo"): admins write sample data only
const hReport = (db, rid) => doc(db, 'priceHistory', key, 'reports', rid);
for (const [role, [, db]] of Object.entries(actors)) {
  add('priceHistory', role, 'read a product', true, () => getDoc(doc(db, `priceHistory/${key}`)));
  add('priceHistory/reports', role, 'read reports', true, () => getDocs(collection(db, 'priceHistory', key, 'reports')));
  add('productGroups', role, 'read a group', true, () => getDoc(doc(db, 'productGroups/g1')));
}
for (const [role, db] of [['user', alice], ['staff', sam]]) {
  add('priceHistory', role, 'create a demo product', false, () => setDoc(doc(db, 'priceHistory/shopee:3:4'), demoProduct('3', '4')));
  add('priceHistory/reports', role, 'create a demo report', false, () => setDoc(hReport(db, 'demo9_none_20261102'), demoReport()));
  add('priceHistory/reports', role, 'delete a demo report', false, () => deleteDoc(hReport(db, 'demo1_none_20261101')));
  add('productGroups', role, 'create a demo group', false, () => setDoc(doc(db, 'productGroups/g3'), demoGroup()));
}
add('priceHistory', 'user', 'create a non-demo product', false, () => setDoc(doc(alice, 'priceHistory/shopee:3:4'), demoProduct('3', '4', { isDemo: false })));
add('priceHistory', 'admin', 'create a demo product', true, () => setDoc(doc(ada, 'priceHistory/shopee:5:6'), demoProduct('5', '6', { groupId: 'g1' })));
add('priceHistory', 'admin', 'delete a demo product', true, () => deleteDoc(doc(ada, 'priceHistory/shopee:1:2')));
add('priceHistory', 'admin', 'create with a 121-character title', false, () => setDoc(doc(ada, 'priceHistory/shopee:7:8'), demoProduct('7', '8', { title: 'x'.repeat(121) })));
add('priceHistory', 'admin', 'create with a 61-character shop name', false, () => setDoc(doc(ada, 'priceHistory/shopee:7:8'), demoProduct('7', '8', { shopName: 'x'.repeat(61) })));
add('priceHistory', 'admin', 'create a non-demo product (opens in G7)', false, () => setDoc(doc(ada, 'priceHistory/shopee:7:8'), demoProduct('7', '8', { isDemo: false })));
add('priceHistory', 'admin', 'shopId/itemId not matching the key', false, () => setDoc(doc(ada, 'priceHistory/shopee:7:8'), demoProduct('7', '9')));
add('priceHistory/reports', 'admin', 'create a demo report', true, () => setDoc(hReport(ada, 'demo3_none_20261102'), demoReport()));
add('priceHistory/reports', 'admin', "create priceType 'sale'", true, () => setDoc(hReport(ada, 'demo4_none_20261102'), demoReport({ priceType: 'sale' })));
add('priceHistory/reports', 'admin', "create priceType 'afterVoucher'", true, () => setDoc(hReport(ada, 'demo5_123_20261102'), demoReport({ priceType: 'afterVoucher', modelKey: '123' })));
add('priceHistory/reports', 'admin', 'delete a demo report', true, () => deleteDoc(hReport(ada, 'demo2_none_20261101')));
add('priceHistory/reports', 'admin', 'productRating 6', false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ productRating: 6 })));
add('priceHistory/reports', 'admin', 'shopRating 0', false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ shopRating: 0 })));
add('priceHistory/reports', 'admin', 'productRatingCount -1', false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ productRatingCount: -1 })));
add('priceHistory/reports', 'admin', "unknown priceType 'coupon'", false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ priceType: 'coupon' })));
add('priceHistory/reports', 'admin', 'amountVnd 0', false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ amountVnd: 0 })));
add('priceHistory/reports', 'admin', "non-demo source 'manual' (opens in G7)", false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ source: 'manual' })));
add('priceHistory/reports', 'admin', 'id not matching modelKey', false, () => setDoc(hReport(ada, 'demo6_999_20261102'), demoReport()));
add('priceHistory/reports', 'admin', 'add a uid field', false, () => setDoc(hReport(ada, 'demo6_none_20261102'), demoReport({ uid: 'ada' })));
add('productGroups', 'admin', 'create a demo group', true, () => setDoc(doc(ada, 'productGroups/g4'), demoGroup()));
add('productGroups', 'admin', 'delete a demo group', true, () => deleteDoc(doc(ada, 'productGroups/g2')));
add('productGroups', 'admin', 'create a non-demo group', false, () => setDoc(doc(ada, 'productGroups/g5'), demoGroup({ isDemo: false })));
add('priceHistory', 'signed out', 'read a product', false, () => getDoc(doc(nobody, `priceHistory/${key}`)));
add('priceHistory/reports', 'signed out', 'read reports', false, () => getDocs(collection(nobody, 'priceHistory', key, 'reports')));
add('productGroups', 'signed out', 'read a group', false, () => getDoc(doc(nobody, 'productGroups/g1')));

// extensionPairings
for (const [role, [, db]] of Object.entries(actors)) {
  add('extensionPairings', role, 'open a pairing by its id', true, () => getDoc(doc(db, 'extensionPairings/p1')));
  add('extensionPairings', role, 'list pairings', false, () => getDocs(collection(db, 'extensionPairings')));
}
add('extensionPairings', 'user', 'approve the pairing for self', true, () => updateDoc(doc(alice, 'extensionPairings/p1'), { status: 'approved', ownerUid: 'alice' }));

// Anything not matched above is denied by default
add('(unmatched path)', 'admin', 'write admin_broadcasts (removed, unused)', false, () => setDoc(doc(ada, 'admin_broadcasts/b1'), { title: 'x' }));

// ---------- Run ----------
const rows = [];
let failed = 0;
for (const [i, c] of cases.entries()) {
  const id = `R-${String(i + 1).padStart(2, '0')}`;
  let result = 'Pass';
  try {
    await (c.allowed ? assertSucceeds(c.run()) : assertFails(c.run()));
  } catch (e) {
    failed++;
    result = `**FAIL** (${String(e.message ?? e).split('\n')[0].slice(0, 80)})`;
  }
  rows.push(`| ${id} | ${c.collectionName} | ${c.role} | ${c.operation} | ${c.allowed ? 'Allowed' : 'Denied'} | ${result} |`);
  console.log(`${result.startsWith('Pass') ? 'PASS' : 'FAIL'} ${id} ${c.collectionName} · ${c.role} · ${c.operation}`);
}
await env.cleanup();

// Coverage check: every role has an allowed and a denied case in every collection it was tested on
const coverage = new Map();
for (const c of cases) {
  const k = `${c.collectionName}|${c.role}`;
  coverage.set(k, (coverage.get(k) ?? new Set()).add(c.allowed));
}
const gaps = [...coverage]
  .filter(([k, s]) => !k.startsWith('(') && ['user', 'staff', 'admin'].includes(k.split('|')[1]) && s.size < 2)
  .map(([k]) => k);

const out = new URL('../../evidence/rules/', here);
mkdirSync(out, { recursive: true });
writeFileSync(new URL('firestore-rules-results.md', out), [
  '# Firestore Security Rules – kết quả chạy trên Emulator',
  '',
  `Sinh tự động bởi \`firebase/tests/rules.test.mjs\` lúc ${new Date().toISOString()}.`,
  `Tổng: ${cases.length} ca · Qua: ${cases.length - failed} · Lỗi: ${failed}.`,
  gaps.length ? `Thiếu ca cho phép/từ chối: ${gaps.join(', ')}` : 'Mỗi vai trò (user, staff, admin) có ít nhất 1 ca cho phép và 1 ca từ chối ở mỗi collection.',
  '',
  '| ID | Collection | Role | Operation | Expected | Result |',
  '|:---|:---|:---|:---|:---|:---|',
  ...rows,
  '',
].join('\n'));

console.log(`\n${cases.length - failed}/${cases.length} passed${gaps.length ? ` · missing pairs: ${gaps.join(', ')}` : ''}`);
process.exit(failed || gaps.length ? 1 : 0);

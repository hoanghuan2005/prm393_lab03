// Firebase cho extension: cùng project với app Why I Buy? (lib/firebase_options.dart → web).
// Chỉ được import động (await import('./firebase')) để bản demo/test không tải SDK.
import { initializeApp, getApps } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInAnonymously, signInWithCredential, signOut as fbSignOut } from 'firebase/auth/web-extension';
import type { User } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const config = {
  apiKey: 'AIzaSyAs5xKjGB5p-4I3Poy2ZI8Er65TVOfTLlk',
  appId: '1:21478927288:web:3a6610131a3a29879dbd4d',
  messagingSenderId: '21478927288',
  projectId: 'prm393-34056',
  authDomain: 'prm393-34056.firebaseapp.com',
  storageBucket: 'prm393-34056.firebasestorage.app',
};

export const app = getApps()[0] ?? initializeApp(config);
export const auth = getAuth(app);
export const db = getFirestore(app);

const identity = () => (globalThis as any).chrome?.identity;

export class SignInCancelled extends Error { constructor(msg = 'cancelled') { super(msg); } }

// Đăng nhập Google bằng chrome.identity (OAuth client loại "Chrome Extension", khai báo ở wxt.config.ts),
// rồi đổi access token thành phiên Firebase → cùng uid với tài khoản trên app.
export async function signIn(): Promise<User> {
  await auth.authStateReady();
  if (auth.currentUser) return auth.currentUser;
  const id = identity();
  if (!id?.getAuthToken) throw new SignInCancelled('Trình duyệt này không hỗ trợ đăng nhập Google cho extension. Hãy dùng Chrome.');
  let token: string | undefined;
  try {
    const r = await id.getAuthToken({ interactive: true });
    token = typeof r === 'string' ? r : r?.token;
  } catch (e) {
    throw new SignInCancelled(String((e as Error)?.message ?? e));
  }
  if (!token) throw new SignInCancelled();
  try {
    return (await signInWithCredential(auth, GoogleAuthProvider.credential(null, token))).user;
  } catch (e) {
    // Token Google hết hạn trong bộ nhớ đệm của Chrome → xoá để lần sau lấy token mới.
    await id.removeCachedAuthToken?.({ token }).catch?.(() => {});
    throw e;
  }
}

// Liên kết bằng QR: extension chỉ cần một phiên ẩn danh (chạy được cả trên Edge); app quét QR
// rồi cấp quyền cho uid ẩn danh này vào dữ liệu của tài khoản (firestore.rules → linkedDevice).
export async function signInAnon(): Promise<User> {
  await auth.authStateReady();
  if (auth.currentUser) return auth.currentUser;
  return (await signInAnonymously(auth)).user;
}

export async function currentUser(): Promise<User | null> {
  await auth.authStateReady();
  return auth.currentUser;
}

export async function signOut() {
  const id = identity();
  try {
    const r = await id?.getAuthToken?.({ interactive: false });
    const token = typeof r === 'string' ? r : r?.token;
    if (token) await id.removeCachedAuthToken({ token });
  } catch { /* chưa có token */ }
  await fbSignOut(auth);
}

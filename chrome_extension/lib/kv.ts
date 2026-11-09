// Lớp lưu trữ key-value: chrome.storage.local trong extension, bộ nhớ trong khi chạy test.
export interface KV {
  get<T>(key: string, fallback: T): Promise<T>;
  set<T>(key: string, value: T): Promise<void>;
  remove(key: string): Promise<void>;
}

export function memoryKV(): KV {
  const m = new Map<string, unknown>();
  return {
    async get<T>(k: string, f: T) { return (m.has(k) ? structuredClone(m.get(k)) : f) as T; },
    async set<T>(k: string, v: T) { m.set(k, structuredClone(v)); },
    async remove(k: string) { m.delete(k); },
  };
}

let current: KV | null = null;
export function setKV(kv: KV) { current = kv; }
export async function kv(): Promise<KV> {
  if (current) return current;
  const { storage } = await import('wxt/storage');
  current = {
    async get<T>(k: string, f: T) { const v = await storage.getItem<T>(`local:${k}`); return (v ?? f) as T; },
    async set<T>(k: string, v: T) { await storage.setItem(`local:${k}`, v); },
    async remove(k: string) { await storage.removeItem(`local:${k}`); },
  };
  return current;
}

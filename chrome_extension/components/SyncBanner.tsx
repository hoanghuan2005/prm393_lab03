// Banner báo đồng bộ đang lỗi (popup + side panel); món vẫn được giữ trên máy và sẽ thử lại.
import { useEffect, useState } from 'react';
import { browser } from 'wxt/browser';
import { IconAlert } from './Icons';
import { getSyncMeta, syncProblemText } from '../features/sync/sync';
import { getPairing } from '../features/pairing/pairing';
import { getSettings } from '../features/items/repo';
import './SyncBanner.css';

const WATCH = ['wib_sync_state', 'wib_pairing', 'wib_settings'];

export function SyncBanner() {
  const [text, setText] = useState<string | null>(null);
  useEffect(() => {
    const load = async () => {
      const [meta, pairing, settings] = await Promise.all([getSyncMeta(), getPairing(), getSettings()]);
      setText(syncProblemText(meta, pairing.linked, settings.syncOn));
    };
    load();
    const on = (ch: Record<string, unknown>, area: string) => { if (area === 'local' && WATCH.some((k) => k in ch)) load(); };
    browser.storage.onChanged.addListener(on);
    return () => browser.storage.onChanged.removeListener(on);
  }, []);
  if (!text) return null;
  return (
    <div className="sync-banner" role="status">
      <span className="ic"><IconAlert /></span>
      <p className="t-body-sm tx">{text}</p>
    </div>
  );
}

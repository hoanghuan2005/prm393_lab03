// Figma X3: Decision Card ở bảng cạnh (side panel).
import { createRoot } from 'react-dom/client';
import { useEffect, useState } from 'react';
import { browser } from 'wxt/browser';
import '../../assets/tokens.css';
import { DecisionCard } from '../../components/DecisionCard';
import { loadAll } from '../../features/items/repo';
import { buildViews, type ItemView } from '../../features/items/price';
import { loadDecisionContext, type DecisionContext } from '../../features/decision/context';
import { syncNow } from '../../features/sync/sync';
import { kv } from '../../lib/kv';
import { SyncBanner } from '../../components/SyncBanner';

function Panel() {
  const [id, setId] = useState<string | null>(null);
  const [views, setViews] = useState<ItemView[]>([]);
  const [ctx, setCtx] = useState<DecisionContext | null>(null);
  const load = async () => {
    const [last, { items, prices }, c] = await Promise.all([kv().then((k) => k.get<string | null>('wib_last_item', null)), loadAll(), loadDecisionContext()]);
    setId(last); setViews(buildViews(items, prices)); setCtx(c);
  };
  useEffect(() => {
    load();
    const on = (ch: Record<string, unknown>) => { if (['wib_last_item', 'wib_items', 'wib_prices', 'wib_decisions', 'wib_pairing'].some((k) => k in ch)) load(); };
    browser.storage.onChanged.addListener(on);
    return () => browser.storage.onChanged.removeListener(on);
  }, []);
  const view = views.find((v) => v.item.id === id);
  return (
    <div style={{ background: 'var(--surface)', minHeight: '100vh', padding: 20 }}>
      <SyncBanner />
      {view && ctx ? <DecisionCard view={view} views={views} ctx={ctx} onChanged={() => { syncNow().finally(load); }} onOpenItem={async (x) => { await (await kv()).set('wib_last_item', x); }} />
        : <p className="t-body-sm muted">Chưa chọn món. Lưu một món từ popup rồi chọn "Cân nhắc sau trong Decision Card".</p>}
    </div>
  );
}
createRoot(document.getElementById('root')!).render(<Panel />);

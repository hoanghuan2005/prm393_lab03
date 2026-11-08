import type { ReactNode } from 'react';
import { IconCheck, IconChevronDown, MotiveIcons, IconBag } from './Icons';
import { MOTIVES, CATEGORIES } from '../features/items/model';
import type { PriceTagInfo } from '../features/items/price';

export function AppIcon({ size = 24 }: { size?: number }) {
  return <img src="/icon/48.png" width={size} height={size} alt="" style={{ borderRadius: Math.round(size * 0.28), display: "block", flexShrink: 0 }} />;
}

export function PriceTag({ info }: { info: PriceTagInfo | null }) {
  return info ? <span className={`ptag ${info.kind}`}>{info.label}</span> : null;
}

export function MotiveChips({ value, onChange }: { value?: string; onChange: (v?: string) => void }) {
  return (
    <div className="chips" role="group" aria-label="Vì sao muốn mua?">
      {MOTIVES.map((m) => {
        const I = MotiveIcons[m.icon];
        const on = value === m.id;
        return (
          <button key={m.id} type="button" className="chip" aria-pressed={on} onClick={() => onChange(on ? undefined : m.id)}>
            <I size={16} />{m.label}
          </button>
        );
      })}
    </div>
  );
}

export function CategorySelect({ value, onChange, prefix = 'Nhóm ngân sách: ' }: { value?: string; onChange: (v?: string) => void; prefix?: string }) {
  return (
    <label className="select-wrap">
      <span className="sr">Nhóm ngân sách</span>
      <select className="field" value={value ?? ''} onChange={(e) => onChange(e.target.value || undefined)}>
        <option value="">{prefix}chưa chọn</option>
        {CATEGORIES.map((c) => <option key={c.id} value={c.id}>{prefix}{c.label}</option>)}
      </select>
      <IconChevronDown />
    </label>
  );
}

export function Switch({ checked, onChange, disabled, label }: { checked: boolean; onChange: (v: boolean) => void; disabled?: boolean; label: string }) {
  return (
    <button type="button" role="switch" aria-checked={checked} aria-label={label} className="switch" disabled={disabled} onClick={() => onChange(!checked)}>
      <span className="track"><span className="knob">{checked && <IconCheck />}</span></span>
    </button>
  );
}

export function CodeInput({ value, onChange, error, large, autoFocus }: { value: string; onChange: (v: string) => void; error?: boolean; large?: boolean; autoFocus?: boolean }) {
  const digits = value.padEnd(6, ' ').slice(0, 6).split('');
  const set = (i: number, ch: string, el: HTMLInputElement) => {
    const clean = ch.replace(/\D/g, '');
    if (clean.length > 1) { onChange(clean.slice(0, 6)); (el.parentElement?.children[Math.min(clean.length, 5)] as HTMLInputElement)?.focus(); return; }
    const arr = value.padEnd(6, ' ').split('');
    arr[i] = clean || ' ';
    onChange(arr.join('').replace(/\s+$/, ''));
    if (clean && i < 5) (el.nextElementSibling as HTMLInputElement)?.focus();
  };
  return (
    <div className={`code${large ? ' lg' : ''}${error ? ' error' : ''}`}>
      {digits.map((d, i) => (
        <input key={i} inputMode="numeric" autoComplete="one-time-code" aria-label={`Số thứ ${i + 1}`} maxLength={6} autoFocus={autoFocus && i === 0}
          value={d.trim()} onChange={(e) => set(i, e.target.value, e.target)}
          onKeyDown={(e) => { if (e.key === 'Backspace' && !d.trim() && i > 0) ((e.target as HTMLElement).previousElementSibling as HTMLInputElement)?.focus(); }} />
      ))}
    </div>
  );
}

export function Thumb({ src, size = 64, radius = 12 }: { src?: string; size?: number; radius?: number }) {
  return (
    <div style={{ width: size, height: size, borderRadius: radius, background: 'var(--surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', flexShrink: 0 }}>
      {src ? <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <IconBag className="thumb-ph" size={Math.round(size * 0.42)} />}
    </div>
  );
}

export function Card({ children, pad = 16, bg = 'var(--surface)', style }: { children: ReactNode; pad?: number; bg?: string; style?: React.CSSProperties }) {
  return <div style={{ background: bg, borderRadius: 16, padding: pad, ...style }}>{children}</div>;
}

export function Stars({ value, onChange, label = 'Mức ưu tiên' }: { value: number; onChange?: (v: number) => void; label?: string }) {
  return (
    <span className={`stars${onChange ? '' : ' readonly'}`} role={onChange ? 'radiogroup' : 'img'} aria-label={`${label}: ${value}/5 sao`}>
      {[1, 2, 3, 4, 5].map((n) => (
        <button key={n} type="button" aria-pressed={n <= value} aria-label={onChange ? `${n} sao` : undefined} tabIndex={onChange ? 0 : -1}
          onClick={onChange ? () => onChange(n) : undefined}>★</button>
      ))}
    </span>
  );
}
export function VerdictTag({ label }: { label: string }) { return <span className="vtag">{label}</span>; }

// Icon nét 24px, vẽ lại theo bộ icon trong Figma (bookmark, shield-check, help, shopping-bag, …).
import type { SVGProps } from 'react';
type P = SVGProps<SVGSVGElement> & { size?: number };
const S = ({ size = 24, children, ...p }: P & { children: React.ReactNode }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" {...p}>{children}</svg>
);
export const IconBookmark = (p: P) => <S {...p}><path d="M6 3h12v18l-6-4-6 4z" /></S>;
export const IconShieldCheck = (p: P) => <S {...p}><path d="M12 3l8 3v6c0 4.5-3.4 8.1-8 9-4.6-.9-8-4.5-8-9V6z" /><path d="M8.5 12l2.5 2.5 4.5-5" /></S>;
export const IconHelp = (p: P) => <S {...p}><circle cx="12" cy="12" r="9" /><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6v.6" /><path d="M12 17h.01" /></S>;
export const IconBag = (p: P) => <S {...p}><path d="M6 7h12l-1 14H7z" /><path d="M9 7a3 3 0 0 1 6 0" /></S>;
export const IconCheckCircle = (p: P) => <S {...p}><circle cx="12" cy="12" r="9" /><path d="M8 12.5l2.5 2.5L16 9.5" /></S>;
export const IconCheck = (p: P) => <S {...p}><path d="M5 12.5l4.5 4.5L19 7.5" /></S>;
export const IconAlert = (p: P) => <S {...p}><circle cx="12" cy="12" r="9" /><path d="M12 7.5v5.5" /><path d="M12 16.5h.01" /></S>;
export const IconChevronDown = (p: P) => <S {...p}><path d="M6 9l6 6 6-6" /></S>;
export const IconExternal = (p: P) => <S {...p}><path d="M14 4h6v6" /><path d="M20 4l-9 9" /><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5" /></S>;
export const IconClose = (p: P) => <S {...p}><path d="M6 6l12 12M18 6L6 18" /></S>;
// Icon động cơ (Motive chip)
export const MotiveIcons: Record<string, (p: P) => JSX.Element> = {
  shield: (p) => <S {...p}><path d="M12 3l8 3v6c0 4.5-3.4 8.1-8 9-4.6-.9-8-4.5-8-9V6z" /></S>,
  sparkles: (p) => <S {...p}><path d="M12 4l1.8 4.6L18 10l-4.2 1.4L12 16l-1.8-4.6L6 10l4.2-1.4z" /><path d="M19 15l.7 1.8L21.5 17.5l-1.8.7L19 20l-.7-1.8-1.8-.7 1.8-.7z" /></S>,
  tag: (p) => <S {...p}><path d="M3 12V4h8l10 10-8 8z" /><circle cx="7.5" cy="8.5" r="1.2" /></S>,
  heart: (p) => <S {...p}><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z" /></S>,
  users: (p) => <S {...p}><circle cx="9" cy="8" r="3.5" /><path d="M2.5 20c.6-3.4 3.3-5.5 6.5-5.5s5.9 2.1 6.5 5.5" /><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8" /><path d="M18.5 14.8c1.7.8 2.8 2.6 3 5.2" /></S>,
  zap: (p) => <S {...p}><path d="M13 2L4 14h7l-1 8 9-12h-7z" /></S>,
  megaphone: (p) => <S {...p}><path d="M3 10v4h4l7 4V6L7 10z" /><path d="M17.5 9.5a4 4 0 0 1 0 5" /></S>,
  more: (p) => <S {...p}><circle cx="5" cy="12" r="1" /><circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /></S>,
};
export const IconSearch = (p: P) => <S {...p}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></S>;
export const IconDownload = (p: P) => <S {...p}><path d="M12 4v11" /><path d="M7 11l5 5 5-5" /><path d="M5 20h14" /></S>;
export const IconLink = (p: P) => <S {...p}><path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1" /><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1" /></S>;

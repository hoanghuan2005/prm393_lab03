# Design system — "Why I Buy?" product presentation website

## 1. Product context
- **What is presented:** "Why I Buy? — The Psychology of Money", a Flutter Android app (PRM393 final assignment, FPT University) that helps young people understand *why* they buy, not just how much: 8 buying motives (Nhu cầu, Mong muốn, Khuyến mãi, Cảm xúc, Ảnh hưởng MXH, Tiện lợi, Quảng cáo, Khác), a wishlist with a cooling-off delay ("2 ngày hoãn"), decisions Mua · Chờ · Bỏ qua, budgets that never turn red ("App không chặn mua"), patterns, AI insights (Gemini via Firebase AI Logic), a Chrome extension "Why I Buy?" that saves Shopee items, and a web admin (sale calendar, suggestions, announcements).
- **Tone:** "Hiểu mình, không phán xét" — calm, honest, non-judgmental. Never shame spending.
- **The site:** a one-page, scroll-driven **web presentation** used live in class (projector, 1920×1080 and 1366×768 laptops; also must work on phones). Left half: a **3D phone** (Three.js) whose screen shows the real app UI. Right half: the explanation of the current step. **Each wheel notch / ↓ / PageDown moves exactly one step** along the user journey and the phone auto-plays that step's micro-demo.
- **Story order (what the lecturer asked for: goal, target group, proof, UX):** Hero → Vấn đề (impulse buying) → Ai dùng & mục tiêu → user journey (Mở app → Đăng nhập → Trang chủ → Lưu món từ Shopee → Cân nhắc/hoãn → Trước khi mua → Ghi khoản mua → Ngân sách → Mô hình → Góc nhìn AI → Lịch sale & thông báo → Cá nhân) → Hệ sinh thái (app + extension + web admin + Firebase) → Bằng chứng (real test numbers) → Cảm ơn.

## 2. Visual direction — "Void Canvas" (inspired by spline.design) × Why I Buy brand
Mode: **inspired by** spline.design (extracted DNA in `.superdesign/website/spline.design/design.md`), blended with the app brand. Rules taken from Spline: a true-black void; the chrome stays achromatic; **color lives only in the 3D object** (the phone, its yellow back and the bright app screen) plus ONE rationed accent, the app yellow #FFDE02, used for the active step, key numbers and the primary CTA; mono-caps eyebrows above every headline; display type with tight negative tracking; frosted glass pills (rgba(255,255,255,.06) fill, 999px radius) as the only ambient texture; hairline borders instead of shadows. From the MiladiCode tutorial: a single soft light bloom behind the 3D object (here: a faint yellow glow emitted by the phone), never a page-wide gradient wash.

### Color tokens (site chrome)
| token | value | use |
|---|---|---|
| --bg | #000000 | the void (page background) |
| --surface | #101010 | raised panels, media cards (16px radius) |
| --ink | #FFFFFF | headings, primary text |
| --ink-soft | #EEEEEE | muted emphasis, near-white solid CTA fill |
| --ink-2 | #8A8A8A | body copy, nav items, secondary labels |
| --line | #2E2E2E | hairline borders / rules |
| --glass | rgba(255,255,255,.06), hover .09, emphasis .18; blur(12px) small controls, blur(40px) floating panels | rail nodes, chips, callouts |
| --brand | #FFDE02 | THE single accent (app primary) |
| --brand-ink | #0F172A | text on yellow (app onPrimary) |
| motive colors | need #3B82F6 · want #EC4899 · sale #F59E0B · emotion #A855F7 · social #0EA5E9 · convenience #14B8A6 · ads #2563EB · other #64748B | ONLY inside the phone screen and in tiny 8px motive dots |
- Background: flat #000. One radial bloom of #FFDE02 at ≤ 12% opacity directly behind the phone (reads as light from the object). No mesh/aurora gradients, no colored section washes, no grain heavier than 3%.
- Card edges: `inset 0 0 0 1px rgba(255,255,255,.06)`; no soft drop shadows on chrome.

### App UI inside the phone (must match the real app, light theme)
Scaffold #F8FAFC, cards #FFFFFF radius 16 with 1px #E2E8F0 border (flat, no shadow), text #0F172A / #334155 / #64748B / #94A3B8, primary buttons #FFDE02 pill with #0F172A text, 48px min height, Material icons (rounded/outlined), bottom nav 5 tabs (Trang chủ, Lịch sử, Mô hình, Góc nhìn, Cá nhân) selected #0F172A w700 / unselected #94A3B8. Money format '1.589.000 ₫'.

### Typography
- **Be Vietnam Pro** (Spline uses Geist, which lacks full Vietnamese; Be Vietnam Pro is the app's own font and covers every diacritic). Display/headlines weight 500–600 with tight negative tracking (≈ -0.055em, Spline-like engineered feel), line-height ≥ 1.1 so stacked diacritics (Ắ, Ễ, Ợ) never clip; hero wordmark may go 700. Body 400 at 16–18px/1.5.
- **JetBrains Mono** 400/500 for mono-caps eyebrows (11–12px, uppercase, +0.08em), step counters, data paths (e.g. `users/{uid}/wishlistItems`), tech chips.
- Scale (desktop): hero title clamp(64px, 8.5vw, 150px); chapter title clamp(40px, 4vw, 64px); lead 19–20px; body 16–17px.

### Layout
- Desktop ≥ 1024px: fixed full-viewport WebGL stage; phone centered in the left column (~46% width), phone height ≈ 78vh. Right column starts ~52vw, text max-width ~34rem, vertically centered per step (each step = 100vh section).
- Fixed **navbar** (Spline style): edge-to-edge, 64px tall, 0 radius, `rgba(0,0,0,.82)` + blur(12px), hairline bottom border. Left: app logo (yellow #FFDE02 circle with the spa/leaf icon, exactly as the app's WhyIBuyLogo) + "Why I Buy?" wordmark. Center: current chapter name in mono caps. Right: step counter "04 / 19" (ghost, #8A8A8A) + a near-white solid pill "Toàn màn hình" (#EEEEEE fill, black text, 34px).
- Fixed **flow rail** bottom center: frosted glass capsule holding a horizontal chain of step nodes joined by thin arrows ("Mở app → Đăng nhập → Trang chủ → …"); nodes are glass pills (rgba(255,255,255,.06), #8A8A8A text); the active node is filled #FFDE02 with #0F172A text; done nodes get a small yellow dot; auto-centers the active node; clickable.
- Each chapter: kicker (mono, "BƯỚC 04 · LƯU MÓN"), big title, lead paragraph, 3 talking points with small yellow square bullets, tech chips (Firebase Auth, Firestore, FCM, Gemini…), optional mono data path; a huge outlined step number in the background.
- Callouts: 1–2 small glass labels next to the phone with a hairline pointing to the exact UI element being demoed.
- Mobile < 900px: phone fixed in the upper ~55vh, text cards scroll underneath on a blurred dark backdrop; native scroll + snap.

### Motion
- Step change: phone eases to a new pose (≤ 20° yaw toward the text, small pitch), screen transitions like Android (shared-axis slide + fade, 450ms), then the micro-demo plays (tap ripple, typing, chips filling, bars growing) — 2–5s, deterministic.
- Text: line-mask reveal (rise from 110% → 0, stagger 60ms); chips fade + rise 8px. No springy overshoot (Spline restraint). Ease: expo.out / power3.inOut. Durations 0.6–1.1s; hover states 0.2s ease.
- Idle: phone floats ±0.03 units, follows the pointer by ±4°.
- Hero: phone spins in from its yellow back (logo on the back) to the front while the screen boots.
- prefers-reduced-motion: no spins/parallax, demos jump to end state, instant scroll.

## 3. Requirements
- Vietnamese copy everywhere, honest claims only (features must exist in the codebase).
- Works offline (single HTML build), 60fps on a mid laptop, keyboard + presenter-clicker friendly (↓ ↑ PageDown PageUp Space Home End, F = fullscreen).
- Accessible: real text (not images), contrast ≥ 4.5:1 for body, focus states on rail buttons.

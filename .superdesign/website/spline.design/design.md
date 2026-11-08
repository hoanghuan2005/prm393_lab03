---
version: "superdesign-alpha"
name: "Void Canvas"
description: "Near-black editorial system where a true-black pixel field carries mono-caps eyebrows, tight-tracked display type, and glass-pill controls; color exists only in embedded 3D viewport content, never in the chrome itself."
colors:
  background: "#000000"
  surface: "#101010"
  text-primary: "#FFFFFF"
  text-secondary: "#8A8A8A"
  text-tertiary: "#EEEEEE"
  border-hairline: "#2E2E2E"
  border-focus: "#8EB2F2"
  accent-blue: "#0062FF"
  accent-blue-light: "#5797FF"
  accent-blue-dark: "#217CE5"
typography:
  display-lg:
    fontFamily: "Geist"
    fontSize: "48px"
    fontWeight: 450
    lineHeight: "1.17"
    letterSpacing: "-2.9px"
  headline-md:
    fontFamily: "Geist"
    fontSize: "56px"
    fontWeight: 450
    lineHeight: "1.14"
    letterSpacing: "-3.4px"
  body-md:
    fontFamily: "Geist"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "1.5"
  label-md:
    fontFamily: "Geist Mono"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "1.55"
    letterSpacing: "0.9px"
  label-mono:
    fontFamily: "Geist Mono"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "1.55"
    letterSpacing: "0.9px"
  body-alt:
    fontFamily: "Spline Sans"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "1.5"
  accent-serif:
    fontFamily: "Times New Roman"
    style: "used as a rare serif interruption in interface mockup content, not in marketing type"
spacing:
  base: "4px"
  scale: "4px, 6px, 8px, 10px, 12px"
  gap-section: "40px"
  content-max-width: "256px"
rounded:
  control-tight: "6px"
  control: "8px"
  card: "16px"
  capsule: "50px"
  pill: "9999px"
components:
  button-primary-hero:
    background: "observed near-white/cream solid, approx #EEEEEE"
    text-color: "#000000"
    radius: "9999px"
    height: "44px"
    note: "observed on first screen; not in measured set — do not substitute glass button values here"
  button-nav-cta:
    background: "#EEEEEE"
    text-color: "#000000"
    radius: "999px"
    height: "34px"
  button-nav-utility:
    background: "transparent"
    text-color: "#8A8A8A"
    radius: "8px"
    height: "32px"
    padding: "0px 10px"
  button-glass-outline:
    background: "rgba(255, 255, 255, 0.06)"
    text-color: "#FFFFFF"
    radius: "999px"
    height: "36px"
    padding: "0px 14px 0px 12px"
    hover-background: "rgba(255, 255, 255, 0.09)"
    hover-text: "#FFFFFF"
  button-glass-muted:
    background: "rgba(255, 255, 255, 0.06)"
    text-color: "#8A8A8A"
    radius: "999px"
    height: "44px"
    padding: "0px 20px"
  button-glass-emphasis:
    background: "rgba(255, 255, 255, 0.18)"
    text-color: "#EEEEEE"
    radius: "999px"
    height: "44px"
    padding: "0px 20px"
  card-media-bleed:
    background: "#101010"
    radius: "16px"
    padding: "0px"
  card-tile-feature:
    background: "transparent"
    radius: "0px"
    padding: "256px 0px 0px 0px"
  card-checklist:
    background: "transparent"
    radius: "0px"
    padding: "0px"
  card-dense-text:
    background: "transparent"
    radius: "0px"
    padding: "12px"
---
# Void Canvas
Source: https://spline.design/

## Overview
This is a dark-mode-default, editorial/typographic system built almost entirely in true black, with glassmorphic control surfaces as its only ambient texture. The aesthetic is Swiss-adjacent in its restraint — tight negative letter-spacing on display type, mono-caps eyebrows, hairline rules — but softened by frosted glass pills and a sticky blurred navbar. Color is not a palette here; it is a rationed intrusion, confined almost entirely to embedded 3D viewport content (an ochre desert scene, a dark cube with red/green/blue axis handles). The chrome itself — nav, buttons, cards — stays grayscale.

## Composition
The first screen centers everything: a capsule eyebrow pill, a two-line display headline with two underlined words and one bracket-selected word, a muted subheadline, and a dark glass prompt-input module stacked above a row of four small capsule shortcut chips. Below the fold, an embedded product/editor mockup bleeds at the base of the viewport — immediately grounding the abstract headline in a tool screenshot. Section rhythm below is consistently: a small mono-caps eyebrow, a large left-aligned headline (sometimes split across two lines, sometimes paired with underlines), then either a logo strip, a horizontal scrolling rail of category pills feeding one large preview card with two peeking side-neighbors, a two-column text+editor-mockup split, or a three-column platform/testimonial band. The deliberate choice is restraint: center-aligned hero copy against a void, rather than a saturated gradient/mesh hero — this keeps the page reading as a tool, not a marketing splash, and rejects the aurora-gradient-hero convention common to adjacent AI product sites.

## Colors
The pixel field is ~79% pure `#000000` background with ~16% `#181818`-range near-black surfaces (cards, panels) and only ~2–3% warmer or lighter accents (the `#C07860`-range desert-scene imagery, mid-gray `#303030`/`#484848` UI chrome). Text ink runs `#FFFFFF` for primary headings and interface copy, `#EEEEEE` for slightly muted emphasis (capsule CTA fills, secondary headline weight), and `#8A8A8A` for secondary/muted labels, nav items, and button copy. Borders are near-invisible hairlines at `#2E2E2E`, with one blue focus-ring token (`#8EB2F2`) reserved for selection states. The declared `--color-blue` family (`#0062FF`, `#5797FF`, `#217CE5`, `#5966F3`) exists as a token set but is essentially never seen as a dominant fill in the pixel field — it is the system's held-in-reserve accent, likely surfacing only in tiny interactive/selection UI, not in marketing surfaces. Nothing is tinted or saturated by design; the entire chrome stays achromatic so that embedded 3D/video content supplies the only chroma.

## Typography
Display and headline type is Geist at 48–56px, weight 450, with aggressively tight negative tracking (-2.9px to -3.4px) and line-height near 1.14–1.17 — this tightness is what gives the large headlines their compact, engineered character despite their size. Body copy drops to 16px/400 at 1.5 line-height, authored in Geist and, in some body passages, Spline Sans — both are plain grotesques so the switch is invisible; treat them as interchangeable UI/body workhorses. Mono-caps eyebrow labels (11px, Geist Mono, 0.9px tracking, uppercase) sit above nearly every section headline — this is the system's structural rhythm marker, not decoration. A serif (Times New Roman) appears only inside embedded editor/mockup content, never in real marketing type — treat it as found object, not a brand font.

## Layout
Content is capped around a 760px measure for body-copy columns, with wider full-bleed zones for media and the horizontal card rail. Card and grid evidence shows several distinct patterns: a 2-up equal-split row (gap 40px), a 3-column asymmetric row with items sized roughly 23%/77%/75% of their tracks (an uneven feature trio, not a uniform grid), and vertical stacked groups (gap 24px) mixing a short label row, a mid-size block, and one full-bleed element. Dense feature/checklist cards use tight 12px padding in strict single-column (4-row) stacks. Spacing primitives are small and exacting (4/6/8/10/12px), reflecting a controls-dense, engineering-tool sensibility rather than generous marketing whitespace — justified further by the near-zero padding (0px) on most content cards, which rely on internal typographic spacing rather than card chrome.

## Components
- **Navbar**: edge-to-edge square bar, 65px tall, spans full 1920px viewport width with 0px inset on both edges, all four corners 0px radius (no rounding at all — a true full-bleed bar, not an inset capsule), sticky on scroll, fill `rgba(0, 0, 0, 0.82)` with `backdrop-filter: blur(12px)`. Carries 9 items: a logo mark + wordmark at left, horizontal text nav items through center-left, and at right a secondary ghost-style utility button (transparent, `#8A8A8A` text, 8px radius, 32px height) followed by the primary nav CTA — `#EEEEEE` fill, `#000000` text, 999px radius, 34px height.
- **Hero primary button**: the solid near-white/cream pill beneath the hero headline (seen, not in the measured set) — approximate fill `#EEEEEE`-range, black text, full pill radius ~9999px, ~44px height. This is the single highest-contrast control on the page and must not be rendered with any glass/translucent fill.
- **Glass outline button** (first-screen shortcut chips): `rgba(255, 255, 255, 0.06)` fill, `#FFFFFF` text, 999px radius, 36px height, padding `0px 14px 0px 12px`; hover lightens fill to `rgba(255, 255, 255, 0.09)`. Used for the icon-label chip row under the hero prompt module.
- **Glass muted button** (mid-page, ×20): `rgba(255, 255, 255, 0.06)` fill, `#8A8A8A` text, 999px radius, 44px height, padding `0px 20px` — the workhorse secondary control used for horizontal category/filter pills.
- **Glass emphasis button** (mid-page, single instance): `rgba(255, 255, 255, 0.18)` fill, `#EEEEEE` text, 999px radius, 44px height — a brighter glass variant reserved for one standout action (e.g. "make your own" style CTA beside a preview card).
- **Media-bleed card** (×14, mid-page): `#101010` fill, 16px radius, 0px padding, top-bled screenshot/illustration media filling the card with caption content below — the primary showcase-card family for embedded 3D previews.
- **Feature tile group** (×6, mid-page): transparent background, 0px radius, top padding 256px reserving space for a media element above, then heading + body text, each containing 4 sub-tiles in a strict single-column stack of six full-width rows — reads as a vertically alternating media/text feature sequence, not a side-by-side grid.
- **Checklist/spec card** (×4, near page end): transparent, 0px radius/padding, heading + list + body text + 2 inline tiles — used for the platform/runtime capability rows (web/Apple/Android style triplets).
- **Dense text card** (×4, first screen; ×4 and ×4 again mid-page): transparent, 0px radius, 12px padding, strict single-column 4-row stacks — used for compact label/value or testimonial-adjacent text blocks.
- **Icon-label card** (×3, mid-page): transparent, heading + icon + body text, no card chrome — used for a small feature triptych.
- **Logo strip**: a horizontal scrolling rail of grayscale wordmarks/logos directly beneath the embedded editor mockup, no card background, simple left-to-right list.
- **Footer**: transparent background, 42 links organized into labeled columns (mono-caps category headers), logo + mark at far left, legal/contact links at far right, hairline divider above the copyright row, social icons bottom-right.

## Graphics & Effects
A single measured gradient, `linear-gradient(90deg, rgba(0, 0, 0, 0.6), rgba(0, 0, 0, 0.36) 55%, rgba(0, 0, 0, 0.26))`, functions as a horizontal scrim laid directly over embedded media (the desert/rover viewport), covering roughly the left-to-right width of that one media panel only — it darkens the left edge for caption legibility and is not a page-wide wash; the surrounding hero and page remain flat black. Live interactive surfaces are rendered as canvas/video elements (3D viewport previews, an editor scene panel) — when rebuilt as static, substitute a flat dark-gray placeholder or single still frame, never a gradient fill. Elevation is communicated through inset/outset hairline shadows rather than soft drop shadows: `rgba(255, 255, 255, 0.06) 0px 0px 0px 1px inset` for subtle card edge-lighting, and crisp `rgb(16, 16, 16) 0px 0px 0px 2px` / `rgb(29, 29, 29) 0px 0px 0px 2px` rings for focus/selection outlines on editor-style components. Two backdrop-blur strengths are in use: `blur(12px)` for the sticky navbar and small glass controls, `blur(40px)` for heavier floating panels.

## Motion
Interactive state changes are fast and linear-feeling: `color 0.2s ease`, `opacity 0.2s ease`, and a combined `background, color 0.2s, 0.2s ease, ease` for hover transitions — no springy overshoot anywhere in the system. A longer `opacity 0.25s ease` governs section/content fades. Named keyframe animations (`drop`, `bounce`, `marquee`, `blink`, `cursor-x`, `cursor-y`) point to a simulated-typing/cursor-trail effect inside editor mockups and a marquee scroll for the logo strip. CSS scroll-driven animations are present, implying content reveals tied directly to scroll position rather than purely time-based entrance animation.

## Guardrails
- Never fill the hero background with the measured scrim gradient — that string belongs only to one media panel's overlay, not the page.
- Never render the hero primary button as a translucent glass pill — it is a solid near-white/cream fill with black text, distinct from every glass control measured.
- Keep all card and button radii literal: 0px flat cards must stay flat, 16px media cards stay softly rounded, pill controls stay full 999px — do not normalize them to one shared radius.
- Do not introduce saturated gradients, mesh backgrounds, or colored section washes; color must stay confined to embedded 3D/media content.
- Preserve the navbar as a true edge-to-edge, zero-radius bar at 65px height with blur — do not convert it to an inset or centered capsule.
- Keep letter-spacing tight and negative on display type; loosening it removes the system's defining engineered feel.
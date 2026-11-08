# Design system v2 — "Paper & Highlighter" (Why I Buy? project defense deck)

Goal: a distinctive editorial look that does NOT read like a generic AI-generated dark landing page.
Explicitly avoid: black void backgrounds, neon/yellow glow blooms, condensed all-caps display fonts, mono-caps
eyebrow labels with numbers ("15 — …"), frosted glass pills, giant outlined background numerals, Inter/Geist.

## Mood
Printed design-review handout / risograph zine. Warm paper, black ink, a yellow highlighter pen (the app's own
#FFDE02) that marks the key words, and papercraft 2.5D diagrams: flat sheets stacked with crisp offset shadows.

## Colour
| token | value | use |
|---|---|---|
| paper | #F3EFE6 | page background |
| paper-2 | #EAE4D7 | panels, sheet backs |
| card | #FFFDF8 | sheet faces, cards |
| ink | #16130F | text, strokes, sheet outlines (1.5px) |
| ink-2 | #5E574C | secondary text |
| rule | #D6CDBB | hairlines, grid |
| highlight | #FFDE02 | marker strokes behind words, active state fill (never as glow) |
| forest | #1F4D3A | "good/terminal" states, links |
| brick | #C2462B | exceptions, warnings (sparingly) |
App motive colours (#3B82F6 need, #EC4899 want, #F59E0B sale, #A855F7 emotion, #0EA5E9 social, #14B8A6 convenience,
#2563EB ads, #64748B other) appear only as small dots/tags tied to the app's data.

## Type (both support Vietnamese)
- Display: **Fraunces** (serif, optical size), 500–600, slight negative tracking, generous line-height 1.08–1.12.
  Slide titles are full conclusion sentences (guideline: "tiêu đề là câu kết luận").
- Text/UI: **Bricolage Grotesque** 400/500/600, 15–18px body.
- Labels: Bricolage Grotesque 600, small caps style via letter-spacing .04em, NOT monospace.
- Numbers: Fraunces lining figures for big stats.

## Layout (16:9, 1440x900 reference)
- Slide frame: 56px outer margin, a thin ink rule under a running header (left: "Why I Buy? · PRM393",
  right: section name + "08/24" in plain text). Footer: source line in ink-2 11px.
- Grid: 12 columns. Design slides: diagram spans 8 columns, a 4-column notes rail on the right with
  "Câu hỏi hội đồng", 3 bullets, and one evidence line.
- Highlight marks: a skewed #FFDE02 band (height 0.42em, slightly rotated -1deg) behind 1–3 key words.

## 2.5D papercraft diagrams
- Nodes are paper sheets: card face #FFFDF8, 1.5px ink outline, 10px radius, and a crisp offset "shadow sheet"
  (#16130F at 100%, offset 6px 6px, no blur) — like a cut-paper layer. Stacked sheets for grouped systems.
- The diagram plane is tilted in CSS 3D (rotateX ~ 52deg, rotateZ ~ -32deg, isometric feel); node labels are
  counter-rotated so text stays upright and readable. A faint dotted grid (#D6CDBB) on the plane.
- Connectors: ink 1.5px paths with a small filled arrowhead; event labels on connectors sit in small card tags.
- Active/current state: highlight yellow face. Terminal states: forest outline. Exceptions: brick dashed path.
- Motion (for the live site): sheets drop in with a short paper-settle (y -12px -> 0, 400ms, ease-out-back small),
  connectors draw (stroke-dashoffset), the active state hops along the path.

## 2D flat diagrams (text-heavy: ERD, class, sequence, traceability, tech stack, testing)
Same paper + ink language, no tilt: ruled tables, ink boxes with offset shadow, highlight bands for keys.

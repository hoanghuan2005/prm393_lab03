/**
 * Diagram kit for the Design / Problem / Proof slides (dark theme of the site).
 * A diagram is data: nodes on a W x H grid and edges between them. The SVG
 * connectors are computed from node geometry, so diagrams stay easy to edit.
 *
 *   graph({ w: 1000, h: 620, deep: true, nodes: [...], edges: [...] })
 *   node: { id, x, y, w, h, title, sub, code, tone: 'accent'|'ok'|'ext'|'muted'|'warn', z: 0..3, cls }
 *   edge: { from, to, fs, ts ('l'|'r'|'t'|'b'), label, dash, warn, via: [[x,y], ...], lx, ly }
 */
const pct = (v, total) => `${((v / total) * 100).toFixed(3)}%`

function anchor(n, side) {
  switch (side) {
    case 'l':
      return [n.x, n.y + n.h / 2]
    case 'r':
      return [n.x + n.w, n.y + n.h / 2]
    case 't':
      return [n.x + n.w / 2, n.y]
    case 'b':
      return [n.x + n.w / 2, n.y + n.h]
    default:
      return [n.x + n.w / 2, n.y + n.h / 2]
  }
}

function autoSides(a, b) {
  const dx = b.x + b.w / 2 - (a.x + a.w / 2)
  const dy = b.y + b.h / 2 - (a.y + a.h / 2)
  if (Math.abs(dx) >= Math.abs(dy)) return dx > 0 ? ['r', 'l'] : ['l', 'r']
  return dy > 0 ? ['b', 't'] : ['t', 'b']
}

export function graph({ w = 1000, h = 620, deep = false, nodes = [], edges = [], cls = '' }) {
  const byId = Object.fromEntries(nodes.map((n) => [n.id, n]))
  const paths = edges
    .map((e, i) => {
      const a = byId[e.from]
      const b = byId[e.to]
      if (!a || !b) return ''
      const [fs, ts] = e.fs && e.ts ? [e.fs, e.ts] : autoSides(a, b)
      const pts = [e.fp || anchor(a, e.fs || fs), ...(e.via || []), e.tp || anchor(b, e.ts || ts)]
      const d = pts.map((p, k) => `${k ? 'L' : 'M'}${p[0]},${p[1]}`).join(' ')
      // label at the middle of the longest segment unless given
      let mx = 0
      let my = 0
      let best = -1
      for (let k = 0; k < pts.length - 1; k++) {
        const len = Math.hypot(pts[k + 1][0] - pts[k][0], pts[k + 1][1] - pts[k][1])
        if (len > best) {
          best = len
          mx = (pts[k][0] + pts[k + 1][0]) / 2
          my = (pts[k][1] + pts[k + 1][1]) / 2
        }
      }
      const lx = e.lx ?? mx
      const ly = e.ly ?? my
      return {
        svg: `<path class="dg-edge ${e.dash ? 'is-dash' : ''} ${e.warn ? 'is-warn' : ''}" d="${d}" pathLength="1" marker-end="url(#dg-arrow${e.warn ? '-warn' : ''})" style="--i:${i}"/>`,
        label: e.label
          ? `<span class="dg-tag ${e.warn ? 'is-warn' : ''}" style="left:${pct(lx, w)};top:${pct(ly, h)};--i:${i}">${e.label}</span>`
          : '',
      }
    })
    .filter(Boolean)
  const nodeHtml = nodes
    .map(
      (n, i) => `<div class="dg-node dg-node--${n.tone || 'base'} ${n.cls || ''}" data-node="${n.id}" style="left:${pct(n.x, w)};top:${pct(n.y, h)};width:${pct(n.w, w)};height:${pct(n.h, h)};--z:${n.z ?? 1};--i:${i}">
        ${n.kicker ? `<span class="dg-kicker">${n.kicker}</span>` : ''}
        ${n.title ? `<span class="dg-title">${n.title}</span>` : ''}
        ${n.sub ? `<span class="dg-sub">${n.sub}</span>` : ''}
        ${n.code ? `<code class="dg-code">${n.code}</code>` : ''}
        ${n.html || ''}
      </div>`,
    )
    .join('')
  return `<div class="dg ${deep ? 'dg--deep' : ''} ${cls}" style="--ar:${w}/${h}">
    <div class="dg-plane">
      ${deep ? '<div class="dg-floor"></div>' : ''}
      <svg class="dg-svg" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none" aria-hidden="true">
        <defs>
          <marker id="dg-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#d9d9d9"/></marker>
          <marker id="dg-arrow-warn" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#f87171"/></marker>
        </defs>
        ${paths.map((p) => p.svg).join('')}
      </svg>
      ${nodeHtml}
      ${paths.map((p) => p.label).join('')}
    </div>
  </div>`
}

/** ruled table: cols = [{ label, w }], rows = [[cell, ...]]; cell may be html */
export function table({ cols, rows, cls = '' }) {
  const tpl = cols.map((c) => c.w || '1fr').join(' ')
  return `<div class="dt ${cls}" style="--cols:${tpl}">
    <div class="dt-row dt-head">${cols.map((c) => `<span>${c.label}</span>`).join('')}</div>
    ${rows.map((r, i) => `<div class="dt-row" style="--i:${i}">${r.map((c) => `<span>${c}</span>`).join('')}</div>`).join('')}
  </div>`
}

export const tag = (t, tone = '') => `<em class="dg-pill ${tone ? `is-${tone}` : ''}">${t}</em>`

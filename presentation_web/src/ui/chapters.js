/**
 * Renders the right-hand text of every step from src/data/chapters.js and
 * plays the text reveal when a step becomes active.
 */
import gsap from 'gsap'
import { SplitText } from 'gsap/SplitText'

gsap.registerPlugin(SplitText)

const pad = (n) => String(n).padStart(2, '0')

function chipsHtml(chips = []) {
  if (!chips.length) return ''
  return `<div class="chips">${chips.map((c) => `<span class="chip ${c.kind ? `chip--${c.kind}` : ''}">${c.label}</span>`).join('')}</div>`
}

function heroHtml(ch) {
  return `
    <div class="chapter__inner">
      <p class="eyebrow" data-r><b>●</b><i></i>${ch.eyebrow}</p>
      <h1 class="hero__title" data-r>Why I Buy<span>?</span></h1>
      <p class="hero__lead" data-r>Khoan đã: mình mua vì cần, hay vì cảm xúc? Một app giúp người trẻ hiểu <strong style="color:#fff;font-weight:600">động cơ đằng sau mỗi lần mua sắm</strong>.</p>
      <div class="hero__meta" data-r>
        <span class="chip chip--android">App Android · Flutter</span>
        <span class="chip chip--web">Tiện ích Chrome</span>
        <span class="chip chip--web">Web admin</span>
        <span class="chip chip--firebase">Firebase</span>
      </div>
    </div>`
}

function wfHtml(wf) {
  return `
    <dl class="wf" data-r>
      <dt>Actor</dt><dd>${wf.actor}</dd>
      <dt>Trigger</dt><dd>${wf.trigger}</dd>
      <dt>Điều kiện</dt><dd>${wf.pre}</dd>
      <dt>Kết quả</dt><dd>${wf.result}</dd>
      <dt>Ngoại lệ</dt><dd>${wf.exception}</dd>
    </dl>
    <ol class="wf-steps" data-r>${wf.steps.map((st) => `<li data-s="${st.s}">${st.t}</li>`).join('')}</ol>`
}

function chapterHtml(ch, i, total) {
  if (ch.kind === 'hero') return heroHtml(ch)
  const eyebrow = `<b>${pad(i + 1)}</b><i></i>${ch.part.startsWith('WF') ? 'Demo' : ch.part} · ${ch.eyebrow}`
  return `
    <div class="chapter__num" aria-hidden="true">${pad(i + 1)}</div>
    <div class="chapter__inner">
      <p class="eyebrow" data-r>${eyebrow}</p>
      <h2 class="chapter__title" id="t-${ch.id}" data-split>${ch.title}</h2>
      ${ch.qa ? `<p class="qa" data-r><b>Câu hỏi hội đồng</b>${ch.qa}</p>` : ''}
      ${ch.lead ? `<p class="chapter__lead" data-r>${ch.lead}</p>` : ''}
      ${ch.wf ? wfHtml(ch.wf) : ''}
      ${ch.points ? `<ul class="points">${ch.points.map((p) => `<li data-r>${p}</li>`).join('')}</ul>` : ''}
      ${ch.evidence ? `<p class="evidence" data-r>${ch.evidence}</p>` : ''}
      ${ch.chips ? `<div data-r>${chipsHtml(ch.chips)}</div>` : ''}
      ${ch.path ? `<code class="datapath" data-r>${ch.path}</code>` : ''}
      ${ch.note ? `<p class="note" data-r>${ch.note}</p>` : ''}
    </div>`
}

export class ChapterText {
  constructor(container, chapters) {
    this.container = container
    this.chapters = chapters
    this.sections = chapters.map((ch, i) => {
      const s = document.createElement('section')
      s.className = `chapter chapter--${ch.kind || 'step'}${ch.visual ? ' chapter--visual' : ''}`
      s.id = ch.id
      s.dataset.index = i
      if (ch.title) s.setAttribute('aria-labelledby', `t-${ch.id}`)
      s.innerHTML = chapterHtml(ch, i, chapters.length)
      container.appendChild(s)
      return s
    })
    this.splits = []
    this.reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
    this.played = new Set()
  }

  /** split titles into masked lines once fonts are ready */
  split() {
    this.sections.forEach((s) => {
      const t = s.querySelector('[data-split]')
      if (!t) return
      const split = SplitText.create(t, {
        type: 'lines',
        mask: 'lines',
        linesClass: 'split-line',
        autoSplit: true,
        onSplit: (self) => {
          if (this.played.has(s.dataset.index)) gsap.set(self.lines, { yPercent: 0 })
          else gsap.set(self.lines, { yPercent: 115 })
        },
      })
      s._split = split
    })
    this.sections.forEach((s) => {
      const els = s.querySelectorAll('[data-r], [data-ri]')
      if (els.length) gsap.set(els, { opacity: 0, y: 18 })
    })
  }

  /** reveal the text of step i (only the first time it is reached) */
  reveal(i) {
    const s = this.sections[i]
    if (!s) return
    const key = String(i)
    if (this.played.has(key)) return
    this.played.add(key)
    const lines = s._split?.lines || []
    const items = s.querySelectorAll('[data-r]')
    const inner = s.querySelectorAll('[data-ri]')
    if (this.reduced) {
      gsap.set(lines, { yPercent: 0 })
      gsap.set([...items, ...inner], { opacity: 1, y: 0 })
      return
    }
    const tl = gsap.timeline()
    if (lines.length) tl.to(lines, { yPercent: 0, duration: 1.05, stagger: 0.07, ease: 'expo.out' }, 0)
    if (items.length) tl.to(items, { opacity: 1, y: 0, duration: 0.8, stagger: 0.06, ease: 'expo.out' }, 0.12)
    if (inner.length) tl.to(inner, { opacity: 1, y: 0, duration: 0.7, stagger: 0.05, ease: 'expo.out' }, 0.3)
    s.querySelectorAll('[data-count]').forEach((el) => {
      const to = parseInt(el.dataset.count, 10)
      if (!Number.isFinite(to)) return
      const o = { v: 0 }
      tl.to(o, { v: to, duration: 1.4, ease: 'power3.out', onUpdate: () => (el.textContent = Math.round(o.v)) }, 0.35)
    })
  }
}

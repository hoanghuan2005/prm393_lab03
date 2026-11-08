/**
 * Bottom rail: the parts of the guideline in order
 * "Problem → Design → Demo → WF-01 → WF-02 → WF-03 → Proof".
 * The current part is yellow, finished parts get a yellow dot; click jumps to its first slide.
 */
import gsap from 'gsap'

const ARROW = `<svg class="rail__arrow" viewBox="0 0 16 16" aria-hidden="true"><path d="M3 8h9M8.5 4.5 12 8l-3.5 3.5" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`

export class Rail {
  constructor({ rail, track, chapters, onPick }) {
    this.rail = rail
    this.track = track
    this.chapters = chapters
    this.parts = []
    chapters.forEach((c, i) => {
      if (!this.parts.find((p) => p.label === c.part)) this.parts.push({ label: c.part, first: i })
    })
    this.track.innerHTML = this.parts
      .map((p, n) => `${n ? ARROW : ''}<button class="rail__node" type="button" data-goto="${p.first}" aria-label="${p.label}"><span class="rail__dot"></span>${p.label}</button>`)
      .join('')
    this.nodes = [...this.track.querySelectorAll('.rail__node')]
    this.arrows = [...this.track.querySelectorAll('.rail__arrow')]
    this.track.addEventListener('click', (e) => {
      const b = e.target.closest('[data-goto]')
      if (b) onPick(+b.dataset.goto)
    })
    this.last = -1
    window.addEventListener('resize', () => this.center(this.last, true))
  }

  set(chapterIndex) {
    this.rail.classList.toggle('is-hidden', chapterIndex === 0)
    const active = this.parts.findIndex((p) => p.label === this.chapters[chapterIndex].part)
    this.nodes.forEach((node, n) => {
      node.classList.toggle('is-active', n === active)
      node.classList.toggle('is-done', n < active)
      if (n === active) node.setAttribute('aria-current', 'step')
      else node.removeAttribute('aria-current')
    })
    this.arrows.forEach((a, n) => a.classList.toggle('is-done', n < active))
    this.last = active
    this.center(active)
  }

  center(n, instant = false) {
    const node = this.nodes[n]
    if (!node) return
    const railW = this.rail.clientWidth
    const trackW = this.track.scrollWidth
    const target = railW / 2 - (node.offsetLeft + node.offsetWidth / 2)
    const x = trackW <= railW ? (railW - trackW) / 2 : Math.max(railW - trackW, Math.min(0, target))
    gsap.to(this.track, { x, duration: instant ? 0 : 0.8, ease: 'power3.inOut', overwrite: true })
  }
}

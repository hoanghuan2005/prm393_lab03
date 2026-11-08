/**
 * Bottom flow rail: "Mở app → Đăng nhập → Trang chủ → …". The active step is
 * yellow, finished steps get a yellow dot, and the track slides so the
 * active node stays centred. Clicking a node jumps to that step.
 */
import gsap from 'gsap'

const ARROW = `<svg class="rail__arrow" viewBox="0 0 16 16" aria-hidden="true"><path d="M3 8h9M8.5 4.5 12 8l-3.5 3.5" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`

export class Rail {
  constructor({ rail, track, chapters, onPick }) {
    this.rail = rail
    this.track = track
    this.items = chapters.map((c, i) => ({ c, i })).filter((x) => x.c.rail)
    this.track.innerHTML = this.items
      .map(
        ({ c, i }, n) =>
          `${n ? ARROW : ''}<button class="rail__node" type="button" data-goto="${i}" aria-label="Bước ${n + 1}: ${c.rail}"><span class="rail__dot"></span>${c.rail}</button>`,
      )
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

  /** chapter index -> highlight */
  set(chapterIndex) {
    const firstStep = this.items[0].i
    this.rail.classList.toggle('is-hidden', chapterIndex < firstStep - 1)
    // active = the journey step at this chapter; done = steps before it
    let activeN = -1
    this.items.forEach(({ i }, n) => {
      if (i === chapterIndex) activeN = n
    })
    const passed = this.items.filter(({ i }) => i < chapterIndex).length
    this.nodes.forEach((node, n) => {
      node.classList.toggle('is-active', n === activeN)
      node.classList.toggle('is-done', activeN === -1 ? n < passed : n < activeN)
      if (n === activeN) node.setAttribute('aria-current', 'step')
      else node.removeAttribute('aria-current')
    })
    this.arrows.forEach((a, n) => a.classList.toggle('is-done', n < (activeN === -1 ? passed - 1 : activeN)))
    const focus = activeN >= 0 ? activeN : Math.min(Math.max(passed - 1, 0), this.nodes.length - 1)
    this.last = focus
    this.center(focus)
  }

  center(n, instant = false) {
    const node = this.nodes[n]
    if (!node) return
    const railW = this.rail.clientWidth
    const trackW = this.track.scrollWidth
    const target = railW / 2 - (node.offsetLeft + node.offsetWidth / 2)
    const min = railW - trackW
    const x = trackW <= railW ? (railW - trackW) / 2 : Math.max(min, Math.min(0, target))
    gsap.to(this.track, { x, duration: instant ? 0 : 0.8, ease: 'power3.inOut', overwrite: true })
  }
}

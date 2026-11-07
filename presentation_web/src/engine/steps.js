/**
 * Step navigation. On desktop one wheel gesture, ↓/↑, PageDown/PageUp,
 * Space or a presenter clicker moves exactly one step (fullpage style).
 * Native scrolling (scrollbar, touch, very tall steps) still works: the
 * active step is always derived from the scroll position.
 */
import gsap from 'gsap'
import { ScrollToPlugin } from 'gsap/ScrollToPlugin'

gsap.registerPlugin(ScrollToPlugin)

export class Steps {
  constructor({ sections, onActivate, onKey }) {
    this.sections = sections
    this.onActivate = onActivate
    this.onKey = onKey
    this.current = -1
    this.target = null
    this.locked = false
    this.quietTimer = null
    this.reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
    this.wheelMode = () => window.innerWidth >= 900 && !matchMedia('(pointer: coarse)').matches

    window.addEventListener('wheel', (e) => this.onWheel(e), { passive: false })
    window.addEventListener('keydown', (e) => this.onKeyDown(e))
    let ticking = false
    window.addEventListener(
      'scroll',
      () => {
        if (ticking) return
        ticking = true
        requestAnimationFrame(() => {
          ticking = false
          this.syncFromScroll()
        })
      },
      { passive: true },
    )
    window.addEventListener('resize', () => {
      if (this.current >= 0 && !this.target) window.scrollTo(0, this.sections[this.current].offsetTop)
    })
  }

  indexFromScroll() {
    const probe = window.scrollY + window.innerHeight * 0.45
    let idx = 0
    for (let i = 0; i < this.sections.length; i++) {
      if (this.sections[i].offsetTop <= probe) idx = i
    }
    return idx
  }

  syncFromScroll() {
    if (this.target !== null) return // a programmatic move is running
    const i = this.indexFromScroll()
    if (i !== this.current) this.activate(i, i > this.current ? 1 : -1)
  }

  activate(i, dir) {
    if (i === this.current) return
    this.current = i
    this.onActivate(i, dir)
  }

  go(i, { instant = false } = {}) {
    const n = Math.max(0, Math.min(this.sections.length - 1, i))
    const dir = n >= this.current ? 1 : -1
    const y = this.sections[n].offsetTop
    gsap.killTweensOf(window)
    if (instant || this.reduced) {
      this.target = null
      window.scrollTo(0, y)
      this.activate(n, dir)
      return
    }
    this.target = n
    this.locked = true
    // activate right away so the phone starts moving with the scroll
    this.activate(n, dir)
    gsap.to(window, {
      scrollTo: { y, autoKill: false },
      duration: 1.05,
      ease: 'power3.inOut',
      onComplete: () => {
        this.target = null
        this.armQuiet()
      },
    })
  }

  next() {
    this.go((this.target ?? this.current) + 1)
  }

  prev() {
    this.go((this.target ?? this.current) - 1)
  }

  /** stay locked until the wheel has been quiet for a moment (trackpad inertia) */
  armQuiet() {
    clearTimeout(this.quietTimer)
    this.quietTimer = setTimeout(() => (this.locked = false), 220)
  }

  onWheel(e) {
    if (e.ctrlKey || !this.wheelMode()) return
    const dy = Math.abs(e.deltaY) > Math.abs(e.deltaX) ? e.deltaY : 0
    const dir = Math.sign(dy)
    // let very tall steps scroll natively until their edge
    const s = this.sections[this.current]
    if (s && this.target === null && !this.locked && dir) {
      const top = s.offsetTop
      const bottom = top + s.offsetHeight - window.innerHeight
      if (bottom > top + 8) {
        if (dir > 0 && window.scrollY < bottom - 4) return
        if (dir < 0 && window.scrollY > top + 4) return
      }
    }
    e.preventDefault()
    if (this.locked) {
      if (this.target === null) this.armQuiet()
      return
    }
    if (Math.abs(dy) < 3) return
    if (dir > 0) this.next()
    else this.prev()
  }

  onKeyDown(e) {
    if (e.altKey || e.metaKey || e.ctrlKey) return
    const tag = (e.target && e.target.tagName) || ''
    if (/INPUT|TEXTAREA|SELECT/.test(tag)) return
    const k = e.key
    if (['ArrowDown', 'PageDown', 'ArrowRight'].includes(k) || (k === ' ' && !e.shiftKey)) {
      e.preventDefault()
      this.next()
    } else if (['ArrowUp', 'PageUp', 'ArrowLeft'].includes(k) || (k === ' ' && e.shiftKey)) {
      e.preventDefault()
      this.prev()
    } else if (k === 'Home') {
      e.preventDefault()
      this.go(0)
    } else if (k === 'End') {
      e.preventDefault()
      this.go(this.sections.length - 1)
    } else {
      this.onKey?.(k, e)
    }
  }
}

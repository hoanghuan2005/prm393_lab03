/**
 * Device: builds the phone's DOM display (status bar, punch hole, gesture
 * bar, finger, glare) and swaps app screens with Android-like transitions,
 * then plays each screen's scripted demo.
 */
import gsap from 'gsap'
import { createKit } from '../screens/kit.js'

const STATUS_ICONS = `
<svg viewBox="0 0 24 24"><path d="M2 22h20V2z" opacity=".3"/><path d="M17 7L2 22h15z"/></svg>
<svg viewBox="0 0 24 24"><path d="M12 21.5l11.6-14.4C23.1 6.7 18.6 3 12 3S.9 6.7.4 7.1L12 21.5z"/></svg>
<svg viewBox="0 0 24 24"><path d="M15.67 4H14V2h-4v2H8.33C7.6 4 7 4.6 7 5.33v15.33C7 21.4 7.6 22 8.33 22h7.33c.74 0 1.34-.6 1.34-1.33V5.33C17 4.6 16.4 4 15.67 4z"/></svg>`

export class Device {
  constructor(screens, callouts) {
    this.screens = screens
    this.callouts = callouts
    this.reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
    this.current = null
    this.currentId = null
    this.tl = null
    this.token = 0

    const el = document.createElement('div')
    el.className = 'device-screen'
    el.innerHTML = `
      <div class="device-viewport"></div>
      <div class="device-status"><span class="device-status__time">9:41</span><span class="device-status__icons">${STATUS_ICONS}</span></div>
      <div class="device-punch"></div>
      <div class="device-gesture"></div>
      <div class="device-ripple"></div>
      <div class="device-finger"></div>
      <div class="device-vignette"></div>
      <div class="device-glare"></div>
      <div class="device-curtain"></div>`
    this.el = el
    this.viewport = el.querySelector('.device-viewport')
    this.status = el.querySelector('.device-status')
    this.gesture = el.querySelector('.device-gesture')
    this.finger = el.querySelector('.device-finger')
    this.ripple = el.querySelector('.device-ripple')
  }

  /**
   * Show screen `id` and play its demo. dir: 1 forward (push), -1 back (pop).
   * demoKey picks an alternative demo when a screen module exports demos{}.
   */
  show(id, { dir = 1, demoKey = null, instant = false } = {}) {
    const mod = this.screens[id]
    if (!mod) {
      console.warn('[device] unknown screen', id)
      return
    }
    const token = ++this.token
    this.tl?.kill()
    gsap.killTweensOf([this.finger, this.ripple])
    gsap.set([this.finger, this.ripple], { opacity: 0 })
    this.callouts?.clear()

    const wrap = document.createElement('div')
    wrap.innerHTML = mod.render().trim()
    const next = wrap.firstElementChild
    next.dataset.screen = id
    this.viewport.appendChild(next)
    const prev = this.current
    const sameScreen = prev && this.currentId === id

    const light = mod.statusBar === 'light'
    this.status.classList.toggle('is-light', light)
    this.gesture.classList.toggle('is-light', light)

    const done = () => {
      if (token !== this.token) return
      if (prev && prev.parentNode) prev.remove()
    }

    this.current = next
    this.currentId = id
    // build the demo now so its start state applies before the screen is visible
    if (!prev || instant || this.reduced) {
      if (prev) prev.remove()
      gsap.set(next, { opacity: 1, x: 0 })
      this.play(mod, next, demoKey, 0.15)
      return
    }
    this.play(mod, next, demoKey, 0.45)
    if (sameScreen) {
      // replay on the same screen: quick fade-through
      gsap.set(next, { opacity: 0 })
      gsap.to(next, { opacity: 1, duration: 0.3, ease: 'power2.out', onComplete: done })
      return
    }
    // Material shared-axis X
    gsap.fromTo(next, { opacity: 0, x: 40 * dir }, { opacity: 1, x: 0, duration: 0.5, ease: 'power3.out', onComplete: done })
    gsap.to(prev, { opacity: 0, x: -40 * dir, duration: 0.32, ease: 'power2.in' })
  }

  play(mod, root, demoKey, delay = 0.15) {
    const demo = (demoKey && mod.demos?.[demoKey]) || mod.demo
    if (!demo) return
    const tl = gsap.timeline({ delay })
    const k = createKit({ screen: this.el, finger: this.finger, ripple: this.ripple, callouts: this.callouts }, root)
    try {
      demo(tl, root, k)
    } catch (err) {
      console.error(`[device] demo of ${mod.id} failed`, err)
    }
    k.lift(tl, '+=0.4')
    if (this.reduced) tl.progress(1)
    this.tl = tl
  }

  /** replay the current demo (presenter pressed R) */
  replay() {
    if (this.currentId) this.show(this.currentId, { instant: false })
  }
}

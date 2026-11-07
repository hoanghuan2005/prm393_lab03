/**
 * Glass labels beside the phone with a hairline pointing at the exact UI
 * element being demoed. Positions follow the floating 3D phone every frame
 * (getBoundingClientRect returns the projected box of CSS3D content).
 */
import gsap from 'gsap'

const NS = 'http://www.w3.org/2000/svg'

export class Callouts {
  constructor({ svg, labels, screenEl }) {
    this.svg = svg
    this.labels = labels
    this.screenEl = screenEl
    this.items = []
    this.raf = null
    this.update = this.update.bind(this)
  }

  show(target, text, side = 'left') {
    if (!target || window.innerWidth < 900) return
    const label = document.createElement('div')
    label.className = 'callout'
    label.textContent = text
    this.labels.appendChild(label)
    const line = document.createElementNS(NS, 'path')
    line.setAttribute('class', 'callout-line')
    const halo = document.createElementNS(NS, 'circle')
    halo.setAttribute('class', 'callout-dot-halo')
    halo.setAttribute('r', '9')
    const dot = document.createElementNS(NS, 'circle')
    dot.setAttribute('class', 'callout-dot')
    dot.setAttribute('r', '3.5')
    this.svg.append(line, halo, dot)
    const item = { target, label, line, dot, halo, side, index: this.items.length, o: { v: 0 } }
    this.items.push(item)
    gsap.to(item.o, { v: 1, duration: 0.5, ease: 'power3.out' })
    if (!this.raf) this.raf = requestAnimationFrame(this.update)
  }

  clear() {
    for (const it of this.items) {
      gsap.killTweensOf(it.o)
      it.label.remove()
      it.line.remove()
      it.dot.remove()
      it.halo.remove()
    }
    this.items = []
  }

  update() {
    this.raf = null
    if (!this.items.length) return
    const phone = this.screenEl.getBoundingClientRect()
    for (const it of this.items) {
      if (!it.target.isConnected) continue
      const r = it.target.getBoundingClientRect()
      const tx = r.left + r.width / 2
      const ty = r.top + r.height / 2
      const lw = it.label.offsetWidth
      const lh = it.label.offsetHeight
      const gap = 36
      const left = it.side === 'left'
      const lx = left ? Math.max(16, phone.left - gap - lw) : Math.min(window.innerWidth - lw - 16, phone.right + gap)
      const ly = Math.max(80, Math.min(window.innerHeight - 120, ty - lh / 2 + it.index * 6))
      const ax = left ? lx + lw : lx
      const ay = ly + lh / 2
      const v = it.o.v
      it.label.style.transform = `translate(${lx + (left ? -12 : 12) * (1 - v)}px, ${ly}px)`
      it.label.style.opacity = v
      const midX = left ? Math.min(tx - 18, ax + 26) : Math.max(tx + 18, ax - 26)
      it.line.setAttribute('d', `M${ax},${ay} L${midX},${ay} L${tx},${ty}`)
      it.line.style.opacity = v
      it.line.style.strokeDasharray = '400'
      it.line.style.strokeDashoffset = `${400 * (1 - v)}`
      it.dot.setAttribute('cx', tx)
      it.dot.setAttribute('cy', ty)
      it.halo.setAttribute('cx', tx)
      it.halo.setAttribute('cy', ty)
      it.dot.style.opacity = v
      it.halo.style.opacity = v * (0.6 + 0.4 * Math.sin(performance.now() / 300))
    }
    this.raf = requestAnimationFrame(this.update)
  }
}

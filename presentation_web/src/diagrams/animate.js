// Entrance animation for a diagram slot + gentle pointer parallax on 2.5D diagrams.
import gsap from 'gsap'

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
let pointerBound = false

export function animateVisual(slot) {
  const nodes = slot.querySelectorAll('.dg-node')
  const edges = slot.querySelectorAll('.dg-edge')
  const tags = slot.querySelectorAll('.dg-tag')
  const rows = slot.querySelectorAll('.dt-row, .vis-card, .stat, .team__member, .vis-title, .vis-note')
  if (reduced) {
    gsap.set(edges, { strokeDashoffset: 0 })
    return
  }
  const tl = gsap.timeline({ delay: 0.25 })
  tl.fromTo(slot, { opacity: 0 }, { opacity: 1, duration: 0.4 }, 0)
  if (nodes.length) tl.fromTo(nodes, { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.6, stagger: 0.045, ease: 'back.out(1.4)' }, 0.05)
  if (edges.length) tl.fromTo(edges, { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.7, stagger: 0.06, ease: 'power2.inOut' }, 0.35)
  if (tags.length) tl.fromTo(tags, { opacity: 0 }, { opacity: 1, duration: 0.35, stagger: 0.05 }, 0.7)
  if (rows.length) tl.fromTo(rows, { opacity: 0, y: 12 }, { opacity: 1, y: 0, duration: 0.5, stagger: 0.06, ease: 'power3.out' }, 0.05)
  // dashed edges keep their dash pattern once drawn
  tl.call(() => slot.querySelectorAll('.dg-edge.is-dash').forEach((e) => (e.style.strokeDashoffset = '')))

  if (!pointerBound) {
    pointerBound = true
    window.addEventListener('pointermove', (e) => {
      const dg = document.querySelector('.visual .dg--deep')
      if (!dg) return
      dg.style.setProperty('--mx', ((e.clientX / innerWidth) * 2 - 1).toFixed(3))
      dg.style.setProperty('--my', ((e.clientY / innerHeight) * 2 - 1).toFixed(3))
    })
  }
}

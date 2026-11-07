// Dev-only harness for lab.html (not part of the production build).
import './styles/fonts.css'
import './styles/device.css'
import './styles/app.css'
import gsap from 'gsap'
import { screens } from './screens/index.js'
import { Device } from './engine/device.js'

const params = new URLSearchParams(location.search)
const id = params.get('screen') || 'home'
const demo = params.get('demo')
const t = params.get('t')
const callouts = []
const device = new Device(screens, {
  show: (el, text) => callouts.push({ text, found: !!el }),
  clear: () => (callouts.length = 0),
})
document.getElementById('mount').appendChild(device.el)
gsap.set(device.el.querySelector('.device-curtain'), { opacity: 0 })

async function run() {
  await document.fonts.ready
  device.show(id, { instant: true, demoKey: demo })
  if (t != null && device.tl) {
    device.tl.pause()
    const at = t === 'end' ? device.tl.duration() : parseFloat(t)
    device.tl.seek(at, false)
  }
  window.__lab = { device, gsap, callouts, duration: device.tl ? device.tl.duration() : 0 }
  window.__labReady = true
}
run()

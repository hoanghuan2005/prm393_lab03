import './styles/fonts.css'
import './styles/site.css'
import './styles/device.css'
import './styles/app.css'

import gsap from 'gsap'
import { chapters } from './data/chapters.js'
import { screens } from './screens/index.js'
import { PhoneStage } from './three/phone.js'
import { Device } from './engine/device.js'
import { Steps } from './engine/steps.js'
import { Callouts } from './ui/callouts.js'
import { ChapterText } from './ui/chapters.js'
import { Rail } from './ui/rail.js'

const $ = (id) => document.getElementById(id)
const pad = (n) => String(n).padStart(2, '0')
const DEFAULT_POSE = { x: 0, y: 0, rx: -0.04, ry: 0.28, rz: 0, s: 1 }

const loaderBar = document.querySelector('.loader__bar span')
const progress = (p) => loaderBar && (loaderBar.style.width = `${Math.round(p * 100)}%`)

async function boot() {
  progress(0.15)
  const callouts = new Callouts({ svg: $('callout-lines'), labels: $('callout-labels'), screenEl: null })
  const device = new Device(screens, callouts)
  callouts.screenEl = device.el

  // fonts first: the 3D back print and the text splitting need real metrics
  await Promise.race([
    Promise.all([
      document.fonts.load('700 96px "Be Vietnam Pro"'),
      document.fonts.load('600 40px "Be Vietnam Pro"'),
      document.fonts.load('500 12px "JetBrains Mono"'),
    ]),
    new Promise((r) => setTimeout(r, 2500)),
  ])
  progress(0.45)

  const stage = new PhoneStage({ canvas: $('gl'), cssLayer: $('css3d'), screenEl: device.el })
  stage.init()
  progress(0.75)

  const text = new ChapterText($('chapters'), chapters)
  text.split()

  let steps
  const rail = new Rail({ rail: $('rail'), track: $('rail-track'), chapters, onPick: (i) => steps.go(i) })
  const navChapter = $('navbar-chapter')
  const navCount = $('navbar-count')
  const keyhint = $('keyhint')

  const journey = chapters.filter((c) => c.rail)
  let shown = { screen: null, demo: null }
  const activate = (i, dir) => {
    const ch = chapters[i]
    const step = journey.indexOf(ch)
    navChapter.textContent = ch.nav || (step >= 0 ? `Bước ${step + 1} / ${journey.length} · ${ch.eyebrow}` : ch.eyebrow)
    navCount.innerHTML = `<b>${pad(i + 1)}</b> / ${pad(chapters.length)}`
    rail.set(i)
    text.reveal(i)
    stage.setPose({ ...DEFAULT_POSE, ...ch.pose })
    if (shown.screen !== ch.screen || shown.demo !== (ch.demo || null) || dir !== 0) {
      device.show(ch.screen, { dir: dir >= 0 ? 1 : -1, demoKey: ch.demo || null })
      shown = { screen: ch.screen, demo: ch.demo || null }
    }
    keyhint.classList.toggle('is-hidden', i > 0)
    if (history.replaceState) history.replaceState(null, '', i ? `#${ch.id}` : location.pathname + location.search)
  }

  steps = new Steps({
    sections: text.sections,
    onActivate: activate,
    onKey: (k) => {
      if (k === 'f' || k === 'F') toggleFullscreen()
      if (k === 'r' || k === 'R') device.replay()
    },
  })

  document.querySelectorAll('[data-goto]').forEach((a) =>
    a.addEventListener('click', (e) => {
      e.preventDefault()
      steps.go(+a.dataset.goto)
    }),
  )
  $('fullscreen-btn').addEventListener('click', toggleFullscreen)
  if (import.meta.env.DEV) window.__wib = { stage, device, steps, text, rail, gsap }

  progress(1)
  await new Promise((r) => setTimeout(r, 250))
  $('loader').classList.add('is-done')

  // deep link (#dang-nhap) or the intro
  const start = Math.max(0, chapters.findIndex((c) => `#${c.id}` === location.hash))
  if (start > 0) {
    gsap.set(device.el.querySelector('.device-curtain'), { opacity: 0 })
    steps.go(start, { instant: true })
  } else {
    window.scrollTo(0, 0)
    steps.current = 0
    device.show(chapters[0].screen, { instant: true, demoKey: chapters[0].demo || null })
    shown = { screen: chapters[0].screen, demo: chapters[0].demo || null }
    rail.set(0)
    navCount.innerHTML = `<b>01</b> / ${pad(chapters.length)}`
    stage.intro()
    setTimeout(() => text.reveal(0), 900)
  }
}

function toggleFullscreen() {
  if (!document.fullscreenElement) document.documentElement.requestFullscreen?.().catch(() => {})
  else document.exitFullscreen?.()
}

boot().catch((err) => {
  console.error(err)
  document.getElementById('loader')?.classList.add('is-done')
})

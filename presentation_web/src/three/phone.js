/**
 * The 3D phone: a procedural Android handset in Three.js (graphite frame,
 * black glass, matte yellow back with the Why I Buy mark, triple camera)
 * plus a live DOM screen mounted on the front glass with CSS3DRenderer, so
 * the app UI stays real, crisp text.
 */
import * as THREE from 'three'
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js'
import { CSS3DRenderer, CSS3DObject } from 'three/addons/renderers/CSS3DRenderer.js'
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js'
import gsap from 'gsap'

export const SCREEN_PX = { w: 360, h: 780 }
const SCREEN_W = 0.704
const SCREEN_H = (SCREEN_W * SCREEN_PX.h) / SCREEN_PX.w
const BEZEL = 0.024
const RIM = 0.013
const BODY_W = SCREEN_W + 2 * (BEZEL + RIM)
const BODY_H = SCREEN_H + 2 * (BEZEL + RIM)
const DEPTH = 0.084
const R_BODY = 0.122
const FOV = 26

function roundedRect(w, h, r) {
  const s = new THREE.Shape()
  const x = -w / 2
  const y = -h / 2
  s.moveTo(x + r, y)
  s.lineTo(x + w - r, y)
  s.absarc(x + w - r, y + r, r, -Math.PI / 2, 0, false)
  s.lineTo(x + w, y + h - r)
  s.absarc(x + w - r, y + h - r, r, 0, Math.PI / 2, false)
  s.lineTo(x + r, y + h)
  s.absarc(x + r, y + h - r, r, Math.PI / 2, Math.PI, false)
  s.lineTo(x, y + r)
  s.absarc(x + r, y + r, r, Math.PI, Math.PI * 1.5, false)
  return s
}

function radialTexture(inner = 'rgba(0,0,0,0.75)', outer = 'rgba(0,0,0,0)') {
  const c = document.createElement('canvas')
  c.width = c.height = 256
  const g = c.getContext('2d')
  const grad = g.createRadialGradient(128, 128, 0, 128, 128, 128)
  grad.addColorStop(0, inner)
  grad.addColorStop(1, outer)
  g.fillStyle = grad
  g.fillRect(0, 0, 256, 256)
  const t = new THREE.CanvasTexture(c)
  t.colorSpace = THREE.SRGBColorSpace
  return t
}

/** "Why I Buy?" mark + wordmark printed on the yellow back glass */
function backPrintTexture() {
  const c = document.createElement('canvas')
  c.width = 1024
  c.height = 512
  const g = c.getContext('2d')
  g.clearRect(0, 0, c.width, c.height)
  g.fillStyle = '#0F172A'
  // spa icon (Material "spa" rounded) scaled into a circle outline
  g.save()
  g.translate(512, 170)
  g.beginPath()
  g.arc(0, 0, 92, 0, Math.PI * 2)
  g.lineWidth = 10
  g.strokeStyle = 'rgba(15,23,42,0.9)'
  g.stroke()
  g.scale(5.2, 5.2)
  g.translate(-12, -12.5)
  const p = new Path2D(
    'M15.49 9.63c-.16-2.42-1.03-4.79-2.64-6.76-.41-.5-1.16-.5-1.57 0a12.102 12.102 0 0 0-2.77 6.76c1.28.68 2.46 1.56 3.49 2.63 1.03-1.06 2.21-1.94 3.49-2.63zM12 15.45c-1.95-2.97-5.14-5.03-8.83-5.39-.64-.06-1.17.47-1.11 1.11.45 4.8 3.65 8.78 7.98 10.33.63.23 1.29.4 1.97.51.68-.12 1.33-.29 1.97-.51 4.33-1.55 7.53-5.52 7.98-10.33a1.02 1.02 0 0 0-1.11-1.11c-3.71.36-6.9 2.42-8.85 5.39z',
  )
  g.fill(p)
  g.restore()
  g.font = '700 96px "Be Vietnam Pro", system-ui, sans-serif'
  g.textAlign = 'center'
  g.textBaseline = 'middle'
  g.fillStyle = 'rgba(15,23,42,0.92)'
  g.fillText('Why I Buy?', 512, 370)
  g.font = '500 34px "JetBrains Mono", ui-monospace, monospace'
  g.fillStyle = 'rgba(15,23,42,0.55)'
  g.fillText('THE PSYCHOLOGY OF MONEY', 512, 450)
  const t = new THREE.CanvasTexture(c)
  t.colorSpace = THREE.SRGBColorSpace
  t.anisotropy = 8
  return t
}

export class PhoneStage {
  constructor({ canvas, cssLayer, screenEl }) {
    this.canvas = canvas
    this.cssLayer = cssLayer
    this.screenEl = screenEl
    this.reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
    this.pose = { x: 0, y: 0, rx: -0.04, ry: 0.28, rz: 0, s: 1 }
    this.base = { x: 0, y: 0, z: 0, scale: 1 }
    this.pointer = { x: 0, y: 0, sx: 0, sy: 0 }
    this.idle = true
    this.listeners = new Set()
    this.timer = new THREE.Timer()
  }

  init() {
    const renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance',
    })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
    renderer.outputColorSpace = THREE.SRGBColorSpace
    renderer.toneMapping = THREE.NeutralToneMapping
    renderer.toneMappingExposure = 1.0
    renderer.setClearColor(0x000000, 0)
    this.renderer = renderer

    const css = new CSS3DRenderer()
    css.domElement.style.pointerEvents = 'none'
    this.cssLayer.appendChild(css.domElement)
    this.css = css

    const scene = new THREE.Scene()
    const pmrem = new THREE.PMREMGenerator(renderer)
    scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture
    scene.environmentIntensity = 0.85
    pmrem.dispose()
    this.scene = scene

    const camera = new THREE.PerspectiveCamera(FOV, 1, 0.1, 60)
    this.camera = camera

    const key = new THREE.DirectionalLight(0xffffff, 1.5)
    key.position.set(-2.5, 3.2, 4)
    // warm rim from behind: a hint of the brand yellow on the frame edge, not a yellow phone
    const rim = new THREE.DirectionalLight(0xffe680, 0.55)
    rim.position.set(3.5, 1.2, -3)
    const fill = new THREE.DirectionalLight(0xbfd2ff, 0.3)
    fill.position.set(2.5, -1.5, 2)
    scene.add(key, rim, fill)

    this.root = new THREE.Group()
    this.phone = new THREE.Group()
    this.root.add(this.phone)
    scene.add(this.root)
    this.buildPhone()

    // contact shadow on an implicit floor
    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(1.25, 0.5),
      new THREE.MeshBasicMaterial({ map: radialTexture(), transparent: true, depthWrite: false, opacity: 0.6 }),
    )
    shadow.rotation.x = -Math.PI / 2
    this.shadow = shadow
    scene.add(shadow)

    this.onResize = () => this.layout()
    window.addEventListener('resize', this.onResize)
    window.addEventListener('pointermove', (e) => {
      this.pointer.x = (e.clientX / window.innerWidth) * 2 - 1
      this.pointer.y = (e.clientY / window.innerHeight) * 2 - 1
    })
    this.layout()
    this.loop = this.loop.bind(this)
    requestAnimationFrame(this.loop)
  }

  buildPhone() {
    const frame = new THREE.MeshPhysicalMaterial({ color: 0x2c2d31, metalness: 1, roughness: 0.3, envMapIntensity: 1.25 })
    const glass = new THREE.MeshPhysicalMaterial({
      color: 0x040405,
      metalness: 0,
      roughness: 0.07,
      clearcoat: 1,
      clearcoatRoughness: 0.04,
    })
    const back = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color('#FFDE02'),
      metalness: 0,
      roughness: 0.42,
      clearcoat: 0.65,
      clearcoatRoughness: 0.28,
    })

    // body with rounded (bevelled) frame
    const bodyGeo = new THREE.ExtrudeGeometry(roundedRect(BODY_W - 2 * RIM, BODY_H - 2 * RIM, R_BODY - RIM), {
      depth: DEPTH - 2 * RIM,
      bevelEnabled: true,
      bevelThickness: RIM,
      bevelSize: RIM,
      bevelSegments: 8,
      curveSegments: 48,
    })
    bodyGeo.translate(0, 0, -(DEPTH - 2 * RIM) / 2)
    const body = new THREE.Mesh(bodyGeo, frame)
    this.phone.add(body)

    // front glass (exactly the flat cap) and back glass
    const capW = BODY_W - 2 * RIM
    const capH = BODY_H - 2 * RIM
    const capR = R_BODY - RIM
    const front = new THREE.Mesh(new THREE.ShapeGeometry(roundedRect(capW, capH, capR), 48), glass)
    front.position.z = DEPTH / 2 + 0.0006
    this.phone.add(front)
    const backGlass = new THREE.Mesh(new THREE.ShapeGeometry(roundedRect(capW, capH, capR), 48), back)
    backGlass.position.z = -DEPTH / 2 - 0.0006
    backGlass.rotation.y = Math.PI
    this.phone.add(backGlass)

    // printed mark on the back
    const print = new THREE.Mesh(
      new THREE.PlaneGeometry(0.56, 0.28),
      new THREE.MeshBasicMaterial({ map: backPrintTexture(), transparent: true, depthWrite: false }),
    )
    print.position.set(0, -0.2, -DEPTH / 2 - 0.0016)
    print.rotation.y = Math.PI
    this.phone.add(print)
    this.backPrint = print

    // camera island (top-left when looking at the back => +x in local space)
    const islandMat = new THREE.MeshPhysicalMaterial({ color: 0x141416, metalness: 0.2, roughness: 0.22, clearcoat: 1 })
    const islandGeo = new THREE.ExtrudeGeometry(roundedRect(0.27, 0.36, 0.085), {
      depth: 0.006,
      bevelEnabled: true,
      bevelThickness: 0.004,
      bevelSize: 0.004,
      bevelSegments: 4,
      curveSegments: 24,
    })
    const island = new THREE.Mesh(islandGeo, islandMat)
    island.rotation.y = Math.PI
    island.position.set(BODY_W / 2 - 0.2, BODY_H / 2 - 0.25, -DEPTH / 2 - 0.0012)
    this.phone.add(island)

    const ringMat = new THREE.MeshPhysicalMaterial({ color: 0xa4a4aa, metalness: 1, roughness: 0.2 })
    const lensMat = new THREE.MeshPhysicalMaterial({
      color: 0x04070f,
      metalness: 0.1,
      roughness: 0.04,
      clearcoat: 1,
      iridescence: 1,
      iridescenceIOR: 1.6,
      iridescenceThicknessMinimum: 200,
      iridescenceThicknessMaximum: 600,
    })
    const lensPos = [
      [0.055, 0.09],
      [0.055, -0.09],
      [-0.07, 0.0],
    ]
    for (const [lx, ly] of lensPos) {
      const ring = new THREE.Mesh(new THREE.CylinderGeometry(0.052, 0.052, 0.014, 40), ringMat)
      ring.rotation.x = Math.PI / 2
      ring.position.set(island.position.x + lx, island.position.y + ly, -DEPTH / 2 - 0.016)
      this.phone.add(ring)
      const lens = new THREE.Mesh(new THREE.CircleGeometry(0.041, 40), lensMat)
      lens.rotation.y = Math.PI
      lens.position.set(ring.position.x, ring.position.y, -DEPTH / 2 - 0.0235)
      this.phone.add(lens)
    }
    const flash = new THREE.Mesh(
      new THREE.CircleGeometry(0.018, 24),
      new THREE.MeshStandardMaterial({ color: 0xfff4d6, emissive: 0x3a3424, roughness: 0.4 }),
    )
    flash.rotation.y = Math.PI
    flash.position.set(island.position.x - 0.07, island.position.y + 0.12, -DEPTH / 2 - 0.012)
    this.phone.add(flash)

    // side keys (right edge when looking at the screen)
    const keyGeo = (len) => new RoundedBoxGeometry(0.014, len, 0.03, 3, 0.006)
    const vol = new THREE.Mesh(keyGeo(0.2), frame)
    vol.position.set(BODY_W / 2 + 0.003, 0.36, 0)
    const power = new THREE.Mesh(keyGeo(0.11), frame)
    power.position.set(BODY_W / 2 + 0.003, 0.08, 0)
    this.phone.add(vol, power)

    // USB-C port + speaker grille on the bottom edge
    const dark = new THREE.MeshStandardMaterial({ color: 0x050505, roughness: 0.6 })
    const port = new THREE.Mesh(new RoundedBoxGeometry(0.09, 0.01, 0.03, 2, 0.005), dark)
    port.position.set(0, -BODY_H / 2 + 0.002, 0)
    this.phone.add(port)
    for (let i = 0; i < 5; i++) {
      const hole = new THREE.Mesh(new THREE.CylinderGeometry(0.0055, 0.0055, 0.01, 12), dark)
      hole.position.set(0.15 + i * 0.022, -BODY_H / 2 + 0.002, 0)
      this.phone.add(hole)
    }

    // the live screen
    const screenObj = new CSS3DObject(this.screenEl)
    screenObj.element.style.pointerEvents = 'none'
    screenObj.scale.setScalar(SCREEN_W / SCREEN_PX.w)
    screenObj.position.z = DEPTH / 2 + 0.0012
    this.phone.add(screenObj)
    this.screenObj = screenObj
  }

  /** fit the phone into the left column (desktop) or the top area (mobile) */
  layout() {
    const w = window.innerWidth
    const h = window.innerHeight
    this.renderer.setSize(w, h)
    this.css.setSize(w, h)
    this.camera.aspect = w / h
    const mobile = w < 900
    const navH = mobile ? 56 : 64
    const railH = mobile ? 70 : 92
    let centerX
    let centerY
    let phonePx
    if (mobile) {
      const area = h * 0.56 - navH
      phonePx = Math.min(area * 0.9, w * 0.48 * (BODY_H / BODY_W))
      centerX = w / 2
      centerY = navH + area / 2 + 6
    } else {
      const textCol = w >= 1100 ? 0.52 : 0.5
      const usable = h - navH - railH
      phonePx = Math.min(usable * 0.9, w * textCol * 0.62 * (BODY_H / BODY_W))
      centerX = (w * textCol) / 2 + w * 0.01
      centerY = navH + usable / 2 + 4
    }
    const fovRad = THREE.MathUtils.degToRad(FOV)
    const dist = BODY_H / ((phonePx / h) * 2 * Math.tan(fovRad / 2))
    this.camera.position.set(0, 0, dist)
    this.camera.updateProjectionMatrix()
    const visH = 2 * dist * Math.tan(fovRad / 2)
    const visW = visH * this.camera.aspect
    this.base.x = (centerX / w - 0.5) * visW
    this.base.y = -(centerY / h - 0.5) * visH
    this.shadow.position.set(this.base.x, this.base.y - BODY_H / 2 - 0.2, 0)
    this.phonePx = phonePx
    document.documentElement.style.setProperty('--bloom-x', `${centerX}px`)
    document.documentElement.style.setProperty('--bloom-y', `${centerY}px`)
    this.listeners.forEach((fn) => fn())
  }

  onLayout(fn) {
    this.listeners.add(fn)
  }

  /** tween to a pose { x, y, rx, ry, rz, s } (x/y are offsets in phone heights) */
  setPose(target, { duration = 1.1, ease = 'power3.inOut' } = {}) {
    gsap.killTweensOf(this.pose)
    if (this.reduced) {
      Object.assign(this.pose, target)
      return null
    }
    return gsap.to(this.pose, { ...target, duration, ease })
  }

  /** intro: the phone spins in from its yellow back while the screen boots */
  intro() {
    const tl = gsap.timeline()
    const curtain = this.screenEl.querySelector('.device-curtain')
    if (this.reduced) {
      gsap.set(curtain, { opacity: 0 })
      return tl
    }
    this.pose.ry = Math.PI + 0.55
    this.pose.rx = 0.12
    this.pose.y = -0.25
    this.pose.s = 0.82
    tl.to(this.pose, { ry: 0.3, rx: -0.04, y: 0, s: 1, duration: 2.6, ease: 'expo.inOut' })
    tl.fromTo(curtain, { opacity: 1 }, { opacity: 0, duration: 0.9, ease: 'power2.out' }, 1.7)
    return tl
  }

  loop() {
    requestAnimationFrame(this.loop)
    this.timer.update()
    const t = this.timer.getElapsed()
    const p = this.pose
    const motion = !this.reduced && this.idle
    this.pointer.sx += (this.pointer.x - this.pointer.sx) * 0.05
    this.pointer.sy += (this.pointer.y - this.pointer.sy) * 0.05
    const float = motion ? Math.sin(t * 0.9) * 0.022 : 0
    const sway = motion ? Math.sin(t * 0.6) * 0.012 : 0
    const px = motion ? this.pointer.sx * 0.07 : 0
    const py = motion ? this.pointer.sy * 0.045 : 0

    this.root.position.set(this.base.x + p.x * BODY_H, this.base.y + p.y * BODY_H + float, 0)
    this.root.scale.setScalar(p.s)
    this.phone.rotation.set(p.rx + py + sway, p.ry + px, p.rz)

    // shadow follows the float
    const lift = (float + 0.022) / 0.044
    this.shadow.material.opacity = 0.62 - lift * 0.18
    this.shadow.scale.set(p.s * (1 - lift * 0.08), 1, p.s)
    this.shadow.position.x = this.base.x + p.x * BODY_H

    // glare band slides with the yaw
    const yaw = this.phone.rotation.y
    this.screenEl.style.setProperty('--glare', `${(30 + yaw * 70).toFixed(1)}%`)

    // hide the DOM screen when it faces away (backface-visibility is not reliable through CSS3D)
    this.phone.updateMatrixWorld()
    this._n = (this._n || new THREE.Vector3()).set(0, 0, 1).transformDirection(this.phone.matrixWorld)
    this._p = (this._p || new THREE.Vector3()).setFromMatrixPosition(this.phone.matrixWorld)
    const toCam = this.camera.position.clone().sub(this._p).normalize()
    const facing = this._n.dot(toCam) > 0.02
    if (facing !== this._facing) {
      this._facing = facing
      this.screenEl.style.visibility = facing ? 'visible' : 'hidden'
    }

    this.renderer.render(this.scene, this.camera)
    this.css.render(this.scene, this.camera)
  }
}

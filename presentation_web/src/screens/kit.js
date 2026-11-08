/**
 * Screen kit: HTML builders for the Why I Buy app components (rebuilt from
 * lib/widgets) and animation helpers for the scripted demos.
 *
 * Contract for a screen module (src/screens/<id>.js):
 *   export default {
 *     id: 'login',
 *     statusBar: 'dark' | 'light',      // status-bar icon colour (default dark)
 *     render() { return html`<div class="wib-screen">…</div>` },
 *     demo(tl, root, k) { … }           // add tweens to the gsap timeline `tl`
 *   }
 * The screen is re-rendered before every demo, so demos always start fresh.
 * Icons: always write names literally, icon('chevron_left_rounded') or
 * { icon: 'bolt_outlined' }, so the build can bundle exactly those SVGs.
 */
import gsap from 'gsap'
import ICONS from 'virtual:icons'

/* ----------------------------------------------------------------- */
/* tiny template helper (content is authored, so no escaping needed)  */
/* ----------------------------------------------------------------- */
export function html(strings, ...values) {
  let out = ''
  strings.forEach((s, i) => {
    out += s
    if (i < values.length) {
      const v = values[i]
      out += Array.isArray(v) ? v.join('') : v == null || v === false ? '' : v
    }
  })
  return out
}

export function icon(name, size, cls = '') {
  const body = ICONS[name]
  if (!body && import.meta.env.DEV) console.warn('[icons] missing', name)
  const style = size ? ` style="font-size:${size}px"` : ''
  return `<svg class="mi ${cls}" viewBox="0 0 24 24" aria-hidden="true"${style}>${body || ''}</svg>`
}

/* ----------------------------------------------------------------- */
/* data + formatting rules from lib/core/formatters                   */
/* ----------------------------------------------------------------- */
export const MOTIVES = {
  need: { label: 'Nhu cầu', icon: 'inventory_2_outlined' },
  want: { label: 'Mong muốn', icon: 'favorite_outline' },
  sale: { label: 'Khuyến mãi', icon: 'local_offer_outlined' },
  emotion: { label: 'Cảm xúc', icon: 'sentiment_very_satisfied_outlined' },
  social: { label: 'Ảnh hưởng MXH', icon: 'trending_up' },
  convenience: { label: 'Tiện lợi', icon: 'bolt_outlined' },
  ads: { label: 'Quảng cáo', icon: 'campaign_outlined' },
  other: { label: 'Khác', icon: 'more_horiz' },
}
export const MOTIVE_COLORS = {
  need: '#3B82F6',
  want: '#EC4899',
  sale: '#F59E0B',
  emotion: '#A855F7',
  social: '#0EA5E9',
  convenience: '#14B8A6',
  ads: '#2563EB',
  other: '#64748B',
}

/** formatVnd: 1589000 -> '1.589.000 ₫'; null -> 'Chưa có giá' */
export function money(amount, empty = 'Chưa có giá') {
  if (amount == null) return empty
  const neg = amount < 0
  const s = Math.round(Math.abs(amount))
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  return `${neg ? '-' : ''}${s} ₫`
}
/** digits only, dot grouped: 450000 -> '450.000' (AmountField text) */
export function grouped(amount) {
  return Math.round(amount)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

/* ----------------------------------------------------------------- */
/* components                                                         */
/* ----------------------------------------------------------------- */
export function logo(size = 48) {
  return `<span class="wib-logo" style="width:${size}px;height:${size}px">${icon('spa_rounded', +(size * 0.58).toFixed(2))}</span>`
}

/** AppHeaderActions: bell, bookmark (count = 'Đang cân nhắc'), yellow avatar */
export function headerActions({ bell = 0, bookmark = 4 } = {}) {
  return html`
    <span class="wib-iconbtn" data-k="bell">
      ${bell ? icon('notifications_rounded') : icon('notifications_none_rounded')}
      ${bell ? `<span class="wib-badge-count">${bell}</span>` : ''}
    </span>
    <span class="wib-iconbtn" data-k="bookmark">
      ${icon('bookmark_outline_rounded')}
      ${bookmark ? `<span class="wib-badge-count">${bookmark}</span>` : ''}
    </span>
    <span class="wib-avatar">${icon('person')}</span>`
}

/**
 * App bar. back: 'arrow' (pushed screens), 'chevron' (tab screens), null.
 * logoSize: show WhyIBuyLogo before the title (tab screens use 26).
 */
export function appBar({ title = '', back = 'arrow', logoSize = 0, strong = false, actions = '', cls = '' } = {}) {
  const lead =
    back === 'arrow'
      ? `<span class="wib-iconbtn">${icon('arrow_back')}</span>`
      : back === 'chevron'
        ? `<span class="wib-iconbtn" style="width:38px">${icon('chevron_left_rounded', 30)}</span>`
        : ''
  return html`
    <div class="wib-appbar ${back ? '' : 'wib-appbar--tab'} ${cls}">
      ${lead}
      <div class="wib-appbar__title ${strong ? 'wib-appbar__title--strong' : ''}" style="${back ? 'padding-left:4px' : 'padding-left:16px'}">
        ${logoSize ? logo(logoSize) : ''}<span>${title}</span>
      </div>
      ${actions}
    </div>`
}

const NAV = [
  { key: 'home', label: 'Trang chủ', on: icon('home_rounded'), off: icon('home_outlined') },
  { key: 'history', label: 'Lịch sử', on: icon('format_list_bulleted_rounded'), off: icon('format_list_bulleted_rounded') },
  { key: 'patterns', label: 'Mô hình', on: icon('bar_chart_rounded'), off: icon('bar_chart_rounded') },
  { key: 'insights', label: 'Góc nhìn', on: icon('lightbulb_rounded'), off: icon('lightbulb_outline_rounded') },
  { key: 'profile', label: 'Cá nhân', on: icon('person_rounded'), off: icon('person_outline_rounded') },
]
/** Custom 60px bottom bar of MainNavigationScreen (no indicator pill) */
export function bottomNav(active = 'home') {
  return html`
    <nav class="wib-nav">
      ${NAV.map(
        (n) => html`<span class="wib-nav__item ${n.key === active ? 'is-active' : ''}" data-tab="${n.key}">
          ${n.key === active ? n.on : n.off}<span>${n.label}</span></span>`,
      )}
    </nav>
    <div class="wib-gesture-pad"></div>`
}

/** AppButton. variant: primary | secondary | danger */
export function button(label, { icon: ic = '', variant = 'primary', lg = false, cls = '', attrs = '' } = {}) {
  return html`<span class="wib-btn wib-btn--${variant} ${lg ? 'wib-btn--lg' : ''} ${cls}" ${attrs}>
    <span class="wib-btn__label wib-row" style="gap:8px">${ic}${label ? `<span>${label}</span>` : ''}</span>
    <span class="wib-btn__spinner"></span>
  </span>`
}

/**
 * AppTextField / AmountField. value '' shows the hint. float: Material
 * floating label inside the border (login form). suffix: e.g. '₫'.
 */
export function field({ label = '', float = '', value = '', hint = '', prefix = '', suffix = '', trailing = '', focused = false, cls = '', valueAttrs = '' } = {}) {
  return html`<div class="wib-field ${cls}">
    ${label ? `<div class="wib-field__label">${label}</div>` : ''}
    <div class="wib-input ${focused ? 'is-focused' : ''}">
      ${float ? `<span class="wib-input__float">${float}</span>` : ''}
      ${prefix}
      <span class="wib-input__value" data-hint="${hint}" ${valueAttrs}>${value}</span>
      ${suffix ? `<span class="wib-input__suffix">${suffix}</span>` : ''}
      ${trailing}
    </div>
  </div>`
}

/** MotiveChip (regular: tappable 48px; compact: display-only 32px) */
export function motiveChip(key, { selected = false, compact = false, cls = '' } = {}) {
  const m = MOTIVES[key]
  return `<span class="wib-motive ${compact ? 'wib-motive--compact' : ''} ${selected ? 'is-selected' : ''} ${cls}" data-motive="${key}">${icon(m.icon)}<span>${m.label}</span></span>`
}
/** small motive tag used in Home / History rows */
export function motiveTag(key) {
  const m = MOTIVES[key]
  return `<span class="wib-motive-tag" data-motive="${key}">${icon(m.icon, 11)}${m.label}</span>`
}
/** 40x40 rounded square with the motive icon (Home / History rows) */
export function motiveSquare(key) {
  return `<span class="wib-motive-square" data-motive="${key}">${icon(MOTIVES[key].icon, 20)}</span>`
}

export function priceChip(amount) {
  return amount == null
    ? `<span class="wib-price-chip wib-price-chip--empty">${icon('sell_outlined', 14)}Cần giá</span>`
    : `<span class="wib-price-chip">${icon('sell_rounded', 14)}${money(amount)}</span>`
}

/**
 * Status badge of WishlistCard. kind: cooldown ('2 ngày hoãn'), considering,
 * purchased, skipped, review ('Xem lại 10/11'), due, device ('Từ máy tính').
 */
export function statusBadge(kind, text) {
  const map = {
    cooldown: ['wib-status--cooldown', icon('timer_outlined', 14)],
    considering: ['', icon('hourglass_top_outlined', 14)],
    purchased: ['', icon('shopping_bag_outlined', 14)],
    skipped: ['', icon('do_not_disturb_on_outlined', 14)],
    review: ['', icon('event', 14)],
    due: ['', icon('notifications_active_outlined', 14)],
    device: ['wib-status--device', icon('computer_rounded', 14)],
  }
  const defaults = { considering: 'Đang cân nhắc', purchased: 'Đã mua', skipped: 'Bỏ qua', due: 'Đến hẹn xem lại', device: 'Từ máy tính' }
  const [cls, ic] = map[kind] || map.considering
  return `<span class="wib-status ${cls}" data-status="${kind}">${ic}<span>${text || defaults[kind] || ''}</span></span>`
}

/** WishlistCard: { title, price, motive, status:{kind,text}, img, device, variant } */
export function wishlistCard(item, cls = '') {
  const img = item.img
    ? `<span class="wib-wish__img" style="${item.img.startsWith('#') || item.img.startsWith('linear') ? `background:${item.img}` : `background-image:url(${item.img})`}">${item.imgIcon || ''}</span>`
    : ''
  return html`<div class="wib-wish ${cls}">
    <div class="wib-wish__top">
      ${img}
      <div class="wib-wish__title">${item.title}</div>
      ${item.price == null ? `<div class="wib-wish__price wib-wish__price--none">Chưa có giá</div>` : `<div class="wib-wish__price">${money(item.price)}</div>`}
    </div>
    ${item.variant ? `<div class="t-caption" style="margin-top:4px">Phân loại: ${item.variant}</div>` : ''}
    <div class="wib-wish__meta">
      ${motiveChip(item.motive || 'other', { compact: true })}
      <span class="wib-row" style="gap:8px">
        ${item.device ? statusBadge('device') : ''}
        ${item.status ? statusBadge(item.status.kind, item.status.text) : ''}
      </span>
    </div>
  </div>`
}

export function section({ title, icon: ic = '', action = '', body = '', cls = '' }) {
  return html`<div class="wib-section ${cls}">
    <div class="wib-section__head">${ic}<span style="flex:1">${title}</span>${action}</div>
    <div class="wib-section__rule"></div>
    ${body}
  </div>`
}

export function bar(pct = 0, { over = false, cls = '', height = 8 } = {}) {
  return `<div class="wib-bar ${cls}" style="height:${height}px"><span class="wib-bar__fill ${over ? 'is-over' : ''}" data-pct="${pct}"></span></div>`
}

export function snackbar(text, action = '') {
  return `<div class="wib-snackbar"><span class="wib-snackbar__text">${text}</span>${action ? `<span class="wib-snackbar__action">${action}</span>` : ''}</div>`
}

export function sheet(title, content) {
  return html`<div class="wib-scrim"></div>
  <div class="wib-sheet">
    <div class="wib-sheet__handle"></div>
    ${title ? `<div class="wib-sheet__title">${title}</div>` : ''}
    <div class="wib-sheet__content">${content}</div>
  </div>`
}

/* ----------------------------------------------------------------- */
/* animation helpers                                                  */
/* ----------------------------------------------------------------- */
/** position of `el` in the coordinate space of `root`, following transforms */
function localPoint(el, root, ax = 0.5, ay = 0.5) {
  let x = el.offsetWidth * ax
  let y = el.offsetHeight * ay
  let node = el
  while (node && node !== root) {
    const t = getComputedStyle(node).transform
    if (t && t !== 'none') {
      const m = new DOMMatrixReadOnly(t)
      x += m.m41
      y += m.m42
    }
    x += node.offsetLeft
    y += node.offsetTop
    const parent = node.offsetParent
    // add translate of non-offsetParent ancestors between node and its offsetParent
    let p = node.parentElement
    while (p && p !== parent && p !== root) {
      const pt = getComputedStyle(p).transform
      if (pt && pt !== 'none') {
        const m = new DOMMatrixReadOnly(pt)
        x += m.m41
        y += m.m42
      }
      p = p.parentElement
    }
    if (parent === root || !parent) break
    node = parent
  }
  return { x, y }
}

/**
 * Builds the helper object handed to demo(tl, root, k).
 * device: { screen, finger, ripple, callouts }
 */
export function createKit(device, root) {
  const { screen, finger, ripple } = device
  const q = (sel) => (typeof sel === 'string' ? root.querySelector(sel) : sel)
  const qa = (sel) => (typeof sel === 'string' ? [...root.querySelectorAll(sel)] : sel)
  let fingerShown = false

  const k = {
    q,
    qa,
    money,
    grouped,

    /** move the finger to `target`, press, ripple. opts.then(el) runs at the press. */
    tap(tl, target, { pos = '+=0.25', then, hold = 0.12, anchor = [0.5, 0.5] } = {}) {
      const el = q(target)
      if (!el) return tl
      const pt = () => localPoint(el, screen, anchor[0], anchor[1])
      const label = `tap${tl.getChildren().length}`
      tl.addLabel(label, pos)
      if (!fingerShown) {
        tl.set(finger, { x: () => pt().x + 40, y: () => pt().y + 70, scale: 1.2, opacity: 0 }, label)
        tl.to(finger, { opacity: 1, duration: 0.25, ease: 'power2.out' }, label)
        fingerShown = true
      }
      tl.to(finger, { x: () => pt().x, y: () => pt().y, scale: 1, duration: 0.5, ease: 'power3.inOut' }, label)
      tl.to(finger, { scale: 0.8, duration: 0.09, ease: 'power2.in' }, '>')
      tl.set(ripple, { x: () => pt().x, y: () => pt().y, scale: 0.2, opacity: 0.95 }, '<')
      tl.to(ripple, { scale: 1, opacity: 0, duration: 0.5, ease: 'power2.out' }, '<')
      tl.call(() => {
        el.classList.add('is-pressed')
        setTimeout(() => el.classList.remove('is-pressed'), 160)
        then?.(el)
      }, null, '<')
      tl.to(finger, { scale: 1, duration: 0.16, ease: 'power2.out' }, `>+=${hold}`)
      return tl
    },

    /** hide the finger */
    lift(tl, pos = '+=0.2') {
      if (!fingerShown) return tl
      tl.to(finger, { opacity: 0, scale: 1.15, duration: 0.3, ease: 'power2.out' }, pos)
      fingerShown = false
      return tl
    },

    /** type `text` into `target` (its textContent), with a blinking caret */
    type(tl, target, text, { pos = '+=0.1', cps = 22, keep = false } = {}) {
      const el = q(target)
      if (!el) return tl
      const state = { n: 0 }
      tl.call(() => el.classList.add('is-typing'), null, pos)
      tl.to(state, {
        n: text.length,
        duration: Math.max(0.3, text.length / cps),
        ease: 'none',
        onUpdate: () => {
          el.textContent = text.slice(0, Math.round(state.n))
        },
      }, '>')
      if (!keep) tl.call(() => el.classList.remove('is-typing'), null, '>+=0.25')
      return tl
    },

    /** toggle a class at a point in time */
    cls(tl, target, name, on = true, pos = '+=0') {
      const els = qa(target)
      const list = Array.isArray(els) ? els : [els]
      tl.call(() => list.forEach((e) => e && e.classList.toggle(name, on)), null, pos)
      return tl
    },

    /** set text at a point in time */
    text(tl, target, value, pos = '+=0') {
      const el = q(target)
      tl.call(() => el && (el.textContent = value), null, pos)
      return tl
    },

    /** fade + rise a list of elements */
    reveal(tl, targets, { pos = '+=0', y = 14, stagger = 0.07, duration = 0.5 } = {}) {
      const els = qa(targets)
      if (!els || (Array.isArray(els) && !els.length)) return tl
      tl.fromTo(els, { opacity: 0, y }, { opacity: 1, y: 0, duration, stagger, ease: 'power3.out' }, pos)
      return tl
    },

    /** scroll a container (translateY) to show content at offset `y` */
    scroll(tl, target, y, { pos = '+=0.2', duration = 0.9 } = {}) {
      tl.to(q(target), { y: -y, duration, ease: 'power3.inOut' }, pos)
      return tl
    },

    /** grow .wib-bar__fill elements to their data-pct (or given pct) */
    fill(tl, targets, { pos = '+=0', pct, duration = 0.9, stagger = 0.08 } = {}) {
      const els = qa(targets)
      tl.fromTo(
        els,
        { width: '0%' },
        { width: (i, el) => `${pct ?? el.dataset.pct ?? 0}%`, duration, stagger, ease: 'power3.out' },
        pos,
      )
      return tl
    },

    /** count a number up inside `target` using `format` */
    count(tl, target, to, { from = 0, pos = '+=0', duration = 1, format = money } = {}) {
      const el = q(target)
      const s = { v: from }
      tl.to(s, {
        v: to,
        duration,
        ease: 'power2.out',
        onStart: () => el && (el.textContent = format(from)),
        onUpdate: () => el && (el.textContent = format(s.v)),
      }, pos)
      return tl
    },

    /** floating SnackBar slides up */
    snack(tl, target = '.wib-snackbar', { pos = '+=0.1' } = {}) {
      tl.to(q(target), { opacity: 1, y: 0, duration: 0.35, ease: 'power3.out' }, pos)
      return tl
    },

    /** bottom sheet open/close (needs .wib-scrim + .wib-sheet inside `scope`) */
    sheet(tl, scope = root, { open = true, pos = '+=0.1' } = {}) {
      const s = q(scope)
      const scrim = s.querySelector('.wib-scrim')
      const sh = s.querySelector('.wib-sheet')
      if (open) {
        tl.to(scrim, { opacity: 1, duration: 0.3, ease: 'power2.out' }, pos)
        tl.to(sh, { yPercent: -105, duration: 0.5, ease: 'power3.out' }, '<')
      } else {
        tl.to(sh, { yPercent: 0, duration: 0.35, ease: 'power3.in' }, pos)
        tl.to(scrim, { opacity: 0, duration: 0.3 }, '<')
      }
      return tl
    },

    /** dialog pop (with optional scrim) */
    dialog(tl, target, { scrim, open = true, pos = '+=0.1' } = {}) {
      const d = q(target)
      const sc = scrim ? q(scrim) : null
      if (open) {
        if (sc) tl.to(sc, { opacity: 1, duration: 0.25 }, pos)
        tl.to(d, { opacity: 1, scale: 1, duration: 0.35, ease: 'power3.out' }, sc ? '<' : pos)
      } else {
        tl.to(d, { opacity: 0, scale: 0.94, duration: 0.2 }, pos)
        if (sc) tl.to(sc, { opacity: 0, duration: 0.2 }, '<')
      }
      return tl
    },

    /** Android shared-axis page change between two elements inside the screen */
    page(tl, from, to, { pos = '+=0.1', dir = 1 } = {}) {
      const a = q(from)
      const b = q(to)
      tl.set(b, { display: '' }, pos)
      tl.fromTo(b, { opacity: 0, x: 36 * dir }, { opacity: 1, x: 0, duration: 0.45, ease: 'power3.out' }, '<')
      tl.to(a, { opacity: 0, x: -36 * dir, duration: 0.3, ease: 'power2.in' }, '<')
      tl.set(a, { display: 'none' }, '>')
      return tl
    },

    /** site-level callout label pointing at an element of the screen */
    callout(tl, target, text, { pos = '+=0', side = 'left' } = {}) {
      tl.call(() => device.callouts?.show(q(target), text, side), null, pos)
      return tl
    },

    wait(tl, s = 0.5) {
      tl.to({}, { duration: s })
      return tl
    },
  }
  return k
}

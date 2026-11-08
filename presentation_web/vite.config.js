import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs'
import { join, resolve } from 'node:path'

const ICON_DIR = resolve('node_modules/@material-design-icons/svg')
const SRC_DIR = resolve('src')
const VIRTUAL_ID = 'virtual:icons'
const RESOLVED_ID = '\0' + VIRTUAL_ID

// Flutter icon names that Material's SVG set spells differently
const ALIASES = {
  favorite_outline: 'outlined/favorite_border',
  favorite_border: 'outlined/favorite_border',
  lightbulb_outline: 'outlined/lightbulb',
  lightbulb_outline_rounded: 'outlined/lightbulb',
  mail_outline_rounded: 'round/mail_outline',
  person_outline_rounded: 'round/person_outline',
  check_circle_outline: 'outlined/check_circle',
  remove_circle_outline: 'outlined/remove_circle',
  info_outline: 'outlined/info',
  bookmark_border_rounded: 'round/bookmark_border',
  bookmark_outline_rounded: 'round/bookmark_border',
  notifications_none_rounded: 'round/notifications_none',
  add_circle_outline_rounded: 'round/add_circle_outline',
  error_outline_rounded: 'round/error_outline',
  help_outline_rounded: 'round/help_outline',
  g_mobiledata: 'filled/g_mobiledata',
}

/** Flutter Icons.* name -> svg file under @material-design-icons/svg */
function resolveIcon(name) {
  const candidates = []
  if (ALIASES[name]) candidates.push(ALIASES[name])
  const m = name.match(/^(.*?)_(rounded|outlined|sharp)$/)
  if (m) {
    const style = m[2] === 'rounded' ? 'round' : m[2]
    candidates.push(`${style}/${m[1]}`)
    if (m[1].endsWith('_outline')) candidates.push(`outlined/${m[1].slice(0, -8)}`, `${style}/${m[1].slice(0, -8)}`)
    candidates.push(`filled/${m[1]}`, `outlined/${m[1]}`)
  } else {
    candidates.push(`filled/${name}`)
    if (name.endsWith('_outline')) candidates.push(`outlined/${name.slice(0, -8)}`)
    candidates.push(`outlined/${name}`, `round/${name}`)
  }
  for (const c of candidates) {
    const file = join(ICON_DIR, `${c}.svg`)
    if (existsSync(file)) return file
  }
  return null
}

function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry)
    if (statSync(p).isDirectory()) walk(p, out)
    else if (/\.(js|html)$/.test(entry)) out.push(p)
  }
  return out
}

/**
 * Bundles only the Material icons the code actually names, so the single-file
 * build stays small and works offline. Usage in code: icon('chevron_left_rounded').
 */
function materialIcons() {
  return {
    name: 'material-icons-subset',
    resolveId(id) {
      return id === VIRTUAL_ID ? RESOLVED_ID : null
    },
    load(id) {
      if (id !== RESOLVED_ID) return null
      const names = new Set()
      for (const file of walk(SRC_DIR)) {
        const text = readFileSync(file, 'utf8')
        for (const m of text.matchAll(/\bicon\(\s*['"`]([a-z0-9_]+)['"`]/g)) names.add(m[1])
        for (const m of text.matchAll(/data-icon="([a-z0-9_]+)"/g)) names.add(m[1])
        for (const m of text.matchAll(/\bicon:\s*['"`]([a-z0-9_]+)['"`]/g)) names.add(m[1])
      }
      const map = {}
      const missing = []
      for (const n of [...names].sort()) {
        const file = resolveIcon(n)
        if (!file) { missing.push(n); continue }
        const svg = readFileSync(file, 'utf8')
        map[n] = svg.replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '')
      }
      if (missing.length) this.warn(`Material icons not found: ${missing.join(', ')}`)
      return `export default ${JSON.stringify(map)}`
    },
    handleHotUpdate({ file, server }) {
      // a source edit may name new icons: rebuild the subset and reload the page
      const norm = (p) => p.replace(/\\/g, '/').toLowerCase()
      if (norm(file).startsWith(norm(SRC_DIR)) && /\.(js|html)$/.test(file)) {
        const mod = server.moduleGraph.getModuleById(RESOLVED_ID)
        if (mod) {
          server.moduleGraph.invalidateModule(mod)
          server.ws.send({ type: 'full-reload' })
          return []
        }
      }
    },
  }
}

// One self-contained dist/index.html (JS, CSS and fonts inlined) so the deck
// opens from a USB stick or a classroom PC without internet.
export default defineConfig({
  base: './',
  plugins: [materialIcons(), viteSingleFile()],
  build: {
    target: 'es2022',
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    chunkSizeWarningLimit: 4000,
  },
  server: { port: 5178, strictPort: true },
  preview: { port: 5179, strictPort: true },
})

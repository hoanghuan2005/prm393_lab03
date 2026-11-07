// Temporary stand-in used until a real screen module is written.
import { html, appBar } from './kit.js'

export function placeholder(id, title) {
  return {
    id,
    render() {
      return html`<div class="wib-screen">${appBar({ title })}
        <div class="wib-body" style="display:grid;place-items:center;color:var(--text-2)">${title}</div></div>`
    },
  }
}

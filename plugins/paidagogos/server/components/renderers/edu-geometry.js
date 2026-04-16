// <edu-geometry config="{...}"> — interactive 2D geometry via JSXGraph.
// Config: { board: JSXGraphBoardAttrs, elements: Array<{type, id?, args, attrs}> }

const { LitElement, html, css } = window.__lit;
const JSX_URL = 'https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.11.1/jsxgraphcore.min.js';
const JSX_CSS = 'https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.11.1/jsxgraph.min.css';

let jsxReady = null;
function ensureJSX() {
  if (window.JXG) return Promise.resolve();
  if (!jsxReady) {
    jsxReady = new Promise((resolve, reject) => {
      if (!document.querySelector('link[data-jsx]')) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = JSX_CSS;
        link.dataset.jsx = 'true';
        document.head.appendChild(link);
      }
      const s = document.createElement('script');
      s.src = JSX_URL;
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }
  return jsxReady;
}

class EduGeometry extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .board { width: 100%; max-width: 600px; height: 400px; border: 1px solid var(--border, #e9ecef); border-radius: 8px; }
  `;

  async firstUpdated() {
    if (!this.config?.board) return;
    await ensureJSX();
    const div = this.renderRoot.querySelector('.board');
    const hostId = 'jxg-' + Math.random().toString(36).slice(2, 10);
    div.id = hostId;
    const board = window.JXG.JSXGraph.initBoard(hostId, this.config.board);
    const refs = {};
    for (const el of (this.config.elements || [])) {
      const resolvedArgs = el.args.map(a =>
        Array.isArray(a) ? a.map(x => refs[x] || x) : (refs[a] || a)
      );
      const created = board.create(el.type, resolvedArgs, el.attrs || {});
      if (el.id) refs[el.id] = created;
    }
  }

  render() {
    return html`<div class="board"></div>`;
  }
}

customElements.define('edu-geometry', EduGeometry);

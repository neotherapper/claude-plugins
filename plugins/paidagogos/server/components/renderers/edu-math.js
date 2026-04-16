// <edu-math config="{...}"> — renders LaTeX via KaTeX.
// Config: { latex: string, display: boolean }

import { LitElement, html, css } from 'https://esm.sh/lit@3.2.1';

// Inject KaTeX stylesheet once.
if (!document.querySelector('link[data-katex]')) {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.css';
  link.dataset.katex = 'true';
  document.head.appendChild(link);
}

// Load KaTeX runtime once.
const katexReady = (async () => {
  if (window.katex) return;
  await new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.js';
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
})();

class EduMath extends LitElement {
  static properties = {
    config: { type: Object },
  };

  // Render into light DOM so the page-level KaTeX stylesheet applies.
  // Shadow DOM would isolate KaTeX's <span class="mord"> markup from its CSS.
  createRenderRoot() { return this; }

  async firstUpdated() { await katexReady; this.requestUpdate(); }
  async updated() { await katexReady; }

  render() {
    if (!this.config || !this.config.latex) {
      return html`<div class="math-error">edu-math: missing config.latex</div>`;
    }
    if (!window.katex) {
      return html`<div class="math-block">Loading KaTeX…</div>`;
    }
    try {
      const rendered = window.katex.renderToString(this.config.latex, {
        displayMode: this.config.display === true,
        throwOnError: false,
        output: 'html',
      });
      const div = document.createElement('div');
      div.className = 'math-block';
      div.innerHTML = rendered;
      return html`${div}`;
    } catch (err) {
      return html`<div class="math-error">KaTeX error: ${err.message}</div>`;
    }
  }
}

customElements.define('edu-math', EduMath);

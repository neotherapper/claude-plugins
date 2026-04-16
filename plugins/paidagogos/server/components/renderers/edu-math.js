// <edu-math config="{...}"> — renders LaTeX via KaTeX.
// Config: { latex: string, display: boolean }

const { LitElement, html, css } = window.__lit;

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

  static styles = css`
    :host { display: block; margin: 1rem 0; font-size: 1.1rem; }
    .math-block { overflow-x: auto; padding: 0.5rem; }
    .math-error { color: var(--warning, #d29922); font-family: monospace; font-size: 0.85rem; }
  `;

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

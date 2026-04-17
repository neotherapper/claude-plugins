// <edu-code config="{...}"> — syntax-highlighted code display.
// Config: { language: string, code: string, editable?: boolean }
//
// V2 uses highlight.js for display-only rendering. V2.1 will add interactive
// editing via CodeMirror 6 behind an `editable: true` flag, with proper
// import-map deduplication of @codemirror/state.

import { LitElement, html } from 'https://esm.sh/lit@3.2.1';

const HLJS_URL = 'https://esm.sh/highlight.js@11.11.1';
const HLJS_CSS = 'https://esm.sh/highlight.js@11.11.1/styles/github-dark.css';

// Inject highlight.js stylesheet once.
if (!document.querySelector('link[data-hljs]')) {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = HLJS_CSS;
  link.dataset.hljs = 'true';
  document.head.appendChild(link);
}

const hljsReady = (async () => {
  const mod = await import(HLJS_URL);
  return mod.default;
})();

const EDU_CODE_STYLE = `
  edu-code { display: block; margin: 1rem 0; }
  edu-code .wrap { border: 1px solid var(--border, #e9ecef); border-radius: 8px; overflow: hidden; background: var(--code-bg, #1e2530); }
  edu-code pre { margin: 0; padding: 1rem; overflow-x: auto; font-family: "SF Mono", Consolas, monospace; font-size: 0.9rem; line-height: 1.5; }
  edu-code code { font-family: inherit; }
`;
if (!document.querySelector('style[data-edu-code]')) {
  const s = document.createElement('style');
  s.dataset.eduCode = 'true';
  s.textContent = EDU_CODE_STYLE;
  document.head.appendChild(s);
}

class EduCode extends LitElement {
  static properties = { config: { type: Object } };

  // Light DOM — highlight.js CSS is loaded in <head> and must apply to the <code> tree.
  createRenderRoot() { return this; }

  async firstUpdated() {
    if (!this.config?.code) return;
    const hljs = await hljsReady;
    const codeEl = this.querySelector('code');
    if (!codeEl) return;
    codeEl.textContent = this.config.code;
    if (this.config.language && hljs.getLanguage(this.config.language)) {
      codeEl.className = `language-${this.config.language}`;
      hljs.highlightElement(codeEl);
    }
  }

  render() {
    return html`<div class="wrap"><pre><code></code></pre></div>`;
  }
}

customElements.define('edu-code', EduCode);

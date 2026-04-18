import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import katex from 'katex';
import katexCss from 'katex/dist/katex.css';

// Inject KaTeX CSS into document head once per page (bundle-side-effect).
// Light-DOM rendering means KaTeX markup lives in the page's DOM, not shadow DOM,
// so KaTeX CSS must cascade in from the page — can't live inside shadow DOM styles.
if (typeof document !== 'undefined' && !document.querySelector('style[data-vk-katex]')) {
  const styleEl = document.createElement('style');
  styleEl.setAttribute('data-vk-katex', '');
  styleEl.textContent = katexCss;
  document.head.appendChild(styleEl);
}

@customElement('vk-math')
export class VkMath extends LitElement {
  // Light-DOM render: KaTeX's CSS in document head must reach its output markup.
  // See reference/README.md delta #4 for the architectural reasoning.
  protected createRenderRoot(): Element {
    return this;
  }

  static styles = css`
    /* Unused under light DOM but declared to satisfy Lit's static-styles contract. */
    :host { display: block; }
  `;

  @property({ type: Boolean }) display = false;

  render() {
    const latex = this.textContent?.trim() ?? '';
    if (!latex) return html``;
    try {
      const rendered = katex.renderToString(latex, {
        displayMode: this.display,
        throwOnError: false,
        output: 'html',
        trust: false,        // blocks \href to non-http(s), \url, \htmlClass, \htmlId, \htmlData
        strict: 'warn',      // warn on non-standard commands; do not silently permit
        maxSize: 10,         // cap rendered-element size multiplier
        maxExpand: 1000,     // cap macro-expansion depth (DoS guard)
      });
      return html`<div .innerHTML=${rendered}></div>`;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return html`<div class="math-error" style="color:var(--vk-warning,#d29922);font-family:monospace;font-size:.85rem">KaTeX error: ${msg}</div>`;
    }
  }
}

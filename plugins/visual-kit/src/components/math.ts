import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import katex from 'katex';
import katexCss from 'katex/dist/katex.css';

// Inject KaTeX CSS into document head once per page (bundle-side-effect).
// Light-DOM rendering means KaTeX markup lives in the page's DOM, not shadow DOM,
// so KaTeX CSS must cascade in from the page — can't live inside shadow DOM styles.
//
// The shell ships CSP `style-src 'self' 'nonce-<X>'`, so DOM-inserted <style>
// elements need that nonce to be accepted. We pick up the current script's
// nonce and propagate it to the injected <style>. `document.currentScript` is
// null for module scripts, so we fall back to `<script[nonce]>` (the shell's
// module <script> carries the active nonce).
if (typeof document !== 'undefined' && !document.querySelector('style[data-vk-katex]')) {
  const styleEl = document.createElement('style');
  styleEl.setAttribute('data-vk-katex', '');
  styleEl.textContent = katexCss;
  const currentNonce =
    (document.currentScript as HTMLScriptElement | null)?.nonce ??
    document.querySelector<HTMLScriptElement>('script[nonce]')?.nonce ??
    '';
  if (currentNonce) styleEl.nonce = currentNonce;
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

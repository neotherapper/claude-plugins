import { LitElement, html, css, unsafeCSS } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import prismThemeCss from './prism-theme.css';

@customElement('vk-code')
export class VkCode extends LitElement {
  static styles = [
    css`
      :host { display: block; position: relative; }
      pre {
        background: var(--vk-code-bg);
        padding: 1rem;
        border-radius: 4px;
        overflow-x: auto;
        margin: 0;
        font-family: 'SF Mono', Consolas, monospace;
        font-size: 0.85rem;
        line-height: 1.5;
      }
      button {
        position: absolute;
        top: 0.5rem;
        right: 0.5rem;
        background: var(--vk-surface);
        border: 1px solid var(--vk-border);
        border-radius: 4px;
        padding: 0.25rem 0.5rem;
        font-size: 0.75rem;
        cursor: pointer;
      }
    `,
    unsafeCSS(prismThemeCss),
  ];

  @property() language = 'text';

  private async copy() {
    try { await navigator.clipboard.writeText(this.textContent ?? ''); } catch { /* clipboard unavailable */ }
  }

  render() {
    return html`
      <pre><code class="language-${this.language}"><slot></slot></code></pre>
      <button @click=${this.copy}>copy</button>`;
  }
}

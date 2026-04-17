import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-comparison')
export class VkComparison extends LitElement {
  static styles = css`
    :host { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; align-items: start; }
    @media (max-width: 720px) { :host { grid-template-columns: 1fr; } }
    ::slotted([slot="variant"]) { padding: 1rem; border: 1px solid var(--vk-border); border-radius: 8px; }
  `;
  render() { return html`<slot name="variant"></slot>`; }
}

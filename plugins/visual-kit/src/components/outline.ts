import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-outline')
export class VkOutline extends LitElement {
  static styles = css`
    :host { display: block; }
    ::slotted(details) { margin: 0.5rem 0; padding: 0.5rem; border-left: 2px solid var(--vk-border); }
  `;
  render() { return html`<slot></slot>`; }
}

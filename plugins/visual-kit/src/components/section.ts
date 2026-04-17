import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-section')
export class VkSection extends LitElement {
  static styles = css`
    :host { display: block; margin: 1.25rem 0; }
    ::slotted([slot="title"]) { margin: 0 0 .5rem; color: var(--vk-text); }
    ::slotted([slot="meta"])  { margin: 0 0 1rem; color: var(--vk-muted); font-size: .875rem; }
  `;
  render() {
    return html`<slot name="title"></slot><slot name="meta"></slot><slot></slot>`;
  }
}

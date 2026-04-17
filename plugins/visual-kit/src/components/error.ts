import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-error')
export class VkError extends LitElement {
  static styles = css`
    :host { display: block; padding: 1rem; border-left: 3px solid var(--vk-danger); background: var(--vk-surface); border-radius: 0 4px 4px 0; }
    ::slotted([slot="title"]) { margin: 0 0 0.5rem; color: var(--vk-danger); }
    ::slotted([slot="detail"]) { margin: 0.25rem 0; font-size: 0.875rem; color: var(--vk-muted); }
  `;
  render() {
    return html`
      <div role="alert">
        <slot name="title"></slot>
        <slot name="detail"></slot>
      </div>`;
  }
}

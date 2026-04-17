import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-loader')
export class VkLoader extends LitElement {
  static styles = css`
    :host { display: inline-flex; align-items: center; gap: 0.5rem; color: var(--vk-muted); }
    .spinner { width: 1rem; height: 1rem; border: 2px solid var(--vk-border); border-top-color: var(--vk-accent); border-radius: 50%; animation: spin 0.8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
  `;
  render() { return html`<div class="spinner"></div><slot></slot>`; }
}

import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-gallery')
export class VkGallery extends LitElement {
  static styles = css`
    :host { display:grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap:1rem; }
  `;
  render() { return html`<slot></slot>`; }
}

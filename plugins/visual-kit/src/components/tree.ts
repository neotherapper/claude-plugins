import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

/**
 * Container for the `tree` surface.
 *
 * Deliberately thin. The tree's markup is deeply nested light DOM, which
 * `::slotted()` cannot reach past the first level, so the tree's visual design
 * lives in the global stylesheet (src/components/theme.css, served at
 * /vk/theme.css) where it can style the whole subtree. This element supplies
 * the block box and the named header slot only.
 */
@customElement('vk-tree')
export class VkTree extends LitElement {
  static styles = css`
    :host { display: block; }
  `;
  render() {
    return html`<slot name="header"></slot><slot></slot>`;
  }
}

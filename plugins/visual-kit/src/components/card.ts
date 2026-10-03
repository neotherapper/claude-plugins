import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';

@customElement('vk-card')
export class VkCard extends LitElement {
  static styles = css`
    :host { display:block; border:1px solid var(--vk-border); border-radius:8px;
      padding:1rem; background:var(--vk-surface); cursor:pointer; }
    :host([data-selected]) { border-color: var(--vk-accent); }
    ::slotted([slot="title"]) { margin:0 0 .25rem; }
    ::slotted([slot="subtitle"]) { margin:0 0 .5rem; color:var(--vk-muted); font-size:.875rem }
    .badges { margin-top:.5rem; display:flex; gap:.25rem; flex-wrap:wrap }
    .link { display:block; color:inherit; text-decoration:none; }
    :host([data-href]:hover) { border-color: var(--vk-accent); }
    :host([data-href]:has(a:focus-visible)) { outline:2px solid var(--vk-accent); outline-offset:2px; }
  `;
  @property({ attribute: 'data-id' }) dataId = '';
  @property({ attribute: 'data-href' }) dataHref = '';
  private toggle() {
    this.toggleAttribute('data-selected');
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true, composed: true,
      detail: { type: this.hasAttribute('data-selected') ? 'select' : 'deselect', id: this.dataId },
    }));
  }
  render() {
    const inner = html`
      <slot name="title"></slot>
      <slot name="subtitle"></slot>
      <slot name="body"></slot>
      <div class="badges"><slot name="badge"></slot></div>`;
    // A linked card navigates and must not also toggle selection — one card,
    // one meaning. Selection stays the behaviour for cards without an href.
    return this.dataHref
      ? html`<a class="link" href=${this.dataHref}>${inner}</a>`
      : html`<div @click=${this.toggle}>${inner}</div>`;
  }
}

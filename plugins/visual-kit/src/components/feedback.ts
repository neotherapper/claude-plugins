import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';

@customElement('vk-feedback')
export class VkFeedback extends LitElement {
  static styles = css`
    :host { display: block; padding: 1rem; border: 1px solid var(--vk-border); border-radius: 8px; }
    form { display: flex; flex-direction: column; gap: 1rem; }
    button { background: var(--vk-accent); color: white; border: 0; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer; }
  `;
  @property({ attribute: 'data-submit-label' }) submitLabel = 'Submit';
  private onSubmit(e: SubmitEvent) {
    e.preventDefault();
    const form = e.target as HTMLFormElement;
    const fields: Record<string, FormDataEntryValue> = {};
    for (const [k, v] of new FormData(form)) fields[k] = v;
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true, composed: true,
      detail: { type: 'feedback', fields },
    }));
  }
  render() {
    return html`
      <form @submit=${this.onSubmit}>
        <slot name="title"></slot>
        <slot name="field"></slot>
        <button type="submit">${this.submitLabel}</button>
      </form>`;
  }
}

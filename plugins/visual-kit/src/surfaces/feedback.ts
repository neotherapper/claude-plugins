import { html, type TemplateResult } from 'lit';

interface FeedbackField {
  type: 'choice' | 'text';
  id: string;
  prompt: string;
  options?: string[];
}

interface FeedbackSpec {
  title?: string;
  submit_label?: string;
  fields: FeedbackField[];
}

export function renderFeedback(spec: FeedbackSpec): TemplateResult {
  return html`
    <vk-feedback data-submit-label="${spec.submit_label ?? 'Submit'}">
      ${spec.title ? html`<h1 slot="title">${spec.title}</h1>` : ''}
      ${spec.fields.map(field)}
    </vk-feedback>
  `;
}

function field(f: FeedbackField): TemplateResult {
  if (f.type === 'choice') {
    return html`
      <fieldset slot="field" data-id="${f.id}">
        <legend>${f.prompt}</legend>
        ${(f.options ?? []).map(opt => html`
          <label><input type="radio" name="${f.id}" value="${opt}">${opt}</label>
        `)}
      </fieldset>
    `;
  }
  return html`
    <label slot="field" data-id="${f.id}">
      <span>${f.prompt}</span>
      <textarea name="${f.id}" rows="3"></textarea>
    </label>
  `;
}

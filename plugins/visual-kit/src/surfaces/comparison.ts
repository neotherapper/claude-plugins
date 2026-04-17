import { html, type TemplateResult } from 'lit';
import { renderSurface } from '../render/dispatcher.js';

interface ComparisonSpec {
  title?: string;
  variants: Array<{ label: string; body: { surface?: string; [k: string]: unknown } }>;
}

export function renderComparison(spec: ComparisonSpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-comparison>
      ${spec.variants.map(v => html`
        <section slot="variant" data-label="${v.label}">
          <header><h2>${v.label}</h2></header>
          ${renderSurface(v.body)}
          <button class="vk-choose" data-variant="${v.label}">Choose ${v.label}</button>
        </section>
      `)}
    </vk-comparison>
  `;
}

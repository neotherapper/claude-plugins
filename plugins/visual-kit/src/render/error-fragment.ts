import { html, type TemplateResult } from 'lit';

export interface VkErrorOpts {
  title: string;
  detail?: string;
  surface?: string;
  capabilitiesUrl?: string;
}

export function renderVkError(opts: VkErrorOpts): TemplateResult {
  return html`
    <vk-error>
      <h2 slot="title">${opts.title}</h2>
      ${opts.detail ? html`<p slot="detail">${opts.detail}</p>` : ''}
      ${opts.surface ? html`<p slot="detail"><strong>Surface:</strong> ${opts.surface}</p>` : ''}
      ${opts.capabilitiesUrl
        ? html`<p slot="detail">
            See available surfaces at
            <a href="${opts.capabilitiesUrl}">${opts.capabilitiesUrl}</a>
          </p>`
        : ''}
    </vk-error>
  `;
}

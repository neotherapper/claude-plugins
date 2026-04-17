import { html, type TemplateResult } from 'lit';

interface GalleryItem {
  id: string;
  title: string;
  subtitle?: string;
  body?: string;
  badges?: Array<{ label: string; tone?: string }>;
}

interface GallerySpec {
  title?: string;
  multiselect?: boolean;
  items: GalleryItem[];
}

export function renderGallery(spec: GallerySpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-gallery data-multiselect="${spec.multiselect ? 'true' : 'false'}">
      ${spec.items.map(item => html`
        <vk-card data-id="${item.id}">
          <h3 slot="title">${item.title}</h3>
          ${item.subtitle ? html`<p slot="subtitle">${item.subtitle}</p>` : ''}
          ${item.body ? html`<p slot="body">${item.body}</p>` : ''}
          ${item.badges?.map(b => html`<span slot="badge" data-tone="${b.tone ?? 'muted'}" data-label="${b.label}">${b.label}</span>`) ?? ''}
        </vk-card>
      `)}
    </vk-gallery>
  `;
}

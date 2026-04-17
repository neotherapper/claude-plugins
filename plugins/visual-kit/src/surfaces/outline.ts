import { html, type TemplateResult } from 'lit';

interface OutlineNode {
  heading: string;
  summary?: string;
  children?: OutlineNode[];
}

interface OutlineSpec {
  title?: string;
  nodes: OutlineNode[];
}

export function renderOutline(spec: OutlineSpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-outline>${spec.nodes.map(node)}</vk-outline>
  `;
}

function node(n: OutlineNode): TemplateResult {
  return html`
    <details open>
      <summary>${n.heading}</summary>
      ${n.summary ? html`<p>${n.summary}</p>` : ''}
      ${n.children?.map(child) ?? ''}
    </details>
  `;
}

function child(n: OutlineNode): TemplateResult {
  return html`
    <details>
      <summary>${n.heading}</summary>
      ${n.summary ? html`<p>${n.summary}</p>` : ''}
      ${n.children?.map(child) ?? ''}
    </details>
  `;
}

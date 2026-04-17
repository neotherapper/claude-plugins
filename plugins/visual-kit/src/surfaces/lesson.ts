import { html, type TemplateResult } from 'lit';

interface LessonSpec {
  topic: string;
  level: string;
  estimated_minutes?: number;
  caveat?: string;
  sections: Array<Record<string, unknown> & { type: string }>;
}

export function renderLesson(spec: LessonSpec): TemplateResult {
  return html`
    <vk-section data-variant="header">
      <h1 slot="title">${spec.topic}</h1>
      <p slot="meta">${spec.level}${spec.estimated_minutes ? ` · ${spec.estimated_minutes} min` : ''}</p>
    </vk-section>
    ${spec.sections.map(section)}
    ${spec.caveat ? html`<vk-section data-variant="caveat"><p>${spec.caveat}</p></vk-section>` : ''}
  `;
}

function section(s: Record<string, unknown> & { type: string }): TemplateResult {
  switch (s.type) {
    case 'concept':   return html`<vk-section data-variant="concept"><h2 slot="title">Concept</h2><p>${String(s.text ?? '')}</p></vk-section>`;
    case 'why':       return html`<vk-section data-variant="why"><h2 slot="title">Why it matters</h2><p>${String(s.text ?? '')}</p></vk-section>`;
    case 'code':      return html`<vk-section data-variant="code"><h2 slot="title">Example</h2><vk-code language="${String(s.language ?? 'text')}">${String(s.source ?? '')}</vk-code></vk-section>`;
    case 'mistakes':  return html`<vk-section data-variant="mistakes"><h2 slot="title">Common mistakes</h2><ul>${(s.items as string[] ?? []).map(m => html`<li>${m}</li>`)}</ul></vk-section>`;
    case 'generate':  return html`<vk-section data-variant="generate"><h2 slot="title">Try it</h2><p>${String(s.task ?? '')}</p></vk-section>`;
    case 'next':      return html`<vk-section data-variant="next"><h2 slot="title">Next</h2><p>${String(s.concept ?? '')}</p></vk-section>`;
    case 'resources': return html`<vk-section data-variant="resources"><h2 slot="title">Resources</h2><ul>${resourceList(s.items as Array<Record<string, unknown>>)}</ul></vk-section>`;
    default:          return html`<vk-section data-variant="${s.type}"><p>Section type "${s.type}" not yet supported in the core bundle. Install Plan B for code, math, chart, quiz renderers.</p></vk-section>`;
  }
}

function resourceList(items: Array<Record<string, unknown>> = []): TemplateResult[] {
  return items.map(r => html`<li><a href="${String(r.url ?? '#')}">${String(r.title ?? '')}</a> — ${String(r.type ?? '')}</li>`);
}

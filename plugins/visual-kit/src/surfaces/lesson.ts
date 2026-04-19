import { html, type TemplateResult } from 'lit';
import { unsafeHTML } from 'lit/directives/unsafe-html.js';
import { unsafeJSON } from '../render/escape.js';
import { highlightToHtml } from '../render/highlight.js';

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
    case 'concept':
      return html`<vk-section data-variant="concept"><h2 slot="title">Concept</h2><p>${String(s.text ?? '')}</p></vk-section>`;

    case 'why':
      return html`<vk-section data-variant="why"><h2 slot="title">Why it matters</h2><p>${String(s.text ?? '')}</p></vk-section>`;

    case 'code': {
      const language = String(s.language ?? 'text');
      const source = String(s.source ?? '');
      const tokens = highlightToHtml(language, source);
      return html`<vk-section data-variant="code">
        <h2 slot="title">Example</h2>
        <vk-code language="${language}">${unsafeHTML(tokens)}</vk-code>
      </vk-section>`;
    }

    case 'math':
      return html`<vk-section data-variant="math">
        <h2 slot="title">Math</h2>
        <vk-math ?display=${s.display === true}>${String(s.latex ?? '')}</vk-math>
      </vk-section>`;

    case 'chart': {
      const chartScript = `<script type="application/json">${unsafeJSON(s.config)}</script>`;
      return html`<vk-section data-variant="chart">
        <h2 slot="title">Chart</h2>
        <vk-chart>${unsafeHTML(chartScript)}</vk-chart>
      </vk-section>`;
    }

    case 'quiz': {
      const quizScript = `<script type="application/json">${unsafeJSON({ items: s.items })}</script>`;
      return html`<vk-section data-variant="quiz">
        <h2 slot="title">Check yourself</h2>
        <vk-quiz>${unsafeHTML(quizScript)}</vk-quiz>
      </vk-section>`;
    }

    case 'mistakes':
      return html`<vk-section data-variant="mistakes"><h2 slot="title">Common mistakes</h2><ul>${(s.items as string[] ?? []).map(m => html`<li>${m}</li>`)}</ul></vk-section>`;

    case 'generate':
      return html`<vk-section data-variant="generate"><h2 slot="title">Try it</h2><p>${String(s.task ?? '')}</p></vk-section>`;

    case 'next':
      return html`<vk-section data-variant="next"><h2 slot="title">Next</h2><p>${String(s.concept ?? '')}</p></vk-section>`;

    case 'resources':
      return html`<vk-section data-variant="resources"><h2 slot="title">Resources</h2><ul>${resourceList(s.items as Array<Record<string, unknown>>)}</ul></vk-section>`;

    default:
      return html`<vk-section data-variant="${s.type}"><p>Section type "${s.type}" not yet supported.</p></vk-section>`;
  }
}

function resourceList(items: Array<Record<string, unknown>> = []): TemplateResult[] {
  return items.map(r => html`<li><a href="${String(r.url ?? '#')}">${String(r.title ?? '')}</a> — ${String(r.type ?? '')}</li>`);
}

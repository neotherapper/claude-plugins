import { render } from '@lit-labs/ssr';
import { collectResultSync } from '@lit-labs/ssr/lib/render-result.js';
import type { TemplateResult } from 'lit';

export function renderFragment(template: TemplateResult): string {
  return collectResultSync(render(template));
}

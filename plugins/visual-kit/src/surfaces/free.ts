import { html, unsafeStatic, literal } from 'lit/static-html.js';
import type { TemplateResult } from 'lit';
import { sanitizeFreeHtml } from '../render/sanitize.js';

interface FreeSpec {
  html: string;
}

export function renderFree(spec: FreeSpec): TemplateResult {
  const safe = sanitizeFreeHtml(spec.html);
  return html`${unsafeStatic(safe)}`;
}

export const _kind = literal`free`;

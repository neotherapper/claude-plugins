/**
 * free-interactive surface — serves AI-authored HTML+JS as-is.
 *
 * Trust model: localhost-only, AI-trusted, no sanitisation, no CSP.
 * See spec: docs/superpowers/specs/2026-04-19-visual-kit-free-interactive-surface.md
 */

export interface FreeInteractiveSpec {
  surface: 'free-interactive';
  version: 1;
  html: string;
  title?: string;
}

const RELOAD_SCRIPT =
  '<script>(function(){var es=new EventSource(\'/events/stream\');' +
  'es.onmessage=function(e){if(e.data===\'refresh\')location.reload();};})();' +
  '</script>';

/**
 * Inserts the SSE auto-reload script immediately before the last </body>
 * tag in `html`. If no </body> exists (fragment input), appends at the end.
 * Case-insensitive match. The LAST occurrence is used so nested srcdoc
 * payloads don't confuse the injection point.
 */
export function injectReloadScript(html: string): string {
  const re = /<\/body\s*>/gi;
  let lastMatch: RegExpExecArray | null = null;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) lastMatch = m;
  if (!lastMatch) return html + RELOAD_SCRIPT;
  const idx = lastMatch.index;
  return html.slice(0, idx) + RELOAD_SCRIPT + html.slice(idx);
}

/**
 * Renders a free-interactive SurfaceSpec into the final HTML body that the
 * server writes to the response. This is a pure string transform — it does
 * not validate, does not sanitise, does not build a shell.
 */
export function renderFreeInteractive(spec: FreeInteractiveSpec): string {
  return injectReloadScript(spec.html);
}

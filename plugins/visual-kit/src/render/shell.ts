import { buildCsp, securityHeaders } from '../server/security.js';

export interface BundleRef {
  url: string;
  sri: string;
}

export interface ShellInput {
  title: string;
  nonce: string;
  csrfToken: string;
  bundles: BundleRef[];
  fragment: string;
  extraScriptSrc?: string[];
}

export function buildShell(input: ShellInput): { html: string; headers: Record<string, string> } {
  const preload = input.bundles
    .map(b => `<link rel="modulepreload" href="${b.url}" integrity="${b.sri}" crossorigin="anonymous">`)
    .join('\n    ');
  const scripts = input.bundles
    .map(b => `<script type="module" src="${b.url}" integrity="${b.sri}" crossorigin="anonymous" nonce="${escapeHtml(input.nonce)}"></script>`)
    .join('\n    ');

  const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="vk-csrf" content="${escapeHtml(input.csrfToken)}">
    <title>${escapeHtml(input.title)}</title>
    ${preload}
    <link rel="stylesheet" href="/vk/theme.css" nonce="${escapeHtml(input.nonce)}">
    ${scripts}
  </head>
  <body>
    <main class="vk-surface">
      ${input.fragment}
    </main>
    <script type="module" nonce="${escapeHtml(input.nonce)}">
      const es = new EventSource('/events/stream');
      es.onmessage = (e) => { if (e.data === 'refresh') location.reload(); };
      window.addEventListener('vk-event', async (ev) => {
        const csrf = document.querySelector('meta[name=vk-csrf]')?.getAttribute('content') ?? '';
        try {
          await fetch('/events', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-Vk-Csrf': csrf },
            body: JSON.stringify({ ...ev.detail, ts: new Date().toISOString() }),
            credentials: 'omit',
          });
        } catch {}
      });
    </script>
  </body>
</html>`;

  return {
    html,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Content-Security-Policy': buildCsp({ nonce: input.nonce, extraScriptSrc: input.extraScriptSrc ?? [] }),
      ...securityHeaders(),
    },
  };
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}

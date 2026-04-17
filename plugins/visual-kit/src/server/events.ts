/**
 * POST /events handler.
 *
 * Security invariants:
 * - The (plugin, surfaceId) identity is ALWAYS derived server-side from the
 *   Referer URL path, never from the request body. Any `plugin` or
 *   `surface` fields in the body are stripped before the event is logged.
 * - The X-Vk-Csrf token must be bound to the same (plugin, surfaceId) pair
 *   that we derived from the Referer; verifyCsrfToken's binding check makes
 *   cross-plugin token reuse impossible even if the attacker obtained a
 *   valid token for a different surface.
 * - Event logs are written under `.<plugin>/state/events` — the plugin
 *   directory is created only after CSRF passes, so a 403 request cannot
 *   cause filesystem writes outside the server-info slot.
 *
 * Wire format of the CSRF token (from T7's makeCsrfToken):
 *   `${base64url(payload)}.${base64url(mac)}`
 *   where payload = UTF-8 bytes of `${plugin}:${surfaceId}:${nonce}`.
 */
import { appendFile, mkdir, stat, rename } from 'node:fs/promises';
import { join } from 'node:path';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { isSafeSegment } from './paths.js';
import { verifyCsrfToken, securityHeaders } from './security.js';

// Per-path serialization queue: each path maps to a promise representing the
// tail of the current append chain. Chaining here prevents concurrent POSTs
// from interleaving JSON lines when the write body exceeds PIPE_BUF.
const appendQueue = new Map<string, Promise<void>>();

async function serializedAppend(path: string, line: string): Promise<void> {
  const prev = appendQueue.get(path) ?? Promise.resolve();
  const next = prev.then(() => rotateIfNeeded(path)).then(() => appendFile(path, line, 'utf8'));
  appendQueue.set(path, next.then(() => {}, () => {}));
  await next;
}

const MAX_BODY = 64 * 1024;            // 64 KB
const MAX_LOG = 50 * 1024 * 1024;      // 50 MB
const REFERER_PATH = /^\/p\/([^/]+)\/([^/]+)$/;

export interface EventCtx {
  projectDir: string;
  secret: Buffer;
}

export async function handleEventPost(
  req: IncomingMessage,
  res: ServerResponse,
  ctx: EventCtx,
): Promise<void> {
  if (req.method !== 'POST') {
    res.writeHead(405, { Allow: 'POST', ...securityHeaders() });
    res.end('Method Not Allowed');
    return;
  }

  const contentType = (req.headers['content-type'] ?? '').split(';')[0]?.trim();
  if (contentType !== 'application/json') {
    res.writeHead(415, securityHeaders());
    res.end('Unsupported Media Type');
    return;
  }

  // Derive plugin + surface from Referer path (server-side only — body field ignored).
  // Origin is intentionally excluded: it carries no path, so its pathname is always '/'
  // and can never match REFERER_PATH.
  const referer = req.headers.referer ?? '';
  let refPath = '';
  try { refPath = new URL(referer).pathname; } catch { /* empty */ }
  const m = refPath.match(REFERER_PATH);
  if (!m) {
    res.writeHead(403, securityHeaders());
    res.end('Forbidden');
    return;
  }
  const [, plugin, surfaceId] = m as unknown as [string, string, string];
  if (!isSafeSegment(plugin) || !isSafeSegment(surfaceId)) {
    res.writeHead(403, securityHeaders());
    res.end('Forbidden');
    return;
  }

  // CSRF: token format is `base64url(payload).base64url(mac)` from T7's makeCsrfToken.
  // Extract the nonce from the payload so we can pass the full binding to verifyCsrfToken.
  // All other validation (plugin/surfaceId equality, MAC correctness, malformed input) is
  // handled inside verifyCsrfToken — we don't duplicate those checks here.
  const token = (req.headers['x-vk-csrf'] ?? '') as string;
  const dot = token.indexOf('.');
  const payloadStr = dot >= 0
    ? (() => { try { return Buffer.from(token.slice(0, dot), 'base64url').toString('utf8'); } catch { return ''; } })()
    : '';
  const nonce = payloadStr.split(':')[2] ?? '';
  if (!verifyCsrfToken(ctx.secret, token, { plugin, surfaceId, nonce })) {
    res.writeHead(403, securityHeaders());
    res.end('Forbidden');
    return;
  }

  // Read body with cap.
  let body = '';
  let over = false;
  for await (const chunk of req) {
    body += chunk;
    if (body.length > MAX_BODY) { over = true; break; }
  }
  if (over) {
    res.writeHead(413, securityHeaders());
    res.end('Payload Too Large');
    return;
  }

  let parsed: unknown;
  try { parsed = JSON.parse(body); } catch {
    res.writeHead(400, securityHeaders());
    res.end('Bad Request');
    return;
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    res.writeHead(400, securityHeaders());
    res.end('Bad Request');
    return;
  }

  // Append JSON line — plugin is server-derived, never client-supplied.
  const stateDir = join(ctx.projectDir, `.${plugin}`, 'state');
  await mkdir(stateDir, { recursive: true });
  const eventsPath = join(stateDir, 'events');

  // Strip body-supplied "plugin" or "surface" if present — server fields take precedence.
  const safeBody = { ...(parsed as Record<string, unknown>) };
  delete safeBody.plugin;
  delete safeBody.surface;
  const line = JSON.stringify({
    ...safeBody,
    plugin,
    surface: surfaceId,
    ts: new Date().toISOString(),
  }) + '\n';
  await serializedAppend(eventsPath, line);

  res.writeHead(204, securityHeaders());
  res.end();
}

async function rotateIfNeeded(path: string): Promise<void> {
  try {
    const s = await stat(path);
    if (s.size > MAX_LOG) {
      await rename(path, path + '.' + Date.now());
    }
  } catch { /* no file yet */ }
}

import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomBytes } from 'node:crypto';
import type { ServeOptions } from '../cli/serve.js';
import { acquireServerSlot, releaseServerSlot, type SlotResult } from './lifecycle.js';
import { loadSchemas, validateSpec } from '../render/validate.js';
import { registerAllSurfaces } from '../surfaces/index.js';
import { buildCapabilities } from './capabilities.js';
import { isHostAllowed, securityHeaders, makeNonce, makeCsrfToken } from './security.js';
import { ContentWatcher } from './watcher.js';
import { SseHub } from './sse.js';
import { isSafeSegment, resolveContained } from './paths.js';
import { renderSurface } from '../render/dispatcher.js';
import { renderFragment } from '../render/ssr.js';
import { buildShell } from '../render/shell.js';
import { serveVkPath } from './bundles.js';

const here = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(here, '../../package.json');

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;
let activeSecret: Buffer | undefined;
let activeSse: SseHub | undefined;
let activeWatcher: ContentWatcher | undefined;

export async function startServer(opts: ServeOptions): Promise<void> {
  const pkg = JSON.parse(await readFile(pkgPath, 'utf8')) as { version: string };
  await loadSchemas();
  registerAllSurfaces();

  const slot = await acquireServerSlot(opts.projectDir, {
    pid: process.pid,
    version: pkg.version,
    host: opts.host,
    urlHost: opts.urlHost,
  });
  if (slot.action === 'attach') {
    process.stdout.write(JSON.stringify(slot.info) + '\n');
    return;
  }

  activeProjectDir = opts.projectDir;
  activeSlot = slot;
  activeSecret = randomBytes(32);
  activeSse = new SseHub();
  activeWatcher = new ContentWatcher(opts.projectDir);
  activeWatcher.onChange(ev => activeSse?.publish(ev));

  const hostPolicy = { port: slot.port, urlHost: opts.urlHost };
  const ctx: RequestCtx = {
    projectDir: opts.projectDir,
    secret: activeSecret,
    sse: activeSse,
    watcher: activeWatcher,
  };

  activeServer = createServer((req, res) => {
    if (!isHostAllowed(req.headers.host, hostPolicy)) {
      res.writeHead(421, { 'Content-Type': 'text/plain' });
      res.end('Misdirected Request');
      return;
    }
    handleRequest(req, res, pkg.version, ctx).catch(() => {
      try {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      } catch {
        /* response may have already been flushed / headers sent */
      }
    });
  });

  try {
    await listen(activeServer, slot.port, opts.host);
  } catch (err) {
    const code = (err as NodeJS.ErrnoException).code;
    activeServer = undefined;
    activeSse?.closeAll();
    activeWatcher?.close();
    activeSse = undefined;
    activeWatcher = undefined;
    activeSecret = undefined;
    await releaseServerSlot(opts.projectDir, slot);
    activeSlot = undefined;
    activeProjectDir = undefined;
    if (code === 'EADDRINUSE') {
      throw new Error(
        `port ${slot.port} became unavailable between probe and bind. Retry the command.`,
      );
    }
    throw err;
  }

  process.stdout.write(JSON.stringify(slot.info) + '\n');

  for (const sig of ['SIGTERM', 'SIGINT'] as const) {
    process.once(sig, () => void stopServer().then(() => process.exit(0)));
  }
}

export async function stopServer(): Promise<void> {
  if (activeSse) {
    activeSse.closeAll();
    activeSse = undefined;
  }
  if (activeWatcher) {
    activeWatcher.close();
    activeWatcher = undefined;
  }
  if (activeServer) {
    await new Promise<void>(resolve => activeServer?.close(() => resolve()));
    activeServer = undefined;
  }
  if (activeSlot && activeProjectDir) {
    await releaseServerSlot(activeProjectDir, activeSlot);
    activeSlot = undefined;
    activeProjectDir = undefined;
  }
  activeSecret = undefined;
}

interface RequestCtx {
  projectDir: string;
  secret: Buffer;
  sse: SseHub;
  watcher: ContentWatcher;
}

async function handleRequest(
  req: IncomingMessage,
  res: ServerResponse,
  version: string,
  ctx: RequestCtx,
): Promise<void> {
  const url = new URL(req.url ?? '/', 'http://x');
  const method = req.method ?? 'GET';

  if (method === 'GET' && url.pathname === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', ...securityHeaders() });
    res.end(JSON.stringify(buildCapabilities(version)));
    return;
  }

  if (method === 'GET' && url.pathname === '/events/stream') {
    const plugin = url.searchParams.get('plugin') ?? undefined;
    const surfaceId = url.searchParams.get('surface') ?? undefined;
    if (plugin && !isSafeSegment(plugin)) return badRequest(res);
    if (surfaceId && !isSafeSegment(surfaceId)) return badRequest(res);
    ctx.sse.attach(res, { plugin, surfaceId });
    return;
  }

  const m = url.pathname.match(/^\/p\/([^/]+)\/([^/]+)$/);
  if (method === 'GET' && m) {
    const [, plugin, surfaceId] = m as unknown as [string, string, string];
    if (!isSafeSegment(plugin) || !isSafeSegment(surfaceId)) return badRequest(res);
    await ctx.watcher.watchPlugin(plugin);
    const contentDir = join(ctx.projectDir, `.${plugin}`, 'content');
    let specPath: string;
    try {
      specPath = await resolveContained(contentDir, `${surfaceId}.json`);
    } catch {
      res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
      res.end('Not Found');
      return;
    }
    const raw = await readFile(specPath, 'utf8');
    let spec: unknown;
    try {
      spec = JSON.parse(raw);
    } catch {
      return renderErrorPage(res, 'Invalid JSON in SurfaceSpec', { plugin, surfaceId });
    }
    const result = validateSpec(spec);
    const nonce = makeNonce();
    const csrf = makeCsrfToken(ctx.secret, { plugin, surfaceId, nonce });
    if (!result.ok) {
      // Even on schema failure, render an error page (200) with vk-error fragment.
      return renderErrorPage(res, `Schema: ${result.errors.join('; ')}`, { plugin, surfaceId }, nonce, csrf);
    }
    const fragment = renderFragment(renderSurface(spec as never));
    const { html, headers } = buildShell({
      title: `${plugin}/${surfaceId}`,
      nonce,
      csrfToken: csrf,
      bundleUrls: ['/vk/core.js'],
      fragment,
    });
    res.writeHead(200, headers);
    res.end(html);
    return;
  }

  if (method === 'GET' && url.pathname.startsWith('/vk/')) {
    const reply = await serveVkPath(url.pathname);
    if (reply) {
      res.writeHead(reply.status, { ...reply.headers, ...securityHeaders() });
      res.end(reply.body);
      return;
    }
    res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
    res.end('Not Found');
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Not Found');
}

function badRequest(res: ServerResponse): void {
  res.writeHead(400, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Bad Request');
}

function renderErrorPage(
  res: ServerResponse,
  detail: string,
  ctx: { plugin: string; surfaceId: string },
  nonce: string = makeNonce(),
  csrf: string = '',
): void {
  const fragment = `<vk-error><h2 slot="title">Render error</h2><p slot="detail">${escapeHtml(detail)}</p></vk-error>`;
  const { html, headers } = buildShell({
    title: `${ctx.plugin}/${ctx.surfaceId}`,
    nonce,
    csrfToken: csrf,
    bundleUrls: ['/vk/core.js'],
    fragment,
  });
  res.writeHead(200, headers);
  res.end(html);
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}

function listen(server: Server, port: number, host: string): Promise<void> {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () => {
      server.off('error', reject);
      resolve();
    });
  });
}

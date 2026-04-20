import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
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
import { buildShell, type BundleRef } from '../render/shell.js';
import { renderFreeInteractive, type FreeInteractiveSpec } from '../surfaces/free-interactive.js';
import { discoverRequiredBundles, resolveBundleRefs } from '../render/autoload.js';
import { serveVkPath } from './bundles.js';

// Injected at build time by scripts/build.mjs via esbuild define.
// Falls back to a dev sentinel when running from source via ts-node / vitest.
declare const __VK_VERSION__: string;
const VK_VERSION: string =
  typeof __VK_VERSION__ !== 'undefined' ? __VK_VERSION__ : '0.0.0-dev';

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;
let activeSecret: Buffer | undefined;
let activeSse: SseHub | undefined;
let activeWatcher: ContentWatcher | undefined;

export async function startServer(opts: ServeOptions): Promise<void> {
  await loadSchemas();
  registerAllSurfaces();

  const slot = await acquireServerSlot(opts.projectDir, {
    pid: process.pid,
    version: VK_VERSION,
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
    handleRequest(req, res, VK_VERSION, ctx).catch((err) => {
      process.stderr.write(`[visual-kit] handleRequest error: ${err instanceof Error ? err.stack : String(err)}\n`);
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
    res.end(JSON.stringify(await buildCapabilities(version)));
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

  if (method === 'POST' && url.pathname === '/events') {
    const { handleEventPost } = await import('./events.js');
    await handleEventPost(req, res, { projectDir: ctx.projectDir, secret: ctx.secret });
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
      const fallbackBundle = await resolveCoreBundle(version);
      return renderErrorPage(res, 'Invalid JSON in SurfaceSpec', { plugin, surfaceId }, undefined, undefined, [fallbackBundle]);
    }
    const result = validateSpec(spec);
    // Pre-compute nonce + CSRF here because the schema-error path below needs
    // them to render the strict-CSP vk-error page. The free-interactive branch
    // ignores them — don't move this below that branch without handling both.
    const nonce = makeNonce();
    const csrf = makeCsrfToken(ctx.secret, { plugin, surfaceId, nonce });
    if (!result.ok) {
      // Schema failure: render vk-error page with only core preloaded.
      const core = await resolveCoreBundle(version);
      return renderErrorPage(res, `Schema: ${result.errors.join('; ')}`, { plugin, surfaceId }, nonce, csrf, [core]);
    }
    if (result.kind === 'free-interactive') {
      // Opt-in permissive surface: serve AI-authored HTML as-is. No CSP, no
      // CSRF binding, no shell. Host-allowlist + securityHeaders() still apply.
      // See: docs/superpowers/specs/2026-04-19-visual-kit-free-interactive-surface.md
      const body = renderFreeInteractive(spec as FreeInteractiveSpec);
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        ...securityHeaders(),
      });
      res.end(body);
      return;
    }
    const fragment = renderFragment(renderSurface(spec as never));
    const caps = await buildCapabilities(version) as { bundles: Array<{ name: string; url: string; sri: string }> };
    const needed = discoverRequiredBundles(fragment);
    const bundles = resolveBundleRefs(needed, caps);
    const { html, headers } = buildShell({
      title: `${plugin}/${surfaceId}`,
      nonce,
      csrfToken: csrf,
      bundles,
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

async function resolveCoreBundle(version: string): Promise<BundleRef> {
  const caps = await buildCapabilities(version) as { bundles: Array<{ url: string; sri: string }> };
  return caps.bundles.find(b => b.url === '/vk/core.js') ?? { url: '/vk/core.js', sri: 'sha384-dev' };
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
  bundles: BundleRef[] = [{ url: '/vk/core.js', sri: 'sha384-dev' }],
): void {
  const fragment = `<vk-error><h2 slot="title">Render error</h2><p slot="detail">${escapeHtml(detail)}</p></vk-error>`;
  const { html, headers } = buildShell({
    title: `${ctx.plugin}/${ctx.surfaceId}`,
    nonce,
    csrfToken: csrf,
    bundles,
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

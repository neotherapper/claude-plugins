import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { ServeOptions } from '../cli/serve.js';
import { acquireServerSlot, releaseServerSlot, type SlotResult } from './lifecycle.js';
import { loadSchemas } from '../render/validate.js';
import { registerAllSurfaces } from '../surfaces/index.js';
import { buildCapabilities } from './capabilities.js';
import { isHostAllowed, securityHeaders } from './security.js';

const here = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(here, '../../package.json');

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;

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

  const hostPolicy = { port: slot.port, urlHost: opts.urlHost };

  activeServer = createServer((req, res) => {
    if (!isHostAllowed(req.headers.host, hostPolicy)) {
      res.writeHead(421, { 'Content-Type': 'text/plain' });
      res.end('Misdirected Request');
      return;
    }
    handleRequest(req, res, pkg.version).catch(() => {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
    });
  });

  try {
    await listen(activeServer, slot.port, opts.host);
  } catch (err) {
    const code = (err as NodeJS.ErrnoException).code;
    activeServer = undefined;
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
  if (activeServer) {
    await new Promise<void>(resolve => activeServer?.close(() => resolve()));
    activeServer = undefined;
  }
  if (activeSlot && activeProjectDir) {
    await releaseServerSlot(activeProjectDir, activeSlot);
    activeSlot = undefined;
    activeProjectDir = undefined;
  }
}

async function handleRequest(
  req: IncomingMessage,
  res: ServerResponse,
  version: string,
): Promise<void> {
  if (req.method === 'GET' && req.url === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', ...securityHeaders() });
    res.end(JSON.stringify(buildCapabilities(version)));
    return;
  }
  res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Not Found');
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

import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { ServeOptions } from '../cli/serve.js';
import { acquireServerSlot, releaseServerSlot, type SlotResult } from './lifecycle.js';

const here = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(here, '../../package.json');

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;

export async function startServer(opts: ServeOptions): Promise<void> {
  const pkg = JSON.parse(await readFile(pkgPath, 'utf8')) as { version: string };
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

  activeServer = createServer((req, res) => handleRequest(req, res, slot.info));

  try {
    await listen(activeServer, slot.port, opts.host);
  } catch (err) {
    // Port grabbed between probe and listen — release the slot and surface the error.
    const code = (err as NodeJS.ErrnoException).code;
    activeServer = undefined;
    await releaseServerSlot(opts.projectDir, slot);
    activeSlot = undefined;
    activeProjectDir = undefined;
    if (code === 'EADDRINUSE') {
      throw new Error(
        `port ${slot.port} became unavailable between probe and bind. ` +
        `Another process grabbed it. Retry the command.`,
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
  info: import('../shared/types.js').ServerInfo,
): Promise<void> {
  if (req.url === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        visual_kit_version: info.visual_kit_version,
        schema_version: 1,
        surfaces: {},
        components: [],
        bundles: [],
      }),
    );
    return;
  }
  res.writeHead(404);
  res.end('not found');
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

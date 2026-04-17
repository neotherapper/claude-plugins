import { mkdir, rm, open, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { createServer as netCreateServer } from 'node:net';
import { workspacePort } from '../shared/hash.js';
import { writeJsonAtomic, readJson } from '../shared/json.js';
import type { ServerInfo } from '../shared/types.js';
import type { FileHandle } from 'node:fs/promises';

export type SlotResult =
  | { action: 'acquired'; port: number; info: ServerInfo; lockHandle: FileHandle }
  | { action: 'attach'; info: ServerInfo };

export interface AcquireOpts {
  pid: number;
  version: string;
  host?: string;
  urlHost?: string;
}

const MAX_PORT_ATTEMPTS = 10;
const LOCK_RECLAIM_ATTEMPTS = 3;

export async function acquireServerSlot(
  projectDir: string,
  opts: AcquireOpts,
): Promise<SlotResult> {
  const stateDir = join(projectDir, '.visual-kit/server/state');
  await mkdir(stateDir, { recursive: true });
  const infoPath = join(stateDir, 'server-info');
  const lockPath = join(stateDir, 'server.lock');

  // First check (unlocked, fast-path attach for the common case).
  const existing = await tryReadInfo(infoPath);
  if (existing && isAlive(existing.pid)) {
    return { action: 'attach', info: existing };
  }

  // Acquire exclusive lock with bounded reclaim attempts.
  // The lock is what serializes concurrent acquirers; everything below
  // happens under the lock so we can re-check state atomically.
  const lockHandle = await acquireLock(lockPath);

  try {
    // Re-check server-info under the lock. Another process may have
    // started a live server between our initial read and our lock.
    const recheck = await tryReadInfo(infoPath);
    if (recheck && isAlive(recheck.pid)) {
      // Release the lock and tell caller to attach.
      await safeClose(lockHandle);
      await rm(lockPath, { force: true });
      return { action: 'attach', info: recheck };
    }
    if (recheck) {
      // Stale info; remove before writing fresh.
      await rm(infoPath, { force: true });
    }

    // Find a free port.
    const baseHost = opts.host ?? '127.0.0.1';
    const base = workspacePort(projectDir);
    let port = -1;
    for (let i = 0; i < MAX_PORT_ATTEMPTS; i++) {
      if (await isPortFree(baseHost, base + i)) {
        port = base + i;
        break;
      }
    }
    if (port < 0) {
      throw new Error(
        `no free port in [${base}, ${base + MAX_PORT_ATTEMPTS}) on ${baseHost}`,
      );
    }

    const info: ServerInfo = {
      status: 'running',
      pid: opts.pid,
      port,
      host: baseHost,
      url: `http://${opts.urlHost ?? 'localhost'}:${port}`,
      started_at: new Date().toISOString(),
      project_dir: projectDir,
      visual_kit_version: opts.version,
    };
    await writeJsonAtomic(infoPath, info);

    return { action: 'acquired', port, info, lockHandle };
  } catch (err) {
    // Any failure between acquiring the lock and successfully writing
    // server-info must release the lock so we don't leak it.
    await safeClose(lockHandle);
    await rm(lockPath, { force: true });
    throw err;
  }
}

export async function releaseServerSlot(
  projectDir: string,
  slot: SlotResult,
): Promise<void> {
  if (slot.action !== 'acquired') return;
  const stateDir = join(projectDir, '.visual-kit/server/state');
  await safeClose(slot.lockHandle);
  await rm(join(stateDir, 'server.lock'), { force: true });
  await rm(join(stateDir, 'server-info'), { force: true });
  await writeFile(join(stateDir, 'server-stopped'), new Date().toISOString());
}

async function tryReadInfo(infoPath: string): Promise<ServerInfo | null> {
  try {
    return await readJson<ServerInfo>(infoPath);
  } catch {
    return null;
  }
}

async function acquireLock(lockPath: string): Promise<FileHandle> {
  let lastErr: unknown;
  for (let attempt = 0; attempt < LOCK_RECLAIM_ATTEMPTS; attempt++) {
    try {
      const handle = await open(lockPath, 'wx');
      // Write our PID so future acquirers can check if we're alive.
      await handle.writeFile(String(process.pid), 'utf8');
      return handle;
    } catch (err) {
      lastErr = err;
      const code = (err as NodeJS.ErrnoException).code;
      if (code !== 'EEXIST') throw err;

      // Lock exists — read the PID to decide whether to reclaim.
      let ownerPid: number | null = null;
      try {
        const { readFile } = await import('node:fs/promises');
        const raw = (await readFile(lockPath, 'utf8')).trim();
        const parsed = Number(raw);
        if (raw.length > 0 && Number.isInteger(parsed) && parsed > 0) {
          ownerPid = parsed;
        }
      } catch {
        // Unreadable or already gone — treat as unknown owner, retry.
      }

      if (ownerPid !== null && isAlive(ownerPid)) {
        throw new Error(`lock held by live process ${ownerPid}`);
      }

      // Owner is dead, PID missing, or file is empty/unreadable — reclaim.
      await rm(lockPath, { force: true });
    }
  }
  throw new Error(
    `failed to acquire ${lockPath} after ${LOCK_RECLAIM_ATTEMPTS} attempts: ${String(lastErr)}`,
  );
}

async function safeClose(handle: FileHandle): Promise<void> {
  try {
    await handle.close();
  } catch {
    /* already closed or fd invalid */
  }
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function isPortFree(host: string, port: number): Promise<boolean> {
  return new Promise(resolve => {
    const probe = netCreateServer();
    probe.once('error', () => {
      probe.close();
      resolve(false);
    });
    probe.listen(port, host, () => {
      probe.close(() => resolve(true));
    });
  });
}

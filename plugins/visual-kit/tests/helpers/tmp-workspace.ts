import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

export interface TmpWorkspace {
  dir: string;
  cleanup: () => Promise<void>;
}

export async function tmpWorkspace(): Promise<TmpWorkspace> {
  const dir = await mkdtemp(join(tmpdir(), 'vk-ws-'));
  return {
    dir,
    cleanup: () => rm(dir, { recursive: true, force: true }),
  };
}

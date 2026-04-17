import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { readFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { writeJsonAtomic } from '../../src/shared/json.js';

describe('writeJsonAtomic', () => {
  let dir: string;

  beforeEach(async () => {
    dir = await mkdtemp(join(tmpdir(), 'vk-json-'));
  });

  afterEach(async () => {
    await rm(dir, { recursive: true, force: true });
  });

  it('writes the JSON payload at the target path', async () => {
    const target = join(dir, 'info.json');
    await writeJsonAtomic(target, { hello: 'world' });
    const raw = await readFile(target, 'utf8');
    expect(JSON.parse(raw)).toEqual({ hello: 'world' });
  });

  it('does not leave a .tmp file behind on success', async () => {
    const target = join(dir, 'a.json');
    await writeJsonAtomic(target, { a: 1 });
    const tmp = target + '.tmp';
    await expect(readFile(tmp)).rejects.toMatchObject({ code: 'ENOENT' });
  });
});

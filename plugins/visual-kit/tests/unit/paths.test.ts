import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, rm, writeFile, symlink, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { isSafeSegment, resolveContained } from '../../src/server/paths.js';

describe('isSafeSegment', () => {
  it('accepts alphanumerics, dash, underscore', () => {
    expect(isSafeSegment('abc')).toBe(true);
    expect(isSafeSegment('lesson-2')).toBe(true);
    expect(isSafeSegment('wave_1')).toBe(true);
  });
  it('rejects dots, slashes, url-encoding', () => {
    expect(isSafeSegment('../etc')).toBe(false);
    expect(isSafeSegment('a.b')).toBe(false);
    expect(isSafeSegment('%2e%2e')).toBe(false);
    expect(isSafeSegment('')).toBe(false);
    expect(isSafeSegment('a b')).toBe(false);
  });
});

describe('resolveContained', () => {
  let root: string;

  beforeEach(async () => {
    root = await mkdtemp(join(tmpdir(), 'vk-paths-'));
  });

  afterEach(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('resolves a real file inside the root', async () => {
    await writeFile(join(root, 'ok.json'), '{}');
    const p = await resolveContained(root, 'ok.json');
    expect(p).toBe(join(root, 'ok.json'));
  });

  it('rejects when path escapes root', async () => {
    await expect(resolveContained(root, '../outside')).rejects.toThrow(/outside/);
  });

  it('rejects symlinks that point outside root', async () => {
    const outside = await mkdtemp(join(tmpdir(), 'vk-outside-'));
    await writeFile(join(outside, 'secret'), 'SECRET');
    await symlink(join(outside, 'secret'), join(root, 'link.json'));
    await expect(resolveContained(root, 'link.json')).rejects.toThrow(/symlink/i);
    await rm(outside, { recursive: true, force: true });
  });

  it('rejects non-existent path with ENOENT', async () => {
    await expect(resolveContained(root, 'missing.json')).rejects.toMatchObject({ code: 'ENOENT' });
  });

  it('rejects symlinked directories', async () => {
    const outside = await mkdtemp(join(tmpdir(), 'vk-outside-'));
    await mkdir(join(outside, 'ct'), { recursive: true });
    await symlink(join(outside, 'ct'), join(root, 'content'));
    await expect(resolveContained(root, 'content')).rejects.toThrow(/symlink/i);
    await rm(outside, { recursive: true, force: true });
  });
});

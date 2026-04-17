import { rename, writeFile, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';

export async function writeJsonAtomic(path: string, data: unknown): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  const tmp = path + '.tmp';
  await writeFile(tmp, JSON.stringify(data, null, 2), 'utf8');
  await rename(tmp, path);
}

export async function readJson<T>(path: string): Promise<T> {
  const { readFile } = await import('node:fs/promises');
  return JSON.parse(await readFile(path, 'utf8')) as T;
}

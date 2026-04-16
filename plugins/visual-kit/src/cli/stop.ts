import { readFile, rm } from 'node:fs/promises';
import { resolve, join } from 'node:path';

export async function runStop(argv: string[]): Promise<void> {
  const projectDir = parseProjectDir(argv);
  const infoPath = join(projectDir, '.visual-kit/server/state/server-info');
  let info: { pid: number; port: number } | undefined;
  try {
    info = JSON.parse(await readFile(infoPath, 'utf8'));
  } catch {
    process.stdout.write(JSON.stringify({ status: 'not-running', projectDir }) + '\n');
    return;
  }
  if (info?.pid) {
    try {
      process.kill(info.pid, 'SIGTERM');
    } catch (err: unknown) {
      const code = (err as NodeJS.ErrnoException).code;
      if (code !== 'ESRCH') throw err;
    }
  }
  await rm(infoPath, { force: true });
  process.stdout.write(JSON.stringify({ status: 'stopped', projectDir }) + '\n');
}

function parseProjectDir(argv: string[]): string {
  const idx = argv.indexOf('--project-dir');
  if (idx < 0 || !argv[idx + 1]) throw new Error('--project-dir is required');
  return resolve(argv[idx + 1]!);
}

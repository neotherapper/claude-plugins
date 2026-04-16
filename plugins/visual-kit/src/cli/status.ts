import { readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';

export async function runStatus(argv: string[]): Promise<void> {
  const projectDir = parseProjectDir(argv);
  const infoPath = join(projectDir, '.visual-kit/server/state/server-info');
  let info: Record<string, unknown> | undefined;
  try {
    info = JSON.parse(await readFile(infoPath, 'utf8'));
  } catch {
    process.stdout.write(JSON.stringify({ status: 'not-running', projectDir }) + '\n');
    return;
  }
  if (info?.pid && !isAlive(info.pid as number)) {
    process.stdout.write(JSON.stringify({ status: 'stale', projectDir, recorded: info }) + '\n');
    return;
  }
  process.stdout.write(JSON.stringify(info) + '\n');
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function parseProjectDir(argv: string[]): string {
  const idx = argv.indexOf('--project-dir');
  if (idx < 0 || !argv[idx + 1]) throw new Error('--project-dir is required');
  return resolve(argv[idx + 1]!);
}

import { resolve } from 'node:path';

export interface ServeOptions {
  projectDir: string;
  host: string;
  urlHost: string;
  foreground: boolean;
}

export async function runServe(argv: string[]): Promise<void> {
  const opts = parseServe(argv);
  const { startServer } = await import('../server/index.js');
  await startServer(opts);
}

export function parseServe(argv: string[]): ServeOptions {
  let projectDir: string | undefined;
  let host = '127.0.0.1';
  let urlHost: string | undefined;
  let foreground = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--project-dir': projectDir = argv[++i]; break;
      case '--host':        host       = argv[++i] ?? host; break;
      case '--url-host':    urlHost    = argv[++i]; break;
      case '--foreground':  foreground = true; break;
      default:
        throw new Error(`unknown argument: ${arg}`);
    }
  }

  if (!projectDir) throw new Error('--project-dir is required');

  if (host !== '127.0.0.1' && host !== 'localhost') {
    process.stderr.write(
      `WARNING: binding to ${host} exposes visual-kit to the network. ` +
      `Only use in trusted remote-dev environments.\n`
    );
  }

  return {
    projectDir: resolve(projectDir),
    host,
    urlHost: urlHost ?? (host === '127.0.0.1' || host === 'localhost' ? 'localhost' : host),
    foreground,
  };
}

import { runServe } from './serve.js';
import { runStop } from './stop.js';
import { runStatus } from './status.js';

const [command, ...rest] = process.argv.slice(2);

switch (command) {
  case 'serve':
    await runServe(rest);
    break;
  case 'stop':
    await runStop(rest);
    break;
  case 'status':
    await runStatus(rest);
    break;
  case '--help':
  case '-h':
  case undefined:
    printUsage(0);
    break;
  default:
    process.stderr.write(`unknown command: ${command}\n`);
    printUsage(2);
}

function printUsage(code: number): never {
  process.stdout.write(`visual-kit — per-workspace local visual renderer

Usage:
  visual-kit serve --project-dir <path> [--host <addr>] [--url-host <name>] [--foreground]
  visual-kit stop  --project-dir <path>
  visual-kit status --project-dir <path>
`);
  process.exit(code);
}

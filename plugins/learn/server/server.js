#!/usr/bin/env node
// learn visual server — file-watcher HTTP server
// Watches screen_dir for new HTML files, serves the newest one.
// Usage: node server.js --screen-dir <path> --state-dir <path> [--port <n>] [--host <h>]

import http from 'http';
import fs from 'fs';
import path from 'path';
import { parseArgs } from 'util';

const { values: args } = parseArgs({
  options: {
    'screen-dir': { type: 'string' },
    'state-dir':  { type: 'string' },
    port:         { type: 'string', default: '7337' },
    host:         { type: 'string', default: '127.0.0.1' },
  },
});

const SCREEN_DIR = args['screen-dir'];
const STATE_DIR  = args['state-dir'];
const HOST       = args['host'];
const INACTIVITY_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes

if (!SCREEN_DIR || !STATE_DIR) {
  console.error('Usage: node server.js --screen-dir <path> --state-dir <path>');
  process.exit(1);
}

fs.mkdirSync(SCREEN_DIR, { recursive: true });
fs.mkdirSync(STATE_DIR,  { recursive: true });

function newestFile() {
  try {
    const files = fs.readdirSync(SCREEN_DIR)
      .filter(f => f.endsWith('.html'))
      .map(f => ({ name: f, mtime: fs.statSync(path.join(SCREEN_DIR, f)).mtimeMs }))
      .sort((a, b) => b.mtime - a.mtime);
    return files[0] ? path.join(SCREEN_DIR, files[0].name) : null;
  } catch { return null; }
}

let inactivityTimer;
function resetInactivity() {
  clearTimeout(inactivityTimer);
  inactivityTimer = setTimeout(() => {
    fs.rmSync(path.join(STATE_DIR, 'server-info'), { force: true });
    fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), 'inactivity');
    process.exit(0);
  }, INACTIVITY_TIMEOUT_MS);
}

function startServer(port, attempts = 0) {
  if (attempts > 10) {
    console.error('No available port found in range', port - attempts, '–', port);
    process.exit(1);
  }
  const server = http.createServer((req, res) => {
    resetInactivity();

    // CORS for local use
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Quiz interaction events
    if (req.method === 'POST' && req.url === '/events') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try { fs.appendFileSync(path.join(STATE_DIR, 'events'), body + '\n'); } catch {}
        res.writeHead(204); res.end();
      });
      return;
    }

    // SSE auto-refresh
    if (req.url === '/events/stream') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      });
      let watcher;
      try {
        watcher = fs.watch(SCREEN_DIR, () => res.write('data: refresh\n\n'));
      } catch { res.end(); return; }
      req.on('close', () => watcher.close());
      return;
    }

    // Serve newest lesson HTML
    const file = newestFile();
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    if (!file) {
      res.end('<html><body style="font-family:sans-serif;padding:2rem;color:#888"><p>Waiting for a lesson…<br>Run <code>/learn [topic]</code> in Claude Code.</p></body></html>');
      return;
    }
    try { res.end(fs.readFileSync(file)); }
    catch { res.end('<html><body>Error reading lesson file.</body></html>'); }
  });

  server.on('error', err => {
    if (err.code === 'EADDRINUSE') { startServer(port + 1, attempts + 1); }
    else { console.error(err); process.exit(1); }
  });

  server.listen(port, HOST, () => {
    const actualPort = server.address().port;
    const info = JSON.stringify({
      port: actualPort,
      screenDir: SCREEN_DIR,
      stateDir:  STATE_DIR,
    });
    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info);
    console.log(info);
    resetInactivity();
  });
}

startServer(parseInt(args.port, 10));

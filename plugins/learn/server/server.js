#!/usr/bin/env node
// learn visual server — file-watcher HTTP server
// Skills write Lesson JSON files to screen_dir; server injects them into the
// lesson.html template and serves the combined page. Same pattern as the
// superpowers visual companion (skills produce data, server owns rendering).
//
// Usage: node server.js --screen-dir <path> --state-dir <path> [--port <n>] [--host <h>]

import http from 'http';
import fs from 'fs';
import path from 'path';
import { parseArgs } from 'util';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE_PATH = path.join(__dirname, 'templates', 'lesson.html');
// Placeholder that the skill leaves in the template; server replaces it with lesson JSON.
const DATA_PLACEHOLDER = '<script id="lesson-data" type="application/json">null</script>';

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

// Returns path to the most-recently-modified .json lesson file, or null.
function newestLesson() {
  try {
    const files = fs.readdirSync(SCREEN_DIR)
      .filter(f => f.endsWith('.json'))
      .map(f => ({ name: f, mtime: fs.statSync(path.join(SCREEN_DIR, f)).mtimeMs }))
      .sort((a, b) => b.mtime - a.mtime);
    return files[0] ? path.join(SCREEN_DIR, files[0].name) : null;
  } catch { return null; }
}

// Builds the full HTML page by injecting lesson JSON into the template.
// Returns the HTML string, or a fallback waiting page if no lesson exists yet.
function buildPage() {
  const lessonFile = newestLesson();
  const template = fs.readFileSync(TEMPLATE_PATH, 'utf-8');

  if (!lessonFile) return template; // template shows its own "Waiting…" state

  const lessonJson = fs.readFileSync(lessonFile, 'utf-8');

  // Guard against </script> sequences inside string values breaking the tag.
  const safeJson = lessonJson.replace(/<\/script>/gi, '<\\/script>');
  return template.replace(
    DATA_PLACEHOLDER,
    `<script id="lesson-data" type="application/json">${safeJson}</script>`,
  );
}

let inactivityTimer;
function resetInactivity() {
  clearTimeout(inactivityTimer);
  inactivityTimer = setTimeout(() => {
    fs.rmSync(path.join(STATE_DIR, 'server-info'), { force: true });
    fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), 'inactivity');
    console.log(JSON.stringify({ type: 'server-stopped', reason: 'inactivity' }));
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

    // Quiz interaction events — POST body appended to state_dir/events (JSON lines).
    if (req.method === 'POST' && req.url === '/events') {
      res.setHeader('Access-Control-Allow-Origin', '*');
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try { fs.appendFileSync(path.join(STATE_DIR, 'events'), body + '\n'); } catch {}
        res.writeHead(204); res.end();
      });
      return;
    }

    // SSE stream — browser subscribes; server sends 'refresh' on new lesson file.
    if (req.url === '/events/stream') {
      res.writeHead(200, {
        'Content-Type':  'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection':    'keep-alive',
      });
      let watcher;
      try {
        watcher = fs.watch(SCREEN_DIR, (_, filename) => {
          if (filename && filename.endsWith('.json')) {
            res.write('data: refresh\n\n');
          }
        });
      } catch { res.end(); return; }
      req.on('close', () => watcher.close());
      return;
    }

    // Serve lesson page — template + injected lesson JSON.
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    try {
      res.end(buildPage());
    } catch {
      res.end('<html><body style="font-family:sans-serif;padding:2rem">Error building lesson page.</body></html>');
    }
  });

  server.on('error', err => {
    if (err.code === 'EADDRINUSE') { startServer(port + 1, attempts + 1); }
    else { console.error(err); process.exit(1); }
  });

  server.listen(port, HOST, () => {
    const actualPort = server.address().port;
    const info = JSON.stringify({
      status:    'running',
      port:      actualPort,
      screenDir: SCREEN_DIR,
      stateDir:  STATE_DIR,
    });
    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info);
    console.log(info);
    resetInactivity();
  });
}

startServer(parseInt(args.port, 10));

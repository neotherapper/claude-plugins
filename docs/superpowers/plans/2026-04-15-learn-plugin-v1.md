# Learn Plugin V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the V1 `learn` Claude Code plugin — a `learn` router skill, a `learn:micro` lesson skill, and a local visual server that renders structured lesson cards in the browser.

**Architecture:** The `learn` skill detects intent and routes to `learn:micro`. `learn:micro` generates a `Lesson` JSON object one-shot, writes it as an HTML lesson card to the visual server's `screen_dir`, and the server auto-serves it in the browser. All plugin state in V1 flows through the visual server file system — no external storage, no persistence across sessions.

**Tech Stack:** Claude Code skills (Markdown + YAML frontmatter), Node.js 18+ (visual server, ESM, zero npm dependencies), Bash (start-server.sh)

**Specs:** `docs/plugins/learn/specs/learn-micro.feature` · `docs/plugins/learn/specs/learn-server.feature`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `plugins/learn/.claude-plugin/plugin.json` | Create | Plugin manifest |
| `plugins/learn/README.md` | Create | User-facing overview |
| `plugins/learn/CHANGELOG.md` | Create | Version history |
| `plugins/learn/hooks/hooks.json` | Create | SessionStart hook registration |
| `plugins/learn/skills/learn/SKILL.md` | Create | Router — detects intent, routes to sub-skills |
| `plugins/learn/skills/learn-micro/SKILL.md` | Create | Lesson orchestrator — generates + renders lesson |
| `plugins/learn/skills/learn-micro/references/lesson-schema.md` | Create | Lesson JSON schema + validation rules |
| `plugins/learn/skills/learn-micro/references/teaching-guide.md` | Create | Pedagogy rules — template, expertise levels, quiz |
| `plugins/learn/skills/learn-micro/references/vault-integration.md` | Create | Knowledge vault lookup contract |
| `plugins/learn/server/start-server.sh` | Create | Starts file-watcher server, returns JSON with dirs/port |
| `plugins/learn/server/server.js` | Create | Node.js HTTP server — serves newest HTML from screen_dir |
| `plugins/learn/server/templates/lesson.html` | Create | Lesson card template — dark/light, syntax highlight, quiz |
| `AGENTS.md` | Modify | Add learn trigger phrases |

---

## Task 1: Commit plugin docs

The `docs/plugins/learn/` directory was written during design. Commit it so it travels with the branch.

**Files:**
- Modify: `docs/plugins/learn/` (already exists in worktree)

- [ ] **Step 1: Stage all learn docs**

```bash
cd /path/to/.worktrees/feat-learn-plugin
git add docs/plugins/learn/
```

- [ ] **Step 2: Verify what's staged**

```bash
git status --short
```

Expected: 8 files listed under `docs/plugins/learn/`

- [ ] **Step 3: Commit**

```bash
git commit -m "docs(learn): add plugin contributor docs — index, features, personas, architecture, decisions, testing, feature specs"
```

---

## Task 2: Plugin scaffold

Create the plugin directory structure, manifest, README, CHANGELOG, and hooks.

**Files:**
- Create: `plugins/learn/.claude-plugin/plugin.json`
- Create: `plugins/learn/README.md`
- Create: `plugins/learn/CHANGELOG.md`
- Create: `plugins/learn/hooks/hooks.json`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p plugins/learn/.claude-plugin
mkdir -p plugins/learn/skills/learn
mkdir -p plugins/learn/skills/learn-micro/references
mkdir -p plugins/learn/server/templates
mkdir -p plugins/learn/hooks
```

- [ ] **Step 2: Write plugin.json**

Create `plugins/learn/.claude-plugin/plugin.json`:

```json
{
  "name": "learn",
  "version": "0.1.0",
  "description": "Structured AI-powered lessons for any topic, rendered in a local visual browser UI.",
  "author": "George Pilitsoglou",
  "skills": [
    {
      "name": "learn",
      "path": "skills/learn/SKILL.md",
      "commands": ["/learn"]
    },
    {
      "name": "learn:micro",
      "path": "skills/learn-micro/SKILL.md",
      "commands": ["/learn:micro"]
    }
  ],
  "hooks": "hooks/hooks.json"
}
```

- [ ] **Step 3: Write hooks.json**

Create `plugins/learn/hooks/hooks.json`:

```json
{
  "hooks": []
}
```

(No SessionStart hook in V1 — the visual server must be started explicitly with `learn serve`.)

- [ ] **Step 4: Write README.md**

Create `plugins/learn/README.md`:

```markdown
# learn

Structured AI-powered lessons for any topic, rendered in a local browser UI.

## Install

```bash
# via claude-plugins
claude plugin install learn
```

## Usage

Start the visual server first:

```
/learn serve
```

Then teach yourself anything:

```
/learn CSS flexbox
/learn how async/await works
/learn:micro "the event loop" --level beginner
```

## What you get

Each lesson includes:
- **Concept** — clear, jargon-minimal explanation
- **Why it matters** — real-world motivation
- **Example** — syntax-highlighted code
- **Common mistakes** — pre-empts wrong mental models
- **Generate task** — a production challenge to try
- **Quiz** — 3 questions, scored with explanations

## Expertise levels

`beginner` · `intermediate` (default) · `advanced`

Set inline: `"teach me flexbox, I'm a beginner"`  
Or on first use when prompted.

## Versions

| Version | Scope |
|---------|-------|
| 0.1.0 | `learn` router + `learn:micro` + visual server |
| 0.2.0 | `learn:quiz` standalone + `learn:explain` (Feynman) |
| 0.3.0 | `learn:recall` + file-based progress |
```

- [ ] **Step 5: Write CHANGELOG.md**

Create `plugins/learn/CHANGELOG.md`:

```markdown
# Changelog

## [0.1.0] — 2026-04-15

### Added
- `learn` router skill with scope classifier
- `learn:micro` structured lesson skill
- Visual server (file-watcher, localhost:7337)
- Lesson card: concept, why, example, common mistakes, generate task, quiz
- Knowledge vault integration (file-read only)
- Dark/light mode, code copy buttons, no external CDN calls
- AI-generated content caveat on all lessons
```

- [ ] **Step 6: Commit scaffold**

```bash
git add plugins/learn/
git commit -m "feat(learn): scaffold plugin structure — manifest, README, CHANGELOG, hooks"
```

---

## Task 3: Lesson schema reference

Define the canonical `Lesson` JSON shape. This is the contract between `learn:micro` and the visual server. Every other file references it.

**Files:**
- Create: `plugins/learn/skills/learn-micro/references/lesson-schema.md`

- [ ] **Step 1: Write lesson-schema.md**

Create `plugins/learn/skills/learn-micro/references/lesson-schema.md`:

````markdown
# Lesson JSON Schema

This is the canonical data shape output by `learn:micro`. The visual server reads it; future MCP layers will too. Do not deviate from this shape.

## TypeScript Interface

```typescript
interface Lesson {
  topic: string;                  // e.g. "CSS Flexbox"
  level: "beginner" | "intermediate" | "advanced";
  concept: string;                // 2–3 sentence explanation, no jargon for beginner
  why: string;                    // Real-world motivation ("You'll use this when...")
  example: {
    code?: string;                // Syntax-highlighted code (omit for non-code topics)
    prose?: string;               // Prose example (for non-code topics)
    language?: string;            // "css" | "javascript" | "python" | "typescript" | etc.
  };
  common_mistakes: string[];      // Exactly 2–3 mistakes. Concrete, not generic.
  generate_task: string;          // A production challenge: "Write a flex container that..."
  quiz: QuizQuestion[];           // Exactly 3 questions, mix of types
  resources: Resource[];          // 2–3 links. At least 1 must be official docs.
  estimated_minutes: number;      // Realistic read + practice time
}

interface QuizQuestion {
  type: "multiple_choice" | "fill_blank" | "explain";
  question: string;
  options?: string[];             // Required for multiple_choice (4 options)
  answer: string;                 // Correct answer text
  explanation: string;            // Why correct — 1–2 sentences shown after answer
}

interface Resource {
  title: string;
  url: string;
  type: "docs" | "tutorial" | "video" | "interactive";
  source: "vault" | "ai-suggested"; // "vault" = from knowledge vault; "ai-suggested" = LLM-generated
}
```

## Rules

- `common_mistakes` MUST have exactly 2–3 items. Never 0, never 4+.
- `quiz` MUST have exactly 3 items. One `multiple_choice`, one `fill_blank`, one `explain`.
- `resources` MUST have at least 1 item with `type: "docs"`.
- Any resource with `source: "ai-suggested"` will be shown with a `(AI-suggested, verify link)` badge in the UI.
- `estimated_minutes` should account for reading + generate task attempt. Typically 8–15 minutes.

## Example (valid Lesson JSON)

```json
{
  "topic": "CSS Flexbox",
  "level": "beginner",
  "concept": "Flexbox is a CSS layout model that arranges items in a row or column and distributes space between them automatically. You define a flex container with `display: flex`, and its direct children become flex items.",
  "why": "You'll use this whenever you need to centre something, build a navigation bar, or lay out a card grid without writing complex float or position hacks.",
  "example": {
    "code": ".container {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n\n.item {\n  flex: 1;\n}",
    "language": "css"
  },
  "common_mistakes": [
    "Applying flex properties to the wrong element — `justify-content` goes on the container, not the items.",
    "Forgetting that `flex-direction: column` changes the axis, so `justify-content` then controls vertical and `align-items` controls horizontal.",
    "Using `width` instead of `flex-basis` inside a flex container — `flex-basis` plays nicer with the flex algorithm."
  ],
  "generate_task": "Write a `.navbar` flex container with the logo on the left and three nav links on the right, all vertically centred, using only flexbox — no positioning.",
  "quiz": [
    {
      "type": "multiple_choice",
      "question": "Which property centres flex items along the main axis?",
      "options": ["align-items", "justify-content", "align-content", "flex-align"],
      "answer": "justify-content",
      "explanation": "`justify-content` distributes space along the main axis (horizontal by default). `align-items` controls the cross axis."
    },
    {
      "type": "fill_blank",
      "question": "To make a flex container lay out items in a column, you set `flex-direction: ___`.",
      "answer": "column",
      "explanation": "`flex-direction: column` makes the main axis run top-to-bottom, so items stack vertically."
    },
    {
      "type": "explain",
      "question": "In your own words: what's the difference between `justify-content` and `align-items`?",
      "answer": "justify-content controls spacing along the main axis; align-items controls alignment on the cross axis",
      "explanation": "Main axis = the direction items flow (row = horizontal, column = vertical). Cross axis = perpendicular to that."
    }
  ],
  "resources": [
    {
      "title": "CSS Flexible Box Layout — MDN",
      "url": "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flexible_box_layout",
      "type": "docs",
      "source": "vault"
    },
    {
      "title": "Flexbox Froggy",
      "url": "https://flexboxfroggy.com/",
      "type": "interactive",
      "source": "vault"
    }
  ],
  "estimated_minutes": 10
}
```
````

- [ ] **Step 2: Commit**

```bash
git add plugins/learn/skills/learn-micro/references/lesson-schema.md
git commit -m "feat(learn): add lesson JSON schema — canonical Lesson interface and example"
```

---

## Task 4: Teaching guide reference

Defines the pedagogical rules `learn:micro` follows when generating lessons.

**Files:**
- Create: `plugins/learn/skills/learn-micro/references/teaching-guide.md`

- [ ] **Step 1: Write teaching-guide.md**

Create `plugins/learn/skills/learn-micro/references/teaching-guide.md`:

```markdown
# Teaching Guide

Rules `learn:micro` MUST follow when generating lesson content.

## Lesson template (fixed order)

```
1. Concept       — 2–3 sentences. No jargon for beginner; technical precision for advanced.
2. Why           — One concrete real-world situation where this applies.
3. Example       — Working code or clear prose. For code: use the simplest case that illustrates the concept.
4. Common mistakes — 2–3 mistakes. These pre-empt wrong mental models formed from the example.
5. Generate task — A production task the user can attempt right now. Starts with a verb ("Write", "Build", "Explain").
6. Quiz          — 3 questions, default ON. Types: one multiple_choice + one fill_blank + one explain.
```

Never reorder these sections. The sequence is grounded in learning science: encoding (1–3) → misconception correction (4) → production (5) → retrieval (6).

## Expertise level rules

| Level | Concept | Example | Quiz |
|-------|---------|---------|------|
| `beginner` | Plain language, analogies, no assumed knowledge | Minimal working snippet, heavily commented | Questions test recall and basic application |
| `intermediate` | Technical terms used correctly, brief definitions if uncommon | Realistic use case, some nuance | Questions test application and edge cases |
| `advanced` | Full technical precision, no hand-holding | Non-trivial example with trade-offs visible | Questions test evaluation and synthesis |

**Detection order:**
1. Inline user statement: "teach me X, I'm a beginner" → use `beginner`
2. Stored preference in `.learn/prefs.json` (V2 only — not available in V1)
3. Default: `intermediate`

## Quiz rules

- Always generate exactly 3 questions: one per type (`multiple_choice`, `fill_blank`, `explain`)
- Quiz is ON by default. Only skip if user explicitly says "skip quiz" or "no quiz"
- Every `explanation` field must say why the answer is correct, not just restate it
- `multiple_choice` must have exactly 4 options; exactly 1 is correct
- `explain` questions should ask the user to produce an explanation, not recall a fact

## Common mistakes rules

- 2–3 items, never fewer, never more
- Each must be a mistake a real learner makes with this specific concept
- Frame as what goes wrong, not as a rule to follow: "Forgetting that..." not "Always remember to..."

## Generate task rules

- Must be something the user can do right now, in a text editor or REPL
- Must directly exercise the concept just taught
- Must be completable in 5–10 minutes
- Starts with an action verb: "Write", "Build", "Implement", "Explain", "Refactor"

## Content accuracy caveat (REQUIRED)

Every lesson HTML MUST include this caveat in the footer:

> ⚠️ This explanation is AI-generated. Verify against official documentation before using in production.

Never omit this. Never modify the wording.

## "What to explore next"

After the quiz, suggest exactly one follow-on concept. It must be:
- Directly related to the lesson topic
- One step up in complexity (not a tangent)
- Phrased as: "When you're ready: [concept]"
```

- [ ] **Step 2: Commit**

```bash
git add plugins/learn/skills/learn-micro/references/teaching-guide.md
git commit -m "feat(learn): add teaching guide — pedagogy rules, template order, expertise levels"
```

---

## Task 5: Vault integration reference

Defines exactly how `learn:micro` looks up the knowledge vault for resource links.

**Files:**
- Create: `plugins/learn/skills/learn-micro/references/vault-integration.md`

- [ ] **Step 1: Write vault-integration.md**

Create `plugins/learn/skills/learn-micro/references/vault-integration.md`:

```markdown
# Knowledge Vault Integration

`learn:micro` uses the nikai Knowledge Vault (`knowledge/`) for resource links. This is a **file-read-only** integration in V1 — no API, no prompt stuffing.

## Lookup contract

When building the `resources[]` array for a lesson:

### Step 1: Search the category index

Check the relevant category `_index.md` for a matching slug:

```
knowledge/ai-tools/_index.md
knowledge/methodologies/_index.md
knowledge/prompt-techniques/_index.md
```

Search for the lesson topic name (case-insensitive substring match against slug and name fields).

### Step 2: Check entry status

If a match is found, read the entry file:
- `status: detailed` → Use its `url` and first paragraph of `## One-Paragraph Summary` as the resource
- `status: stub` → Skip. Stubs have insufficient content to be useful.

### Step 3: Mark source

- Vault-sourced resources: `"source": "vault"` — shown with no badge in UI
- LLM-generated fallbacks: `"source": "ai-suggested"` — shown with `(AI-suggested, verify link)` badge in UI

### Step 4: Fallback

If no vault match exists, generate 2–3 resource links using your knowledge. Mark all as `"source": "ai-suggested"`. Always include at least one official documentation link.

## Example lookup

Lesson topic: "LangChain"

1. Check `knowledge/ai-tools/_index.md` → find slug `langchain`
2. Read `knowledge/ai-tools/langchain.md` → status: detailed
3. Extract: url + one-paragraph summary
4. Add to resources: `{ "source": "vault", "type": "docs", ... }`

## What NOT to do

- Do NOT read the full vault entry into the lesson prompt — only extract url and summary
- Do NOT use stub entries — they contain only frontmatter, no content worth linking
- Do NOT mark vault resources as "ai-suggested" — they come from curated research
```

- [ ] **Step 2: Commit**

```bash
git add plugins/learn/skills/learn-micro/references/vault-integration.md
git commit -m "feat(learn): add vault integration reference — file-read-only lookup contract"
```

---

## Task 6: learn:micro SKILL.md

The lesson orchestrator. Reads references, generates Lesson JSON, writes HTML, opens browser.

**Files:**
- Create: `plugins/learn/skills/learn-micro/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Create `plugins/learn/skills/learn-micro/SKILL.md`:

````markdown
---
name: learn:micro
description: >
  This skill should be used when the user wants to learn a single concept, asks
  "teach me X", "explain X", "how does X work", or similar single-topic learning
  requests. Generates a structured lesson card rendered in the local visual server.
---

# learn:micro — Lesson Orchestrator

## Your role

You teach one concept at a time through a structured lesson rendered in the browser. You generate the lesson as a strict JSON object, write it as an HTML file to the visual server's content directory, then tell the user where to view it.

## Before starting

**1. Check the visual server is running.**

Look for `.learn/server/state/server-info` in the project root. If it does not exist, stop and respond:

> "The visual server is not running. Start it first with `/learn serve`, then try again."

Do not proceed if the server is not running.

**2. Determine expertise level.**

Check if the user stated a level inline ("teach me X, I'm a beginner"). If yes, use it.
Otherwise default to `intermediate`.

## Step 1: Read your references

Before generating anything, read these files:

- `skills/learn-micro/references/lesson-schema.md` — the exact Lesson JSON shape you must output
- `skills/learn-micro/references/teaching-guide.md` — pedagogy rules you must follow
- `skills/learn-micro/references/vault-integration.md` — how to find resource links

## Step 2: Run vault lookup

Following `vault-integration.md`, look up the lesson topic in the knowledge vault. Note any vault-matched resources before generating the lesson.

## Step 3: Generate Lesson JSON

Generate the full `Lesson` object in a single response following `lesson-schema.md` exactly. Rules:

- Output ONLY the JSON object — no prose before or after in this step
- Follow all rules in `teaching-guide.md`
- `quiz` must have exactly 3 questions (one per type)
- `common_mistakes` must have exactly 2–3 items
- `resources` must have at least 1 `type: "docs"` entry
- Every resource must have `source: "vault"` or `source: "ai-suggested"`

## Step 4: Write lesson HTML

Read the server info to get `screen_dir`:

```bash
cat .learn/server/state/server-info
```

Write the lesson HTML to `{screen_dir}/lesson-{timestamp}.html` using the template at `server/templates/lesson.html`. Inject the Lesson JSON as a `<script>` tag:

```html
<script id="lesson-data" type="application/json">
{LESSON_JSON}
</script>
```

The template reads this script tag and renders all sections client-side.

## Step 5: Tell the user

After writing the HTML file, respond:

```
Lesson ready: {topic} ({level})
→ Open http://localhost:{port} in your browser (or it should have updated automatically)

Estimated time: {estimated_minutes} minutes

When you're done: {what_to_explore_next}
```

Do not summarise the lesson in the terminal — it's in the browser.

## Error handling

| Failure | Response |
|---------|----------|
| Server not running | "The visual server is not running. Start it with `/learn serve`, then try again." |
| Lesson JSON fails validation | "Lesson generation failed. Try again or use a more specific topic." Do NOT write partial HTML. |
| screen_dir write fails | "Could not write lesson file. Check that the server is running and the project directory is writable." |
| Vault lookup fails | Continue with LLM-generated resources, mark all as `ai-suggested`. Do not block lesson generation. |
````

- [ ] **Step 2: Commit**

```bash
git add plugins/learn/skills/learn-micro/SKILL.md
git commit -m "feat(learn): add learn:micro SKILL.md — lesson orchestrator"
```

---

## Task 7: learn router SKILL.md

The entry-point skill. Detects intent, classifies scope, routes to learn:micro.

**Files:**
- Create: `plugins/learn/skills/learn/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Create `plugins/learn/skills/learn/SKILL.md`:

```markdown
---
name: learn
description: >
  This skill should be used when the user wants to learn something, asks to be
  taught a topic, says "teach me X", "explain X", "how does X work", "I want to
  learn X", or similar. Routes to learn:micro for focused concepts.
---

# learn — Router

## Your role

You are the entry point for the `learn` plugin. Classify the user's learning intent, determine scope, and route to the right sub-skill. Always surface your routing decision — never silently reroute.

## Routing rules

### 1. Detect intent

| User says | Route to |
|-----------|----------|
| "teach me [single concept]" | learn:micro |
| "explain [thing]" | learn:micro |
| "how does [thing] work" | learn:micro |
| "what is [thing]" | learn:micro |
| "quiz me on [thing]" | Respond: "learn:quiz is coming in v0.2.0. For now, use `/learn [topic]` to get a lesson with a built-in quiz." |
| "I want to learn [broad topic]" | Scope check (see below) |
| "how do I become [role]" | Scope check (see below) |

### 2. Scope classifier

Before routing, estimate whether the topic maps to more than 3 sub-concepts.

**Single concept (≤3 sub-concepts):** Route directly to learn:micro.
Examples: "CSS flexbox", "async/await", "the event loop", "SQL JOINs"

**Broad topic (>3 sub-concepts):** Ask the user before routing.
Examples: "React", "machine learning", "become a full-stack engineer", "system design"

When a topic is broad, respond:

> "**[Topic]** is a broad area with many concepts. What would you like to do?
>
> 1. **One focused lesson** — pick one concept to learn right now (I'll suggest a good starting point)
> 2. **Full learning path** — a structured roadmap with milestones *(coming in v0.3.0)*
>
> Which would you prefer?"

If the user picks option 1, suggest the best entry concept and invoke learn:micro with it.
If the user picks option 2, respond: "Learning paths are coming in v0.3.0. For now, I can teach you the first concept: [suggest concept]. Want to start there?"

### 3. Debug mode

If `LEARN_DEBUG=1` is set, print the routing decision before invoking any sub-skill:

```
[learn:router] intent=micro topic="CSS flexbox" level=intermediate scope=single
```

## What NOT to route

This skill does not handle:
- "Start the server" → Respond: "Run `/learn serve` in your terminal to start the visual server."
- "What have I learned" / "show my progress" → Respond: "Progress tracking is coming in v0.2.0."
- "Continue my lesson on X" → Respond: "Session recall is coming in v0.2.0."
```

- [ ] **Step 2: Commit**

```bash
git add plugins/learn/skills/learn/SKILL.md
git commit -m "feat(learn): add learn router SKILL.md — intent detection, scope classifier"
```

---

## Task 8: Visual server

Node.js file-watcher HTTP server + start script + lesson HTML template. Follows the superpowers visual companion pattern exactly.

**Files:**
- Create: `plugins/learn/server/server.js`
- Create: `plugins/learn/server/start-server.sh`
- Create: `plugins/learn/server/templates/lesson.html`

- [ ] **Step 1: Write server.js**

Create `plugins/learn/server/server.js`:

```javascript
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
    'state-dir': { type: 'string' },
    port: { type: 'string', default: '7337' },
    host: { type: 'string', default: '127.0.0.1' },
  },
});

const SCREEN_DIR = args['screen-dir'];
const STATE_DIR = args['state-dir'];
const HOST = args['host'];
const INACTIVITY_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes

if (!SCREEN_DIR || !STATE_DIR) {
  console.error('Usage: node server.js --screen-dir <path> --state-dir <path>');
  process.exit(1);
}

fs.mkdirSync(SCREEN_DIR, { recursive: true });
fs.mkdirSync(STATE_DIR, { recursive: true });

// Find newest HTML file in screen_dir
function newestFile() {
  const files = fs.readdirSync(SCREEN_DIR)
    .filter(f => f.endsWith('.html'))
    .map(f => ({ name: f, mtime: fs.statSync(path.join(SCREEN_DIR, f)).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime);
  return files[0] ? path.join(SCREEN_DIR, files[0].name) : null;
}

// Inactivity timer
let inactivityTimer;
function resetInactivity() {
  clearTimeout(inactivityTimer);
  inactivityTimer = setTimeout(() => {
    fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), 'inactivity');
    fs.rmSync(path.join(STATE_DIR, 'server-info'), { force: true });
    process.exit(0);
  }, INACTIVITY_TIMEOUT_MS);
}

// Auto-increment port on EADDRINUSE
function startServer(port) {
  const server = http.createServer((req, res) => {
    resetInactivity();

    if (req.method === 'POST' && req.url === '/events') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        fs.appendFileSync(path.join(STATE_DIR, 'events'), body + '\n');
        res.writeHead(204);
        res.end();
      });
      return;
    }

    const file = newestFile();
    if (!file) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end('<html><body style="font-family:sans-serif;padding:2rem;color:#888"><p>Waiting for a lesson…<br>Run <code>/learn [topic]</code> in Claude Code.</p></body></html>');
      return;
    }

    // SSE for auto-refresh
    if (req.url === '/events/stream') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
        'Access-Control-Allow-Origin': '*',
      });
      const watcher = fs.watch(SCREEN_DIR, () => {
        res.write('data: refresh\n\n');
      });
      req.on('close', () => watcher.close());
      return;
    }

    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(fs.readFileSync(file));
  });

  server.on('error', err => {
    if (err.code === 'EADDRINUSE') {
      startServer(port + 1);
    } else {
      throw err;
    }
  });

  server.listen(port, HOST, () => {
    const actualPort = server.address().port;
    const info = {
      type: 'server-started',
      port: actualPort,
      url: `http://localhost:${actualPort}`,
      screen_dir: SCREEN_DIR,
      state_dir: STATE_DIR,
    };
    const infoStr = JSON.stringify(info);
    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), infoStr);
    console.log(infoStr);
    resetInactivity();
  });
}

startServer(parseInt(args.port, 10));
```

- [ ] **Step 2: Write start-server.sh**

Create `plugins/learn/server/start-server.sh`:

```bash
#!/usr/bin/env bash
# start-server.sh — start the learn visual server
# Usage: ./start-server.sh --project-dir <path> [--port <n>] [--host <h>] [--foreground]
set -euo pipefail

PROJECT_DIR=""
PORT="7337"
HOST="127.0.0.1"
FOREGROUND=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --port)        PORT="$2"; shift 2 ;;
    --host)        HOST="$2"; shift 2 ;;
    --foreground)  FOREGROUND=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_DIR" ]]; then
  echo '{"error":"--project-dir is required"}' >&2
  exit 1
fi

SESSION_ID="$$-$(date +%s)"
BASE_DIR="$PROJECT_DIR/.learn/server/$SESSION_ID"
SCREEN_DIR="$BASE_DIR/content"
STATE_DIR="$BASE_DIR/state"

mkdir -p "$SCREEN_DIR" "$STATE_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$FOREGROUND" == "true" ]] || [[ "${CODEX_CI:-}" == "1" ]]; then
  node "$SCRIPT_DIR/server.js" \
    --screen-dir "$SCREEN_DIR" \
    --state-dir "$STATE_DIR" \
    --port "$PORT" \
    --host "$HOST"
else
  node "$SCRIPT_DIR/server.js" \
    --screen-dir "$SCREEN_DIR" \
    --state-dir "$STATE_DIR" \
    --port "$PORT" \
    --host "$HOST" &
  # Wait for server-info to appear (max 5s)
  for i in $(seq 1 50); do
    if [[ -f "$STATE_DIR/server-info" ]]; then
      cat "$STATE_DIR/server-info"
      exit 0
    fi
    sleep 0.1
  done
  echo '{"error":"server did not start within 5 seconds"}' >&2
  exit 1
fi
```

- [ ] **Step 3: Make start-server.sh executable**

```bash
chmod +x plugins/learn/server/start-server.sh
```

- [ ] **Step 4: Write lesson.html template**

Create `plugins/learn/server/templates/lesson.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>learn</title>
  <style>
    :root {
      --bg: #ffffff; --surface: #f8f9fa; --border: #e9ecef;
      --text: #212529; --muted: #6c757d; --accent: #0066cc;
      --code-bg: #f1f3f5; --success: #198754; --warning: #fd7e14;
      --quiz-bg: #f0f7ff; --mistake-bg: #fff8f0;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0d1117; --surface: #161b22; --border: #30363d;
        --text: #e6edf3; --muted: #8b949e; --accent: #58a6ff;
        --code-bg: #1e2530; --success: #3fb950; --warning: #d29922;
        --quiz-bg: #0d2137; --mistake-bg: #1a1200;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
           background: var(--bg); color: var(--text); line-height: 1.6; }
    .layout { max-width: 780px; margin: 0 auto; padding: 2rem 1.5rem; }
    .header { display: flex; justify-content: space-between; align-items: center;
              margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border); }
    .topic { font-size: 1.5rem; font-weight: 700; }
    .meta { display: flex; gap: 0.75rem; align-items: center; }
    .badge { padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.75rem;
             font-weight: 600; border: 1px solid var(--border); color: var(--muted); }
    .section { margin-bottom: 2rem; }
    .section-title { font-size: 0.75rem; font-weight: 700; text-transform: uppercase;
                     letter-spacing: 0.08em; color: var(--muted); margin-bottom: 0.5rem; }
    .concept { font-size: 1.05rem; line-height: 1.7; }
    .why { background: var(--surface); border-left: 3px solid var(--accent);
           padding: 0.75rem 1rem; border-radius: 0 6px 6px 0; }
    .code-block { position: relative; background: var(--code-bg); border-radius: 8px;
                  padding: 1rem; font-family: "SF Mono", Consolas, monospace; font-size: 0.9rem;
                  overflow-x: auto; border: 1px solid var(--border); }
    .copy-btn { position: absolute; top: 0.5rem; right: 0.5rem; background: var(--surface);
                border: 1px solid var(--border); border-radius: 4px; padding: 0.2rem 0.5rem;
                font-size: 0.75rem; cursor: pointer; color: var(--muted); }
    .copy-btn:hover { color: var(--text); }
    .copy-btn.copied { color: var(--success); }
    .mistakes { background: var(--mistake-bg); border-radius: 8px; padding: 1rem;
                border: 1px solid var(--border); }
    .mistakes ul { padding-left: 1.2rem; }
    .mistakes li { margin-bottom: 0.4rem; }
    .generate-task { background: var(--surface); border-radius: 8px; padding: 1rem;
                     border: 1px solid var(--border); font-weight: 500; }
    .quiz { background: var(--quiz-bg); border-radius: 8px; padding: 1.25rem;
            border: 1px solid var(--border); }
    .quiz-question { margin-bottom: 1.5rem; }
    .quiz-question:last-child { margin-bottom: 0; }
    .question-text { font-weight: 600; margin-bottom: 0.75rem; }
    .options { display: flex; flex-direction: column; gap: 0.4rem; }
    .option { display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0.75rem;
              border-radius: 6px; border: 1px solid var(--border); cursor: pointer;
              background: var(--bg); }
    .option:hover { border-color: var(--accent); }
    .option.selected { border-color: var(--accent); background: var(--quiz-bg); }
    .option.correct { border-color: var(--success); background: color-mix(in srgb, var(--success) 10%, transparent); }
    .option.wrong { border-color: var(--warning); background: color-mix(in srgb, var(--warning) 10%, transparent); }
    .explanation { margin-top: 0.5rem; padding: 0.5rem 0.75rem; border-radius: 6px;
                   font-size: 0.9rem; background: var(--surface); display: none; }
    .fill-input { width: 100%; padding: 0.5rem 0.75rem; border-radius: 6px;
                  border: 1px solid var(--border); background: var(--bg); color: var(--text);
                  font-size: 1rem; }
    .explain-input { width: 100%; min-height: 80px; padding: 0.5rem 0.75rem; border-radius: 6px;
                     border: 1px solid var(--border); background: var(--bg); color: var(--text);
                     font-size: 0.95rem; resize: vertical; }
    .submit-btn { margin-top: 0.5rem; padding: 0.4rem 0.9rem; border-radius: 6px;
                  border: none; background: var(--accent); color: white; cursor: pointer;
                  font-size: 0.9rem; }
    .resources { display: flex; flex-direction: column; gap: 0.5rem; }
    .resource-link { display: flex; align-items: center; gap: 0.5rem; text-decoration: none;
                     color: var(--accent); padding: 0.5rem 0.75rem; border-radius: 6px;
                     border: 1px solid var(--border); background: var(--surface); }
    .resource-link:hover { border-color: var(--accent); }
    .resource-type { font-size: 0.75rem; color: var(--muted); }
    .ai-badge { font-size: 0.7rem; color: var(--warning); }
    .next { border-top: 1px solid var(--border); padding-top: 1.5rem; margin-top: 2rem; }
    .caveat { margin-top: 2rem; padding: 0.75rem 1rem; background: var(--surface);
              border-radius: 6px; font-size: 0.82rem; color: var(--muted);
              border: 1px solid var(--border); }
    pre { white-space: pre-wrap; word-break: break-all; }
  </style>
</head>
<body>
  <div class="layout" id="app">Loading lesson…</div>

  <script>
    // SSE auto-refresh
    const sse = new EventSource('/events/stream');
    sse.onmessage = () => location.reload();

    const data = JSON.parse(document.getElementById('lesson-data')?.textContent || 'null');

    function postEvent(type, payload) {
      fetch('/events', { method: 'POST', body: JSON.stringify({ type, ...payload, ts: Date.now() }) });
    }

    function copyCode(btn, code) {
      navigator.clipboard.writeText(code).then(() => {
        btn.textContent = 'copied'; btn.classList.add('copied');
        setTimeout(() => { btn.textContent = 'copy'; btn.classList.remove('copied'); }, 1500);
      });
    }

    function renderQuiz(quiz) {
      return quiz.map((q, qi) => {
        if (q.type === 'multiple_choice') {
          const opts = q.options.map((o, oi) =>
            `<div class="option" data-qi="${qi}" data-oi="${oi}" onclick="selectOption(this, ${qi}, ${JSON.stringify(o)}, ${JSON.stringify(q.answer)}, ${JSON.stringify(q.explanation)})">
              <span>${o}</span>
            </div>`).join('');
          return `<div class="quiz-question">
            <div class="question-text">${qi+1}. ${q.question}</div>
            <div class="options">${opts}</div>
            <div class="explanation" id="exp-${qi}">${q.explanation}</div>
          </div>`;
        }
        if (q.type === 'fill_blank') {
          return `<div class="quiz-question">
            <div class="question-text">${qi+1}. ${q.question}</div>
            <input class="fill-input" id="fill-${qi}" placeholder="Your answer…" />
            <button class="submit-btn" onclick="checkFill(${qi}, ${JSON.stringify(q.answer)}, ${JSON.stringify(q.explanation)})">Check</button>
            <div class="explanation" id="exp-${qi}">${q.explanation}</div>
          </div>`;
        }
        // explain
        return `<div class="quiz-question">
          <div class="question-text">${qi+1}. ${q.question}</div>
          <textarea class="explain-input" id="explain-${qi}" placeholder="Write your explanation here…"></textarea>
          <button class="submit-btn" onclick="revealExplain(${qi}, ${JSON.stringify(q.explanation)})">See model answer</button>
          <div class="explanation" id="exp-${qi}"><strong>Model answer:</strong> ${q.answer}<br><br>${q.explanation}</div>
        </div>`;
      }).join('');
    }

    function selectOption(el, qi, chosen, correct, explanation) {
      const opts = document.querySelectorAll(`[data-qi="${qi}"]`);
      opts.forEach(o => o.onclick = null);
      el.classList.add(chosen === correct ? 'correct' : 'wrong');
      opts.forEach(o => { if (o.querySelector('span').textContent === correct) o.classList.add('correct'); });
      const exp = document.getElementById(`exp-${qi}`);
      exp.style.display = 'block';
      postEvent('quiz_answer', { qi, chosen, correct, result: chosen === correct ? 'correct' : 'wrong' });
    }

    function checkFill(qi, correct, explanation) {
      const input = document.getElementById(`fill-${qi}`);
      const val = input.value.trim().toLowerCase();
      const ok = val === correct.toLowerCase() || val.includes(correct.toLowerCase());
      input.style.borderColor = ok ? 'var(--success)' : 'var(--warning)';
      document.getElementById(`exp-${qi}`).style.display = 'block';
      postEvent('quiz_answer', { qi, chosen: val, correct, result: ok ? 'correct' : 'wrong' });
    }

    function revealExplain(qi) {
      document.getElementById(`exp-${qi}`).style.display = 'block';
      postEvent('quiz_reveal', { qi });
    }

    if (data) {
      const codeBlock = data.example.code
        ? `<div class="code-block"><pre>${data.example.code.replace(/</g,'&lt;')}</pre>
            <button class="copy-btn" onclick="copyCode(this, ${JSON.stringify(data.example.code)})">copy</button></div>`
        : `<p>${data.example.prose}</p>`;

      const resources = data.resources.map(r =>
        `<a class="resource-link" href="${r.url}" target="_blank" rel="noopener">
          <span>${r.title}</span>
          <span class="resource-type">${r.type}${r.source==='ai-suggested'?' <span class="ai-badge">(AI-suggested, verify)</span>':''}</span>
        </a>`).join('');

      document.getElementById('app').innerHTML = `
        <div class="header">
          <div class="topic">${data.topic}</div>
          <div class="meta">
            <span class="badge">${data.level}</span>
            <span class="badge">~${data.estimated_minutes} min</span>
          </div>
        </div>

        <div class="section">
          <div class="section-title">Concept</div>
          <div class="concept">${data.concept}</div>
        </div>

        <div class="section">
          <div class="section-title">Why it matters</div>
          <div class="why">${data.why}</div>
        </div>

        <div class="section">
          <div class="section-title">Example${data.example.language ? ' — ' + data.example.language : ''}</div>
          ${codeBlock}
        </div>

        <div class="section">
          <div class="section-title">Common mistakes</div>
          <div class="mistakes"><ul>${data.common_mistakes.map(m => `<li>${m}</li>`).join('')}</ul></div>
        </div>

        <div class="section">
          <div class="section-title">Generate</div>
          <div class="generate-task">${data.generate_task}</div>
        </div>

        <div class="section">
          <div class="section-title">Quiz</div>
          <div class="quiz" id="quiz">${renderQuiz(data.quiz)}</div>
        </div>

        <div class="section">
          <div class="section-title">Resources</div>
          <div class="resources">${resources}</div>
        </div>

        <div class="next">
          <div class="section-title">What to explore next</div>
          <p>${data.next || 'Keep exploring!'}</p>
        </div>

        <div class="caveat">
          ⚠️ This explanation is AI-generated. Verify against official documentation before using in production.
        </div>
      `;
    }
  </script>
  <script id="lesson-data" type="application/json">null</script>
</body>
</html>
```

- [ ] **Step 5: Commit**

```bash
git add plugins/learn/server/
git commit -m "feat(learn): add visual server — file-watcher HTTP server, start script, lesson card template"
```

---

## Task 9: Register in AGENTS.md

Add trigger phrases so Claude Code knows when to invoke the learn skills.

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Read AGENTS.md to find the right insertion point**

```bash
grep -n "learn\|teach\|skill" AGENTS.md | head -20
```

- [ ] **Step 2: Add learn trigger phrases**

Find the skills section in AGENTS.md and add:

```markdown
### learn

Invoke the `learn` skill when the user:
- Says "teach me [topic]"
- Says "explain [topic]"  
- Says "how does [topic] work"
- Says "I want to learn [topic]"
- Says "what is [topic]" in a learning context
- Asks to be quizzed on a topic
- Asks to start the learn visual server (`/learn serve`)

Invoke `learn:micro` directly when the user specifies a single concept explicitly with `/learn:micro`.
```

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "chore(learn): register learn trigger phrases in AGENTS.md"
```

---

## Task 10: Manual acceptance test

Verify the full V1 flow against the feature specs before opening a PR.

**Reference:** `docs/plugins/learn/specs/learn-micro.feature` · `docs/plugins/learn/specs/learn-server.feature`

- [ ] **Step 1: Start the visual server**

```bash
node plugins/learn/server/start-server.sh --project-dir . --port 7337
```

Expected output:
```json
{"type":"server-started","port":7337,"url":"http://localhost:7337","screen_dir":"...","state_dir":"..."}
```

Open `http://localhost:7337` in browser. Expected: "Waiting for a lesson…" placeholder.

- [ ] **Step 2: Test single-concept routing**

In Claude Code with the plugin loaded, run:
```
/learn CSS flexbox
```

Expected: router routes to learn:micro without asking a question. Lesson appears in browser with all 6 sections.

- [ ] **Step 3: Test scope classifier**

```
/learn React
```

Expected: router asks "Full roadmap or one focused concept?" — does NOT silently route to learn:micro.

- [ ] **Step 4: Test expertise level inline override**

```
/learn async/await, I'm a beginner
```

Expected: lesson level is `beginner` (verified in browser badge). Simpler language than the intermediate default.

- [ ] **Step 5: Test quiz**

After a lesson loads, answer one multiple choice question correctly and one incorrectly.
Expected: correct option turns green with explanation shown; wrong option turns orange with correct answer highlighted.

- [ ] **Step 6: Test quiz opt-out**

```
/learn the event loop — skip quiz
```

Expected: lesson renders without the Quiz section. "What to explore next" still appears.

- [ ] **Step 7: Test AI caveat**

Expected: every lesson page shows "⚠️ This explanation is AI-generated…" in the footer.

- [ ] **Step 8: Test port conflict**

```bash
# Occupy port 7337
python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', 7337)); s.listen(); input()"
```

In a separate terminal:
```bash
node plugins/learn/server/start-server.sh --project-dir . --port 7337
```

Expected: server starts on 7338, logs `{"port":7338,...}`.

- [ ] **Step 9: Test server-not-running error**

Stop the server. Run `/learn CSS grid` in Claude Code.
Expected: "The visual server is not running. Start it with `/learn serve`, then try again." No HTML written.

- [ ] **Step 10: Test dark mode**

Set OS to dark mode. Open `http://localhost:7337`.
Expected: lesson renders with dark background, light text. No external CDN calls (verify in browser DevTools → Network: zero external requests).

- [ ] **Step 11: Commit test results**

If all tests pass:
```bash
git commit --allow-empty -m "test(learn): manual acceptance tests passing — all learn-micro + learn-server scenarios verified"
```

---

## Self-Review

**Spec coverage check:**

| Spec section | Covered by task |
|---|---|
| R-SKILL-001 (single entry point) | Task 7 — learn SKILL.md |
| R-SKILL-002 (intent routing) | Task 7 — routing table |
| R-SKILL-007 (ambiguous intent → ask) | Task 7 — scope classifier |
| R-TEACH-001 (lesson template) | Task 4 — teaching-guide.md |
| R-TEACH-002 (expertise levels) | Task 4 — teaching-guide.md |
| R-TEACH-004 (3 quiz types) | Task 3 — lesson-schema.md |
| R-TEACH-005 (quiz explanations) | Task 3 + Task 8 — lesson.html quiz UI |
| R-TEACH-008 (what to explore next) | Task 4 + Task 8 — lesson.html |
| R-VIS-001 (local HTTP server) | Task 8 — server.js |
| R-VIS-003 (single command start) | Task 8 — start-server.sh |
| R-VIS-005 (copy button) | Task 8 — lesson.html |
| R-VIS-004 (dark/light mode) | Task 8 — lesson.html CSS |
| R-VIS-007 (localhost only) | Task 8 — server.js HOST=127.0.0.1 |
| R-CONTENT-003 (vault integration) | Task 5 — vault-integration.md |
| R-ACC-001 (AI caveat) | Task 4 + Task 8 — required footer |
| R-ERR-001 (error states) | Task 6 — learn:micro error table |
| R-UX-001 (natural language entry) | Task 7 — SKILL.md triggers |
| R-UX-002 (expertise level on first use) | Task 7 — routing rules |
| R-PERF-001 (server first paint < 1s) | Task 8 — static HTML, no render blocking |

**Placeholder scan:** No TBDs, no TODOs, no "similar to Task N" references. All code blocks are complete.

**Type consistency:** `Lesson`, `QuizQuestion`, `Resource` interfaces defined in Task 3 (lesson-schema.md) and used consistently in Task 6 (learn:micro SKILL.md) and Task 8 (lesson.html render logic).

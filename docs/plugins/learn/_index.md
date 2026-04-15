# Learn — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Learn teaches users anything through structured, visual lessons. It detects intent, routes to the appropriate skill, generates a typed `Lesson` JSON object, and renders the lesson as a browser card via a local visual server — concept explanation, syntax-highlighted example, common mistakes, a production task, and an inline quiz.

**Current version:** 0.1.0

**Commands:** `/learn {topic}` · `/learn:micro {topic}`

**Version:** 0.1.0 — see `features.md` for v1 scope and v2+ roadmap.

---

## File map

```
plugins/learn/
├── README.md                          ← user-facing overview (ships)
├── CHANGELOG.md                       ← version history
│
├── .claude-plugin/
│   └── plugin.json                    ← manifest: name, version, author, hooks, skills[]
│
├── skills/
│   ├── learn/
│   │   └── SKILL.md                   ← /learn — intent detection + routing
│   └── learn-micro/
│       ├── SKILL.md                   ← /learn:micro — lesson orchestrator
│       └── references/
│           ├── lesson-schema.md       ← Lesson JSON schema (typed, versioned)
│           ├── teaching-guide.md      ← pedagogy rules + lesson template
│           └── vault-integration.md  ← knowledge vault lookup contract
│
├── server/
│   ├── start-server.sh                ← launch script (same pattern as superpowers)
│   ├── server.js                      ← file-watcher HTTP server
│   └── templates/
│       └── lesson.html                ← lesson card template
│
└── hooks/
    └── hooks.json                     ← hook registrations
```

---

## How skills communicate

Lesson data flows through a single write — never through conversation history.

| Step | Owner | What happens |
|------|-------|-------------|
| 1. JSON generation | `learn:micro` | Generates full `Lesson` JSON in one shot, strict schema |
| 2. File write | `learn:micro` | Writes lesson to `screen_dir/lesson-{slug}.json` |
| 3. File watch | visual server | Detects new file, reads and renders `lesson.html` template |
| 4. Browser refresh | visual server | SSE pushes `refresh` event; browser reloads to `localhost:{port}/` |
| 5. Quiz interaction | browser UI | Answer selection and explanation rendering handled client-side |

The visual server uses the same file-watcher and `screen_dir` / `state_dir` pattern as the superpowers visual companion. A lesson write always replaces the previous — no accumulation.

---

## Key rules

- **Router surfaces its decision.** `/learn` never silently reroutes. It always tells the user what it detected and where it is routing.
- **One-shot JSON, strict schema.** `learn:micro` generates the full `Lesson` JSON in a single prompt. No iterative assembly, no inter-step state.
- **Quiz is default ON.** Users opt out, not in. The quiz is part of the lesson, not an add-on.
- **No external CDN calls.** All assets are bundled in `server/templates/`. The lesson page makes zero external requests.
- **SKILL.md stays lean.** Move detail to `references/`. Target 1,500–2,000 words per skill file.
- **Visual server is the only render path.** There is no terminal fallback for quiz rendering. If the server is down, skip the quiz with an explicit error message — two render paths are two maintenance surfaces.
- **AI-generated caveat on all lessons.** Every lesson rendered in the browser must include the disclaimer: "This explanation is AI-generated — verify against official docs."

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-04-15-learn-plugin-design.md` |
| Feature specs (.feature) | `docs/plugins/learn/specs/` |
| Features & roadmap | `docs/plugins/learn/features.md` |
| Architectural decisions | `docs/plugins/learn/DECISIONS.md` |
| User-facing README | `plugins/learn/README.md` |

# Draftloom Plugin — Design Spec

**Date:** 2026-04-15
**Status:** Approved
**Author:** Georgios Pilitsoglou

---

## Overview

Draftloom is a public Claude Code plugin that guides any user through writing viral, catchy blog posts. It conducts a voice-profile interview, proposes a section wireframe, drafts prose via a writer agent, then runs four specialist eval agents in parallel — scoring SEO, hook strength, voice match, and readability. Failing dimensions are patched by the writer agent and re-evaluated, iterating up to three times until all scores pass a 75/100 threshold. A distribution agent then generates platform-specific copy (X, LinkedIn, email, newsletter). The whole system communicates through a structured file workspace — no state passes through conversation history.

**Target users:** Any writer using Claude Code — indie hackers, developer bloggers, content marketers, corporate comms teams. Adapts via named voice profiles (e.g. `george-personal`, `vanguard-corporate`).

**Plugin name:** `draftloom`
**Location in repo:** `plugins/draftloom/`
**Version:** `0.1.0`

---

## Problem Statement

Existing AI writing flows treat a blog post as a single prompt → single output. There is no structured voice capture, no section-level layout approval, no multi-dimensional evaluation, and no iterative patching loop. The result is generic prose that doesn't match the writer's voice and doesn't optimise for virality or SEO. Draftloom solves this by breaking the workflow into distinct, specialist phases — each owned by a focused agent with a clear file contract.

---

## Architecture

### Plugin structure

```
plugins/draftloom/
├── .claude-plugin/
│   └── plugin.json                    # manifest — name, version, author, hooks, skills[], agents[]
├── skills/
│   ├── setup/                         # /draftloom:setup
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── interview-questions.md # 3 essential Qs + 6 deferred Qs
│   │       ├── profile-schema.md      # full JSON schema + validation rules
│   │       └── storage-guide.md       # project vs global ~/.draftloom/ config
│   ├── draft/                         # /draftloom:draft
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── brief-questions.md     # 4 mandatory Qs + optional SEO/timing opt-in
│   │       ├── layout-templates.md    # section templates + parse-able wireframe editor
│   │       ├── workspace-schema.md    # ★ complete file contract for all agents
│   │       ├── scoring-rubric.md      # thresholds, iteration rules, routing logic, aggregate calc
│   │       ├── eval-output-spec.md    # standardised eval JSON schema
│   │       ├── distribution-guide.md  # platform copy templates + character limits
│   │       └── turso-setup.md         # optional Turso MCP backend guide
│   └── eval/                          # /draftloom:eval (standalone scorer)
│       ├── SKILL.md
│       └── references/
│           └── eval-guide.md          # how to run eval-only mode via orchestrator
├── agents/
│   ├── orchestrator.md                # ★ owns eval loop, spawns agents, aggregates, decides
│   ├── writer.md                      # drafts + patches prose (sections_affected only)
│   ├── seo-eval.md                    # → seo-eval.json
│   ├── hook-eval.md                   # → hook-eval.json
│   ├── voice-eval.md                  # → voice-eval.json
│   ├── readability-eval.md            # → readability-eval.json
│   └── distribution.md               # → distribution.json (runs when all pass or on halt)
└── hooks/
    └── hooks.json                     # SessionStart: detect profiles → hint /draftloom:setup
```

### Workspace per post

Every post gets an isolated folder. All agents read and write files here — no state passes through conversation history.

```
posts/{slug}/
├── draft.md                      # prose — writer reads/writes
├── brief.md                      # locked during active iteration (read-only flag in state.json)
├── meta.json                     # schema_version, title, slug, profile_id, keywords[], meta_description, draft_status, created_at, updated_at
├── scores.json                   # schema_version, iteration, timestamp, aggregate_score, seo{}, hook{}, voice{}, readability{}
├── scoring-config.json           # weights per-workspace (user-editable)
├── state.json                    # current_iteration, locked_brief, last_updated
├── session.json                  # profile_id, checkpoint, brief_answered, wireframe_approved, created_at
├── seo-eval.json                 # raw agent output — overwrite each iteration
├── hook-eval.json
├── voice-eval.json
├── readability-eval.json
│                                 # eval agents write atomically (tmp → rename); presence = complete
├── distribution.json             # x_hook, linkedin_opener, email_subject, newsletter_blurb, draft_hash
└── iterations.log                # append-only — last 3 full, older summarised
```

### Profile storage

```
.draftloom/
├── config.json                   # { storage_mode: "project|global", storage_path, version, created_at }
└── profiles/
    └── {name}.json               # voice profile (see schema below)
```

Default: project-local `.draftloom/`. Alternative: user-global `~/.draftloom/`. Configured during first setup run.

---

## Skills

### setup (`/draftloom:setup`)

**Trigger phrases:** "draftloom setup", "create a blog profile", "new writing profile", "set up my blog voice", "draftloom new profile"

**Flow:**
1. Check `.draftloom/profiles/` — if profiles exist, offer: create new / edit existing / delete
2. **Edit mode** (`/draftloom:setup edit {name}`): load profile, show current field values, allow single-field or multi-field update, save delta
3. **Create mode**: ask 3 essential questions (one at a time):
   - Profile name (slug format, e.g. `george-personal`)
   - Target audience (free text)
   - Tone (3–5 adjectives or pick from presets: authoritative · conversational · technical · witty · direct · inspirational)
4. Save to `.draftloom/profiles/{name}.json` immediately
5. Confirm saved. Show 6 deferred fields available via `/draftloom:setup edit {name}` (blog URL, pillars, channels, length preference, inspiration, CTA goal)

**Profile JSON schema:**
```json
{
  "id": "george-personal",
  "blog_name": "George's Build Log",
  "blog_url": "https://george.dev",
  "audience": "indie hackers and frontend developers",
  "audience_expertise": "intermediate",
  "tone": ["direct", "opinionated", "technical", "slightly irreverent"],
  "pillars": ["AI tooling", "frontend architecture", "building in public"],
  "channels": ["own blog", "X", "LinkedIn"],
  "typical_length": "medium",
  "inspiration": ["Paul Graham", "Dan Luu"],
  "cta_goal": "newsletter subscribe",
  "language": "en",
  "seo_default_keywords": [],
  "brand_voice_examples": [
    { "source": "local_file|url|inline", "value": "path/or/url/or/text", "context": "Example of my opinionated tone" }
  ],
  "storage": "project",
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:00:00Z"
}
```

---

### draft (`/draftloom:draft`)

**Trigger phrases:** "draftloom draft", "write a blog post", "start a new post", "I want to write a post", "help me write a blog post", "draft a blog post"

**Flow:**

**1. Profile selection**
- If no profiles: prompt to run `/draftloom:setup` first
- If one profile: confirm and use it
- If multiple profiles: show tiered list (recent first with draft count + last-used date, then all others; user types number or search string)

**2. Brief interview** (one question at a time)

Mandatory (4 questions):
- What's the topic or angle?
- What's the one insight the reader should leave with?
- Any specific examples, data, or stories to include?
- Target length? (short ~500w / medium ~1000w / long ~2000w+)

Optional SEO/timing opt-in (offered after mandatory):
- Primary keyword?
- Competitor posts to beat? (URLs)
- Target publish date?

Brief saved to `brief.md` (9 fields: Topic, Insight, Audience, Tone, Examples, Length, Key Messages, CTA, Constraints).

**3. Wireframe layout proposal**

Orchestrator proposes numbered section outline in terminal:
```
① Hook           ~120w  — bold claim + surprising stat
② Problem setup  ~200w  — agitate the pain
③ Core insight   ~350w  — the non-obvious perspective
④ Evidence       ~250w  — stories, data, code
⑤ CTA            ~80w   — one clear ask

Total: ~1000w (matches your medium preference)
Tweaks? (e.g. "change 3 to 500w", "add section between 1 and 2: backstory 150w", "remove 4")
```

Parse-able commands applied, word count validated against profile.typical_length, delta shown before confirming. `wireframe_approved: true` written to `session.json`.

**4. Draft → eval loop**

See Eval Loop section below.

**5. Distribution**

On all-pass or user halt, distribution agent runs → writes `distribution.json`.
Final output:
```
✓ Draft complete: posts/why-ai-tooling-matters/
  draft.md       — your post
  distribution.json — X hook · LinkedIn · email subject · newsletter blurb
  scores.json    — final eval scores
```

---

### eval (`/draftloom:eval`)

**Trigger phrases:** "draftloom eval", "score my post", "evaluate this blog post", "check my draft"

**Flow:**
1. Ask for path to existing markdown file
2. Ask which profile to score against (or "none" for generic)
3. Create temporary workspace `posts/{slug}/` with provided `draft.md`
4. Call orchestrator in eval-only mode (skip brief, skip writing phase)
5. Run 4 eval agents → show scored report with sections_affected and suggestions
6. Offer: "Patch failing dimensions? (y/n)" → if yes, dispatch writer agent

---

## Agents

### orchestrator.md

Owns the entire eval loop. The draft SKILL.md delegates to it after wireframe approval.

**Responsibilities:**
- Iteration 1: dispatch writer with brief only (no eval context yet)
- Wait for `draft.md` to be written (poll with timeout)
- Dispatch all 4 eval agents in parallel
- Poll for all 4 `*-eval.json` files to exist (agents write atomically via tmp→rename — presence signals completion)
- Validate each `*-eval.json` against eval-output-spec.md schema (abort if malformed)
- Aggregate into `scores.json`
- Decide: patch / escalate / pass / halt
- On subsequent iterations: dispatch writer with `scores.json` + all `*-eval.json` files as context
- On all-pass or halt: dispatch distribution agent

**User communication events:**
```
ITERATION_START:  "Iteration N of 3 — running 4 evals..."
EVAL_COMPLETE:    "✓ SEO (78) · ✓ Hook (85) · ⚠ Voice (68) · ✓ Readability (80)"
PATCH_START:      "Patching: voice match in [intro, body_para_2]..."
ITERATION_END:    Show delta vs previous iteration
LOOP_END:         "All dimensions passing. Generating distribution copy..."
```

**Halt detection:** If user types "finalize", "publish now", or "skip iterations" mid-loop, orchestrator dispatches distribution immediately with current draft.

**Retry logic:** Each agent gets 3 retries with exponential backoff (30s timeout per attempt). If all retries fail, skip that dimension and log warning.

---

### writer.md

**Reads:** `brief.md` + `scores.json` (if iteration > 1) + `draft.md` (if iteration > 1) + all `*-eval.json` files (if available)

**Iteration 1:** Write full draft from brief only. Eval files do not exist — skip gracefully.

**Iteration 2+:** Read `sections_affected` from each `*-eval.json`. Patch only those sections. Preserve all other paragraphs verbatim. Never restructure passing sections.

**Context window management:** Read only last 3 entries from `iterations.log`. Summarise older entries if needed.

**Writes:** `draft.md`, appends to `iterations.log`

---

### seo-eval.md / hook-eval.md / voice-eval.md / readability-eval.md

Each agent follows the same output contract (eval-output-spec.md):

```json
{
  "schema_version": "1.0",
  "agent": "seo-eval",
  "iteration": 2,
  "timestamp": "2026-04-15T10:30:00Z",
  "score": 78,
  "feedback": "Keyword density improved. Meta description still too generic.",
  "sections_affected": ["meta_description"],
  "suggestion_type": "enhance",
  "specifics": {
    "keyword_coverage": { "primary": "2.1%", "secondary": "1.2%" },
    "recommend": "Rewrite meta description to include primary keyword and value prop"
  }
}
```

Writes to its own file (`seo-eval.json` etc) — no shared writes, no race conditions. Overwrites each iteration (latest only). Uses atomic write (tmp → rename) so orchestrator can rely on file presence as a completion signal.

**Dimension rubrics:**
- **SEO:** keyword density 1–3%, meta description completeness, heading hierarchy (H1→H2→H3), Flesch readability ≥60, internal link suggestions
- **Hook:** first-sentence novelty, curiosity gap, title specificity (numbers/concrete claims), scroll-stop power
- **Voice:** tone adjective match vs profile, sentence rhythm, vocabulary range, brand_voice_examples comparison (loads by source type: local_file / url / inline)
- **Readability:** paragraph length ≤4 sentences, subheading every 300w, bullet/list distribution, sentence length variance

---

### distribution.md

**Precondition:** All 4 eval dimensions ≥ 75, or explicit halt signal from orchestrator.

**Reads:** `draft.md` (final), `meta.json`, profile JSON

**Writes:** `distribution.json`

```json
{
  "draft_hash": "sha256:...",
  "x_hook": "...",
  "linkedin_opener": "...",
  "email_subject": "...",
  "newsletter_blurb": "..."
}
```

**Platform constraints (enforced, not truncated — agent re-generates if over limit):**
- `x_hook`: ≤280 chars, no links
- `linkedin_opener`: ≤300 chars, professional tone
- `email_subject`: ≤60 chars
- `newsletter_blurb`: ≤150 words, conversational

**Staleness check:** If `draft.md` changes after `distribution.json` is written (hash mismatch), orchestrator re-runs distribution agent.

---

## Eval Loop Rules

### Scoring

```
aggregate_score = min(seo_score, hook_score, voice_score, readability_score)
```

Minimum (not average) — no dimension can be papered over by a strong score elsewhere.

**Default weights in `scoring-config.json` (per-workspace, user-editable):**
```json
{ "seo": 0.35, "hook": 0.30, "voice": 0.25, "readability": 0.10 }
```
Weights are used for display/trend purposes only. Pass criteria is purely per-dimension threshold.

**Routing:**
| Score | Action |
|-------|--------|
| any dimension < 50 | Escalate to user (max 1× per run). Pause loop. Ask 4 structured questions. If user declines, set `draft_status: "paused"` and exit. |
| any dimension 50–74 | Dispatch writer agent. Patch `sections_affected` only. |
| all dimensions ≥ 75 | Pass. Dispatch distribution agent. |

**Max iterations:** 3. When reached, offer:
1. Publish anyway (dispatch distribution with current draft)
2. Extend by N more iterations
3. Discard (set `draft_status: "abandoned"`)

---

## Session Recovery

`session.json` tracks checkpoint at each major milestone. On `/draftloom:draft {slug}`:
- If incomplete session detected: "Found incomplete draft: '{slug}' (checkpoint: eval_loop_start). Resume? (y/n)"
- Recovery uses `state.json` iteration counter + `iterations.log` to reconstruct last good state
- If `session.json` is corrupted: fallback to `iterations.log` replay, then ask user to restart if unrecoverable

---

## Backend: Hybrid File + Turso

**Default (v1):** File-based workspace (`posts/{slug}/`). Zero dependencies. Works everywhere. Git-trackable.

**Optional (Turso MCP):** If `.draftloom/config.json` has `turso_enabled: true` + API key, agents write to Turso as secondary persistence. File system remains primary source of truth. Turso failure is logged but never blocks iteration.

**Turso tables (when enabled):**
- `posts`: id, slug, profile_id, title, draft_status, latest_aggregate_score, timestamps
- `scores`: post_id, iteration, aggregate_score, seo, hook, voice, readability, timestamp
- `eval_events`: post_id, iteration, agent, score, feedback, sections_affected

See `references/turso-setup.md` for setup guide and MCP configuration.

---

## Hooks

**SessionStart (`hooks/hooks.json`):**
- Check `.draftloom/profiles/` exists and has at least one profile
- If no profiles found: print one-line hint — "No Draftloom profiles found. Run `/draftloom:setup` to create your first writing profile."
- If profiles found: silent (no noise on every session open)

---

## v1 vs v2 Boundary

**Ships in v1:**
- 3-skill + 7-agent plugin with full eval loop
- 3Q setup → named profile.json
- 4-question brief + parse-able wireframe
- Writer → 4-eval → patch loop (max 3 iterations)
- distribution.json generation with platform limits
- File-based workspace with session recovery
- Profile edit field-by-field
- halt/finalize mid-loop ("finalize", "publish now", "skip iterations")
- Turso as optional reference (setup doc + backend flag)

**Deferred to v2+:**
- Style extraction from existing blog posts → auto-populates brand_voice_examples
- Interactive drag-drop wireframe (browser-based, local server)
- SERP/competitor research agent (pre-draft outline validation)
- E-E-A-T validation agent (Google 2025 guidelines)
- Fact-check / citation verification agent
- Sentiment / emotional resonance eval
- Visual content recommendations with placements
- Workspace file locking for concurrent sessions
- Performance feedback loop (post analytics → profile learning)
- Global ~/.draftloom cloud sync

---

## File Count Summary

| Type | Count | Notes |
|------|-------|-------|
| Skills (SKILL.md) | 3 | setup · draft · eval |
| Reference docs | 11 | 3 in setup + 7 in draft + 1 in eval |
| Agents | 7 | orchestrator · writer · 4 evals · distribution |
| Plugin manifest + hooks | 2 | plugin.json · hooks.json |
| **Total plugin files (static)** | **23** | |
| Workspace files per post (runtime) | 13 | created fresh per post, not shipped |

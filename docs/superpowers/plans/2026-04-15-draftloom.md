# Draftloom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create all 23 static plugin files that make Draftloom work — plugin manifest, 3 skills with reference docs, 7 agents, and 1 hook config.

**Architecture:** Pure-document plugin. No application code. Every file is Markdown or JSON that Claude Code loads into context at runtime. Skills orchestrate agents. Agents communicate through a structured file workspace (`posts/{slug}/`). All state lives on the filesystem — no conversation history passing.

**Tech Stack:** Claude Code plugin system, JSON manifests, Markdown skill/agent definitions, Gherkin acceptance criteria in `docs/plugins/draftloom/specs/`

---

## File map

Files to create (all inside `plugins/draftloom/`):

```
.claude-plugin/plugin.json           — manifest: skills[], agents[], hooks
hooks/hooks.json                     — SessionStart: profile check + hint
skills/setup/SKILL.md                — /draftloom:setup workflow
skills/setup/references/
  interview-questions.md             — 3 essential Qs + 6 deferred
  profile-schema.md                  — full JSON schema + validation rules
  storage-guide.md                   — project vs global ~/.draftloom/
skills/draft/SKILL.md                — /draftloom:draft workflow
skills/draft/references/
  brief-questions.md                 — 4 mandatory Qs + SEO opt-in
  layout-templates.md                — section templates + wireframe editor rules
  workspace-schema.md                — ★ complete file contract for all agents
  scoring-rubric.md                  — thresholds, routing, aggregate calc
  eval-output-spec.md                — standardised eval JSON schema
  distribution-guide.md              — platform copy templates + char limits
  turso-setup.md                     — optional Turso MCP backend
skills/eval/SKILL.md                 — /draftloom:eval workflow
skills/eval/references/
  eval-guide.md                      — eval-only mode via orchestrator
agents/orchestrator.md               — ★ owns eval loop, aggregates, decides
agents/writer.md                     — drafts + patches prose
agents/seo-eval.md                   — keyword, meta, heading analysis
agents/hook-eval.md                  — first sentence, title, curiosity gap
agents/voice-eval.md                 — tone match, rhythm, vocabulary
agents/readability-eval.md           — paragraph length, subheadings, scan
agents/distribution.md               — platform copy generator
```

---

## Task 1: Plugin manifest

**Files:**
- Create: `plugins/draftloom/.claude-plugin/plugin.json`

- [ ] **Step 1: Create the manifest**

```json
{
  "name": "draftloom",
  "version": "0.1.0",
  "author": "neotherapper",
  "description": "AI-powered blog post drafting. Write in your voice, optimised for virality.",
  "skills": [
    {
      "name": "setup",
      "command": "/draftloom:setup",
      "description": "This skill should be used when the user asks to create a writing profile, set up their blog voice, create a new blog profile, or edit an existing profile."
    },
    {
      "name": "draft",
      "command": "/draftloom:draft",
      "description": "This skill should be used when the user asks to write a blog post, draft a post, start a new post, help me write a blog post, or draftloom draft."
    },
    {
      "name": "eval",
      "command": "/draftloom:eval",
      "description": "This skill should be used when the user asks to score a post, evaluate a blog post, check a draft, or run draftloom eval."
    }
  ],
  "agents": [
    { "name": "orchestrator", "description": "Owns the eval loop — dispatches all agents, aggregates scores, decides next action." },
    { "name": "writer", "description": "Drafts full posts on iteration 1 and patches sections_affected on iteration 2+." },
    { "name": "seo-eval", "description": "Scores keyword density, meta description, heading hierarchy, and Flesch readability." },
    { "name": "hook-eval", "description": "Scores first-sentence novelty, curiosity gap, title specificity, and scroll-stop power." },
    { "name": "voice-eval", "description": "Scores tone adjective match, sentence rhythm, vocabulary, and brand voice example alignment." },
    { "name": "readability-eval", "description": "Scores paragraph length, subheading frequency, bullet distribution, and sentence length variance." },
    { "name": "distribution", "description": "Generates X hook, LinkedIn opener, email subject, and newsletter blurb from the final draft." }
  ],
  "hooks": {
    "SessionStart": "hooks/hooks.json"
  }
}
```

- [ ] **Step 2: Verify manifest is valid JSON**

```bash
cd plugins/draftloom && cat .claude-plugin/plugin.json | python3 -c "import sys,json; json.load(sys.stdin); print('valid')"
```

Expected: `valid`

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/.claude-plugin/plugin.json
git commit -m "feat(draftloom): add plugin.json manifest"
```

---

## Task 2: SessionStart hook

**Files:**
- Create: `plugins/draftloom/hooks/hooks.json`

- [ ] **Step 1: Create the hook config**

```json
{
  "SessionStart": {
    "action": "check-profiles",
    "check_path": ".draftloom/profiles/",
    "hint_when_empty": "No Draftloom profiles found. Run `/draftloom:setup` to create your first writing profile.",
    "silent_when_found": true
  }
}
```

- [ ] **Step 2: Verify against setup.feature**

Open `docs/plugins/draftloom/specs/setup.feature` and check the scenario:
> "SessionStart hook hints setup when no profiles exist"

Confirm the hint message in `hooks.json` matches the expected output in the feature file exactly.

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/hooks/hooks.json
git commit -m "feat(draftloom): add SessionStart hook"
```

---

## Task 3: Setup SKILL.md

**Files:**
- Create: `plugins/draftloom/skills/setup/SKILL.md`

- [ ] **Step 1: Write the setup skill**

```markdown
---
name: setup
command: /draftloom:setup
description: "This skill should be used when the user asks to create a writing profile, set up their blog voice, create a new blog profile, or run draftloom setup."
version: "0.1.0"
references:
  - references/interview-questions.md
  - references/profile-schema.md
  - references/storage-guide.md
---

# Draftloom Setup Skill

Guides the user through creating or editing a named voice profile for blog post drafting.

## Entry point

On invocation, check `.draftloom/profiles/` for existing profile files.

### If no profiles directory or directory is empty

Proceed directly to Create mode (Step 2 below).

### If profiles exist

Present three options:
1. Create a new profile
2. Edit an existing profile (list profile names)
3. Delete a profile (list profile names, ask for confirmation)

Wait for the user's choice before proceeding.

---

## Edit mode (`/draftloom:setup edit {name}` or user chooses option 2)

Load the profile JSON from `.draftloom/profiles/{name}.json`.

Show current values for all fields. Ask the user which field(s) to update. Apply each change one at a time, confirming the new value before saving.

Save the updated profile to the same path. Confirm: "Profile '{name}' updated."

Load `references/profile-schema.md` to validate field formats before saving.

---

## Create mode (no profiles exist, or user chooses option 1)

Ask the following 3 essential questions **one at a time**. Wait for the answer to each before asking the next.

Load `references/interview-questions.md` for the exact question wording and validation rules.

### Question 1 — Profile name

Ask for a profile name (slug format, e.g. `george-personal`). Validate: lowercase, hyphens only, no spaces, no special characters. If invalid, explain and re-ask.

### Question 2 — Target audience

Ask: "Who is your target reader? (e.g. indie hackers, senior engineers, marketing managers)"

Accept free text. No validation required.

### Question 3 — Tone

Ask: "How would you describe your writing tone? Choose 3–5 adjectives, or pick from these presets:
- authoritative
- conversational
- technical
- witty
- direct
- inspirational

You can mix presets and your own words."

Accept a list of 3–5 adjectives. If fewer than 3, ask for at least one more.

---

## Save profile

Construct the profile JSON using the 3 collected answers. Set all deferred fields to `null`. Load `references/profile-schema.md` for the full schema.

Determine storage path:
- Check if `.draftloom/config.json` exists. If `storage_mode: "global"`, write to `~/.draftloom/profiles/{name}.json`.
- Otherwise write to `.draftloom/profiles/{name}.json`.

Load `references/storage-guide.md` if the user asks about storage options.

Write the profile JSON. Confirm: "Profile '{name}' saved to `.draftloom/profiles/{name}.json`."

---

## Post-save: deferred fields hint

After confirming save, show:

```
Profile created. Optional extras you can add later with `/draftloom:setup edit {name}`:
  • Blog URL
  • Content pillars (topic clusters)
  • Distribution channels
  • Typical post length preference
  • Writing inspiration (authors, publications)
  • CTA goal (newsletter, follow, contact)
  • Brand voice examples (local file, URL, or inline text)
```

---

## Delete mode (user chooses option 3)

List profiles. Ask which to delete. Ask for confirmation: "Delete '{name}'? This cannot be undone. (y/n)". On confirmation, remove the file. Confirm deletion.
```

- [ ] **Step 2: Verify against setup.feature**

Check these scenarios are covered by the skill:
- "First-time user with no profiles" → goes to Create mode
- "Profile name validation" → slug format enforced
- "Tone presets offered" → presets listed in Question 3
- "Profile saved to correct path" → path logic handled
- "Edit mode updates a single field" → Edit mode covers this

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/setup/SKILL.md
git commit -m "feat(draftloom): add setup SKILL.md"
```

---

## Task 4: Setup references

**Files:**
- Create: `plugins/draftloom/skills/setup/references/interview-questions.md`
- Create: `plugins/draftloom/skills/setup/references/profile-schema.md`
- Create: `plugins/draftloom/skills/setup/references/storage-guide.md`

- [ ] **Step 1: Write interview-questions.md**

```markdown
# Interview Questions — Setup

Reference for the setup skill. Load this file when running the 3-question interview.

## Essential questions (asked every time)

### Q1 — Profile name
"What would you like to call this profile? Use a short slug like `george-personal` or `vanguard-corporate`."

Validation rules:
- Lowercase only
- Hyphens allowed, no spaces, no special characters
- 3–40 characters
- Must not conflict with an existing profile name

### Q2 — Target audience
"Who is your target reader? Be specific — their role, seniority, and what they care about."

Examples:
- "indie hackers building their first SaaS"
- "senior frontend engineers at enterprise companies"
- "marketing managers at B2B software companies"

Validation: free text, 10–200 characters.

### Q3 — Tone
"How would you describe your writing tone? Pick 3–5 adjectives."

Presets to offer:
- authoritative — you state things confidently, no hedging
- conversational — you write like you talk, casual and warm
- technical — you go deep on implementation detail
- witty — you use humour and wordplay to make points land
- direct — you cut to the point fast, no preamble
- inspirational — you motivate, challenge, and energise

Accept: presets only, custom adjectives only, or a mix. Minimum 3, maximum 5.

---

## Deferred questions (surfaced after profile creation, or in edit mode)

### Q4 — Blog URL
"What's the URL of your blog or publication?" (optional, for distribution link attribution)

### Q5 — Content pillars
"What are your 2–4 main topic areas?" (used to suggest post angles)

### Q6 — Distribution channels
"Where do you typically publish? (e.g. own blog, X, LinkedIn, newsletter)" (shapes distribution copy)

### Q7 — Typical post length
"How long are your posts usually? short (~500w) / medium (~1000w) / long (~2000w+)" (default wireframe sizing)

### Q8 — Writing inspiration
"Who writes in a style you admire? (authors, newsletters, publications)" (informs voice-eval comparisons)

### Q9 — CTA goal
"What's the main action you want readers to take?" (e.g. subscribe, follow, contact, share)
```

- [ ] **Step 2: Write profile-schema.md**

```markdown
# Profile Schema

Full JSON schema for a voice profile. Load this file when constructing or validating a profile.

## Full schema

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
    {
      "source": "local_file",
      "value": "posts/my-best-post/draft.md",
      "context": "My most-shared post — this is the tone to match"
    },
    {
      "source": "url",
      "value": "https://george.dev/writing/example",
      "context": "Opinionated take format I use often"
    },
    {
      "source": "inline",
      "value": "Here's the thing nobody talks about: ...",
      "context": "My opening sentence pattern"
    }
  ],
  "storage": "project",
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:00:00Z"
}
```

## Field reference

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | slug format, unique per storage location |
| `blog_name` | string | no | display name for UI |
| `blog_url` | string | no | used in distribution copy |
| `audience` | string | yes | free text, collected in Q2 |
| `audience_expertise` | string | no | beginner / intermediate / advanced |
| `tone` | string[] | yes | 3–5 adjectives, collected in Q3 |
| `pillars` | string[] | no | 2–4 topic areas |
| `channels` | string[] | no | distribution channels |
| `typical_length` | string | no | short / medium / long |
| `inspiration` | string[] | no | author or publication names |
| `cta_goal` | string | no | desired reader action |
| `language` | string | no | BCP-47 language code, default "en" |
| `seo_default_keywords` | string[] | no | pre-loaded into each brief |
| `brand_voice_examples` | object[] | no | local_file / url / inline |
| `storage` | string | yes | "project" or "global" |
| `created_at` | string | yes | ISO-8601 |
| `updated_at` | string | yes | ISO-8601 |

## Null fields

All deferred fields not collected during setup must be written as `null` (not omitted). This ensures the schema is always complete and agents can check field presence reliably.

## brand_voice_examples loading

When voice-eval loads brand_voice_examples:
- `local_file`: read the file at `value` path (relative to project root)
- `url`: fetch the URL content (text/plain or HTML, strip tags)
- `inline`: use `value` directly as text

If a source fails to load, log a warning and skip that example. Do not abort evaluation.
```

- [ ] **Step 3: Write storage-guide.md**

```markdown
# Storage Guide

Reference for where Draftloom profiles and config are stored.

## Storage modes

### Project mode (default)
Profiles live inside the current project directory:
```
{project-root}/
└── .draftloom/
    ├── config.json
    └── profiles/
        └── {name}.json
```

Use project mode when:
- You have one persona per project
- You want profiles committed to git alongside the project
- You want isolation between different clients or brands

### Global mode
Profiles live in the user's home directory:
```
~/.draftloom/
├── config.json
└── profiles/
    └── {name}.json
```

Use global mode when:
- You write with the same voice across many projects
- You don't want profiles in your project git repo

## config.json schema

```json
{
  "storage_mode": "project",
  "storage_path": ".draftloom",
  "version": "0.1.0",
  "created_at": "2026-04-15T10:00:00Z"
}
```

## First-run behaviour

On first setup run, if `.draftloom/config.json` does not exist:
- Create `.draftloom/config.json` with `storage_mode: "project"`
- Do NOT ask the user about storage during setup (deferred)
- If user asks about storage, load this guide and explain the options

## Switching modes

To switch from project to global after setup:
1. Copy profiles from `.draftloom/profiles/` to `~/.draftloom/profiles/`
2. Update `.draftloom/config.json` → `storage_mode: "global"`
3. Optionally delete `.draftloom/profiles/` from the project
```

- [ ] **Step 4: Commit**

```bash
git add plugins/draftloom/skills/setup/references/
git commit -m "feat(draftloom): add setup reference docs"
```

---

## Task 5: Draft SKILL.md

**Files:**
- Create: `plugins/draftloom/skills/draft/SKILL.md`

- [ ] **Step 1: Write the draft skill**

```markdown
---
name: draft
command: /draftloom:draft
description: "This skill should be used when the user asks to write a blog post, draft a post, start a new post, help me write a blog post, or run draftloom draft."
version: "0.1.0"
references:
  - references/brief-questions.md
  - references/layout-templates.md
  - references/workspace-schema.md
  - references/scoring-rubric.md
  - references/eval-output-spec.md
  - references/distribution-guide.md
  - references/turso-setup.md
---

# Draftloom Draft Skill

Orchestrates the full blog post workflow: profile selection → brief interview → wireframe → eval loop → distribution.

## Entry point: session recovery check

Before anything else, check for existing `session.json` files in `posts/*/session.json` where `draft_status` is not `published` or `abandoned`.

If an incomplete session is found:
- Show: "Found incomplete draft: '{title}' (checkpoint: {checkpoint}). Resume? (y/n)"
- If yes: load `state.json` and `session.json`, skip to the appropriate checkpoint step below
- If no: proceed with a new draft

---

## Step 1: Profile selection

Check `.draftloom/profiles/` (and `~/.draftloom/profiles/` if config.json has `storage_mode: "global"`).

**No profiles found:**
Show: "No profiles found. Run `/draftloom:setup` to create your first writing profile." Stop.

**One profile found:**
Show profile name and confirm: "Using profile '{name}'. Continue? (y/n)"

**Multiple profiles found:**
Show a tiered list. Recent profiles (used in last 30 days) appear first with their last-used date and draft count. All others listed below. User types a number or search string to select.

Write selected `profile_id` to `session.json` → checkpoint: `profile_selected`.

---

## Step 2: Brief interview

Load `references/brief-questions.md` for exact question wording.

Ask the 4 mandatory questions **one at a time**. Wait for each answer before asking the next.

After the 4 mandatory questions, offer: "Would you like to add SEO targeting, competitor reference URLs, or a publish date? (y/n)"

If yes, ask the 3 optional questions from brief-questions.md.

Generate a slug from the post topic (lowercase, hyphens, max 50 chars). Check if `posts/{slug}/` already exists. If it does, append a short suffix (e.g. `-2`).

Create workspace directory `posts/{slug}/`. Load `references/workspace-schema.md` for the full file contract.

Write `brief.md` with all answers. Write `meta.json` with title (derived from topic), slug, profile_id, draft_status: "drafting", timestamps.

Write `session.json` → checkpoint: `brief_complete`, brief_answered: true.

Set `state.json` → current_iteration: 0, locked_brief: true.

---

## Step 3: Wireframe layout

Load `references/layout-templates.md` for section templates.

Propose a numbered section outline based on the brief topic, insight, and target length. Display in terminal in this format:

```
① Hook           ~120w  — bold claim + surprising stat
② Problem setup  ~200w  — agitate the pain
③ Core insight   ~350w  — the non-obvious perspective
④ Evidence       ~250w  — stories, data, code
⑤ CTA            ~80w   — one clear ask

Total: ~1000w (matches your medium preference)
Tweaks? (e.g. "change 3 to 500w", "add backstory between 1 and 2: 150w", "remove 4")
```

Accept parse-able edit commands. Apply each edit, recompute total word count, show updated wireframe. Validate total against profile `typical_length` (short: 300–700w, medium: 700–1500w, long: 1500–3000w). Warn if significantly over or under.

Ask: "Looks good?" When confirmed, write wireframe to `brief.md` (append as Sections block).

Write `session.json` → checkpoint: `wireframe_approved`, wireframe_approved: true.

---

## Step 4: Delegate to orchestrator

Dispatch `agents/orchestrator.md` with context:
- Path to `posts/{slug}/`
- Profile JSON path
- Mode: "full_draft" (writer runs first, then eval loop)

The orchestrator owns all further steps. This skill waits for the orchestrator to signal completion.

Load `references/scoring-rubric.md` to understand the routing logic if the orchestrator asks for a user decision (halt, escalate).

---

## Step 5: Post-completion output

When orchestrator signals `loop_end`, display:

```
✓ Draft complete: posts/{slug}/
  draft.md          — your post
  distribution.json — X hook · LinkedIn opener · email subject · newsletter blurb
  scores.json       — final eval scores
```

Load `references/distribution-guide.md` to format the distribution copy display correctly.

If Turso is enabled (check `.draftloom/config.json`), load `references/turso-setup.md` to verify post data was synced.
```

- [ ] **Step 2: Verify against draft.feature**

Check these scenario groups are covered:
- Profile selection (no profiles, one profile, multiple profiles, recent first)
- Brief interview (4 mandatory, 3 optional, brief.md written)
- Wireframe (proposal format, parse-able edits, word count validation, confirmation)
- Session recovery (incomplete session detected, checkpoint resume)
- Delegation to orchestrator

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/draft/SKILL.md
git commit -m "feat(draftloom): add draft SKILL.md"
```

---

## Task 6: Draft references — brief and layout

**Files:**
- Create: `plugins/draftloom/skills/draft/references/brief-questions.md`
- Create: `plugins/draftloom/skills/draft/references/layout-templates.md`

- [ ] **Step 1: Write brief-questions.md**

```markdown
# Brief Questions

Questions asked during the draft brief interview. Load this file during Step 2 of the draft skill.

## Mandatory questions (4) — ask in order

### Q1 — Topic and angle
"What's the topic or angle for this post? Be specific — what's the take or twist that makes it worth writing?"

Examples:
- "Why I stopped using React Query and went back to fetch"
- "The hidden cost of 'free' AI APIs for startups"
- "How I went from 0 to 500 newsletter subscribers in 60 days"

Validation: free text, 20–200 characters. If too vague (e.g. "AI"), probe: "What's the specific angle or opinion?"

### Q2 — Core insight
"What's the one insight you want the reader to leave with? If they forget everything else, what's the sentence that stays?"

Validation: free text, 20–300 characters. This becomes the post's thesis and informs hook scoring.

### Q3 — Examples, data, stories
"Any specific examples, data points, or stories to include? (optional — press Enter to skip)"

Validation: free text or empty. If the user provides URLs, treat them as reference material for the writer agent.

### Q4 — Target length
"How long should this post be?
  short  — ~500 words (opinion, quick take)
  medium — ~1000 words (how-to, explainer)
  long   — ~2000+ words (deep dive, case study)"

Accept: "short", "medium", "long", or a word count like "800 words". Normalise to short/medium/long for the wireframe.

---

## Optional questions (3) — offer as a group after mandatory

### Q5 — Primary keyword (SEO)
"What's the primary keyword you want to rank for? (e.g. 'react state management')"

Stored in `meta.json` → keywords[0]. Used by seo-eval.

### Q6 — Competitor posts to beat
"Any competitor posts you want to outrank or write a better version of? Paste URLs (one per line, or press Enter to skip)"

Stored in `brief.md` → Competitor URLs. Writer agent uses these as style/depth references.

### Q7 — Target publish date
"Do you have a target publish date?" (optional, used for scheduling context only)

---

## brief.md format

Write all answers in this format to `posts/{slug}/brief.md`:

```markdown
# Brief: {Title}

**Topic:** {Q1 answer}
**Insight:** {Q2 answer}
**Audience:** {from profile.audience}
**Tone:** {from profile.tone, joined by commas}
**Examples:** {Q3 answer or "none provided"}
**Length:** {short/medium/long}
**Key Messages:** {derived from Q1 and Q2 by the skill}
**CTA:** {from profile.cta_goal}
**Constraints:** {any hard constraints mentioned by user}

## Optional
**Primary keyword:** {Q5 or null}
**Competitor URLs:** {Q6 urls or null}
**Publish date:** {Q7 or null}

## Sections
{wireframe block appended after Step 3}
```
```

- [ ] **Step 2: Write layout-templates.md**

```markdown
# Layout Templates

Section templates and wireframe editor rules. Load this file during Step 3 of the draft skill.

## Standard section types

| Section | Purpose | Typical word range |
|---------|---------|-------------------|
| Hook | Bold claim + surprising stat or provocative question | 80–150w |
| Problem setup | Agitate the pain — make the reader feel it | 150–250w |
| Core insight | The non-obvious perspective or key thesis | 250–500w |
| Evidence | Stories, data, code examples, case studies | 200–400w |
| How-to / Steps | Numbered actionable steps (if applicable) | 100–200w per step |
| Counterpoint | Address the obvious objection | 100–200w |
| Backstory | Personal narrative or context | 100–200w |
| CTA | One clear ask — subscribe, follow, share, contact | 60–120w |

## Default wireframes by length

### Short (~500w)
```
① Hook           ~100w
② Core insight   ~250w
③ CTA            ~80w
```

### Medium (~1000w)
```
① Hook           ~120w
② Problem setup  ~200w
③ Core insight   ~350w
④ Evidence       ~250w
⑤ CTA            ~80w
```

### Long (~2000w)
```
① Hook           ~150w
② Problem setup  ~200w
③ Core insight   ~400w
④ Evidence       ~500w
⑤ How-to         ~400w
⑥ Counterpoint   ~200w
⑦ CTA            ~100w
```

## Parse-able wireframe edit commands

Accept these natural language commands during wireframe review:

| Command pattern | Example | Effect |
|----------------|---------|--------|
| "change {N} to {X}w" | "change 3 to 500w" | Update section N word count |
| "add {name} between {N} and {M}: {X}w" | "add backstory between 1 and 2: 150w" | Insert section |
| "remove {N}" | "remove 4" | Delete section N |
| "rename {N} to {name}" | "rename 3 to Framework" | Rename section |
| "swap {N} and {M}" | "swap 2 and 3" | Reorder sections |

After each edit command: recompute total word count, renumber sections, display updated wireframe.

## Word count validation

| Length target | Acceptable range |
|--------------|-----------------|
| short (~500w) | 300–700w |
| medium (~1000w) | 700–1500w |
| long (~2000w+) | 1500–3000w |

If total falls outside the range, warn: "This wireframe totals ~{X}w — {above/below} your {length} target. Continue anyway? (y/n)"
```

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/draft/references/brief-questions.md \
        plugins/draftloom/skills/draft/references/layout-templates.md
git commit -m "feat(draftloom): add brief-questions and layout-templates references"
```

---

## Task 7: Draft references — workspace schema (critical contract)

**Files:**
- Create: `plugins/draftloom/skills/draft/references/workspace-schema.md`

This is the most important reference file. Every agent reads this to know which files exist, who owns them, and what they contain.

- [ ] **Step 1: Write workspace-schema.md**

```markdown
# Workspace Schema

★ This is the source of truth for all files in `posts/{slug}/`. Every agent must read this before writing any file. No agent may create a file not listed here.

## Directory

```
posts/{slug}/
├── draft.md                — prose content of the post
├── brief.md                — locked brief (read-only once loop starts)
├── meta.json               — post metadata
├── scores.json             — aggregated scores per iteration
├── scoring-config.json     — per-workspace score weights (user-editable)
├── state.json              — current iteration and loop status
├── session.json            — checkpoint for session recovery
├── seo-eval.json           — SEO eval agent output (latest iteration)
├── hook-eval.json          — hook eval agent output (latest iteration)
├── voice-eval.json         — voice eval agent output (latest iteration)
├── readability-eval.json   — readability eval agent output (latest iteration)
├── distribution.json       — platform-specific copy
└── iterations.log          — append-only audit trail
```

---

## File contracts

### draft.md
**Owner:** writer agent (writes and patches)
**Readers:** all eval agents, distribution agent, orchestrator (hash check)
**Format:** Markdown prose. No frontmatter. Section headings match wireframe section names.
**Notes:** Writer patches only sections listed in `sections_affected` on iteration 2+. All other content preserved verbatim.

---

### brief.md
**Owner:** draft skill (writes once after wireframe approval)
**Readers:** writer agent (reads on every iteration), orchestrator
**Format:** Markdown. See brief-questions.md for the exact structure.
**Notes:** `locked_brief: true` in state.json means this file must not be modified. Writer reads it as context only.

---

### meta.json
**Owner:** draft skill (creates), orchestrator (updates draft_status)
**Readers:** distribution agent, any agent needing post metadata
**Schema:**
```json
{
  "schema_version": "1.0",
  "title": "Why AI Tooling Matters Now",
  "slug": "why-ai-tooling-matters",
  "profile_id": "george-personal",
  "keywords": ["AI tooling", "developer tools"],
  "meta_description": null,
  "draft_status": "drafting",
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:30:00Z"
}
```
`draft_status` values: `drafting` · `iterating` · `passing` · `paused` · `abandoned` · `published`

---

### scores.json
**Owner:** orchestrator (writes after each iteration)
**Readers:** orchestrator (routing decisions), draft skill (final display)
**Schema:**
```json
{
  "schema_version": "1.0",
  "iteration": 2,
  "timestamp": "2026-04-15T10:45:00Z",
  "aggregate_score": 68,
  "seo": { "score": 78, "status": "pass" },
  "hook": { "score": 85, "status": "pass" },
  "voice": { "score": 68, "status": "fail" },
  "readability": { "score": 80, "status": "pass" }
}
```
`aggregate_score` = `min(seo, hook, voice, readability)`. Never the mean.

---

### scoring-config.json
**Owner:** draft skill (creates with defaults), user (may edit directly)
**Readers:** orchestrator (display/trend only — not used for pass/fail routing)
**Schema:**
```json
{
  "schema_version": "1.0",
  "weights": { "seo": 0.35, "hook": 0.30, "voice": 0.25, "readability": 0.10 }
}
```
Weights are cosmetic — pass criteria is always per-dimension threshold (75). Changing weights does not change routing.

---

### state.json
**Owner:** orchestrator (writes after each state change)
**Readers:** all agents, draft skill (recovery)
**Schema:**
```json
{
  "current_iteration": 2,
  "locked_brief": true,
  "last_updated": "2026-04-15T10:45:00Z"
}
```

---

### session.json
**Owner:** draft skill (creates and updates checkpoints)
**Readers:** draft skill (recovery check on entry)
**Schema:**
```json
{
  "profile_id": "george-personal",
  "slug": "why-ai-tooling-matters",
  "checkpoint": "wireframe_approved",
  "brief_answered": true,
  "wireframe_approved": true,
  "created_at": "2026-04-15T10:00:00Z"
}
```
Checkpoint values in order: `profile_selected` · `brief_complete` · `wireframe_approved` · `eval_loop_start` · `distribution_complete`

---

### seo-eval.json / hook-eval.json / voice-eval.json / readability-eval.json
**Owner:** each respective eval agent (overwrites each iteration)
**Readers:** orchestrator (aggregation, routing), writer (patch context)
**Write protocol:** Write to `{name}-eval.tmp` first, then rename to `{name}-eval.json`. File presence = write complete. Never write directly to the `.json` extension.
**Schema:** See eval-output-spec.md for the full contract.

---

### distribution.json
**Owner:** distribution agent
**Readers:** draft skill (final display)
**Schema:**
```json
{
  "schema_version": "1.0",
  "draft_hash": "sha256:abc123...",
  "x_hook": "...",
  "linkedin_opener": "...",
  "email_subject": "...",
  "newsletter_blurb": "..."
}
```
`draft_hash` is the SHA-256 of `draft.md` at the time distribution ran. If orchestrator detects the hash has changed (draft was patched after distribution ran), it re-runs the distribution agent.

---

### iterations.log
**Owner:** writer (appends on write), orchestrator (appends on score)
**Readers:** writer (context — last 3 entries only), orchestrator (recovery)
**Format:** Append-only plain text. One entry per action:
```
2026-04-15T10:00:00Z  ITERATION_1  writer    draft.md written (823w)
2026-04-15T10:05:00Z  ITERATION_1  seo-eval  score=78 sections_affected=["meta_description"]
2026-04-15T10:05:00Z  ITERATION_1  hook-eval score=85
2026-04-15T10:05:00Z  ITERATION_1  voice-eval score=68 sections_affected=["intro","body_para_2"]
2026-04-15T10:05:00Z  ITERATION_1  readability-eval score=80
2026-04-15T10:05:01Z  ITERATION_1  orchestrator aggregate=68 routing=patch
2026-04-15T10:10:00Z  ITERATION_2  writer    patched intro,body_para_2
```
Entries older than the last 3 full iterations are summarised in-place by the orchestrator ("Summarised N earlier iterations"). Full entries preserved for last 3.
```

- [ ] **Step 2: Verify completeness**

Check: every file listed in the design spec workspace section has a contract in this file. Cross-reference with the workspace section of `docs/superpowers/specs/2026-04-15-draftloom-design.md`.

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/draft/references/workspace-schema.md
git commit -m "feat(draftloom): add workspace-schema (file contract)"
```

---

## Task 8: Draft references — scoring and eval spec

**Files:**
- Create: `plugins/draftloom/skills/draft/references/scoring-rubric.md`
- Create: `plugins/draftloom/skills/draft/references/eval-output-spec.md`

- [ ] **Step 1: Write scoring-rubric.md**

```markdown
# Scoring Rubric

Rules the orchestrator uses to route after each eval. Load this file in orchestrator.md.

## aggregate_score calculation

```
aggregate_score = min(seo_score, hook_score, voice_score, readability_score)
```

The minimum score across all dimensions. Never the average. No dimension can compensate for another.

## Routing table

| Condition | Action |
|-----------|--------|
| any dimension < 50 | **Escalate.** Pause loop. Ask user 4 structured questions (see below). Max 1 escalation per run. |
| any dimension 50–74 | **Patch.** Dispatch writer with failing eval JSONs. Writer patches `sections_affected` only. |
| all dimensions ≥ 75 | **Pass.** Dispatch distribution agent. |
| max iterations reached | **Offer choice.** See max-iterations section. |

## Escalation questions (when any dimension < 50)

Ask these 4 questions one at a time:
1. "The {dimension} score is {score}/100 — this usually means the {specific_issue}. Want to revise the brief? (y/n)"
2. If yes: "What should change? (topic angle / core insight / examples / length)"
3. "Should I restart with the revised brief, or patch what's there?"
4. If restart: unlock `locked_brief`, update `brief.md`, reset `current_iteration` to 0.

If user declines: set `draft_status: "paused"` in `meta.json`, exit loop.

## Pass threshold

Each dimension must score **≥ 75** to pass. This threshold is fixed — it is not configurable per workspace.

## Max iterations

Default: 3. When `current_iteration` reaches max:

Show:
```
Reached {max} iterations. Aggregate score: {score}/100.

What would you like to do?
1. Publish anyway (dispatch distribution with current draft)
2. Continue for N more iterations (specify N)
3. Discard this draft (draft_status: abandoned)
```

Wait for user choice. Execute accordingly.

## Halt detection

If the user types any of: "finalize", "publish now", "skip iterations", "good enough", "ship it" — treat as a halt signal. Dispatch distribution immediately with the current `draft.md`. Do not run another eval iteration.

## Per-dimension rubrics (for eval agents)

### SEO (pass ≥ 75)
- Keyword density 1–3% for primary keyword
- Meta description present, 120–160 chars, includes primary keyword and value prop
- Heading hierarchy correct: exactly one H1, H2s for major sections, H3 for sub-points
- Flesch Reading Ease ≥ 60 (accessible prose)
- At least 2 internal link opportunities identified

### Hook (pass ≥ 75)
- First sentence creates curiosity gap or makes a specific, counterintuitive claim
- Title contains at least one of: number, specific outcome, time frame, named concept
- No throat-clearing (first sentence doesn't start with "In today's world..." or similar)
- Scroll-stop power: would this stop a fast scroller within 3 seconds?

### Voice (pass ≥ 75)
- ≥ 3 of profile's `tone` adjectives reflected in the prose style
- Sentence rhythm varies (mix of short punchy and longer analytical sentences)
- Vocabulary matches audience expertise level (profile.audience_expertise)
- If brand_voice_examples present: prose patterns align with examples

### Readability (pass ≥ 75)
- Average paragraph length ≤ 4 sentences
- At least one subheading every 300 words
- At least one list (bullet or numbered) if post is medium or long
- Sentence length variance: not all sentences the same length (avg ≤ 25 words, some ≤ 10)
```

- [ ] **Step 2: Write eval-output-spec.md**

```markdown
# Eval Output Specification

Contract for all eval agent output files. Every eval agent must write a file matching this schema exactly.

## Required fields

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
  "specifics": {}
}
```

## Field definitions

| Field | Type | Rules |
|-------|------|-------|
| `schema_version` | string | Always `"1.0"` in v1 |
| `agent` | string | Exact agent name: `seo-eval`, `hook-eval`, `voice-eval`, `readability-eval` |
| `iteration` | number | Current iteration number (1, 2, 3) |
| `timestamp` | string | ISO-8601 UTC |
| `score` | number | Integer 0–100 |
| `feedback` | string | Human-readable summary, 1–3 sentences |
| `sections_affected` | string[] | Section names from wireframe (e.g. `["intro", "meta_description"]`) |
| `suggestion_type` | string | One of: `rewrite`, `restructure`, `enhance`, `keep` |
| `specifics` | object | Dimension-specific detail (see below) |

## suggestion_type values

- `rewrite` — this section needs to be substantially rewritten
- `restructure` — the ideas are right but the structure/order is wrong
- `enhance` — small additions or changes needed (don't fully rewrite)
- `keep` — this section is passing (use when score ≥ 75 for that section)

## specifics object — per dimension

### seo-eval specifics
```json
{
  "keyword_coverage": { "primary": "2.1%", "secondary": "1.2%" },
  "meta_description_length": 95,
  "heading_issues": ["no H2 found after intro"],
  "flesch_score": 62,
  "recommend": "Rewrite meta_description to include primary keyword 'react state management' and value proposition"
}
```

### hook-eval specifics
```json
{
  "first_sentence": "In today's world, AI is changing everything.",
  "hook_issues": ["throat-clearing opening", "no specific claim"],
  "title_score": 45,
  "title_issues": ["no number", "no specific outcome"],
  "recommend": "Rewrite first sentence to open with a specific counterintuitive claim. Rewrite title to include a concrete outcome."
}
```

### voice-eval specifics
```json
{
  "tone_adjectives_found": ["technical"],
  "tone_adjectives_missing": ["direct", "opinionated"],
  "avg_sentence_length": 28,
  "vocabulary_level": "formal",
  "voice_examples_matched": false,
  "recommend": "Shorten sentences in intro and body_para_2. Add an opinionated claim in intro."
}
```

### readability-eval specifics
```json
{
  "avg_paragraph_sentences": 6.2,
  "subheadings_per_300w": 0.5,
  "has_lists": false,
  "avg_sentence_words": 22,
  "offending_sections": ["body_para_1", "body_para_3"],
  "recommend": "Break body_para_1 into two shorter paragraphs. Add a subheading before body_para_3."
}
```

## Atomic write protocol

1. Compute the full JSON output
2. Write to `{slug}/{agent-name}.tmp`
3. Rename `{slug}/{agent-name}.tmp` → `{slug}/{agent-name}.json`

Never write directly to the `.json` file. The orchestrator polls for file presence — a file that exists is a complete file.

## Validation

Before the orchestrator aggregates, it validates each eval JSON against this schema. Required field missing or wrong type → log validation error → report that dimension as "unavailable". Do not crash other dimensions.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/draft/references/scoring-rubric.md \
        plugins/draftloom/skills/draft/references/eval-output-spec.md
git commit -m "feat(draftloom): add scoring-rubric and eval-output-spec"
```

---

## Task 9: Draft references — distribution and Turso

**Files:**
- Create: `plugins/draftloom/skills/draft/references/distribution-guide.md`
- Create: `plugins/draftloom/skills/draft/references/turso-setup.md`

- [ ] **Step 1: Write distribution-guide.md**

```markdown
# Distribution Guide

Templates and character limits for platform copy. Load this file in distribution.md.

## Platform constraints

| Platform | Field | Hard limit | Notes |
|----------|-------|-----------|-------|
| X (Twitter) | `x_hook` | 280 chars | No links. Pure text hook that makes people stop. |
| LinkedIn | `linkedin_opener` | 300 chars | Professional tone. Can include an emoji. |
| Email | `email_subject` | 60 chars | No clickbait. Promise what the post delivers. |
| Newsletter | `newsletter_blurb` | 150 words | Conversational. Ends with a CTA link placeholder. |

**Enforcement rule:** If generated copy exceeds the limit, regenerate — do not truncate. Truncating mid-sentence produces bad copy. Regenerate with the constraint as a hard instruction.

## X hook template patterns

Strong X hooks follow one of these patterns:

| Pattern | Example |
|---------|---------|
| Counterintuitive claim | "Most developers optimise for the wrong thing. Here's what actually matters." |
| Specific stat | "I went from 0 to 500 subscribers in 60 days. 3 things I did that nobody talks about." |
| Challenge | "Your state management is the problem. Not your framework." |
| Story hook | "Six months ago I deleted all my React Query code. Here's what happened." |

## LinkedIn opener template

LinkedIn openers should:
- State the core thesis in sentence 1
- Give a specific claim or number in sentence 2
- End with a teaser ("More in the post 👇" or "Here's what I learned:")

## Email subject template

Email subjects should:
- Be specific, not clever
- Promise a concrete takeaway
- Avoid spam trigger words (FREE, !!!!, URGENT)
- Test: would you open this email from an unfamiliar sender?

## newsletter_blurb template

```
{2-3 sentence summary of the post's core argument}

{1 sentence on who this is most useful for}

Read it here → {CTA_LINK}
```

Replace `{CTA_LINK}` with a placeholder — the actual URL is added by the user at publish time.

## Staleness check

The distribution agent writes a SHA-256 hash of `draft.md` to `distribution.json → draft_hash`. If the orchestrator detects that `draft.md` has been modified after `distribution.json` was written (hash mismatch), it re-runs the distribution agent automatically.
```

- [ ] **Step 2: Write turso-setup.md**

```markdown
# Turso MCP Setup (Optional)

Turso provides optional cross-project analytics for Draftloom. File-based workspace is always primary. Turso is secondary redundancy only.

## When to use

Use Turso if you want to:
- Track post performance analytics across multiple projects
- Query historical eval scores (e.g. "what's my average hook score over 30 days?")
- Build a cross-project writing dashboard

## Prerequisites

- Turso account (turso.tech)
- Turso CLI installed: `brew install tursodatabase/tap/turso`
- Turso MCP configured in Claude Code settings

## Setup steps

### 1. Create a Turso database
```bash
turso db create draftloom-analytics
turso db show draftloom-analytics --url
turso db tokens create draftloom-analytics
```

### 2. Enable in config.json
Add to `.draftloom/config.json`:
```json
{
  "turso_enabled": true,
  "turso_url": "libsql://draftloom-analytics-yourname.turso.io",
  "turso_auth_token": "your-token-here"
}
```

### 3. Schema (created automatically on first use)
```sql
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL,
  profile_id TEXT NOT NULL,
  title TEXT,
  draft_status TEXT,
  latest_aggregate_score INTEGER,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS scores (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  iteration INTEGER NOT NULL,
  aggregate_score INTEGER,
  seo INTEGER,
  hook INTEGER,
  voice INTEGER,
  readability INTEGER,
  timestamp TEXT
);

CREATE TABLE IF NOT EXISTS eval_events (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  iteration INTEGER NOT NULL,
  agent TEXT NOT NULL,
  score INTEGER,
  feedback TEXT,
  sections_affected TEXT,
  timestamp TEXT
);
```

## Failure handling

If the Turso write fails for any reason:
- Log the error to `iterations.log` with tag `[TURSO_ERROR]`
- Continue the eval loop without retrying
- The file-based workspace is always the source of truth

Never block or retry the eval loop on a Turso failure.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/draft/references/distribution-guide.md \
        plugins/draftloom/skills/draft/references/turso-setup.md
git commit -m "feat(draftloom): add distribution-guide and turso-setup"
```

---

## Task 10: Eval skill

**Files:**
- Create: `plugins/draftloom/skills/eval/SKILL.md`
- Create: `plugins/draftloom/skills/eval/references/eval-guide.md`

- [ ] **Step 1: Write eval SKILL.md**

```markdown
---
name: eval
command: /draftloom:eval
description: "This skill should be used when the user asks to score a post, evaluate a blog post, check my draft, or run draftloom eval."
version: "0.1.0"
references:
  - references/eval-guide.md
---

# Draftloom Eval Skill

Standalone scorer for an existing markdown file. Runs all 4 eval agents and presents a scored report, with an optional patch offer.

## Step 1: Get the file path

Ask: "Path to the markdown file you'd like to score?"

Validate the file exists. If not, ask again.

## Step 2: Select a profile (for voice matching)

If profiles exist in `.draftloom/profiles/`, ask: "Score voice against which profile? (name or 'none' for generic)"

If "none" or no profiles exist: voice-eval uses generic clarity and consistency rubric — does not attempt to load a profile JSON.

## Step 3: Create workspace

Derive slug from the filename (strip extension, normalise to slug format). Check if `posts/{slug}/` already exists. If yes, append `-eval` suffix.

Create `posts/{slug}/`. Copy the provided file to `posts/{slug}/draft.md`.

Write minimal `meta.json`:
```json
{
  "schema_version": "1.0",
  "title": "{filename}",
  "slug": "{slug}",
  "profile_id": "{selected or null}",
  "draft_status": "eval_only"
}
```

## Step 4: Dispatch orchestrator in eval-only mode

Dispatch `agents/orchestrator.md` with:
- Path: `posts/{slug}/`
- Profile JSON path (or null)
- Mode: "eval_only" (skip writer, skip brief, run 4 evals directly)

Load `references/eval-guide.md` for eval-only mode specifics.

## Step 5: Show scored report

When orchestrator signals eval complete, display:

```
Score report: {filename}

SEO          {score}/100  {✓ or ⚠}
Hook         {score}/100  {✓ or ⚠}
Voice        {score}/100  {✓ or ⚠}
Readability  {score}/100  {✓ or ⚠}

Aggregate (minimum): {aggregate}/100

{For each ⚠ dimension:}
  ⚠ {dimension}: {feedback}
     Sections: {sections_affected}
     Suggestion: {recommend}
```

## Step 6: Patch offer

If any dimension scored below 75:
- Ask: "Patch failing dimensions? (y/n)"
- If yes: dispatch writer agent in patch mode, run a second eval pass, show delta

If all dimensions ≥ 75:
- Show: "All dimensions passing." No patch offer.
```

- [ ] **Step 2: Write eval-guide.md**

```markdown
# Eval Guide

Instructions for running eval-only mode via the orchestrator. Load this file in the eval skill.

## Eval-only mode differences

When orchestrator is dispatched with `mode: "eval_only"`:
- Skip Step 1 (writer dispatch — `draft.md` already exists)
- Skip brief validation (no `brief.md` required)
- Proceed directly to: dispatch all 4 eval agents in parallel
- Poll for all 4 eval JSON files
- Aggregate into `scores.json`
- Return eval results to the eval skill

The orchestrator does NOT loop in eval-only mode. It runs exactly one eval pass and returns.

## Voice-eval without a profile

If `profile_id` is null:
- voice-eval scores for generic clarity and consistency
- Does not check tone adjective match
- Does not load brand_voice_examples
- Evaluates: sentence variety, vocabulary range, absence of filler phrases, consistent register throughout

## Patch mode after eval

If the user answers "yes" to the patch offer:
- Dispatch writer with `mode: "patch_only"` — reads all failing eval JSONs, patches sections_affected
- Run a second eval pass (eval-only mode again)
- Show iteration-2 scores alongside iteration-1 scores for comparison:
  ```
  Before → After
  SEO    78 → 84  ✓
  Voice  61 → 79  ✓
  ```
- Do not offer another patch — one patch round is the limit in eval mode
```

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/skills/eval/SKILL.md \
        plugins/draftloom/skills/eval/references/eval-guide.md
git commit -m "feat(draftloom): add eval skill"
```

---

## Task 11: Orchestrator agent

**Files:**
- Create: `plugins/draftloom/agents/orchestrator.md`

This is the most complex agent — the central coordinator of the eval loop.

- [ ] **Step 1: Write orchestrator.md**

```markdown
# Orchestrator Agent

Owns the eval loop. Dispatches all agents, polls output files, aggregates scores, and decides next action.

## Context on entry

Required inputs:
- `workspace_path`: path to `posts/{slug}/`
- `profile_path`: path to profile JSON (may be null in eval-only mode)
- `mode`: `"full_draft"` | `"eval_only"` | `"patch_only"` (rare, used internally)

Load from workspace:
- `state.json` — current_iteration, locked_brief
- `brief.md` — post brief (if exists)
- `scoring-rubric.md` — routing rules

---

## Full-draft mode flow

### Iteration 1

1. Print: `"Iteration 1 of 3 — drafting..."`
2. Dispatch `writer.md` with context: `brief.md`, `workspace_path`, iteration=1
3. Poll for `draft.md` to be written. Timeout: 120s. If timeout, log error and exit.
4. Once `draft.md` exists, print: `"Draft written. Running 4 evaluations in parallel..."`
5. Dispatch all 4 eval agents in parallel:
   - `seo-eval.md` — reads `draft.md`, `meta.json`, `brief.md` (for keywords)
   - `hook-eval.md` — reads `draft.md`, `meta.json`
   - `voice-eval.md` — reads `draft.md`, profile JSON
   - `readability-eval.md` — reads `draft.md`
6. Poll for all 4 `*-eval.json` files. Each agent writes atomically (tmp→rename). Timeout: 120s per agent.
7. Validate each eval JSON against eval-output-spec.md. If a file is malformed, mark that dimension "unavailable".
8. Aggregate into `scores.json`. Calculate `aggregate_score = min(seo, hook, voice, readability)`.
9. Update `state.json` → current_iteration: 1.
10. Print eval summary: `"✓ SEO (78) · ✓ Hook (85) · ⚠ Voice (68) · ✓ Readability (80)"`
11. Route using scoring-rubric.md routing table.

### Subsequent iterations (2, 3)

1. Print: `"Iteration N of 3 — patching..."`
2. Collect `sections_affected` arrays from all failing eval JSONs.
3. Dispatch `writer.md` with context: `draft.md`, all `*-eval.json` files, `brief.md`, iteration=N
4. Writer patches only `sections_affected` sections.
5. Rename old eval JSONs to `{name}-eval.prev.json` (backup for delta display).
6. Dispatch 4 eval agents in parallel (same as iteration 1).
7. Poll, validate, aggregate.
8. Show delta vs previous: `"Voice: 68 → 79 ✓  (+11)"`
9. Route again.

### All-pass routing

When all 4 dimensions ≥ 75:
1. Print: `"All dimensions passing. Generating distribution copy..."`
2. Update `meta.json` → draft_status: "passing".
3. Dispatch `distribution.md` with context: `draft.md`, `meta.json`, profile JSON.
4. Wait for `distribution.json` to be written.
5. Signal to the draft skill: `loop_end`.

### Halt detection

After each user message, check for halt phrases: "finalize", "publish now", "skip iterations", "good enough", "ship it".

On halt signal: dispatch distribution immediately. Do not run another eval iteration.

### Max iterations reached

When `current_iteration` equals the maximum (default 3), show the user choice menu from scoring-rubric.md.

---

## Eval-only mode flow

1. `draft.md` already exists — skip writer dispatch.
2. Dispatch all 4 eval agents in parallel.
3. Poll, validate, aggregate.
4. Print scored report (see eval SKILL.md for display format).
5. Signal completion to eval skill.
6. Do not loop.

---

## User communication events

Print these messages at the right moments (not at every tick):

```
ITERATION_START:   "Iteration N of 3 — {drafting/patching}..."
EVAL_RUNNING:      "Running 4 evaluations in parallel..."
EVAL_COMPLETE:     "✓ SEO (78) · ✓ Hook (85) · ⚠ Voice (68) · ✓ Readability (80)"
PATCH_START:       "Patching: voice match in [intro, body_para_2]..."
ITERATION_END:     Show delta vs previous iteration
LOOP_END:          "All dimensions passing. Generating distribution copy..."
HALT:              "Finalising with current draft..."
MAX_ITER:          Show the 3-option choice menu
```

---

## Retry logic for eval agents

If an eval agent does not write its output file within 120s (3 retries, exponential backoff):
- Mark that dimension as "unavailable" in `scores.json`
- Log to `iterations.log`: `[AGENT_TIMEOUT] {agent-name} failed after 3 attempts`
- Continue with remaining dimensions
- Warn user: "Note: {dimension} could not be evaluated this iteration."

Do not crash. Do not block the other dimensions.

---

## Turso sync (if enabled)

After each iteration where `turso_enabled: true` in config.json:
1. Write post record to `posts` table (upsert by slug)
2. Write scores record to `scores` table
3. Write each eval event to `eval_events` table

If Turso write fails: log `[TURSO_ERROR]` to iterations.log, continue.
```

- [ ] **Step 2: Verify against draft.feature and eval.feature**

Check these scenarios are handled:
- "Eval agents run in parallel" (step 5 dispatches all 4 simultaneously)
- "Aggregate score is minimum" (step 8 uses min())
- "Patch touches only sections_affected" (step 2 of subsequent iterations)
- "Halt signal stops loop immediately" (halt detection section)
- "Eval agent timeout marks dimension unavailable" (retry logic section)

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/agents/orchestrator.md
git commit -m "feat(draftloom): add orchestrator agent"
```

---

## Task 12: Writer agent

**Files:**
- Create: `plugins/draftloom/agents/writer.md`

- [ ] **Step 1: Write writer.md**

```markdown
# Writer Agent

Drafts the full post on iteration 1. Patches only failing sections on iteration 2+.

## Context on entry

Required:
- `workspace_path`: path to `posts/{slug}/`
- `iteration`: current iteration number (1, 2, 3)
- Profile JSON (loaded by caller)

Reads from workspace:
- `brief.md` — always (locked, read-only)
- `draft.md` — iteration 2+ only (to preserve passing sections)
- All `*-eval.json` files — iteration 2+ only (for sections_affected)
- `iterations.log` — last 3 entries only (context efficiency)

## Iteration 1: Full draft

Read `brief.md` in full. Do not read `draft.md` (it doesn't exist yet).

Write a complete blog post to `draft.md`:
- Match the wireframe section structure from `brief.md → Sections`
- Use the exact section headings from the wireframe
- Target the word counts per section from the wireframe (±10%)
- Apply the tone adjectives from the profile JSON
- Incorporate the examples, data, and stories from brief Q3
- Write the CTA from the profile `cta_goal`

Do not write frontmatter. Start directly with the post content. Use H2 headings for sections, H3 for sub-points.

After writing: append to `iterations.log`:
```
{timestamp}  ITERATION_1  writer  draft.md written ({word_count}w)
```

## Iteration 2+: Patch mode

### Step 1: Identify sections to patch

Read all `*-eval.json` files that have `score < 75`. Collect their `sections_affected` arrays. Deduplicate. This is the patch list.

Sections NOT on the patch list must be preserved verbatim. Do not rewrite, reorder, or improve them.

### Step 2: Read current draft

Read `draft.md` in full. Identify which paragraphs/sections correspond to each item on the patch list.

### Step 3: Read the eval specifics

For each section on the patch list, read the `specifics.recommend` field from its eval JSON. This is the concrete instruction for the patch.

Also read `suggestion_type`:
- `rewrite` — replace the section substantially
- `restructure` — keep ideas, change order/structure
- `enhance` — small targeted addition or change

### Step 4: Apply patches

Rewrite `draft.md`. Patched sections get new content per the recommendation. All other sections are copied verbatim from the current `draft.md`.

### Step 5: Log

Append to `iterations.log`:
```
{timestamp}  ITERATION_{N}  writer  patched {section1},{section2}
```

## Context window management

When reading `iterations.log`, load only the last 3 complete iteration blocks. Older entries have been summarised by the orchestrator.

If `draft.md` is very long (> 2500w), read only the sections on the patch list — not the full file. This keeps context cost proportional to the work.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/draftloom/agents/writer.md
git commit -m "feat(draftloom): add writer agent"
```

---

## Task 13: SEO eval agent

**Files:**
- Create: `plugins/draftloom/agents/seo-eval.md`

- [ ] **Step 1: Write seo-eval.md**

```markdown
# SEO Eval Agent

Scores keyword density, meta description, heading hierarchy, Flesch readability, and internal link opportunities.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the post prose
- `posts/{slug}/meta.json` — for existing meta_description and keywords
- `posts/{slug}/brief.md` — for primary keyword (Q5) if set

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → SEO dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Primary keyword density 1–3% | 25 | < 0.5% or > 4% |
| Meta description present and 120–160 chars | 20 | Missing or wrong length |
| Meta description includes primary keyword | 10 | Keyword absent |
| Heading hierarchy (one H1, logical H2/H3) | 20 | No H1, or H3 before H2 |
| Flesch Reading Ease ≥ 60 | 15 | < 50 = heavy penalty |
| Internal link opportunities identified (≥ 2) | 10 | 0 identified |

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Meta description | `["meta_description"]` |
| Keyword density | `["intro"]` or the section with lowest keyword density |
| Heading hierarchy | `["structure"]` |
| Flesch score | `["body_para_1"]` or densest paragraph |

## Output

Write to `posts/{slug}/seo-eval.tmp`, then rename to `posts/{slug}/seo-eval.json`.

Follow the eval-output-spec.md schema exactly. Populate `specifics` with:
```json
{
  "keyword_coverage": { "primary": "2.1%", "secondary": "0.8%" },
  "meta_description_length": 95,
  "heading_issues": [],
  "flesch_score": 64,
  "recommend": "Rewrite meta_description to include 'react state management' and add value proposition. Current length 95 chars — target 120–160."
}
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/draftloom/agents/seo-eval.md
git commit -m "feat(draftloom): add seo-eval agent"
```

---

## Task 14: Hook eval agent

**Files:**
- Create: `plugins/draftloom/agents/hook-eval.md`

- [ ] **Step 1: Write hook-eval.md**

```markdown
# Hook Eval Agent

Scores first-sentence novelty, curiosity gap, title specificity, and scroll-stop power.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the post prose (focus on first 150 words and title)
- `posts/{slug}/meta.json` — for the title

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Hook dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| First sentence: no throat-clearing | 25 | Starts with "In today's world", "We live in", "It's no secret", "As a", etc. |
| First sentence: specific claim | 25 | Generic statement with no claim, number, or opinion |
| Title: contains number, timeframe, or concrete outcome | 25 | Title is vague or generic |
| Curiosity gap: reader wants to know more | 25 | First paragraph answers itself — no tension created |

## Throat-clearing patterns (auto-fail first 25 points)

These opening patterns score 0 on that check:
- "In today's world..."
- "We live in an age where..."
- "It's no secret that..."
- "As a [job title], I've..."
- "With the rise of..."
- "In recent years..."

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Throat-clearing / weak opening | `["intro"]` |
| Weak title | `["headline"]` |
| No curiosity gap | `["intro", "hook"]` |

## Output

Write to `posts/{slug}/hook-eval.tmp`, rename to `posts/{slug}/hook-eval.json`.

Populate specifics:
```json
{
  "first_sentence": "In today's world, AI is changing everything.",
  "hook_issues": ["throat-clearing", "no specific claim"],
  "title_score": 45,
  "title_issues": ["no number", "no specific outcome", "too generic"],
  "recommend": "Replace first sentence with a specific, counterintuitive claim. E.g.: 'Most developers are optimising for the wrong metric — here's the one that actually predicts retention.' Rewrite title to include a concrete number or outcome."
}
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/draftloom/agents/hook-eval.md
git commit -m "feat(draftloom): add hook-eval agent"
```

---

## Task 15: Voice eval agent

**Files:**
- Create: `plugins/draftloom/agents/voice-eval.md`

- [ ] **Step 1: Write voice-eval.md**

```markdown
# Voice Eval Agent

Scores tone adjective match, sentence rhythm, vocabulary range, and brand voice example alignment.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the full post
- Profile JSON — for tone[], audience_expertise, brand_voice_examples
- Profile is null in eval-only mode with "none" selection → use generic rubric

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Voice dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Tone adjectives reflected (≥ 3 of profile.tone) | 40 | < 2 tone adjectives detectable |
| Sentence rhythm varies (mix of short + long) | 20 | All sentences similar length |
| Vocabulary matches audience_expertise | 20 | Mismatch (too simple/complex) |
| Brand voice examples alignment | 20 | Present but patterns don't match |

## Loading brand_voice_examples

For each entry in `brand_voice_examples`:
- `local_file`: read the file at `value` (relative to project root). If file not found: log warning, skip.
- `url`: fetch the URL as text. If fetch fails: log warning, skip.
- `inline`: use `value` text directly.

Compare prose patterns from examples against draft.md:
- Sentence starters (does the writer often open with a verb? a question?)
- Use of parentheticals, em-dashes, or brackets
- Whether the writer uses "I" or "we" or impersonal voice
- Characteristic phrases or structural tics

## Generic voice rubric (no profile)

When profile is null:
- Sentence variety: mix of ≤ 10w and 20–25w sentences = pass
- No filler phrases: "very", "really", "basically", "just" used ≤ 3× per 500w
- Consistent register: formal throughout or conversational throughout (no mixing)
- Skip: tone adjective check (no profile), brand voice examples (no profile)
- Max score without a profile: 75 (voice adjective check worth 40 points → set to 30/40 as neutral)

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Tone adjectives missing | `["intro"]` + highest-density section lacking tone |
| Sentence rhythm flat | `["body_para_1"]` or the longest paragraph |
| Vocabulary mismatch | `["intro", "core_insight"]` |

## Output

Write to `posts/{slug}/voice-eval.tmp`, rename to `posts/{slug}/voice-eval.json`.

Populate specifics:
```json
{
  "tone_adjectives_found": ["technical"],
  "tone_adjectives_missing": ["direct", "opinionated"],
  "avg_sentence_length": 28,
  "vocabulary_level": "formal",
  "voice_examples_matched": false,
  "recommend": "Shorten sentences in intro and body_para_2 to ≤ 15 words. Add an opinionated first-person claim in intro — your profile's 'opinionated' tone is absent."
}
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/draftloom/agents/voice-eval.md
git commit -m "feat(draftloom): add voice-eval agent"
```

---

## Task 16: Readability eval agent

**Files:**
- Create: `plugins/draftloom/agents/readability-eval.md`

- [ ] **Step 1: Write readability-eval.md**

```markdown
# Readability Eval Agent

Scores paragraph length, subheading frequency, list distribution, and sentence length variance.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the full post

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Readability dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Avg paragraph ≤ 4 sentences | 30 | Avg > 5 sentences per paragraph |
| Subheading every 300w | 30 | Gap > 400w without a heading |
| At least one list (if medium/long post) | 20 | No list in a 700w+ post |
| Sentence length variance | 20 | All sentences 18–25w (no variety) |

## Counting rules

- A paragraph = block of text separated by blank lines
- A subheading = H2 or H3 markdown heading
- A list = bullet list (- or *) or numbered list (1. 2. 3.)
- Sentence length = word count per sentence (split on . ! ?)
- Short posts (< 500w): list check is optional (max penalty 10, not 20)

## sections_affected naming

Name sections by their markdown heading text, lowercased and hyphenated. If no heading, use position: `body_para_1`, `body_para_2`, etc.

## Output

Write to `posts/{slug}/readability-eval.tmp`, rename to `posts/{slug}/readability-eval.json`.

Populate specifics:
```json
{
  "avg_paragraph_sentences": 6.2,
  "subheadings_per_300w": 0.5,
  "has_lists": false,
  "avg_sentence_words": 22,
  "sentence_length_variance": "low",
  "offending_sections": ["body_para_1", "body_para_3"],
  "recommend": "Split body_para_1 into two paragraphs (currently 8 sentences). Add a subheading before body_para_3. Add a bullet list to the Evidence section."
}
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/draftloom/agents/readability-eval.md
git commit -m "feat(draftloom): add readability-eval agent"
```

---

## Task 17: Distribution agent

**Files:**
- Create: `plugins/draftloom/agents/distribution.md`

- [ ] **Step 1: Write distribution.md**

```markdown
# Distribution Agent

Generates platform-specific copy from the final draft: X hook, LinkedIn opener, email subject, newsletter blurb.

## Context on entry

Required:
- `workspace_path`: path to `posts/{slug}/`

Reads:
- `posts/{slug}/draft.md` — final post prose
- `posts/{slug}/meta.json` — title, keywords, draft_status
- Profile JSON — tone[], cta_goal, blog_url, channels

Load `skills/draft/references/distribution-guide.md` for platform templates and character limits.

## Precondition check

Only run if:
- All 4 eval dimensions ≥ 75 in `scores.json`, OR
- Orchestrator has signalled a halt/finalize

If `distribution.json` already exists, check hash: if `draft_hash` matches SHA-256 of current `draft.md`, skip (already up to date).

## Generation steps

### 1. X hook (≤ 280 chars, no links)

Read the post's core thesis from the brief and the hook section of `draft.md`.

Select a pattern from the distribution-guide templates:
- If post has data/stats → use specific stat pattern
- If post is opinion → use counterintuitive claim pattern
- If post is narrative → use story hook pattern

Generate. Count characters. If > 280, regenerate with "≤ 280 characters" as a hard constraint. Do not truncate.

### 2. LinkedIn opener (≤ 300 chars, professional)

State the core thesis in sentence 1. Add a specific claim or number in sentence 2. End with a teaser.

Generate. Count characters. If > 300, regenerate.

### 3. Email subject (≤ 60 chars)

Specific, no clickbait, promises a concrete takeaway.

Generate. Count characters. If > 60, regenerate.

### 4. Newsletter blurb (≤ 150 words)

2–3 sentences on the core argument. 1 sentence on who benefits. End with `Read it here → {CTA_LINK}`.

Generate. Count words. If > 150, regenerate.

## Output

Write to `posts/{slug}/distribution.tmp`:

```json
{
  "schema_version": "1.0",
  "draft_hash": "sha256:{hash-of-draft.md}",
  "x_hook": "...",
  "linkedin_opener": "...",
  "email_subject": "...",
  "newsletter_blurb": "..."
}
```

Rename `distribution.tmp` → `distribution.json`.

## Display

Print each field with its character/word count:
```
Distribution copy ready:

X hook (243/280 chars):
"{x_hook}"

LinkedIn (287/300 chars):
"{linkedin_opener}"

Email subject (52/60 chars):
"{email_subject}"

Newsletter blurb (134/150 words):
"{newsletter_blurb}"
```
```

- [ ] **Step 2: Verify against eval.feature and draft.feature**

Check:
- "Distribution runs on all-pass" (precondition check)
- "Distribution runs on halt" (precondition check)
- "X hook ≤ 280 chars" (generation step 1 — regenerate, don't truncate)
- "Staleness check via draft_hash" (precondition: hash comparison)

- [ ] **Step 3: Commit**

```bash
git add plugins/draftloom/agents/distribution.md
git commit -m "feat(draftloom): add distribution agent"
```

---

## Task 18: End-to-end setup smoke test

Verify the setup skill works correctly before calling implementation done.

- [ ] **Step 1: Test no-profile flow**

Open a new project in Claude Code with Draftloom installed. Run `/draftloom:setup`.

Verify:
- Claude asks Q1 (profile name) first, without asking anything else
- Claude validates a slug-format name (try "My Profile" — should reject and re-ask)
- Claude asks Q2 (audience) after Q1
- Claude shows tone presets in Q3
- After Q3, `.draftloom/profiles/{name}.json` exists and contains all fields from profile-schema.md
- Deferred fields are `null` (not omitted)
- Claude shows the 6 deferred fields hint

Check against `docs/plugins/draftloom/specs/setup.feature`:
- Scenario: "First-time user with no profiles" ✓
- Scenario: "Profile name slug validation" ✓
- Scenario: "Tone presets offered" ✓
- Scenario: "Profile saved immediately after creation" ✓

- [ ] **Step 2: Test edit flow**

Run `/draftloom:setup` again (profile now exists). Choose "edit". Update the tone field.

Verify updated profile JSON has new tone values and updated `updated_at`.

- [ ] **Step 3: Commit any fixes found during smoke test**

```bash
git add -p  # stage only relevant fixes
git commit -m "fix(draftloom): setup smoke test fixes"
```

---

## Task 19: End-to-end draft smoke test

- [ ] **Step 1: Run a full draft**

With a profile in place, run `/draftloom:draft`.

Walk through:
1. Profile selected (confirm displayed correctly)
2. Answer all 4 mandatory brief questions
3. Decline optional SEO questions
4. Review wireframe — make one edit ("change 3 to 400w")
5. Confirm wireframe

Verify after step 5:
- `posts/{slug}/brief.md` exists with all 9 fields
- `posts/{slug}/meta.json` exists with correct slug, profile_id, draft_status: "drafting"
- `posts/{slug}/session.json` checkpoint: `wireframe_approved`
- `posts/{slug}/state.json` current_iteration: 0, locked_brief: true

- [ ] **Step 2: Complete eval loop**

After wireframe, let the orchestrator run.

Verify after iteration 1:
- `posts/{slug}/draft.md` exists with content
- All 4 `*-eval.json` files exist
- `posts/{slug}/scores.json` has `aggregate_score = min(seo, hook, voice, readability)` — verify manually
- Claude prints the eval summary in the correct format

Let the loop continue to completion (or halt with "finalize").

Verify after completion:
- `posts/{slug}/distribution.json` exists with all 4 fields
- `posts/{slug}/iterations.log` has entries for each step
- Final Claude output shows the 3-line summary (draft.md, distribution.json, scores.json)

Check against `docs/plugins/draftloom/specs/draft.feature`:
- Scenario: "Brief interview 4 mandatory questions" ✓
- Scenario: "Wireframe parse-able edit applied" ✓
- Scenario: "Eval agents write atomically" ✓
- Scenario: "aggregate_score equals minimum" ✓
- Scenario: "Distribution copy written after all pass" ✓

- [ ] **Step 3: Commit any fixes**

```bash
git add -p
git commit -m "fix(draftloom): draft smoke test fixes"
```

---

## Task 20: End-to-end eval smoke test

- [ ] **Step 1: Score an existing markdown file**

Create a test file `test-post.md` with deliberate weaknesses (throat-clearing opener, no subheadings, long paragraphs).

Run `/draftloom:eval`. Provide `test-post.md` as input.

Verify:
- Workspace created at `posts/test-post/`
- All 4 eval agents ran and `*-eval.json` files exist
- `scores.json` written with correct `aggregate_score = min(...)`
- Report displayed with ✓/⚠ per dimension
- Failing dimensions show `sections_affected` and concrete recommendation

- [ ] **Step 2: Test patch offer**

When eval completes with failing dimensions: respond "y" to the patch offer.

Verify:
- Writer patches only `sections_affected` sections
- Second eval pass runs
- Delta displayed (before → after for each dimension)

- [ ] **Step 3: Test "none" profile**

Run `/draftloom:eval` again, select "none" for profile.

Verify:
- Voice eval runs and scores (does not crash)
- Voice eval output does not reference tone adjectives
- Max possible voice score without profile ≤ 75 (as designed)

Check against `docs/plugins/draftloom/specs/eval.feature`:
- Scenario: "Eval on an existing markdown file" ✓
- Scenario: "Eval without a profile uses generic voice scoring" ✓
- Scenario: "Aggregate score reported as minimum" ✓
- Scenario: "Patch offer shown when dimensions fail" ✓

- [ ] **Step 4: Final commit**

```bash
git add -p
git commit -m "fix(draftloom): eval smoke test fixes"
git tag draftloom/v0.1.0
```

---

## Spec coverage check

| Spec requirement | Task |
|-----------------|------|
| plugin.json manifest | Task 1 |
| SessionStart hook | Task 2 |
| /draftloom:setup — 3Q interview | Task 3 |
| Profile JSON schema | Task 4 |
| Storage project vs global | Task 4 |
| /draftloom:draft — profile selection | Task 5 |
| Brief interview 4+3 questions | Task 5, 6 |
| Wireframe parse-able editor | Task 5, 6 |
| Session recovery via session.json | Task 5 |
| Workspace file contract | Task 7 |
| aggregate_score = min() | Task 8 |
| Routing table (< 50 / 50-74 / ≥ 75) | Task 8 |
| Eval output JSON schema | Task 8 |
| Distribution char limits + regenerate | Task 9, 17 |
| Turso optional backend | Task 9 |
| /draftloom:eval standalone | Task 10 |
| Orchestrator eval loop | Task 11 |
| Orchestrator retry + timeout | Task 11 |
| Writer patch mode | Task 12 |
| SEO eval rubric | Task 13 |
| Hook eval rubric + throat-clearing | Task 14 |
| Voice eval + brand examples | Task 15 |
| Readability eval rubric | Task 16 |
| Distribution staleness check | Task 17 |
| Halt detection | Task 11 |
| Max iterations choice | Task 11 |

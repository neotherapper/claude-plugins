---
name: draft
description: >
  This skill should be used when the user asks to write a blog post, draft a
  post, start a new post, or wants help writing content. Trigger phrases:
  "draftloom draft", "write a blog post", "start a new post", "I want to write
  a post", "help me write a blog post", "draft a blog post", "/draftloom:draft".
  Use this skill whenever the user wants to create a new piece of written
  content — even if they don't explicitly say "blog post".
version: "0.1.0"
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

Check `.draftloom/profiles/` (and `~/.draftloom/profiles/` if `config.json` has `storage_mode: "global"`).

**No profiles found:**
Show: "No profiles found. Run `/draftloom:setup` to create your first writing profile." Stop.

**One profile found:**
Show profile name and confirm: "Using profile '{name}'. Continue? (y/n)"

**Multiple profiles found:**
Show a tiered list. Recent profiles (used in last 30 days) appear first with their last-used date and draft count. All others listed below. User types a number or search string to select.

Write selected `profile_id` to `session.json` → checkpoint: `profile_selected`.

---

## Step 2: Brief interview

Load `skills/draft/references/brief-questions.md` for the exact question wording and validation rules.

Ask the 4 mandatory questions **one at a time**. Wait for each answer before asking the next. After the 4 mandatory questions, offer: "Would you like to add SEO targeting, competitor reference URLs, or a publish date? (y/n)"

If yes, ask the 3 optional questions from brief-questions.md.

Generate a slug from the post topic (lowercase, hyphens, max 50 chars). Check if `posts/{slug}/` already exists. If it does, append a short suffix (e.g. `-2`).

Create workspace directory `posts/{slug}/`. Load `skills/draft/references/workspace-schema.md` for the complete file contract — every file you create must be documented there.

Write `brief.md` with all answers. Write `meta.json` with title (derived from topic), slug, profile_id, `draft_status: "drafting"`, and timestamps.

Write `session.json` → checkpoint: `brief_complete`, `brief_answered: true`.

Set `state.json` → `current_iteration: 0`, `locked_brief: true`.

---

## Step 3: Wireframe layout

Load `skills/draft/references/layout-templates.md` for section templates and word-count ranges.

Propose a numbered section outline based on the brief topic, core insight, and target length. Display in this format:

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

Ask: "Looks good?" When confirmed, append wireframe as a Sections block to `brief.md`.

Write `session.json` → checkpoint: `wireframe_approved`, `wireframe_approved: true`.

---

## Step 4: Delegate to orchestrator

Dispatch `agents/orchestrator.md` with context:
- Path to `posts/{slug}/`
- Profile JSON path
- Mode: `"full_draft"` (writer runs first, then eval loop)

The orchestrator owns all further steps — scoring, patching, iteration decisions. This skill waits for the orchestrator to signal completion.

Load `skills/draft/references/scoring-rubric.md` if the orchestrator surfaces a routing decision that requires user input (escalation when a dimension scores < 50, or max iterations reached).

---

## Step 5: Post-completion output

When orchestrator signals `loop_end`, display:

```
✓ Draft complete: posts/{slug}/
  draft.md          — your post
  distribution.json — X hook · LinkedIn opener · email subject · newsletter blurb
  scores.json       — final eval scores
```

Load `skills/draft/references/distribution-guide.md` to format the distribution copy display correctly (respecting character limits per platform).

If Turso is enabled in `.draftloom/config.json`, load `skills/draft/references/turso-setup.md` to confirm the post was synced.

---

## Halt detection

If the user types "finalize", "publish now", "skip iterations", or "ship it" at any point after the wireframe is approved, relay the halt signal to the orchestrator immediately. The orchestrator will dispatch the distribution agent with the current draft.

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

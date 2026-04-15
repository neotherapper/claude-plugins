# Distribution Agent

Generates platform-specific copy from the final draft: X hook, LinkedIn opener, email subject, newsletter blurb.

## Context on entry

Required:
- `workspace_path`: path to `posts/{slug}/`

Reads:
- `{workspace_path}/draft.md` — final post prose
- `{workspace_path}/meta.json` — title, keywords, draft_status
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

Generate. Count words. If > 150, regenerate. Substitute `{CTA_LINK}` with `profile.blog_url` if available; otherwise use the literal placeholder `[INSERT_URL]`.

## Output

Write to `{workspace_path}/distribution.tmp`:

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

Rename `{workspace_path}/distribution.tmp` → `{workspace_path}/distribution.json`.

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

# Idea Generator — Main Orchestration

This is the master prompt for generating business ideas from existing vault research. Follow all four sections in order. All phases run as sequential steps in this conversation — do not dispatch subagents.

**Stage mapping:** Section 2 = Stage 1 (Generate), Section 3 = Stage 2 (Score), Section 4 = Stage 3 (Seeds).

---

## Section 1: Data Layer

### Step 1 — Domain lookup

Read `ideas/_registry/master-index.yaml`. Match the user's domain input against the `domains` tags on existing ideas. Matching rules:
- Case-insensitive, partial match acceptable ("property" matches "real-estate", "real estate" matches "real-estate")
- If multiple domain clusters match, ask once: *"I found domains: X, Y — which one, or should I treat this as a new space?"* After selection, treat only the chosen cluster's ideas as the corpus.

If no match:
> *"No existing ideas for this domain. I can generate ideas from your description alone — describe the space in a sentence or two. Note: without vault research, all evidence will be inferred, and the hard Evidence floor means description-only runs will surface candidates for discussion but will not produce evaluator-ready seeds. You will get a candidate list to review, not a saved seed file."*

Run generation using only the user's description as the corpus. Skip Steps 2-4 and proceed directly to Section 2 with the description as the corpus. **Do not attempt to call research CLIs or external tools** — that is out of scope for v1.

### Step 2 — Corpus assembly

*(Skip Steps 2-4 entirely in no-vault-match mode — proceed directly to Section 2 with the user's description as the corpus.)*

For each matched idea in master-index.yaml:
- **Resolve the idea path**: check `ideas/{slug}/idea.md` first (researched folder), then fall back to `ideas/drafts/{slug}.md` (draft). Both locations never contain the same slug.
- Load the resolved file (always exists for any slug in master-index — frontmatter with status, tags, family)
- If the idea has `latest_evaluation` set: load `ideas/{slug}/{latest_evaluation}` (the scored card — this only exists for researched folders, never for drafts)
- If the idea's `family_id` is set: also load sibling slugs from master-index **that share the matched domain tag** and their scored cards (resolving each sibling's path the same way)

**Do not read** `ideas/{slug}/research/` files or `ideas/_registry/families/` scorecard files — the individual scored cards are already digested summaries. Drafts have no research folder by definition.

**Corpus size guard:** If the matched corpus contains more than 10 ideas total (evaluated or brainstorm), ask the user: *"Found [N] ideas across [M] clusters — this is a broad match. Want to narrow to a specific cluster (e.g. [A], [B]) or proceed with all?"* Count is the union of domain-tag matches plus any same-domain family siblings, deduplicated by slug.

**All KILL verdicts:** If all matched ideas have `verdict: KILL`, surface this before generation: *"All existing ideas in this domain were killed. Generation will focus on different angles on the same demand — confirm you want to proceed?"* On confirmation, proceed with the standard pattern pass — KILL cards become Pattern 1 evidence but all other patterns remain viable. If the user declines, stop and suggest: *"Consider a different domain or fresh research before retrying."*

**Mixed corpus:** If some ideas are evaluated and some are brainstorm, treat the corpus as "scored cards present" (run all 5 patterns), using scored cards for evidence-heavy patterns and frontmatter for lighter signals.

If no evaluated ideas exist for the domain (all have `status: brainstorm`): proceed with idea.md frontmatter only. Note: *"No evaluated ideas found — generating from concept only. Evidence signals will be weaker."*

**Sparse corpus warning:** If the corpus has fewer than 2 evaluated ideas, note: *"Only [N] evaluated idea(s) in this domain — signal will be sparse and some patterns may be skipped."*

**Single-idea corpus:** If the corpus contains only 1 idea total (evaluated or brainstorm), warn the user: *"Corpus is a single idea — generation will be largely inferential. Consider treating this as a no-vault-match run instead."* Offer to switch to description-only mode before proceeding.

### Step 3 — De-duplicate against vault

Before generation, extract all existing `slug` values and `name` values from master-index.yaml for this domain. During Stage 1, any candidate that would likely resolve to an existing slug must be skipped. Overlap check: after drafting each candidate, check if its proposed name shares key nouns with any existing name (substring match on core topic words). If overlap is evident, redirect to a meaningfully different angle instead.

### Step 4 — Present context + confirm intent

One-liner to the user before generation:
> *"Found [N] ideas in [domain] ([X] evaluated, [Y] brainstorm). [Siblings in this domain: A, B — omit line if none share the matched domain tag.] Generating ideas that expand this space."*

---

## Section 2: Generation Pipeline

Read `skills/generate/references/gap-patterns.md` now. Apply the pre-flight check, then work through all applicable patterns as an explicit checklist against the corpus assembled in Section 1.

Apply all applicable patterns in one sequential pass. For each pattern, check whether the corpus contains signal. If it does, produce one candidate using the candidate format from gap-patterns.md. If it does not, skip the pattern and move to the next.

**Killed ideas:** Any idea already loaded into the corpus in Section 1 with `verdict: KILL` should be treated as Pattern 1 evidence per the instructions in gap-patterns.md. (Skip this step in no-vault-match mode — there is no corpus to inspect.)

After all candidates are drafted, run the evidence verification step from gap-patterns.md before presenting to the user. Then present all candidates before scoring, using the CANDIDATE/PATTERN/EVIDENCE/CUSTOMER/GAP block format from gap-patterns.md, grouped by pattern number.

---

## Section 3: Light Scoring

Read all Stage 1 candidates and score each on 3 criteria (1–3 each, max 9). No new research — judgment against each candidate's own EVIDENCE field only.

### The 3 Criteria

| Criterion | Score 1 | Score 2 | Score 3 |
|---|---|---|---|
| **Evidence strength** | Inferred / single weak signal | Single clear signal from corpus | Multiple corroborating signals with source citations |
| **Timing / catalyst** | No tailwind or catalyst | Gradual market growth | Specific recent catalyst (regulation, tech shift, competitor exit, market event) |
| **Founder executable** | Requires team, rare expertise, or data that doesn't exist | Solo founder could build in 1-3 months with standard stack | Solo founder could ship in weeks — data already accessible or existing stack available |

### Advancement Rule

**Hard floor:** Any candidate with Evidence=1 is dropped before ranking regardless of total score — a weak evidence signal cannot be compensated by timing or executability.

From the remaining candidates, the top 3-5 by total score advance to Stage 3, but only if they score ≥6/9. The 3-5 range is a cap, not a minimum — if only 1 or 2 candidates score ≥6, advance them anyway. If more than 5 candidates qualify, take the top 5 sorted by total → evidence → timing → executable. If a tie persists after all three tiebreakers, present the tied candidates and ask the user to pick 3-5 to advance.

If no candidate scores ≥6 after the hard floor, present the table, report the highest score among candidates that survived the hard floor, and stop:
> *"No candidates reached the quality threshold (6/9). Consider researching this domain more thoroughly before generating."*

### Scoring Table Format

```
| Rank | Candidate       | Pattern | Evidence | Timing | Executable | Total |
|------|----------------|---------|----------|--------|------------|-------|
| 1    | [name]         | 1       | 3        | 3      | 2          | 8     |
| 2    | [name]         | 3       | 3        | 2      | 3          | 8     |
| 3    | [name]         | 4       | 2        | 2      | 3          | 7     |
```

Present the table and confirm:
> *"Top [N] candidates (score ≥6) advancing to seed generation. Proceed?"*

---

## Section 4: Evaluator-Ready Seeds

Produce one structured seed per top candidate. The seed gives `/idea-forge:evaluate` everything needed to start its Step 0 (parse the idea) immediately — without pre-filling the evaluator's adaptive interview (its Step 1).

**Important:** Do NOT create vault entries (neither `ideas/{slug}/idea.md` nor `ideas/drafts/{slug}.md`) during generation. Seeds are pre-evaluation artifacts. The evaluator's Step 0a creates the vault entry on first evaluation, and it creates it as a draft at `ideas/drafts/{slug}.md`.

### BUSINESS_MODEL Inference

Use this hint table to pick the model from the pattern type and gap shape:

| Pattern + Gap shape | Likely model |
|---|---|
| Demand without supply + listing/comparison gap | `directory` |
| Demand without supply + workflow/automation gap | `saas` |
| Customer friction + manual process | `saas` or `tool-site` |
| Customer friction + segment exclusion | `saas` or `directory` |
| Unoccupied distribution + content/community | `content` |
| Unoccupied distribution + transaction gap | `marketplace` |
| Incumbent blindness + underserved segment | `saas` or `directory` |
| Technology wave + information aggregation | `directory` or `content` |
| Technology wave + workflow automation | `saas` or `tool-site` |

When ambiguous, pick the simpler model (directory > saas > marketplace).

### Seed Format

```markdown
## Idea Seed: {IDEA_NAME}

**IDEA_SLUG:** {url-friendly-slug}
**BUSINESS_MODEL:** {directory|saas|marketplace|content|tool-site|ecommerce}
**NICHE_KEYWORDS:** {3-5 search keywords}
**DATA_ENTITIES:** {what would be listed, sold, or served}
**FAMILY_HINT:** {family_id from corpus if idea extends a known family, e.g. "greek-education"; omit if not applicable}

### Description
{2-3 sentences — what it is, who it's for, what problem it solves. Include enough detail for the evaluator to infer Wikipedia article titles for the topic.}

### Quick Context
- **Gap:** {one line — what doesn't exist, from Stage 1 evidence}
- **Why it matters:** {one line — the specific pain it addresses}
- **Founder fit:** {one line — why founder is positioned, if known from corpus; omit if not known}
```

**What the seed does NOT include:**
- Pre-filled interview answers (why doesn't this exist, unfair insight, validation signals) — the evaluator's adaptive interview (Step 1) surfaces these from the founder
- Wikipedia titles — the evaluator generates these from the description (the description must be specific enough to make this unambiguous)

### Output File

All seeds for a run saved together in one file. Normalize domain to lowercase-kebab-case before substituting (e.g. "real estate" → "real-estate", "B2B SaaS" → "b2b-saas"):
```
ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md
```

To compute N: substitute the normalized domain and today's date, then use the Glob tool with pattern `ideas/_registry/idea-seeds-{normalized-domain}-{today}-run-*.md` where `{normalized-domain}` and `{today}` are substituted before calling Glob (e.g. for domain `real-estate` on 2026-04-07, the pattern is `ideas/_registry/idea-seeds-real-estate-2026-04-07-run-*.md`). Use max+1. Default to `run-1` if none exist.

If the file write fails, surface the error to the user and print all seeds inline in the conversation as a fallback so no work is lost.

Each seed is self-contained and can be copy-pasted directly into a new `/idea-forge:evaluate` session.

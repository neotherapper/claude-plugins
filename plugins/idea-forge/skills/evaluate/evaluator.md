# Evaluate — Main Orchestration

This is the master prompt for evaluating a business idea. The evaluator supports multiple business model types (directory, e-commerce, SaaS, marketplace, content) with lens-specific scoring rubrics. Follow these steps exactly.

## Evaluation Modes

### Mode A: Single Idea Evaluation (default)
Standard flow below. Triggered when the user describes one idea or asks to evaluate/score/validate a specific product.

### Mode B: Family Evaluation
Use when the user says "evaluate the [X] family", "should I pursue the [X] cluster", or "evaluate these ideas together as a group". In this case:
1. Identify the family slug from `ideas/_registry/master-index.yaml`
2. Read `agents/family-evaluator.md`
3. Follow the family evaluator pipeline instead of the steps below
4. The family evaluator produces a family scorecard saved to `ideas/_registry/families/{slug}-scorecard-v1.md`

**Rule:** If a user evaluates an individual idea that belongs to a known family, mention the family at the end of Step 0 confirmation: "Note: this idea is part of the **{family_name}** family. Running a family evaluation after individual ideas are scored will show the combined strategic value."

## Prerequisites

Before starting, ensure:
- The user has provided an idea description (1-2 paragraphs)

**CLI Tool Setup (for subagents running research steps):**
All research CLIs live in the user's project `tools/` directory. Call the venv's Python directly — do NOT use `source venv/bin/activate` (Claude Code blocks `source` from the allowlist, so it prompts on every invocation):
```bash
cd tools && ./venv/bin/python -m cli.<module> ...
```
`./venv/bin/python` already knows about its own site-packages — no activation needed.

> **Note:** The research CLI tools above are optional. If unavailable, agents should use web search (WebSearch tool) and manual research as fallback. The evaluation pipeline is fully functional without the CLI toolkit — research quality may vary.

Several CLIs are broken or behave differently than the prompts assume, and a fresh worktree has no `tools/venv` at all. `references/tool-status.md` lists the failures, substitutes, and setup; every research agent reads it first (the dispatch briefs below say so).

## Step 0: Parse the Idea

From the user's idea description, extract:

1. **IDEA_NAME**: A short name for the idea (e.g., "AI Coding Assistants Directory")
2. **IDEA_SLUG**: URL-friendly slug (e.g., "ai-coding-assistants")
3. **BUSINESS_MODEL**: Detect the primary business model type:
   - `directory` — Listing/comparison site aggregating information about entities
   - `ecommerce` — Selling physical or digital products directly (art, fashion, food, etc.)
   - `saas` — Software as a Service with subscription pricing
   - `marketplace` — Two-sided platform connecting buyers with sellers/providers
   - `content` — Content platform, reference site, newsletter, or educational resource
   - `tool-site` — Free web utility (calculator, converter, generator, analyzer) monetized through traffic
4. **NICHE_KEYWORDS**: 3-5 search keywords
5. **DATA_ENTITIES**: What would be listed, sold, or served
6. **WIKIPEDIA_TITLES**: 1-2 likely Wikipedia article titles for the topic

Confirm these with the user before proceeding:

> "I'll evaluate **{IDEA_NAME}** as a **{BUSINESS_MODEL}** idea using these search terms: {NICHE_KEYWORDS}. Does this look right, or should I use a different business model lens?"

Save `BUSINESS_MODEL` for use in the scoring stage. The scoring agent will read the corresponding lens file at `references/lenses/{BUSINESS_MODEL}.md` to apply model-specific rubrics.

Available lenses: `directory`, `ecommerce`, `saas`, `marketplace`, `content`, `tool-site`

## Step 0a: Initialize Idea Vault Entry

Idea files live in one of two locations:

- **Draft**: `ideas/drafts/{slug}.md` — flat file, idea has only frontmatter + description, no research content
- **Researched folder**: `ideas/{slug}/idea.md` — folder with additional files (scored cards, research/)

**Resolve the current path**: check `ideas/{IDEA_SLUG}/idea.md` first, then `ideas/drafts/{IDEA_SLUG}.md`.

### Case A: NEITHER exists (new idea being evaluated for the first time)

Since this evaluator writes scored cards and research files, the idea MUST be promoted to a folder before any non-`idea.md` content is written.

1. Create `ideas/{IDEA_SLUG}/` directory
2. Write `ideas/{IDEA_SLUG}/idea.md` from template at `ideas/_templates/idea.md` (skipping the draft stage entirely, since we are about to write a scored card)
3. Populate: id, name, model (from Step 0), status: `evaluating`, created: today's date
4. Add initial evaluation entry: `version: v1`, `trigger: initial`
5. Update `ideas/_registry/master-index.yaml` with new idea entry

### Case B: Draft exists at `ideas/drafts/{IDEA_SLUG}.md`

**Promote the draft to a folder before doing anything else** (writing a scored card is a file beyond idea.md and triggers promotion):

1. `mkdir ideas/{IDEA_SLUG}`
2. `mv ideas/drafts/{IDEA_SLUG}.md ideas/{IDEA_SLUG}/idea.md`
3. Read the moved `idea.md` frontmatter
4. Update frontmatter: `status: evaluating`, add initial evaluation entry `version: v1, trigger: initial`
5. Update `ideas/_registry/master-index.yaml` with status change

After promotion, proceed as if this were Case C (re-evaluation of an existing folder).

### Case C: Researched folder exists at `ideas/{IDEA_SLUG}/idea.md` (re-evaluation)

1. Read `ideas/{IDEA_SLUG}/idea.md` frontmatter
2. Determine version N = length of `evaluations[]` + 1
3. Append new evaluation entry to `evaluations[]` with `version: v{N}`, `trigger: re-evaluation`
4. Set `status: evaluating` (only if current status is not `building` or `launched`)

### Case D: Both exist (should never happen)

If both `ideas/{IDEA_SLUG}/idea.md` AND `ideas/drafts/{IDEA_SLUG}.md` exist, the folder wins. Delete the stale draft, log a warning, and proceed as Case C.

## Step 1: Adaptive Interview

Before launching research, conduct a structured 3-pass interview to surface information research agents cannot discover. Each pass has explicit skip conditions — if the description already provides clear, specific answers, skip that pass silently.

**Before asking anything**, briefly state what you already understand from the description in 1-2 sentences, then signal that a couple of quick questions are coming:
> "From your description, I can see [summarize: business model, target customer, and problem]. A couple of quick questions before I start the research."

---

### Pass 1 — Idea Clarity *(adaptive, 0-2 questions)*

**Check first:** Does the description concretely name:
- A specific target customer (not a broad category like "small businesses" or "people who struggle with X")?
- A specific painful workaround — what users currently do before your product exists?

**If YES to both:** Skip Pass 1 silently. Proceed to Pass 2.

**If NO to either:** Ask only the missing question(s), one at a time:
- "Who specifically is your target customer? Not the broad category — the person you'd call tomorrow."
- "What does their current painful workaround look like before your product exists?"

Wait for each answer before asking the next.

---

### Pass 2 — Founder Insight *(always runs — never skip)*

This pass always runs regardless of description richness. Founders describe what they're building, not why they're the right person or why now — these are the highest-value evaluation inputs and research agents cannot surface them.

Ask in order, waiting for each answer before asking the next:

**Q1 (always ask):**
> "Why doesn't something like this already exist — or why have past attempts failed?"

**Q2 (always ask):**
> "What do you know about this market that most people outside it don't?"

**Q3 (conditional — only ask if Q1 and Q2 answers don't reveal any personal connection or lived experience with the problem):**
> "What's your personal connection to this problem?"

---

### Pass 3 — Traction & Build *(adaptive, 0-2 questions)*

**Check first:** Does the description explicitly name:
- Concrete validation signals (specific numbers, named early users, paid customers, LOIs, or waitlist signups)?
- Technical background clearly establishing whether the founder can build the MVP? (not just "I'm a developer" — look for specific skills, prior launches, or a named tech stack relevant to this idea)

**If YES to both:** Skip Pass 3 silently.

**If NO to either:** Ask only the missing question(s), one at a time:
- "Any early validation so far? Signups, conversations where someone said they'd pay, beta users, or strong reactions when you described the idea?"
- "Can you build the MVP yourself, and do you have any existing infrastructure — a tech stack, deployment setup, or audience — you could reuse?"

Wait for each answer before asking the next.

---

### Compile INTERVIEW_CONTEXT

After all passes are complete (or skipped), compile answers into a structured block. Tag each field with its source: `direct` = founder answered directly, `inferred` = extracted from description.

```
INTERVIEW_CONTEXT:
  target_customer: "[answer or inferred value]" (source: direct|inferred)
  painful_workaround: "[answer or inferred value]" (source: direct|inferred)
  why_doesnt_exist: "[Pass 2 Q1 answer]" (source: direct)
  unfair_insight: "[Pass 2 Q2 answer]" (source: direct)
  founder_origin: "[Pass 2 Q3 answer, or inferred from Q1/Q2 if personal connection was clear, or 'not established' if neither Q3 was asked nor any connection inferred]" (source: direct|inferred|none)
  validation_signals: "[Pass 3 answer or inferred value]" (source: direct|inferred)
  build_ability: "[Pass 3 answer or inferred value]" (source: direct|inferred)
  infrastructure: "[Pass 3 answer or inferred value]" (source: direct|inferred)
```

Save INTERVIEW_CONTEXT for use in Step 3 (scoring).

## Step 2: Launch Stage 1 — Research Agents (Parallel)

Dispatch the 5 research agents below in a single message so they run in parallel (Agent tool, `subagent_type="general-purpose"`). Each one reads its prompt file and `references/tool-status.md`, runs the research with the extracted keywords, and returns a structured report. Each brief is self-contained, because the agent sees nothing of this conversation.

Substitute the absolute path of this skill's folder for `<skill-folder>` in every dispatch prompt below before dispatching — subagents start without it.

### Agents 1–5

**Agent 1: Market Research**
```
Read the prompt at <skill-folder>/agents/market-research.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}
WIKIPEDIA_TITLES: {titles}

Run the research the prompt specifies, adapting queries to this specific idea and using the tool-status.md substitute wherever a CLI is broken. Return the complete Market Research Report in the format specified.
```

**Agent 2: Competition Research**
```
Read the prompt at <skill-folder>/agents/competition-research.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}

Run the research the prompt specifies, adapting queries to this specific idea and using the tool-status.md substitute wherever a CLI is broken. Return the complete Competition Research Report in the format specified.
```

**Agent 3: Data Research**
```
Read the prompt at <skill-folder>/agents/data-research.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}
DATA_ENTITIES: {entities}

Run the research the prompt specifies, adapting queries to this specific idea and using the tool-status.md substitute wherever a CLI is broken. Return the complete Data Research Report in the format specified.
```

**Agent 4: Distribution Research**
```
Read the prompt at <skill-folder>/agents/distribution-research.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}
DATA_ENTITIES: {entities}

Run the research the prompt specifies, adapting queries to this specific idea and using the tool-status.md substitute wherever a CLI is broken. Return the complete Distribution Research Report in the format specified.
```

**Agent 5: Customer Voice Research**
```
Read the prompt at <skill-folder>/agents/customer-voice.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}
DATA_ENTITIES: {entities}
COMPETITOR_DOMAINS: {any known competitors, or "none yet"}

Run the research the prompt specifies, using the tool-status.md substitute wherever a CLI is broken. Search Reddit (via site:reddit.com SERPs), Google PAA, reviews, and forums for real customer pain signals. Return the complete Customer Voice Report in the format specified.
```

## Step 2.5: Stage 1.5 — Competitor Deep-Dive

As soon as the Competition Research Agent (Agent 2) returns, without waiting for the other four, extract the competitor domains from its report (look for the `COMPETITOR_DOMAINS:` line).

Dispatch 1 additional agent:

**Agent 6: Competitor Deep-Dive**
```
Read the prompt at <skill-folder>/agents/competitor-deep-dive.md and follow its instructions exactly. First read <skill-folder>/references/tool-status.md: it lists broken CLIs and their substitutes; report any new failure you hit.

IDEA_DESCRIPTION: {idea_description}
NICHE_KEYWORDS: {keywords}
COMPETITOR_DOMAINS: {domains from competition research report}

Run the research the prompt specifies for each competitor domain, using the tool-status.md substitute wherever a CLI is broken. Return the complete Competitor Deep-Dive Report in the format specified.
```

It needs Agent 2's domain list, so it starts after Agent 2; Agents 1, 3, 4, and 5 keep running alongside it.

## Step 3: Stage 2 — Scoring

Once all 6 reports are in (Market, Competition, Data, Distribution, Customer Voice, Competitor Deep-Dive):

1. Read `agents/scoring.md`
2. Follow the scoring process with these inputs:
   - IDEA_DESCRIPTION
   - MARKET_RESEARCH (from Agent 1)
   - COMPETITION_RESEARCH (from Agent 2)
   - DATA_RESEARCH (from Agent 3)
   - DISTRIBUTION_RESEARCH (from Agent 4)
   - CUSTOMER_VOICE (from Agent 5)
   - COMPETITOR_DEEP_DIVE (from Agent 6)
   - BUSINESS_MODEL (from Step 0 — the scoring agent needs this to load the correct lens)
   - INTERVIEW_CONTEXT (from Step 1 — structured founder interview covering target customer, painful workaround, timing hypothesis, unfair insight, founder origin, validation signals, build ability, and infrastructure)
3. Score all 13 criteria using the lens-specific rubrics. The Customer Voice report provides [SYNTHETIC-INTERVIEW] evidence for Problem Severity (Criterion 2) — use quoted customer language as evidence, weighted higher than aggregate metrics.
4. Produce the Scoring Report

## Step 4: Stage 3 — Critic Review

With the scoring report complete:

1. Read `agents/critic.md`
2. Apply the critic process with:
   - IDEA_DESCRIPTION
   - SCORING_REPORT (from Step 3)
   - All 6 research reports for cross-reference
3. Review each score for bias
4. Produce the Critic Review with adjusted scores

## Step 5: Stage 4 — Final Orchestration

With the critic review complete:

1. Read `agents/orchestrator.md`
2. Apply the orchestration process with:
   - IDEA_DESCRIPTION
   - IDEA_SLUG
   - CRITIC_REVIEW (from Step 4)
   - Research summaries from Agents 1–5
   - COMPETITOR_DEEP_DIVE (from Agent 6)
   - BUSINESS_MODEL (from Step 0)
3. Calculate the weighted score using the lens-specific weights from `references/lenses/{BUSINESS_MODEL}.md`
4. Determine the verdict
5. Generate the scored idea card

## Step 5.5: Archive Research Data

Save all raw research data for future reference. Use the Write tool to save each research report as a markdown file under `research/v{N}/`, where N is the evaluation version from Step 0a (1 for a first evaluation), so a re-evaluation never overwrites earlier evidence.

**Path assumption:** By this step, the idea is guaranteed to be at `ideas/{slug}/` (a promoted folder), because Step 0a promoted any existing draft before research began. Never write research files under `ideas/drafts/` — the drafts/ location is reserved for flat `{slug}.md` files only, and any idea that needs a research/ subfolder must already be promoted.

- `ideas/{slug}/research/v{N}/market.md` — full Market Research report
- `ideas/{slug}/research/v{N}/competition.md` — full Competition Research report
- `ideas/{slug}/research/v{N}/data.md` — full Data Research report
- `ideas/{slug}/research/v{N}/distribution.md` — full Distribution Research report
- `ideas/{slug}/research/v{N}/customer-voice.md` — full Customer Voice report
- `ideas/{slug}/research/v{N}/competitor-profiles.md` — full Competitor Deep-Dive report
- `ideas/{slug}/research/v{N}/scoring.md` — full Scoring Report
- `ideas/{slug}/research/v{N}/critic.md` — full Critic Review

This creates a permanent, human-reviewable archive of all evidence used in the evaluation.

## Step 6: Save Outputs

### Save the Idea Card

Write the scored card to:
```
ideas/{slug}/scored-card-v{N}.md
```

### Update the Ranking

Check if `ideas/_registry/ranking.md` exists.

**If it doesn't exist**, create it:
```markdown
# Idea Rankings

Ideas ranked by weighted evaluation score. Each idea was evaluated through the multi-stage pipeline (Research > Deep-Dive > Score > Critic > Orchestrate).

| Rank | Idea | Verdict | Score | Top Strength | Top Weakness | Date |
|------|------|---------|-------|-------------|-------------|------|
| 1 | [{idea_name}](../{slug}/scored-card-v{N}.md) | {VERDICT} | {percentage}% | {strength} | {weakness} | {date} |
```

**If it exists**, read it, insert the new entry at the correct position (sorted by score descending), and re-number all ranks.

## Step 6b: Write-Back to Idea Vault

After writing the scored card, update the idea's metadata in the vault:

1. Read `ideas/{slug}/idea.md`
2. Update `evaluations[latest]`: set `score` and `verdict` from the orchestrator output
3. Set `latest_evaluation: scored-card-v{N}.md`
4. If status was `evaluating`, set `status: evaluated`
5. Rewrite `ideas/{slug}/idea.md` with updated frontmatter
6. Update `ideas/_registry/master-index.yaml` with new score, verdict, status, and latest_evaluation

**Error handling:** If YAML parsing of idea.md fails, write updates to `ideas/{slug}/idea-update-pending.yaml` sidecar file and report the error to the user.

## Step 7: Report to User

Present the verdict clearly:

```
## Evaluation Complete

**{IDEA_NAME}**: {VERDICT} ({percentage}%)

### Scorecard Summary
{Show the 13 criteria table with scores}

### Top 3 Strengths
1. {strength}
2. {strength}
3. {strength}

### Top 3 Weaknesses
1. {weakness}
2. {weakness}
3. {weakness}

### Recommendation
{2-3 sentences from the orchestrator}

Full scored card saved to: ideas/{slug}/scored-card-v{N}.md
```

## Error Recovery

- If a research agent fails entirely, proceed with the remaining agents and note the gap in the scoring
- If CLI tools are unavailable (network issues, missing dependencies), score affected criteria at 2 with a note that evidence was unavailable
- If the user skips or gives minimal answers in Pass 2 (the founder insight pass), score Criterion 11 at 3 (neutral) and note the unfair insight and timing hypothesis were not assessed
- If INTERVIEW_CONTEXT fields are `inferred` rather than `direct` for C11-relevant dimensions, treat them as supporting context rather than primary evidence — score conservatively

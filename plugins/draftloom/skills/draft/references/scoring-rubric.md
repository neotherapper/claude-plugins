# Scoring Rubric

Rules the orchestrator uses to route after each eval. Load this file in orchestrator.md.

## aggregate_score calculation

aggregate_score = min(seo_score, hook_score, voice_score, readability_score)

The minimum score across all dimensions. Never the average. No dimension can compensate for another.

## Routing table

| Condition | Action |
|-----------|--------|
| halt phrase detected | **Halt.** Dispatch distribution immediately with current `draft.md`. Do not evaluate. (See halt detection section.) |
| any dimension < 50 | **Escalate.** Pause loop. Ask user escalation questions (see below). Max 1 escalation per run — tracked via `escalation_triggered: true` in `meta.json`. |
| any dimension 50–74 | **Patch.** Dispatch writer with failing eval JSONs. Writer patches `sections_affected` only. |
| all dimensions ≥ 75 | **Pass.** Dispatch distribution agent. |
| max iterations reached | **Offer choice.** See max-iterations section. |

## Escalation questions (when any dimension < 50)

Ask up to 4 questions — Q2 is only asked if user answers yes to Q1; Q4 is an action, not a question:
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

Reached {max} iterations. Aggregate score: {score}/100.

What would you like to do?
1. Publish anyway (dispatch distribution with current draft)
2. Continue for N more iterations (specify N)
3. Discard this draft (draft_status: abandoned)

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

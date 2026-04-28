# Idea Forge — Personas

## The Domain Scout

Runs `/idea-forge:generate` to surface business ideas from accumulated research.

**Goal:** Arrive at a ranked shortlist of opportunity seeds without starting from a blank page. The Scout has already done domain research — they want the model to find the gaps they haven't articulated yet.

**Trigger:** Has a vault domain with research content and wants to know which opportunities are worth pursuing before committing to evaluation.

**Workflow:**
1. Points `/idea-forge:generate` at a domain in their vault
2. Reviews the ranked shortlist in the seeds file
3. Discards obvious misfits, passes the rest to `/idea-forge:evaluate` one at a time

**What they care about:**
- Candidates grounded in real research signals, not fabricated
- Clear Evidence scores so they can judge the quality of the shortlist
- A seeds file they can return to across multiple sessions

**What they don't want:**
- Generic ideas that ignore the domain context they've built
- A long interview before seeing any output
- Seeds with no differentiation rationale

---

## The Validator

Runs `/idea-forge:evaluate` on a specific idea they already have in mind.

**Goal:** Get evidence-backed scoring with an honest verdict before investing months of founder time. The Validator is not looking for encouragement — they want the model to find the weaknesses they haven't seen.

**Trigger:** Has a concrete idea (from a seeds file or their own thinking) and needs a structured, researched assessment to decide whether to build, pivot, or kill it.

**Workflow:**
1. Invokes `/idea-forge:evaluate` with a seed or inline description
2. Answers the 5 intake questions to sharpen the research brief
3. Reviews the scored card and the critic's adjustments
4. Uses the verdict and dimension scores to decide next action

**What they care about:**
- Research agents that return real competitive signal, not placeholder data
- Critic pass that flags where the scoring is optimistic
- A verdict they can defend to themselves and co-founders
- Scores broken out by dimension so they know which weakness to address first

**What they don't want:**
- Scores that drift with each run (no determinism in the rubric)
- A verdict that hedges without a clear recommendation
- Having to supply a seeds file when they already know their idea

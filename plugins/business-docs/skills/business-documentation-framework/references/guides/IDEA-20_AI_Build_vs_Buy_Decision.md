# Generation Guide: IDEA-20 AI Build vs Buy Decision

**Purpose:** Decide whether to build a custom AI capability or purchase an existing SaaS solution.

---

## Prerequisites
- IDEA-19 Feasibility Assessment

## Questions to Ask the User
- Is this capability a core differentiator for your business?
- Do you have internal development capacity?
- What is the "OpenAI Test": what happens if OpenAI releases this tomorrow?

## Document Template

```markdown
# AI Build vs Buy Decision

**ID:** IDEA-20
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** IDEA-19
**Gateway:** No

---

## Capability Evaluated: [Name]

### Option A: BUILD
- **Pros:** [Customization, data moat]
- **Cons:** [Higher TCO, maintenance]
- **5-Year TCO:** [$X]

### Option B: BUY
- **Pros:** [Speed to market, lower upfront]
- **Cons:** [Vendor lock-in, generic]
- **5-Year TCO:** [$X]

## Decision Matrix
| Factor | Weight | Build Score | Buy Score |
|---|---|---|---|
| Core differentiator? | 3x | /5 | /5 |

## Final Recommendation
> [Decision + Rationale]
```

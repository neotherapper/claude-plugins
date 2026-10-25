# Generation Guide: PROD-19 Experiment Results

**Purpose:** Record the outcome of hypothesis testing and determine the next steps (pivot, persevere, or kill).

---

## Prerequisites
- PROD-18 Hypothesis Documentation

## Questions to Ask the User
- What were the actual results of the experiment?
- Were there any surprises or confounding factors?
- What is the final decision: Proceed or Pivot?

## Document Template

```markdown
# Experiment Results: [H-ID]

**ID:** PROD-19
**Version:** 1.0
**Status:** Complete
**Created:** [Date]
**Dependencies:** PROD-18
**Gateway:** No

---

## Results Table
| Metric | Target | Actual | Status |
|---|---|---|---|
| | | | ✓/✗ |

## Key Learnings
1. [Surprising behavior]
2. [Validated assumption]

## Conclusion
- **Verdict:** [VALIDATED / INVALIDATED]
- **Next Action:** [Proceed / Pivot / Kill]

## Impact on Roadmap
[Updates required to PROD-05]
```

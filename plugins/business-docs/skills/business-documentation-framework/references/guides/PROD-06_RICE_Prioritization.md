# Generation Guide: PROD-06 RICE Prioritization

**Purpose:** Quantitatively score and rank features based on impact and effort.

---

## Prerequisites
- PROD-09 PRD (backlog)

## Questions to Ask the User
- How many people will this affect (Reach)?
- How much will this move the North Star metric (Impact)?
- How sure are you about these numbers (Confidence)?

## Document Template

```markdown
# RICE Prioritization Matrix

**ID:** PROD-06
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-09
**Gateway:** No

---

| Feature | Reach | Impact | Confidence | Effort | RICE Score |
|---|---|---|---|---|---|
| [Feat 1] | | | | | |

## Scoring Legend
- **Reach:** Customers per period
- **Impact:** 3 (Massive), 2 (High), 1 (Medium), 0.5 (Low)
- **Confidence:** % (80-100% is high)
- **Effort:** Person-months
```

# Generation Guide: PROD-18 Hypothesis Documentation

**Purpose:** Formally document testable assumptions about product behavior and user response.

---

## Prerequisites
- PROD-17 MVP Canvas

## Questions to Ask the User
- What specific experiment will you run?
- How will you collect data?
- What sample size makes the results meaningful?

## Document Template

```markdown
# Hypothesis: [H-ID] [Title]

**ID:** PROD-18
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-17
**Gateway:** No

---

## Statement
> We believe that **[action]** will result in **[outcome]** for **[segment]**.

## Experiment Design
- **Type:** [A/B Test / Fake Door / Interview]
- **Duration:** [X days]
- **Sample Size:** [N]

## Metrics
- **Primary:** [Metric]
- **Baseline:** [Current value]
- **Target:** [Value]

## Success Criteria
- **Validated:** [Target met]
- **Invalidated:** [Target missed]
```

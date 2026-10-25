# Generation Guide: IDEA-03 5 Whys Analysis

**Purpose:** Perform root cause analysis to uncover human/systemic problems underlying a specific failure or problem.

---

## Prerequisites
- A clearly identified problem or incident

## Questions to Ask the User
- What is the specific problem or incident that occurred?
- Who was involved or affected?
- What was the immediate first cause you identified?

## Document Template

```markdown
# 5 Whys Analysis: [Problem Title]

**ID:** IDEA-03
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** IDEA-01 (or incident discovery)
**Gateway:** No

---

## Problem Statement
[Brief, specific description of the problem]

## Analysis

**1. Why did [problem] occur?**
- Answer: [Direct cause]
- Corrective Action: [Small proportional fix]
- Owner: [Name]

**2. Why did [Answer 1] happen?**
- Answer: [Underlying cause]
- Corrective Action: [Process improvement]
- Owner: [Name]

**3. Why did [Answer 2] happen?**
- Answer: [Systemic cause]
- Corrective Action: [Training or tool change]
- Owner: [Name]

**4. Why did [Answer 3] happen?**
- Answer: [Management or cultural cause]
- Corrective Action: [Policy update]
- Owner: [Name]

**5. Why did [Answer 4] happen?**
- Answer: [Root Cause]
- Corrective Action: [Strategic investment]
- Owner: [Name]

## Root Cause Summary
[Summary of the fundamental human or systemic issue discovered. Focus on process, not people.]

## Completion Checklist
- [ ] Reached a human or systemic root cause
- [ ] Proportional investment identified for each level
- [ ] Assignees and deadlines set
- [ ] Communicated to relevant stakeholders
```

# Generation Guide: PROD-21 Release Plan

**Purpose:** Orchestrate the timing and sequence of feature releases across internal and external environments.

---

## Prerequisites
- PROD-05 Product Roadmap

## Questions to Ask the User
- When is the target GA (General Availability) date?
- Will there be a private or public beta?
- What are the critical dependencies for this release?

## Document Template

```markdown
# Release Plan: [Version]

**ID:** PROD-21
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-05
**Gateway:** No

---

## Rollout Timeline
- **Alpha:** [Date] - [Internal only]
- **Beta:** [Date] - [Waitlist users]
- **GA:** [Date] - [Public]

## Scope
- [Feature 1]
- [Feature 2]

## Dependencies
- **Technical:** [e.g., API migration]
- **Marketing:** [e.g., Launch blog]
```

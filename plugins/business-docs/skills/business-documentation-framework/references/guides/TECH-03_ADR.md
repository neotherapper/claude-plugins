# Generation Guide: TECH-03 ADR (Architecture Decision Record)

**Purpose:** Document a single architecturally significant decision and its rationale for future reference.

---

## Prerequisites
- TECH-02 TDD

## Questions to Ask the User
- What specific decision was made (e.g., choice of DB)?
- What was the context or problem driving this choice?
- What are the positive and negative consequences?

## Document Template

```markdown
# ADR-[NNNN]: [Decision Title]

**ID:** TECH-03
**Status:** [Proposed / Accepted / Superseded]
**Date:** [Date]
**Deciders:** [List]

---

## Context
[What is the issue we're seeing that motivates this decision?]

## Decision
[What is the change we're proposing and/or doing?]

## Consequences
- **Positive:** [What becomes easier?]
- **Negative:** [What becomes harder? New constraints?]
- **Neutral:** [Known side effects]

## Alternatives Considered
- [Alt 1] - Rationale for rejection: [Reason]
```

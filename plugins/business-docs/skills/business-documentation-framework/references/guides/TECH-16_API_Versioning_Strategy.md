# Generation Guide: TECH-16 API Versioning Strategy

**Purpose:** Document the policy and mechanism for managing API changes to ensure backward compatibility and smooth migrations.

---

## Prerequisites
- TECH-12 OpenAPI Spec (or similar)

## Questions to Ask the User
- What is your versioning scheme (Path, Header, Query)?
- What is the deprecation policy (timeframe)?
- How are breaking changes communicated to consumers?

## Document Template

```markdown
# API Versioning Strategy

**ID:** TECH-16
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** TECH-12
**Gateway:** No

---

## Versioning Mechanism
- **Scheme:** [e.g., URL path /v1/]
- **Format:** [e.g., Semantic Versioning]

## Lifecycle Policy
- **Deprecation period:** [X months]
- **Sunset notification:** [Mechanism]

## Breaking Change Definition
- [List criteria]
```

# Generation Guide: TECH-02 Technical Design Document (GATEWAY)

**Purpose:** Provide a detailed blueprint for implementation, ensuring architecture, data, and security are sound.

---

## Prerequisites
- PROD-09 PRD

## Extraction from PRD
- Functional requirements
- Performance/Security targets
- User flows

## Questions to Ask the User
- What is the high-level architecture pattern (e.g., Microservices, Monolith)?
- What is the primary data model and relationships?
- What are the biggest technical risks you foresee?

## Document Template

```markdown
# Technical Design Document (TDD)

**ID:** TECH-02
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-09
**Gateway:** Yes

---

## 1. Overview
**What:** [Brief description]
**Why:** [Reference to PRD requirements]

## 2. Architecture
### System Context (C4 Level 1)
[Mermaid Diagram]

### Container Diagram (C4 Level 2)
[Mermaid Diagram]

## 3. Detailed Design
### Data Model
[ERD or Schema definition]

### Component Breakdown
| Component | Responsibility | Tech |
|---|---|---|
| | | |

## 4. Security & Performance
- **Auth:** [Mechanism]
- **Scalability:** [10x growth plan]

## 5. Alternatives Considered
[Brief summary of choices made]

## Gateway Approval
**Required Approvers:** Tech Lead, Security Review
```

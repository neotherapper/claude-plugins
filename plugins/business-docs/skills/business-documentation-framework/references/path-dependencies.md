# Path Dependencies Reference

Detailed dependency tables for each documentation path.

---

## Table of Contents

- [Internal Tool Path (6 Documents)](#internal-tool-path-6-documents)
- [MVP Path (11 Documents)](#mvp-path-11-documents)
- [Investor Path (16+ Documents)](#investor-path-16-documents)
- [Full Path (85 Documents)](#full-path-85-documents)
- [Gateway Documents Summary](#gateway-documents-summary)
- [Dependency Resolution Rules](#dependency-resolution-rules)

---

## Internal Tool Path (6 Documents)

For internal tools where users are known employees.

```
IDEA-04⭐ → IDEA-09(lite) → IDEA-19⭐ → PROD-29 → TECH-02⭐ → OPS-01
```

| Order | ID      | Name                   | Gateway | Depends On                    | Time     |
| ----- | ------- | ---------------------- | ------- | ----------------------------- | -------- |
| 1     | IDEA-04 | Problem Statement      | **YES** | None (internal validation OK) | 2-3 days |
| 2     | IDEA-09 | Lean Canvas (lite)     | No      | IDEA-04                       | 1 day    |
| 3     | IDEA-19 | Feasibility Assessment | **YES** | IDEA-09                       | 2-3 days |
| 4     | PROD-29 | One-Pager PRD          | No      | IDEA-19                       | 1-2 days |
| 5     | TECH-02 | Technical Design Doc   | **YES** | PROD-29                       | 3-5 days |
| 6     | OPS-01  | README                 | No      | TECH-02                       | 1 day    |

### Internal Tool Adaptations

| Document | Standard Requirement     | Internal Tool Adaptation                                 |
| -------- | ------------------------ | -------------------------------------------------------- |
| IDEA-04  | 10+ customer interviews  | Informal stakeholder conversations OK                    |
| IDEA-09  | All 9 Lean Canvas blocks | Focus on: Problem, Solution, Key Metrics, Cost Structure |
| IDEA-19  | Market Feasibility       | "Internal Demand Assessment" instead                     |
| TECH-02  | Full architecture        | Lighter for simple tools (skip C4 Level 3+)              |

---

## MVP Path (11 Documents)

For external products focused on customer validation.

```
IDEA-01 → IDEA-02 → IDEA-04⭐ → IDEA-08 → IDEA-09⭐ → IDEA-19⭐ → PROD-17 → PROD-18 → PROD-09⭐ → TECH-02⭐
```

| Order | ID      | Name                     | Gateway | Depends On       | Time      |
| ----- | ------- | ------------------------ | ------- | ---------------- | --------- |
| 1     | IDEA-01 | Customer Interviews      | No      | None             | 2-3 weeks |
| 2     | IDEA-02 | JTBD Analysis            | No      | IDEA-01          | 2-3 days  |
| 3     | IDEA-04 | Problem Statement        | **YES** | IDEA-02          | 2-3 days  |
| 4     | IDEA-08 | Value Proposition Canvas | No      | IDEA-04          | 1-2 days  |
| 5     | IDEA-09 | Lean Canvas              | **YES** | IDEA-08          | 2-3 days  |
| 6     | IDEA-19 | Feasibility Assessment   | **YES** | IDEA-09          | 2-3 days  |
| 7     | PROD-17 | MVP Canvas               | No      | IDEA-09          | 1-2 days  |
| 8     | PROD-18 | Hypothesis Documentation | No      | PROD-17          | 1-2 days  |
| 9     | PROD-09 | PRD                      | **YES** | IDEA-19, PROD-18 | 3-5 days  |
| 10    | TECH-02 | Technical Design Doc     | **YES** | PROD-09          | 3-5 days  |

### Optional Discovery Addition

If user indicates unclear solution, insert IDEA-18 (Opportunity Solution Tree) after IDEA-09:

```
IDEA-09⭐ → IDEA-18 (optional) → IDEA-19⭐
```

Trigger: User says "I'm not sure what to build" or "multiple possible solutions"

---

## Investor Path (16+ Documents)

MVP Path + Market Analysis + Pitch Deck.

### Core MVP Documents (same as MVP Path)

Orders 1-10 same as MVP Path above.

### Market Analysis Track (parallel after IDEA-04)

| Order | ID      | Name                  | Gateway | Depends On | Time     |
| ----- | ------- | --------------------- | ------- | ---------- | -------- |
| 4a    | IDEA-05 | Mission Statement     | No      | IDEA-04    | 0.5 days |
| 4b    | IDEA-06 | Vision Statement      | No      | IDEA-05    | 0.5 days |
| 4c    | IDEA-10 | Business Model Canvas | No      | IDEA-06    | 1-2 days |
| 4d    | IDEA-11 | TAM/SAM/SOM Analysis  | No      | IDEA-04    | 2-3 days |
| 4e    | IDEA-12 | Porter's Five Forces  | No      | IDEA-11    | 1-2 days |
| 4f    | IDEA-14 | Competitive Analysis  | No      | IDEA-12    | 2-3 days |
| 4g    | IDEA-15 | Why Now Analysis      | No      | IDEA-14    | 1 day    |

### Build vs Buy (after IDEA-19)

| Order | ID      | Name                   | Gateway | Depends On | Time     |
| ----- | ------- | ---------------------- | ------- | ---------- | -------- |
| 11    | IDEA-20 | Build vs Buy Framework | No      | IDEA-19    | 1-2 days |

### Pitch Deck (final)

| Order | ID      | Name       | Gateway | Depends On | Time     |
| ----- | ------- | ---------- | ------- | ---------- | -------- |
| 12    | IDEA-16 | Pitch Deck | **YES** | All above  | 3-5 days |

---

## Full Path (85 Documents)

For enterprise, regulated, or comprehensive documentation needs.

See [document-registry.md](document-registry.md) for complete list of all 85 documents.

### Phase Overview

| Phase      | Documents          | Focus                                     |
| ---------- | ------------------ | ----------------------------------------- |
| Ideation   | IDEA-01 to IDEA-21 | Customer understanding, market validation |
| Product    | PROD-01 to PROD-29 | Requirements, specifications, features    |
| Technical  | TECH-01 to TECH-16 | Architecture, design, infrastructure      |
| Operations | OPS-01 to OPS-07   | Documentation, deployment, monitoring     |
| ML/AI      | ML-01 to ML-04     | Data, models, ML systems                  |
| Security   | SEC-01 to SEC-02   | Security review, compliance               |

---

## Gateway Documents Summary

Gateway documents require explicit approval before proceeding to next phase.

| ID      | Name                   | What It Gates                             |
| ------- | ---------------------- | ----------------------------------------- |
| IDEA-04 | Problem Statement      | Validates problem worth solving           |
| IDEA-09 | Lean Canvas            | Validates business model viability        |
| IDEA-16 | Pitch Deck             | Validates investor readiness              |
| IDEA-19 | Feasibility Assessment | Validates technical/financial feasibility |
| PROD-09 | PRD                    | Validates product scope                   |
| TECH-02 | Technical Design Doc   | Validates architecture                    |
| SEC-01  | Security Review        | Validates security posture                |

---

## Dependency Resolution Rules

### If dependency exists in project:

1. Search project for document ID
2. Extract required information (see extraction-guide.md)
3. Reference it explicitly in new document

### If dependency is missing:

1. Check if on defined path - backtrack if needed
2. If user is skipping, offer Quick Foundation Questions
3. Generate with [ASSUMPTION] markers

### Cross-document consistency:

- Customer segment must match IDEA-04 wording
- Problem statement must be consistent
- Metrics must align across documents
- Terminology must be identical (no synonyms)

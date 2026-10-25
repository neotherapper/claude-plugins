# Generation Guide: OPS-06 Technical Debt Register

**Purpose:** Track and prioritize known shortcuts, legacy code, and architectural issues requiring remediation.

---

## Prerequisites
- Implementation experience or TECH-03 ADRs

## Questions to Ask the User
- What is the specific area of debt?
- What is the "interest" (friction or risk) being paid?
- What is the estimated effort to resolve?

## Document Template

```markdown
# Technical Debt Register

**ID:** OPS-06
**Updated:** [Date]

---

## Debt Inventory

| ID | Item | Risk/Friction | Effort | Status |
|---|---|---|---|---|
| TD-1 | [Description] | [High/Med/Low] | [S/M/L] | Backlog |

## Detail: [TD-1]
- **Context:** [Why we took the shortcut]
- **Impact:** [How it slows us down]
- **Remediation Plan:** [Step-by-step fix]
```

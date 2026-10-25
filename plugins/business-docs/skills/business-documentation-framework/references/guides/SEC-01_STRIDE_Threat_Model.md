# Generation Guide: SEC-01 STRIDE Threat Model (GATEWAY)

**Purpose:** Systematically identify security threats by evaluating the system against the STRIDE categories (Spoofing, Tampering, etc.).

---

## Prerequisites
- TECH-05 C4 Container Diagram

## Questions to Ask the User
- What are the primary trust boundaries in your architecture?
- Which containers handle sensitive data (PII, Payments)?
- What authentication and authorization mechanisms are in place?

## Document Template

```markdown
# STRIDE Threat Model: [System Name]

**ID:** SEC-01
**Gateway:** Yes

---

## 1. Analysis Scope
- **Components:** [From TECH-05]
- **Trust Boundaries:** [e.g., Web to API]

## 2. Threat Assessment
| Category | Threat | Asset | Mitigation |
|---|---|---|---|
| **S**poofing | | | |
| **T**ampering | | | |
| **R**epudiation | | | |
| **I**nfo Disclosure| | | |
| **D**enial of Service| | | |
| **E**levation | | | |

## 3. Risk Summary
- **High Risk:** [Priority item]
- **Residual Risk:** [Accepted item]

## Gateway Approval
**Required Approver:** Security Lead
```

# Generation Guide: OPS-04 Runbook

**Purpose:** Provide step-by-step instructions for responding to specific operational alerts or system failures.

---

## Prerequisites
- TECH-05 C4 Container Diagram

## Questions to Ask the User
- What is the specific alert name or failure scenario?
- What is the immediate diagnosis command?
- What is the escalation path if the first responder can't fix it?

## Document Template

```markdown
# Runbook: [Scenario/Alert Name]

**ID:** OPS-04
**Severity:** [P1 / P2 / P3]
**Last Updated:** [Date]

---

## 1. Overview
- **Trigger:** [Alert description]
- **Impact:** [What happens to users?]

## 2. Diagnosis
```bash
# Command to check logs
kubectl logs ...
```

## 3. Resolution
1. [Step 1: e.g., Restart service]
2. [Step 2: e.g., Flush cache]

## 4. Escalation
| Level | Contact | When |
|---|---|---|
| L1 | On-call | 0-15 min |
| L2 | Tech Lead | > 15 min |
```

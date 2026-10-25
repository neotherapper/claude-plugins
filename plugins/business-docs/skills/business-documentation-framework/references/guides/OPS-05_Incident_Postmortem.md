# Generation Guide: OPS-05 Incident Postmortem

**Purpose:** Analyze an incident to find root causes and create preventive action items without assigning blame.

---

## Prerequisites
- Incident data/logs

## Questions to Ask the User
- What was the total downtime or impact?
- What was the identified root cause (5 Whys)?
- What luck or preventative measures worked?

## Document Template

```markdown
# Postmortem: [Incident Title]

**ID:** OPS-05
**Date:** [Date]
**Incident ID:** [ID]

---

## Summary
[2-3 sentence overview]

## Impact
- **Duration:** [Time]
- **Users Affected:** [%]

## Timeline
- [HH:MM] Detection
- [HH:MM] Mitigation
- [HH:MM] Resolution

## Root Cause
[Summary of 5 Whys]

## Lessons Learned
- **What went well:**
- **What didn't:**
- **Where we got lucky:**

## Action Items
| Action | Owner | Status |
|---|---|---|
| [Fix] | | |
```

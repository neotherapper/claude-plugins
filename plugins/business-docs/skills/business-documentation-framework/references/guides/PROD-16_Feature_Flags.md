# Generation Guide: PROD-16 Feature Flags Documentation

**Purpose:** Document the configuration, rollout plan, and cleanup strategy for features managed by toggles.

---

## Prerequisites
- PROD-15 Feature Specification

## Questions to Ask the User
- What is the unique key for this flag?
- Who should see this feature first?
- What is the "kill switch" condition?

## Document Template

```markdown
# Feature Flag: [Name]

**ID:** PROD-16
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-15
**Gateway:** No

---

## Configuration
- **Key:** `feat_[name]_enabled`
- **Default State:** [Off/On]
- **Targeting:** [Internal/Beta/Public]

## Rollout Plan
1. **Internal (100%):** [Date]
2. **Beta (10%):** [Date]
3. **General Release:** [Date]

## Success Metrics
- [Metric to monitor] - Stop if [Value < X]

## Cleanup Plan
- **Target Removal Date:** [Date]
- **Owner:** [Name]
```

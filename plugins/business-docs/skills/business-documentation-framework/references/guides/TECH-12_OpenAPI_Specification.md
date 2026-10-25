# Generation Guide: TECH-12 OpenAPI Specification

**Purpose:** Define the machine-readable contract for RESTful APIs to enable implementation and consumer integration.

---

## Prerequisites
- TECH-02 TDD

## Questions to Ask the User
- What are the core endpoints and HTTP methods?
- What are the request/response schemas (JSON)?
- What authentication mechanism is used (Bearer, API Key)?

## Document Template

```markdown
# API Specification: [Service Name]

**ID:** TECH-12
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** TECH-02
**Gateway:** No

---

## Specification
```yaml
openapi: 3.1.0
info:
  title: [API Name]
  version: 1.0.0
paths:
  /resource:
    get:
      summary: List items
      responses:
        '200':
          description: OK
```

## Integration Guide
- **Base URL:** [URL]
- **Authentication:** [Details]
```

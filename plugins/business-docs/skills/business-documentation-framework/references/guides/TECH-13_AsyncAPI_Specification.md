# Generation Guide: TECH-13 AsyncAPI Specification

**Purpose:** Define the machine-readable contract for event-driven architectures and messaging systems.

---

## Prerequisites
- TECH-02 TDD

## Questions to Ask the User
- What message broker is used (Kafka, RabbitMQ)?
- What are the primary channels (topics/queues)?
- What is the payload schema for events?

## Document Template

```markdown
# AsyncAPI Specification: [Service Name]

**ID:** TECH-13
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** TECH-02
**Gateway:** No

---

## Specification
```yaml
asyncapi: 3.0.0
info:
  title: [Service] Events
  version: 1.0.0
channels:
  user/created:
    address: user.created
    messages:
      userCreated:
        payload:
          type: object
          properties:
            id: { type: string }
```
```

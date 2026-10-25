# Generation Guide: TECH-14 GraphQL Schema

**Purpose:** Define the schema for GraphQL-based APIs, including types, queries, and mutations.

---

## Prerequisites
- TECH-02 TDD

## Questions to Ask the User
- What are the core entities (Types)?
- What queries are needed for fetching data?
- What mutations are needed for modifying data?

## Document Template

```markdown
# GraphQL Schema: [Service Name]

**ID:** TECH-14

---

## Schema Definition
```graphql
type User {
  id: ID!
  username: String!
}

type Query {
  me: User
}

type Mutation {
  updateUser(username: String!): User
}
```

## Type Reference
- **[Type]:** [Description]
```

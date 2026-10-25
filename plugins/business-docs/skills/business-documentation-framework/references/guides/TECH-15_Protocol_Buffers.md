# Generation Guide: TECH-15 Protocol Buffers

**Purpose:** Define the structured data and service interfaces for gRPC or high-performance binary communication.

---

## Prerequisites
- TECH-02 TDD

## Questions to Ask the User
- What are the service methods (RPCs)?
- What are the request and response message structures?
- What is the package/namespace convention?

## Document Template

```markdown
# Protocol Buffers: [Service Name]

**ID:** TECH-15

---

## Specification
```protobuf
syntax = "proto3";

package example.v1;

service UserService {
  rpc GetUser (GetUserRequest) returns (User);
}

message GetUserRequest {
  string user_id = 1;
}

message User {
  string id = 1;
  string name = 2;
}
```
```

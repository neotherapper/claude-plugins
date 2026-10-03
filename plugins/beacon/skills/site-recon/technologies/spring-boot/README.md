---
framework: spring-boot
version: "3.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Spring Boot Framework Detection

## Framework Summary
- **Name**: Spring Boot
- **Type**: Application framework / microservice platform
- **Language**: Java (requires Java 17+ for 3.x)
- **Popularity**: #1 Java web framework; dominant in enterprise Java
- **Website**: [https://spring.io/projects/spring-boot](https://spring.io/projects/spring-boot)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| `X-Application-Context` header | `application=NAME:PROFILE:VERSION` | HTTP response headers |
| Whitelabel Error Page | HTML title "Whitelabel Error Page" | Trigger 404/500 error |
| `/actuator/` endpoints | Health, info, env, beans, mappings | HTTP GET |
| Error URL params | `?status=404&message=Not+Found` | Error page URL |
| Spring packages in stack trace | `org.springframework.web.servlet` | Debug mode errors |
| Thymeleaf attributes | `th:href`, `th:src` in HTML | Page source inspection |

### Technology Stack
Spring Boot is commonly paired with:
- Java 17+ (Spring Boot 3.x) / Java 8+ (Spring Boot 2.x)
- Apache Tomcat, Jetty, or Undertow (embedded servlet containers)
- Spring Security for authentication/authorization
- Spring Data JPA / Hibernate for persistence
- Thymeleaf or FreeMarker for server-side templating
- React, Vue.js, or Angular for SPA front-ends
- Spring Cloud for microservices patterns

## Fingerprint Probes

```bash
# Check for Spring Boot headers
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'application-context|x-'

# Trigger error page
curl -s https://target.example.com/does-not-exist/ | grep -i 'whitelabel\|spring'

# Probe actuator endpoints
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/actuator/health
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/actuator/info

# Check for Swagger/OpenAPI docs
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/swagger-ui/
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/v3/api-docs
```

## Security Considerations
- Actuator endpoints are often exposed in dev/staging; many contain sensitive data
- `server.error.include-stacktrace=always` leaks internal structure
- Spring Security 3.x defaults to deny-all; publicly accessible APIs indicate intentional config
- JWT (JJWT library) and session-based auth frequently coexist

## Resources
- [Spring Boot Official Documentation](https://spring.io/projects/spring-boot)
- [Spring Boot Actuator Reference](https://docs.spring.io/spring-boot/docs/current/actuator-api/)
- [Spring Security Reference](https://spring.io/projects/spring-security)
- [springdoc-openapi for Swagger UI](https://springdoc.org/)
- [Spring Boot GitHub](https://github.com/spring-projects/spring-boot)
---
framework: spring-boot
version: "3.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Spring Boot 3.x — Fingerprinting Guide

## Framework Overview

Spring Boot is a Java-based enterprise framework that makes it easy to create stand-alone, production-grade Spring-based applications. It is the dominant Java web framework, widely used in enterprise environments. This guide covers fingerprinting techniques for Spring Boot 3.x applications.

## Fingerprinting Patterns

### 1. HTTP Response Headers

| Header | Value Example | Confidence | Notes |
|--------|--------------|------------|-------|
| `X-Application-Context` | `myapp:prod:1` | High | Spring Boot 2.x default; may be disabled in 3.x via `server.servlet.application-display-name` |
| `Server` | `Apache-Coyote/1.1`, `nginx`, `Tomcat/10.1` | Low | Deployment container, not definitive |
| `X-Content-Type-Options` | `nosniff` | Medium | Spring Security default; indicates security filter chain |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | Medium | Spring Security default headers |
| `Cache-Control` | Spring-managed cache headers | Low | Generic; common across frameworks |

**Probe:**
```bash
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'application-context|x-|server|cache'
```

### 2. Error Page Signatures

| Error Type | Content | Confidence | Notes |
|------------|---------|------------|-------|
| 404 Whitelabel | `<title>Whitelabel Error Page</title>` in HTML | Definitive | Default Spring Boot error page |
| 404 status param | URL contains `?status=404&message=Not+Found` | High | Spring MVC error handler query params |
| 500 stack trace | `org.springframework.web.servlet` in stack trace | Definitive | Spring packages visible when DEBUG=True |
| 500 Spring Boot banner | Stack trace contains `ApplicationRunner` or `SpringApplication` | Definitive | Spring Boot startup context |
| Exception class names | `NestedServletException`, `HandlerDispatchException` | Definitive | Spring MVC exception classes |

**Probe:**
```bash
# Trigger 404 to check for Whitelabel error
curl -s https://target.example.com/does-not-exist-abc123/ | grep -i 'whitelabel\|spring\|status\|message'

# Trigger 500 for stack trace (may require specific input)
curl -s "https://target.example.com/?param=%7B%7D" | grep -o 'org\.springframework\.[^ ]*'
```

### 3. Cookie Patterns

| Cookie Name | Value Pattern | Confidence | Notes |
|-------------|--------------|------------|-------|
| `JSESSIONID` | Alphanumeric string, 32+ chars | High | Default servlet session cookie; does NOT indicate Spring Boot specifically (any Java servlet uses it) |
| `SPRING_SECURITY_REMEMBER_ME_COOKIE` | Hashed token | Definitive | Spring Security remember-me feature |
| `XSRF-TOKEN` | Bearer-like token string | High | Angular/Vue CSRF token; signals SPA + Spring Security |

### 4. HTML/Content Signatures

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `spring-boot` in script paths | `/webjars/spring-boot/` or `spring-boot-auto-configure` in JS | High | WebJars or Spring Boot devtools in page source |
| `data-template` attributes | Thymeleaf template attributes | Medium | Thymeleaf template engine in use |
| Bootstrap 5 via WebJars | `/webjars/bootstrap/5.x/` in HTML | Medium | Common pairing with Spring Boot + Thymeleaf |
| jQuery via WebJars | `/webjars/jquery/` in HTML | Low | Generic; many frameworks use jQuery |
| Thymeleaf expression | `th:href`, `th:src`, `th:text` in HTML | High | Thymeleaf template engine detected |
| `data-th-` attributes | Thymeleaf 3 specific attributes | High | Definitive for Thymeleaf usage |
| `csrfmiddlewaretoken` is Django | Different framework — avoid | — | Not Spring Boot |

### 5. JAR Signatures

When the application JAR is served or downloadable, the internal JAR structure reveals Spring Boot:

| File | What it reveals | Confidence |
|------|----------------|------------|
| `BOOT-INF/lib/spring-boot-*.jar` | Spring Boot libraries | Definitive |
| `BOOT-INF/classes/application.properties` | Embedded config file | Definitive |
| `BOOT-INF/classes/application.yml` | Embedded YAML config | Definitive |
| `META-INF/MANIFEST.MF` with `Spring-Boot-Version` | Spring Boot version | Definitive |
| `org/springframework/boot/loader/` classes | Spring Boot custom classloader | Definitive |

**Probe JAR structure:**
```bash
# Check if JAR is accessible (may be at /app.jar or similar)
curl -sI https://target.example.com/app.jar | head -5

# If accessible, probe internal structure
curl -s https://target.example.com/app.jar | unzip -l - 2>/dev/null | grep -iE 'spring-boot|application|manifest' | head -20
```

## Version Detection

### Method 1: X-Application-Context Header (Spring Boot 2.x)

```bash
# Parse application name, profile, and version from header
curl -I https://target.example.com/ 2>/dev/null | grep 'X-Application-Context'
# Example: X-Application-Context: myapp:prod:1.2.3
```

### Method 2: Actuator Info Endpoint

```bash
# Requires spring-boot-actuator and spring.info.git enabled
curl -s https://target.example.com/actuator/info | python3 -m json.tool
# Shows: build.artifact, build.group, build.name, git.commit.id, git.commit.time
```

### Method 3: MANIFEST.MF in JAR

```bash
# If JAR is accessible
curl -s https://target.example.com/app.jar | unzip -p - META-INF/MANIFEST.MF 2>/dev/null
# Look for: Spring-Boot-Version, Implementation-Version, Built-By
```

### Method 4: Error Page Stack Trace (DEBUG mode)

```bash
# Trigger an error and grep for version in trace
curl -s https://target.example.com/error 2>/dev/null | grep -oP 'Spring Boot \d+\.\d+\.\d+'
```

### Version Comparison Table

| Spring Boot Version | Java Required | X-Application-Context | Default Security |
|---------------------|---------------|----------------------|------------------|
| 1.x | 7+ | Yes | Disabled by default |
| 2.x | 8+ | Yes (default on) | Disabled by default |
| 3.x | 17+ | Disabled by default | Enabled by default (deny-all) |

## Confidence Level Definitions

| Level | Meaning | When to use |
|-------|---------|-------------|
| **Definitive** | Cannot be produced by any other framework | Use as primary confirmation |
| **High** | Very strong signal; unlikely false positive | Use as strong evidence |
| **Medium** | Present in many frameworks or common configuration | Use as supporting evidence |
| **Low** | Generic signal; many possible explanations | Use as hint only |

## Quick Fingerprinting Commands

```bash
# Quick check: headers + error page
curl -Is https://target.example.com/ 2>/dev/null | grep -iE 'application-context|x-|server'
curl -s https://target.example.com/nonexistent-abc/ | grep -i 'whitelabel\|spring\|status'

# Actuator probe (try common endpoints)
for endpoint in health info env beans mappings; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://target.example.com/actuator/$endpoint")
  echo "GET /actuator/$endpoint → $status"
done

# Swagger probe
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/swagger-ui/
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/v3/api-docs

# OpenAPI spec (full API inventory)
curl -s https://target.example.com/v3/api-docs | python3 -m json.tool 2>/dev/null | head -100
```

## False Positive Mitigation

- **`JSESSIONID` alone does not mean Spring Boot.** It only means Java servlet container (Tomcat, Jetty, Undertow). Combine with other signals (headers, error pages, actuator) before concluding Spring Boot.
- **`X-Application-Context` header may be suppressed** in Spring Boot 3.x or via `server.servlet.application-display-name` configuration.
- **Whitelabel Error Page may be replaced** by a custom error page (Thymeleaf error template at `src/main/resources/templates/error.html`). A missing Whitelabel page does not mean absence of Spring Boot.
- **Spring Security headers (`X-Frame-Options: DENY`)** are also produced by other frameworks with security filters. Use as a supporting signal only.

## Technology Stack Pairings

Spring Boot is commonly paired with:

| Technology | Detection Method | Confidence |
|------------|-----------------|------------|
| Thymeleaf | `th:*` HTML attributes | High |
| Spring Data JPA | Entity manager patterns in `/actuator/beans` | High |
| Hibernate | SQL logs in debug mode; `/actuator/beans` shows `EntityManagerFactory` | Medium |
| Spring Security | `SPRING_SECURITY_REMEMBER_ME_COOKIE`, security headers | High |
| Spring Session | `SPRING_SESSION` cookie or Redis-backed session | High |
| Micrometer + Prometheus | `/actuator/prometheus` endpoint | Definitive |
| springdoc-openapi | `/swagger-ui/`, `/v3/api-docs` | Definitive |
| Vue.js / React SPA | Separate front-end; JS bundle patterns from SPA | Medium |

## Changelog

- 2026-05-11: Initial Spring Boot 3.x tech pack with comprehensive actuator, security, and API surface coverage
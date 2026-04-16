Feature: visual-kit security hardening — CSP, CSRF, path validation, DNS rebinding defense

  Background:
    Given visual-kit v1.0.0 is installed and running at http://localhost:34287 for workspace "/work/demo"

  # ── Bind address and host allowlist ─────────────────────────────────────

  Scenario: Default bind is 127.0.0.1
    When I run "visual-kit serve --project-dir /work/demo"
    Then the server binds to 127.0.0.1
    And the server-info host field equals "127.0.0.1"

  Scenario: Binding to 0.0.0.0 emits a visible warning
    When I run "visual-kit serve --project-dir /work/demo --host 0.0.0.0 --url-host localhost"
    Then stderr contains "WARNING: binding to 0.0.0.0 exposes visual-kit to the network"
    And the server starts
    And server-info host field equals "0.0.0.0"
    And the returned url field uses "localhost"

  Scenario: Request with disallowed Host header is rejected
    Given the server is bound to 127.0.0.1:34287 with url-host "localhost"
    When a request arrives with Host header "attacker.example:34287"
    Then the response status is 421

  Scenario: Request with allowed Host header is accepted
    When a request arrives with Host header "127.0.0.1:34287"
    Then the server processes the request normally
    When a request arrives with Host header "localhost:34287"
    Then the server processes the request normally

  # ── Content Security Policy ─────────────────────────────────────────────

  Scenario: Every rendered page ships strict CSP with per-response nonce
    When I GET /p/paidagogos/lesson (with a valid SurfaceSpec)
    Then the response includes Content-Security-Policy header
    And the CSP directive default-src equals 'none'
    And the CSP directive script-src contains 'self' and a nonce matching "nonce-<base64>"
    And the CSP directive style-src contains 'self' and a matching nonce
    And the CSP directive connect-src equals 'self'
    And the CSP directive frame-ancestors equals 'none'
    And no directive contains 'unsafe-inline'
    And no directive contains 'unsafe-eval'
    And every <script> tag in the response has the matching nonce attribute

  Scenario: Inline script in a free surface is neutralized by CSP
    Given a free SurfaceSpec whose html includes "<script>alert(1)</script>"
    When I GET /p/paidagogos/custom
    Then the response body does not contain the raw <script> tag (DOMPurify removed it)
    And even if a script is injected, the CSP refuses execution (SecurityPolicyViolationEvent recorded)

  Scenario: Accompanying security headers are present
    When I GET any /p/* URL
    Then the response includes X-Content-Type-Options: nosniff
    And Referrer-Policy: no-referrer
    And Cross-Origin-Opener-Policy: same-origin
    And Cross-Origin-Resource-Policy: same-origin

  # ── CSRF on POST /events ────────────────────────────────────────────────

  Scenario: POST /events without token is rejected
    When I POST /events with a valid JSON body but no X-Vk-Csrf header
    Then the response status is 403

  Scenario: POST /events with a wrong token is rejected
    Given a page is served with token "ABC" in <meta name="vk-csrf">
    When I POST /events with X-Vk-Csrf: "WRONG"
    Then the response status is 403

  Scenario: POST /events with the correct token succeeds
    Given a page served at /p/paidagogos/lesson with nonce N and CSRF token T
    When I POST /events with X-Vk-Csrf: T and Referer: /p/paidagogos/lesson
    Then the response status is 204
    And /work/demo/.paidagogos/state/events gains one appended JSON line

  Scenario: Cross-plugin event isolation — body plugin field is ignored
    Given a page served at /p/paidagogos/lesson with CSRF token T
    When I POST /events with X-Vk-Csrf: T and body {"plugin":"draftloom","type":"foo"}
    Then the resolved target plugin is "paidagogos" (from Referer path)
    And the event is appended to .paidagogos/state/events
    And .draftloom/state/events is not modified

  Scenario: Cross-plugin event isolation — valid token cannot write to a different plugin
    Given a browser page served under /p/paidagogos/lesson with CSRF token T bound to that surface
    When a crafted POST /events uses Referer "/p/draftloom/outline" with token T
    Then the token validation fails (token bound to paidagogos/lesson, not draftloom/outline)
    And the response status is 403

  # ── Input validation ────────────────────────────────────────────────────

  Scenario: POST /events over 64 KB is rejected
    When I POST /events with a 128 KB JSON body
    Then the response status is 413

  Scenario: POST /events with wrong content type is rejected
    When I POST /events with Content-Type "application/x-www-form-urlencoded"
    Then the response status is 415

  Scenario: POST /events with invalid JSON body is rejected
    When I POST /events with Content-Type application/json and a malformed body
    Then the response status is 400

  # ── Path traversal ──────────────────────────────────────────────────────

  Scenario: Path traversal in /vk/* is rejected
    When I GET /vk/..%2f..%2fetc%2fpasswd
    Then the response status is 400
    And the body is a generic 400 message (no stack trace)

  Scenario: Path traversal in /p/<plugin>/<surface> is rejected
    When I GET /p/paidagogos/..%2f..%2fother
    Then the response status is 400

  Scenario: Symlinked SurfaceSpec is refused
    Given /work/demo/.paidagogos/content/hack.json is a symlink to ~/.ssh/id_rsa
    When I GET /p/paidagogos/hack
    Then the server rejects the symlink via lstat and returns 404

  Scenario: Symlinked bundle file is refused
    Given /work/demo/.visual-kit/cache/core.js is a symlink to a file outside CLAUDE_PLUGIN_ROOT
    When I GET /vk/core.js (if served from cache)
    Then the server rejects the symlink and returns 404

  # ── Supply chain ────────────────────────────────────────────────────────

  Scenario: Every bundled script tag carries an SRI hash
    When I GET a rendered page that loads /vk/core.js and /vk/chart.js
    Then each <script> tag has an integrity attribute matching sha384-...
    And both hashes match the values declared in /vk/capabilities

  Scenario: Bundles are served only from the plugin's dist directory
    When I GET /vk/core.js
    Then the file served is resolved to ${CLAUDE_PLUGIN_ROOT}/dist/core.js
    And no files outside that directory can be accessed via /vk/*

  # ── Error responses ─────────────────────────────────────────────────────

  Scenario: Server errors return generic bodies
    When a rendering bug causes an exception on GET /p/paidagogos/lesson
    Then the response status is 500
    And the response body is "Internal Server Error" with no stack trace
    And the stack trace is logged to /work/demo/.visual-kit/logs/ with mode 0600

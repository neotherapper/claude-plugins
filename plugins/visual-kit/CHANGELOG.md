# Changelog

## 1.0.0 — 2026-04-17

First release. Shared visual renderer for Claude Code plugins.

- CLI: `visual-kit serve | stop | status` (per-workspace, deterministic port via workspace-path hash)
- HTTP server: localhost-only, strict CSP with per-response nonce, per-page CSRF token, Host-header allowlist, path-traversal guards (regex + realpath + symlink rejection), HMAC-SHA256 CSRF tokens with timing-safe comparison, EADDRINUSE handling, advisory lock for multi-session safety
- Six V1 surfaces: lesson, gallery, outline, comparison, feedback, free (server-side DOMPurify sanitized; CSP neutralizes inline scripts regardless)
- Core bundle (~7.7 KB gzipped): vk-section, vk-card, vk-gallery, vk-outline, vk-comparison, vk-feedback, vk-loader, vk-error, vk-code
- `GET /vk/capabilities` for graceful version degradation
- SSE auto-reload on content-dir changes
- POST /events with cross-plugin isolation (target plugin derived server-side from Referer; body-supplied plugin field ignored)
- Bundled SRI hashes on all `<script>` and `<link>` tags
- CI gates: pure-component lint (no fetch/localStorage in components), security-headers test, bundle-size budget (40 KB gz max for core)
- 49 tests across unit + integration

Paidagogos 0.2.0 migrated to depend on this — its in-house HTTP server has been deleted.

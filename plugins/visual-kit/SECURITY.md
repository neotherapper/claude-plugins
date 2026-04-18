# Visual-Kit Security Posture

## Supply-chain pinning

`prismjs`, `katex`, and `chart.js` are pinned to exact versions in `package.json` (no `^` / `~`) per spec §3.9. This trades automatic patch uptake for reproducible builds and deliberate review before every bump. CI runs `pnpm audit --audit-level=high --prod` so any new **high** or **critical** advisory on a prod dep fails the verify chain.

## Known moderate advisories (1.1.0 release)

At release time, `pnpm audit --audit-level=moderate` reports these advisories on pinned prod deps. All are mitigated in visual-kit's usage; none block the release.

| Dep | Advisory | Affected versions | Mitigation in visual-kit |
|-----|----------|-------------------|--------------------------|
| `prismjs` | DOM-clobbering via `document.getElementsByTagName` | `< 1.30.0` (we pin `1.29.0`) | `highlightToHtml` runs **server-side only**; the advisory requires a browser `document`, which the node build never has. |
| `katex` | `\htmlData` attribute XSS | `< 0.16.21` (we pin `0.16.11`) | `<vk-math>` passes `trust: false` to `renderToString`, which disables `\htmlData`, `\href`, `\url`, `\htmlClass`, `\htmlId` unconditionally. |
| `dompurify` | 7 separate DOM-clobbering / mutation-XSS CVEs | `< 3.3.2` (we pin `3.1.7`) | `sanitizeFreeHtml` runs only on the `free` surface, under the page-level CSP `script-src 'self' 'nonce-<X>'` that neutralizes any surviving inline script. The `free` surface is opt-in; lesson/gallery/outline/comparison/feedback do not reach DOMPurify. |
| `ajv` | ReDoS in `$data` references | `< 8.18.0` (we pin `8.17.1`) | Our schemas never use `$data` — schemas are authored in-house, static, and validated at load time. |

## Refresh schedule

Pins will be refreshed in visual-kit **1.2.0**, scheduled as the first task of Plan B2. That refresh will:

1. Update all four deps to their latest patch versions.
2. Run the adversarial payload fixtures (`tests/integration/event-quiz.test.ts`, Playwright regression suite) against the new versions.
3. Bump the pins in `package.json` and the advisory table above.

If a **high** or **critical** advisory appears against a pinned dep before 1.2.0 ships, `pnpm run audit` will fail the verify chain and force an out-of-band patch release.

## Reporting security issues

Open a GitHub issue tagged `security` on `neotherapper/claude-plugins`, or email the maintainer directly. Do not post exploit proofs in public issues.

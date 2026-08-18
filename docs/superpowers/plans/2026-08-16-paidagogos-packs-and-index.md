# Paidagogos Packs and Roadmap Index Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make paidagogos curricula discoverable from a `packs/` directory rather than a hand-maintained table in prose, and add a roadmap.sh-style index page that links to each one.

**Architecture:** Each curriculum becomes a self-contained directory under `plugins/paidagogos/packs/<slug>/` holding a `pack.json` manifest plus its renderable surface specs. Discovery is a filesystem glob, so adding a pack requires no edit to any skill. The index is a `gallery` SurfaceSpec generated from those manifests by a script; `gallery` gains one optional `href` field so a card can navigate, which it currently cannot.

**Tech Stack:** TypeScript, Lit 3 (web components, SSR via `@lit-labs/ssr`), Ajv 2020 (JSON Schema 2020-12), Vitest, pnpm, Node ≥20.

**Spec:** None separate. The two open design decisions were resolved directly with the user in session on 2026-08-16 and are recorded under [Design decisions](#design-decisions) below. A standalone `-design.md` was deliberately skipped: both forks were closed before planning began, so a spec document would only restate this plan's own header.

## Global Constraints

- **Node**: `>=20`. **Package manager**: `pnpm`.
- **`pnpm verify` currently fails** on `pnpm audit --audit-level=high` — 7 pre-existing high advisories in transitive deps (`ajv > fast-uri`, others). This is unrelated to this work. Use `pnpm build`, `pnpm vitest run`, and `node scripts/lint-pure-components.mjs` as the gates. Do **not** attempt to resolve the audit findings inside this plan.
- **Pure-component rule** (`plugins/visual-kit/scripts/lint-pure-components.mjs`): no `fetch`, `localStorage`, `eval`, or `new Function` in anything under `src/components/`. `unsafeHTML` and `unsafeJSON` are grep-banned outside their allowlist. This lint fails closed and **also scans comments** — do not write a banned identifier into a doc comment.
- **Schema changes to a `v1` file must be additive.** Adding an optional property is the established pattern (`lesson.v1.json` was tightened additively in visual-kit 1.1.0). Never remove or narrow an existing field in a `v1` schema.
- **Palette**: specs carry a palette **slot** (`"1"`–`"8"`), never a raw colour. The theme owns what a slot looks like.
- **Concept IDs in `ai-engineering.curriculum.json` are frozen.** The nikai session has wired them into its learning path. This plan moves files; it must not rename a single node `id`.
- **Dates**: today is `2026-08-16`. Use it verbatim for `updated_at` and CHANGELOG headings.
- All work happens on branch `feat/paidagogos-ai-engineering-curriculum` (already checked out, 8 commits, unpushed).

---

## Design decisions

Recorded here because they were resolved in conversation, not in a spec file.

**1. The index gets its links from a new `href` field on `gallery`, not a new surface.**
`gallery.v1.json` items are `id / title / subtitle / body / badges` — there is no link field anywhere in the schema, so a gallery card cannot currently navigate. Rejected alternatives: adding `href` to `tree` nodes (a spine drawn through five sibling roadmaps depicts a structure that is not there), and a purpose-built `index` surface (~350 lines plus a full test suite to duplicate `gallery` minus one attribute).

**2. The existing curriculum files move into `packs/`; nothing is left behind.**
Leaving them in place would force discovery to glob two locations permanently — the exact ambiguity the manifest exists to remove.

**3. `href` needs a URL allowlist, and this exposed a live gap.**
Two things were found while scoping:

- `ajv-formats` is a declared dependency (`package.json:28`) but **is never registered** with the Ajv instance in `src/render/validate.ts`. Every `"format"` in every schema is therefore silently ignored — Ajv prints `unknown format "uri" ignored in schema at path "#/$defs/resource/properties/url"` on each test run. `tree.v1.json` claims to constrain resource URLs and does not.
- `src/surfaces/tree.ts` renders `<a href=${r.url}>` with no scheme check, and no URL sanitiser exists anywhere in `src/render/`.

Today the strict CSP (`default-src 'none'; script-src 'self' 'nonce-…'`) blocks a `javascript:` URL from executing. That mitigation does **not** cover the `free-interactive` surface, which ships deliberately without CSP. Adding a field whose entire purpose is navigation, to a spec format that is AI-authored, without a scheme allowlist would be putting the vector in on purpose. Task 1 closes it.

---

## File structure

| File | Responsibility |
|---|---|
| `plugins/visual-kit/src/render/escape.ts` | **Modify.** Gains `safeUrl()` — the single place a spec-supplied URL is vetted. |
| `plugins/visual-kit/src/render/validate.ts` | **Modify.** Registers `ajv-formats` so declared formats actually apply. |
| `plugins/visual-kit/schemas/surfaces/gallery.v1.json` | **Modify.** One optional `href` on items. |
| `plugins/visual-kit/src/surfaces/gallery.ts` | **Modify.** Passes a vetted `href` through to the card. |
| `plugins/visual-kit/src/components/card.ts` | **Modify.** Renders an anchor when `data-href` is set, a selectable div otherwise. |
| `plugins/visual-kit/tests/unit/url-safety.test.ts` | **Create.** `safeUrl()` behaviour, including the bypasses. |
| `plugins/visual-kit/tests/unit/gallery.test.ts` | **Create.** Gallery schema + render, linked and unlinked. |
| `plugins/paidagogos/schemas/pack.v1.json` | **Create.** The pack manifest contract. |
| `plugins/paidagogos/packs/<slug>/pack.json` | **Create.** One manifest per curriculum. |
| `plugins/paidagogos/packs/<slug>/*.json` \| `*.md` | **Move.** The renderable specs themselves. |
| `plugins/paidagogos/scripts/build-index.mjs` | **Create.** Globs packs, validates, emits the gallery spec. Deterministic; the enforcement-grade replacement for the prose table. |
| `plugins/paidagogos/skills/paidagogos-path/SKILL.md` | **Modify.** Table of curricula replaced by "run the script". |
| `plugins/paidagogos/skills/paidagogos/SKILL.md` | **Modify.** Router gains the index intent. |
| `AGENTS.md` | **Modify.** Intent map gains "show me all roadmaps". |

---

### Task 1: URL safety — `safeUrl()` and real format validation

Closes the gap in Design decision 3. Everything downstream depends on `safeUrl`, so this task comes first.

**Files:**
- Modify: `plugins/visual-kit/src/render/escape.ts`
- Modify: `plugins/visual-kit/src/render/validate.ts:30-31`
- Modify: `plugins/visual-kit/src/surfaces/tree.ts:386-388, 418-420`
- Test: `plugins/visual-kit/tests/unit/url-safety.test.ts` (create)

**Interfaces:**
- Consumes: nothing.
- Produces: `export function safeUrl(raw: unknown): string | undefined` from `src/render/escape.ts`. Returns the trimmed URL when its scheme is allowed, `undefined` otherwise. Task 2 imports this.

- [ ] **Step 1: Write the failing test**

Create `plugins/visual-kit/tests/unit/url-safety.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { safeUrl } from '../../src/render/escape.js';

describe('safeUrl', () => {
  it('passes absolute http(s) URLs through unchanged', () => {
    expect(safeUrl('https://example.com/a?b=c#d')).toBe('https://example.com/a?b=c#d');
    expect(safeUrl('http://example.com')).toBe('http://example.com');
  });

  it('passes site-relative and fragment targets', () => {
    expect(safeUrl('/p/paidagogos/ai-engineering')).toBe('/p/paidagogos/ai-engineering');
    expect(safeUrl('#section')).toBe('#section');
  });

  it('rejects the script-bearing schemes', () => {
    expect(safeUrl('javascript:alert(1)')).toBeUndefined();
    expect(safeUrl('JavaScript:alert(1)')).toBeUndefined();
    expect(safeUrl('data:text/html;base64,PHNjcmlwdD4=')).toBeUndefined();
    expect(safeUrl('vbscript:msgbox(1)')).toBeUndefined();
  });

  // Browsers strip control characters before parsing the scheme, so a check
  // that only trims whitespace is bypassed by embedding one.
  it('rejects a scheme smuggled past the check with control characters', () => {
    expect(safeUrl('java\nscript:alert(1)')).toBeUndefined();
    expect(safeUrl('java\tscript:alert(1)')).toBeUndefined();
    expect(safeUrl('  javascript:alert(1)')).toBeUndefined();
    expect(safeUrl('java script:alert(1)')).toBeUndefined();
    expect(safeUrl('java\u0000script:alert(1)')).toBeUndefined();
  });

  // `//evil.com` inherits the current scheme and leaves the origin.
  it('rejects protocol-relative URLs', () => {
    expect(safeUrl('//evil.com/x')).toBeUndefined();
  });

  it('returns undefined for anything that is not a usable string', () => {
    expect(safeUrl(undefined)).toBeUndefined();
    expect(safeUrl(null)).toBeUndefined();
    expect(safeUrl(42)).toBeUndefined();
    expect(safeUrl('')).toBeUndefined();
    expect(safeUrl('   ')).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd plugins/visual-kit && pnpm vitest run tests/unit/url-safety.test.ts`
Expected: FAIL — `No "safeUrl" export is defined on the module`.

- [ ] **Step 3: Implement `safeUrl`**

Append to `plugins/visual-kit/src/render/escape.ts`:

```ts
/**
 * Vets a spec-supplied URL before it reaches an href.
 *
 * SurfaceSpecs are AI-authored, so a URL in one is untrusted input. The strict
 * CSP blocks `javascript:` from executing, but the free-interactive surface
 * ships without CSP by design, so the scheme check cannot be delegated to it.
 *
 * Control characters are stripped first: browsers ignore them when parsing the
 * scheme, so `java\nscript:` reaches the parser as `javascript:` and a check
 * that only trims whitespace lets it through.
 */
const ALLOWED_TARGET = /^(?:https?:\/\/|\/(?!\/)|#)/i;

export function safeUrl(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  // Strip C0/C1 controls *and* spaces before reading the scheme, so both
  // `java\nscript:` and `java script:` collapse to a form the test rejects.
  const cleaned = raw.replace(/[\u0000-\u0020\u007F-\u00A0]/g, '');
  if (!cleaned) return undefined;
  return ALLOWED_TARGET.test(cleaned) ? raw.trim() : undefined;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd plugins/visual-kit && pnpm vitest run tests/unit/url-safety.test.ts`
Expected: PASS — 6 tests.

- [ ] **Step 5: Register `ajv-formats` so declared formats apply**

In `plugins/visual-kit/src/render/validate.ts`, add the import beside the existing Ajv import:

```ts
import addFormats from 'ajv-formats';
```

and register it immediately after the Ajv instance is constructed (line 30):

```ts
const ajv = new Ajv2020({ strict: false, allErrors: true });
// ajv-formats was a declared dependency that was never registered, so every
// "format" in every schema was silently ignored — Ajv logged
// `unknown format "uri" ignored` on each run and validated nothing.
addFormats(ajv);
```

- [ ] **Step 6: Add the regression test for format enforcement**

Append to `plugins/visual-kit/tests/unit/tree.test.ts`, inside the existing `describe('tree.v1.json', ...)` block:

```ts
  // ajv-formats was declared but never registered, so these passed silently.
  it('rejects a malformed verified_at now that formats are enforced', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: { resources: [{ type: 'docs', title: 'x', verified_at: 'last Tuesday' }] },
      }],
    }));
    expect(r.ok).toBe(false);
  });

  it('rejects a resource url that is not a URI', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: { resources: [{ type: 'docs', title: 'x', url: 'not a url' }] },
      }],
    }));
    expect(r.ok).toBe(false);
  });
```

- [ ] **Step 7: Harden the tree surface's own anchors**

In `plugins/visual-kit/src/surfaces/tree.ts`, add `safeUrl` to the existing import from the escape module (create the import if the file has none):

```ts
import { safeUrl } from '../render/escape.js';
```

Replace the resource title anchor (currently `${r.url ? html`<a href=${r.url} …` at ~line 386):

```ts
                ${safeUrl(r.url)
                  ? html`<a href=${safeUrl(r.url)} target="_blank" rel="noopener noreferrer">${r.title}</a>`
                  : html`<span>${r.title}</span>`}
```

and the artifact anchor (~line 418):

```ts
                ${safeUrl(r.artifact_url)
                  ? html`<a class="vk-tree-artifact" href=${safeUrl(r.artifact_url)} target="_blank" rel="noopener noreferrer">retrieved document</a>`
                  : ''}
```

- [ ] **Step 8: Add the tree render regression test**

Append inside the existing `describe('renderTree', ...)` block in `plugins/visual-kit/tests/unit/tree.test.ts`:

```ts
  it('renders a hostile resource url as plain text instead of a link', () => {
    const out = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'docs', title: 'Trap', url: 'javascript:alert(1)' }] },
      }],
    }));
    expect(out).not.toContain('href="javascript:alert(1)"');
    expect(out).toContain('Trap');
  });
```

- [ ] **Step 9: Run the full suite**

Run: `cd plugins/visual-kit && pnpm vitest run 2>&1 | tail -20`
Expected: PASS. Test count rises from 176 to 185. **The `unknown format … ignored` warnings on stderr must be gone** — their absence is the proof that registration took effect.

If any *existing* test now fails, a schema's declared format was being violated by a fixture that previously passed. Fix the fixture, not the schema.

- [ ] **Step 10: Verify the shipped curricula still validate**

Run from `plugins/visual-kit`:

```bash
node --input-type=module -e "
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { readFileSync } from 'node:fs';
const ajv = new Ajv.default({ strict:false, allErrors:true });
addFormats(ajv);
const v = ajv.compile(JSON.parse(readFileSync('schemas/surfaces/tree.v1.json','utf8')));
for (const f of [
  '../paidagogos/skills/paidagogos-micro/references/curricula/ai-engineering.curriculum.json',
  '../paidagogos/skills/paidagogos-micro/references/curricula/ai-engineering.catalogue.json',
]) {
  const ok = v(JSON.parse(readFileSync(f,'utf8')));
  console.log(f.split('/').pop(), ok ? 'VALID' : JSON.stringify(v.errors,null,1));
}"
```
Expected: both print `VALID`. If either fails, a URL or date in the shipped data was malformed and only passed because formats were inert — fix the data.

- [ ] **Step 11: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/visual-kit/src/render/escape.ts plugins/visual-kit/src/render/validate.ts \
        plugins/visual-kit/src/surfaces/tree.ts plugins/visual-kit/tests/unit/url-safety.test.ts \
        plugins/visual-kit/tests/unit/tree.test.ts
git commit -m "fix(visual-kit): vet spec-supplied URLs and enforce declared formats

ajv-formats was a declared dependency that was never registered, so every
format in every schema was inert — Ajv logged 'unknown format uri ignored'
on each run while validating nothing. Registering it makes tree.v1.json
enforce the URL and date constraints it already claimed.

safeUrl() gates any URL heading for an href behind an http(s)/relative/
fragment allowlist. The strict CSP blocks javascript: today, but the
free-interactive surface ships without CSP by design, so the check cannot
be delegated to it. Control characters are stripped before the scheme is
read, since browsers ignore them and 'java\\nscript:' otherwise slips past
a whitespace-only trim."
```

---

### Task 2: `href` on gallery cards

**Files:**
- Modify: `plugins/visual-kit/schemas/surfaces/gallery.v1.json`
- Modify: `plugins/visual-kit/src/surfaces/gallery.ts`
- Modify: `plugins/visual-kit/src/components/card.ts`
- Test: `plugins/visual-kit/tests/unit/gallery.test.ts` (create)

**Interfaces:**
- Consumes: `safeUrl(raw: unknown): string | undefined` from Task 1.
- Produces: a `gallery` SurfaceSpec item may carry `href?: string`. When present the card renders as `<a href>` and emits **no** `vk-event`. Task 4 generates specs relying on this.

- [ ] **Step 1: Write the failing test**

Create `plugins/visual-kit/tests/unit/gallery.test.ts`:

```ts
import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';
import { renderGallery } from '../../src/surfaces/gallery.js';
import { renderFragment } from '../../src/render/ssr.js';

beforeAll(async () => { await loadSchemas(); });

const spec = (items: unknown[]) => ({ surface: 'gallery', version: 1, items });

describe('gallery.v1.json href', () => {
  it('accepts an absolute and a site-relative href', () => {
    expect(validateSpec(spec([{ id: 'a', title: 'A', href: 'https://example.com' }])).ok).toBe(true);
    expect(validateSpec(spec([{ id: 'b', title: 'B', href: '/p/paidagogos/x' }])).ok).toBe(true);
  });

  it('still accepts an item with no href at all', () => {
    expect(validateSpec(spec([{ id: 'c', title: 'C' }])).ok).toBe(true);
  });

  it('rejects a javascript: or protocol-relative href', () => {
    expect(validateSpec(spec([{ id: 'd', title: 'D', href: 'javascript:alert(1)' }])).ok).toBe(false);
    expect(validateSpec(spec([{ id: 'e', title: 'E', href: '//evil.com' }])).ok).toBe(false);
  });
});

describe('renderGallery', () => {
  it('emits data-href on a card that carries one', () => {
    const out = renderFragment(renderGallery({ items: [
      { id: 'a', title: 'AI Engineering', href: '/p/paidagogos/ai-engineering' },
    ] }));
    expect(out).toContain('data-href="/p/paidagogos/ai-engineering"');
  });

  it('omits the attribute entirely when there is no href', () => {
    const out = renderFragment(renderGallery({ items: [{ id: 'a', title: 'A' }] }));
    expect(out).not.toContain('data-href');
  });

  // Defence in depth: the dispatcher can call a renderer on an unvalidated spec.
  it('drops a hostile href even if it reached the renderer unvalidated', () => {
    const out = renderFragment(renderGallery({ items: [
      { id: 'a', title: 'A', href: 'javascript:alert(1)' },
    ] }));
    expect(out).not.toContain('javascript:alert(1)');
    expect(out).not.toContain('data-href');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd plugins/visual-kit && pnpm vitest run tests/unit/gallery.test.ts`
Expected: FAIL — the schema rejects the unknown `href` property, and `data-href` is absent from output.

- [ ] **Step 3: Add `href` to the schema**

In `plugins/visual-kit/schemas/surfaces/gallery.v1.json`, add to the item `properties` object, after `body`:

```json
          "href": {
            "type": "string",
            "maxLength": 2048,
            "pattern": "^(?:https?://|/(?!/)|#)",
            "description": "Turns the card into a link. Restricted to http(s), site-relative and fragment targets: a card is navigation, and specs are AI-authored, so `javascript:` and `data:` targets are the injection vector. A card with an href does not emit a selection event."
          },
```

- [ ] **Step 4: Pass the vetted href through the renderer**

In `plugins/visual-kit/src/surfaces/gallery.ts`, change the lit import and the interface, then the card:

```ts
import { html, nothing, type TemplateResult } from 'lit';
import { safeUrl } from '../render/escape.js';

interface GalleryItem {
  id: string;
  title: string;
  subtitle?: string;
  body?: string;
  href?: string;
  badges?: Array<{ label: string; tone?: string }>;
}
```

and inside `spec.items.map`, replace the opening `<vk-card …>` tag:

```ts
      ${spec.items.map(item => html`
        <vk-card data-id="${item.id}" data-href=${safeUrl(item.href) ?? nothing}>
```

- [ ] **Step 5: Make `vk-card` render an anchor when linked**

Replace the `render()` method and add the property in `plugins/visual-kit/src/components/card.ts`:

```ts
  @property({ attribute: 'data-href' }) dataHref = '';

  render() {
    const inner = html`
      <slot name="title"></slot>
      <slot name="subtitle"></slot>
      <slot name="body"></slot>
      <div class="badges"><slot name="badge"></slot></div>`;
    // A linked card navigates and must not also toggle selection — one card,
    // one meaning. Selection stays the behaviour for cards without an href.
    return this.dataHref
      ? html`<a class="link" href=${this.dataHref}>${inner}</a>`
      : html`<div @click=${this.toggle}>${inner}</div>`;
  }
```

and add to `static styles`, inside the existing `css` template:

```css
    .link { display:block; color:inherit; text-decoration:none; }
    :host([data-href]:hover) { border-color: var(--vk-accent); }
    :host([data-href]:has(a:focus-visible)) { outline:2px solid var(--vk-accent); outline-offset:2px; }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd plugins/visual-kit && pnpm vitest run tests/unit/gallery.test.ts`
Expected: PASS — 6 tests.

- [ ] **Step 7: Run the full suite and the pure-component lint**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run 2>&1 | tail -6 && node scripts/lint-pure-components.mjs
```
Expected: all tests pass (191 total); lint prints `lint-pure-components passed`.

- [ ] **Step 8: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/visual-kit/schemas/surfaces/gallery.v1.json plugins/visual-kit/src/surfaces/gallery.ts \
        plugins/visual-kit/src/components/card.ts plugins/visual-kit/tests/unit/gallery.test.ts
git commit -m "feat(visual-kit): let a gallery card be a link

gallery items had no link field, so a card could be selected but never
navigated to — which is the one thing an index of anything has to do.
href is optional and additive, so every existing gallery spec is
unaffected.

A card with an href renders an anchor and does not attach the selection
handler: navigating and toggling are different meanings and a card should
carry one. The scheme allowlist is enforced twice, in the schema and again
in the renderer, because the dispatcher can invoke a renderer on a spec
that was never validated."
```

---

### Task 3: The pack manifest and the migration

**Files:**
- Create: `plugins/paidagogos/schemas/pack.v1.json`
- Create: `plugins/paidagogos/packs/ai-engineering/pack.json`
- Create: `plugins/paidagogos/packs/seo-developer-mastery/pack.json`
- Move: `plugins/paidagogos/skills/paidagogos-micro/references/curricula/ai-engineering.curriculum.json` → `plugins/paidagogos/packs/ai-engineering/curriculum.json`
- Move: `…/ai-engineering.catalogue.json` → `plugins/paidagogos/packs/ai-engineering/catalogue.json`
- Move: `…/seo-developer-mastery.md` → `plugins/paidagogos/packs/seo-developer-mastery/curriculum.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `packs/<slug>/pack.json` conforming to `pack.v1.json`. Every manifest has `id`, `title`, and a non-empty `surfaces` array whose entries are `{ id, title, file, role }` with `role` one of `curriculum | catalogue`. Task 4 globs these.

- [ ] **Step 1: Write the manifest schema**

Create `plugins/paidagogos/schemas/pack.v1.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "paidagogos://schemas/pack.v1.json",
  "title": "PaidagogosPackV1",
  "type": "object",
  "required": ["id", "title", "surfaces"],
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-z0-9][a-z0-9-]{0,63}$",
      "description": "Slug. Must equal the pack's directory name — build-index.mjs checks this, because a manifest that disagrees with its own location produces links that 404."
    },
    "title": { "type": "string", "maxLength": 200 },
    "subtitle": { "type": "string", "maxLength": 200 },
    "summary": { "type": "string", "maxLength": 1000 },
    "badges": {
      "type": "array",
      "maxItems": 6,
      "items": {
        "type": "object",
        "required": ["label"],
        "additionalProperties": false,
        "properties": {
          "label": { "type": "string", "maxLength": 40 },
          "tone": { "enum": ["ok", "warn", "danger", "info", "muted"] }
        }
      }
    },
    "updated_at": {
      "type": "string",
      "format": "date",
      "description": "When the pack's content was last revised. Distinct from a git timestamp: moving a file is not revising a curriculum."
    },
    "surfaces": {
      "type": "array",
      "minItems": 1,
      "maxItems": 20,
      "description": "The renderable specs in this pack. A pack has more than one whenever its catalogue is a separate tree from its curriculum.",
      "items": {
        "type": "object",
        "required": ["id", "title", "file", "role"],
        "additionalProperties": false,
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_-]+$",
            "maxLength": 80,
            "description": "Staged filename and URL segment. The server rejects any other character class, so dots are not permitted here even though the source file has one."
          },
          "title": { "type": "string", "maxLength": 200 },
          "file": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9][a-zA-Z0-9._-]*$",
            "description": "Path relative to the pack directory. No slashes: a pack is one flat directory, and allowing traversal here would let a manifest reach outside it."
          },
          "format": { "enum": ["tree", "markdown"], "default": "tree" },
          "role": { "enum": ["curriculum", "catalogue"] }
        }
      }
    }
  }
}
```

- [ ] **Step 2: Move the files with git so history follows them**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/paidagogos
mkdir -p packs/ai-engineering packs/seo-developer-mastery schemas scripts
git mv skills/paidagogos-micro/references/curricula/ai-engineering.curriculum.json packs/ai-engineering/curriculum.json
git mv skills/paidagogos-micro/references/curricula/ai-engineering.catalogue.json  packs/ai-engineering/catalogue.json
git mv skills/paidagogos-micro/references/curricula/seo-developer-mastery.md       packs/seo-developer-mastery/curriculum.md
rmdir skills/paidagogos-micro/references/curricula 2>/dev/null || true
```

- [ ] **Step 3: Confirm the move changed no content**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git diff --cached --stat
```
Expected: three `rename` lines, `0 insertions(+), 0 deletions(-)`. Any non-zero line count means a file was rewritten rather than moved — undo and redo with `git mv`.

- [ ] **Step 4: Write the AI Engineering manifest**

Create `plugins/paidagogos/packs/ai-engineering/pack.json`:

```json
{
  "id": "ai-engineering",
  "title": "AI Engineering",
  "subtitle": "38 concepts across five tracks",
  "summary": "Toward AI engineer / architect, ordered so the Claude Certified Architect – Foundations domains come first. Track letters and the two-axis framing are shared with the nikai learning path.",
  "badges": [
    { "label": "CCAR-F", "tone": "info" },
    { "label": "38 concepts", "tone": "muted" }
  ],
  "updated_at": "2026-08-16",
  "surfaces": [
    {
      "id": "ai-engineering",
      "title": "AI Engineering curriculum",
      "file": "curriculum.json",
      "format": "tree",
      "role": "curriculum"
    },
    {
      "id": "ai-engineering-courses",
      "title": "External courses and certifications",
      "file": "catalogue.json",
      "format": "tree",
      "role": "catalogue"
    }
  ]
}
```

- [ ] **Step 5: Write the SEO manifest**

Create `plugins/paidagogos/packs/seo-developer-mastery/pack.json`:

```json
{
  "id": "seo-developer-mastery",
  "title": "Developer SEO Mastery",
  "subtitle": "12 lessons, strictly linear",
  "summary": "The original markdown curriculum format: a fixed lesson sequence with no tracks and no cross-cutting prerequisites. Kept as-is; new curricula should use the tree format.",
  "badges": [
    { "label": "legacy format", "tone": "warn" },
    { "label": "12 lessons", "tone": "muted" }
  ],
  "updated_at": "2026-07-12",
  "surfaces": [
    {
      "id": "seo-developer-mastery",
      "title": "Developer SEO Mastery",
      "file": "curriculum.md",
      "format": "markdown",
      "role": "curriculum"
    }
  ]
}
```

- [ ] **Step 6: Validate both manifests against the schema**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/visual-kit
node --input-type=module -e "
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { readFileSync } from 'node:fs';
const ajv = new Ajv.default({ strict:false, allErrors:true });
addFormats(ajv);
const v = ajv.compile(JSON.parse(readFileSync('../paidagogos/schemas/pack.v1.json','utf8')));
for (const p of ['ai-engineering','seo-developer-mastery']) {
  const ok = v(JSON.parse(readFileSync(\`../paidagogos/packs/\${p}/pack.json\`,'utf8')));
  console.log(p, ok ? 'VALID' : JSON.stringify(v.errors,null,1));
}"
```
Expected: both print `VALID`.

- [ ] **Step 7: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/paidagogos/schemas plugins/paidagogos/packs
git commit -m "refactor(paidagogos): move curricula into self-describing packs

Curricula lived under paidagogos-micro/references/, which is a strange
home for a library two other skills read, and the only record of what
existed was a markdown table inside a skill. A pack is a directory with a
manifest, so discovery becomes a filesystem glob and adding a curriculum
touches no skill at all.

surfaces[] rather than a single file path: the AI Engineering pack already
ships two renderable trees, its curriculum and its course catalogue, and
collapsing them would have needed undoing on the next pack.

Files moved with git mv — content is byte-identical and every concept id
is unchanged, so the nikai session's wiring is unaffected."
```

---

### Task 4: The index generator

The enforcement-grade replacement for the prose table. A script, not skill instructions, because a documented step that a skill is meant to remember is the failure mode this repo has already recorded twice.

**Files:**
- Create: `plugins/paidagogos/scripts/build-index.mjs`
- Test: exercised by Step 4 below against the two real packs.

**Interfaces:**
- Consumes: `packs/*/pack.json` (Task 3), the `href` field (Task 2).
- Produces: a `gallery` SurfaceSpec on stdout. Invoked as `node plugins/paidagogos/scripts/build-index.mjs [--out <path>]`. Exit code `0` on success, `1` with errors on stderr if any manifest is invalid.

- [ ] **Step 1: Write the script**

Create `plugins/paidagogos/scripts/build-index.mjs`:

```js
#!/usr/bin/env node
/**
 * Builds the roadmap index from the pack manifests.
 *
 * Discovery is a glob rather than a list, so a new pack appears in the index
 * by existing. The previous arrangement was a markdown table inside a skill,
 * which is the shape of instruction this project has twice found gets skipped.
 *
 * Fails closed: one invalid manifest aborts the whole index rather than
 * silently emitting a directory with a hole in it.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const here = dirname(fileURLToPath(import.meta.url));
const packsDir = join(here, '..', 'packs');
const schemaPath = join(here, '..', 'schemas', 'pack.v1.json');

const ajv = new Ajv.default({ strict: false, allErrors: true });
addFormats(ajv);
const validate = ajv.compile(JSON.parse(await readFile(schemaPath, 'utf8')));

const errors = [];
const packs = [];

for (const entry of await readdir(packsDir, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const manifestPath = join(packsDir, entry.name, 'pack.json');
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  } catch (err) {
    errors.push(`${entry.name}: ${err.code === 'ENOENT' ? 'no pack.json' : err.message}`);
    continue;
  }
  if (!validate(manifest)) {
    errors.push(`${entry.name}: ${validate.errors.map(e => `${e.instancePath} ${e.message}`).join('; ')}`);
    continue;
  }
  // A manifest that disagrees with its own directory yields links that 404,
  // and the schema cannot see the filesystem.
  if (manifest.id !== entry.name) {
    errors.push(`${entry.name}: manifest id "${manifest.id}" does not match directory name`);
    continue;
  }
  packs.push(manifest);
}

if (errors.length) {
  console.error('build-index failed:\n  ' + errors.join('\n  '));
  process.exit(1);
}

// Stable order: the index must not reshuffle between runs.
packs.sort((a, b) => a.title.localeCompare(b.title, 'en'));

const items = packs.map(p => {
  const main = p.surfaces.find(s => s.role === 'curriculum') ?? p.surfaces[0];
  const extra = p.surfaces.filter(s => s !== main);
  return {
    id: p.id,
    title: p.title,
    ...(p.subtitle ? { subtitle: p.subtitle } : {}),
    ...(p.summary ? { body: p.summary } : {}),
    href: `/p/paidagogos/${main.id}`,
    badges: [
      ...(p.badges ?? []),
      ...extra.map(s => ({ label: s.title, tone: 'muted' })),
    ].slice(0, 6),
  };
});

const spec = {
  surface: 'gallery',
  version: 1,
  title: 'Roadmaps',
  items,
};

const outFlag = process.argv.indexOf('--out');
const json = JSON.stringify(spec, null, 2);
if (outFlag !== -1 && process.argv[outFlag + 1]) {
  await writeFile(process.argv[outFlag + 1], json + '\n', 'utf8');
  console.error(`wrote ${items.length} roadmap(s)`);
} else {
  process.stdout.write(json + '\n');
}
```

- [ ] **Step 2: Run it against the real packs**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
node plugins/paidagogos/scripts/build-index.mjs
```
Expected: a gallery spec on stdout with exactly 2 items, `AI Engineering` first (alphabetical), each carrying `"href": "/p/paidagogos/…"`. The AI Engineering card must show a muted badge reading `External courses and certifications`.

- [ ] **Step 3: Verify it fails closed on a broken manifest**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
cp plugins/paidagogos/packs/ai-engineering/pack.json /tmp/pack-backup.json
node -e "const f='plugins/paidagogos/packs/ai-engineering/pack.json';const j=require('./'+f);j.id='wrong-name';require('fs').writeFileSync(f,JSON.stringify(j,null,2))"
node plugins/paidagogos/scripts/build-index.mjs; echo "exit=$?"
cp /tmp/pack-backup.json plugins/paidagogos/packs/ai-engineering/pack.json && rm /tmp/pack-backup.json
```
Expected: stderr reports `manifest id "wrong-name" does not match directory name`, and `exit=1`. Then confirm the restore: `git diff --quiet plugins/paidagogos/packs/ai-engineering/pack.json && echo restored`.

- [ ] **Step 4: Verify the generated index validates as a gallery spec**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
node plugins/paidagogos/scripts/build-index.mjs --out /tmp/index.json
cd plugins/visual-kit && node --input-type=module -e "
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { readFileSync } from 'node:fs';
const ajv = new Ajv.default({ strict:false, allErrors:true });
addFormats(ajv);
const v = ajv.compile(JSON.parse(readFileSync('schemas/surfaces/gallery.v1.json','utf8')));
const ok = v(JSON.parse(readFileSync('/tmp/index.json','utf8')));
console.log(ok ? 'VALID' : JSON.stringify(v.errors,null,1));"
```
Expected: `VALID`. This is the join between Task 2 and Task 4 — if the `href` pattern and the generated path disagree, it surfaces here.

- [ ] **Step 5: Render it end to end in the browser**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
node plugins/visual-kit/dist/cli.js stop --project-dir . || true
pnpm --dir plugins/visual-kit build
node plugins/visual-kit/dist/cli.js serve --project-dir . > /dev/null 2>&1 &
sleep 4
mkdir -p .paidagogos/content
node plugins/paidagogos/scripts/build-index.mjs --out .paidagogos/content/roadmaps.json
cp plugins/paidagogos/packs/ai-engineering/curriculum.json .paidagogos/content/ai-engineering.json
cat .visual-kit/server/state/server-info
```
Then open `http://localhost:<port>/p/paidagogos/roadmaps` and confirm: two cards render, and **clicking the AI Engineering card navigates to the spine roadmap**. That click is the whole point of Task 2; verify it rather than assuming it.

- [ ] **Step 6: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/paidagogos/scripts/build-index.mjs
git commit -m "feat(paidagogos): generate the roadmap index from pack manifests

Discovery is a glob over packs/*/pack.json, so a curriculum appears in the
index by existing rather than by someone remembering to add a row. The
manifest id is checked against its own directory name because the schema
cannot see the filesystem and a mismatch yields links that 404.

Fails closed on any invalid manifest: an index missing an entry looks
exactly like an index that is complete, so a partial one is worse than
no output."
```

---

### Task 5: Rewire the skills

**Files:**
- Modify: `plugins/paidagogos/skills/paidagogos-path/SKILL.md`
- Modify: `plugins/paidagogos/skills/paidagogos/SKILL.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `build-index.mjs` (Task 4), the pack layout (Task 3).
- Produces: no code. The `paidagogos:path` skill no longer names individual curricula.

- [ ] **Step 1: Replace the curriculum table in `paidagogos-path/SKILL.md`**

Delete the `## Available curricula` section entirely (the table and the two sentences under it, currently lines 25–34) and put in its place:

```markdown
## Available curricula

Do not keep a list here. Run:

```bash
node plugins/paidagogos/scripts/build-index.mjs
```

It prints a `gallery` SurfaceSpec built from `plugins/paidagogos/packs/*/pack.json`.
Every pack that exists is in that output; anything not in it does not exist.
A list written into this file would be a second source of truth that drifts
from the first one silently.
```

- [ ] **Step 2: Add the index phase to `paidagogos-path/SKILL.md`**

Insert a new phase between the current Phase 1 and Phase 2, and renumber the rest (old Phase 2→3, 3→4, 4→5, 5→6):

```markdown
### Phase 2 — Show the index when the request is not about one subject

If the user asked what curricula exist, or asked for "the roadmaps", stage the
index instead of a single curriculum:

```bash
node plugins/paidagogos/scripts/build-index.mjs --out .paidagogos/content/roadmaps.json
```

Give them `http://localhost:<port>/p/paidagogos/roadmaps`. Each card links
straight to its curriculum. If the script exits non-zero, report its stderr
verbatim and stop — a manifest is broken, and rendering a partial index would
present a missing curriculum as one that does not exist.

If the user named a subject, skip this phase.
```

- [ ] **Step 3: Fix the stale path in the authoring section**

In the same file, the "Validate before rendering" snippet and the authoring prose reference the old `references/curricula/` location. Replace every occurrence of

```
plugins/paidagogos/skills/paidagogos-micro/references/curricula/
```

with

```
plugins/paidagogos/packs/<slug>/
```

and add to the authoring conventions table:

```markdown
| Pack manifest | Every curriculum needs `packs/<slug>/pack.json` validated against `plugins/paidagogos/schemas/pack.v1.json`. Without it the curriculum is invisible to the index. |
```

- [ ] **Step 4: Add the index intent to the router**

In `plugins/paidagogos/skills/paidagogos/SKILL.md`, add these rows to the routing table alongside the existing `paidagogos:path` entries:

```markdown
| "what curricula do you have" / "show me all roadmaps" | `paidagogos:path` (index) |
| "/paidagogos:path" with no topic | `paidagogos:path` (index) |
```

- [ ] **Step 5: Update `AGENTS.md`**

In the root `AGENTS.md`, add to the **Intent → Skill Mapping** table, directly under the existing `paidagogos:path` rows:

```markdown
| "show me all roadmaps" / "what curricula exist" | `paidagogos:path` (renders the index) |
```

- [ ] **Step 6: Verify no stale path references survive**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
grep -rn "references/curricula" --include=*.md --include=*.json . | grep -v node_modules | grep -v "^./.git/" | grep -v CHANGELOG | grep -v "docs/superpowers/plans/"
```
Expected: **no output**. CHANGELOGs are excluded because a changelog records what was true at the time and must not be rewritten.

- [ ] **Step 7: Re-sync the skill symlink farm**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
./scripts/sync-skills.sh
git status --short .agents .kiro
```
Expected: symlinks resolve; no broken links reported.

- [ ] **Step 8: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/paidagogos/skills AGENTS.md .agents .kiro
git commit -m "docs(paidagogos): discover curricula by glob instead of by table

paidagogos:path listed the available curricula in a markdown table, so
every new pack needed a skill edit and the list could disagree with the
filesystem without anything noticing. The skill now runs build-index.mjs
and reads the answer.

Adds the index phase for requests that name no subject, and points the
authoring instructions at packs/<slug>/ instead of the removed
references/curricula/ path."
```

---

### Task 6: Versions and changelogs

**Files:**
- Modify: `plugins/visual-kit/.claude-plugin/plugin.json`, `plugins/visual-kit/package.json`, `plugins/visual-kit/CHANGELOG.md`
- Modify: `plugins/paidagogos/.claude-plugin/plugin.json`, `plugins/paidagogos/CHANGELOG.md`

**Interfaces:**
- Consumes: everything above.
- Produces: visual-kit `1.4.0`, paidagogos `0.4.0` depending on `visual-kit ~1.4.0`.

- [ ] **Step 1: Bump visual-kit to 1.4.0**

Set `"version": "1.4.0"` in both `plugins/visual-kit/.claude-plugin/plugin.json` and `plugins/visual-kit/package.json`. Minor, not patch: `gallery` gained a field and validation behaviour changed.

- [ ] **Step 2: Write the visual-kit changelog entry**

Prepend under `# Changelog` in `plugins/visual-kit/CHANGELOG.md`:

```markdown
## 1.4.0 — 2026-08-16

### Added
- `gallery` items accept an optional `href`, turning a card into a link. Additive, so existing gallery specs are unaffected. A linked card renders an anchor and does not emit a selection event — navigating and selecting are different meanings and one card should carry one of them.
- `safeUrl()` in `src/render/escape.ts` — the single place a spec-supplied URL is vetted before reaching an `href`.

### Fixed
- **`ajv-formats` was a declared dependency that was never registered**, so every `"format"` in every schema was inert. Ajv had been logging `unknown format "uri" ignored` on each run while validating nothing. `tree.v1.json` now enforces the URL and date constraints it already claimed to.
- The `tree` surface rendered resource URLs into anchors with no scheme check. Both anchors now go through `safeUrl()`.

### Security
URLs in a SurfaceSpec are untrusted input, since specs are AI-authored. `safeUrl()` allows `http(s)`, site-relative and fragment targets only, and strips control characters before reading the scheme — browsers ignore them, so `java\nscript:` defeats a whitespace-only trim. The scheme allowlist is enforced twice, in the schema and again in the renderer, because the dispatcher can invoke a renderer on a spec that was never validated. The strict CSP would block `javascript:` from executing, but `free-interactive` ships without CSP by design, so that mitigation could not be relied on.
```

- [ ] **Step 3: Bump paidagogos to 0.4.0**

In `plugins/paidagogos/.claude-plugin/plugin.json` set `"version": "0.4.0"` and update the dependency to `{ "name": "visual-kit", "version": "~1.4.0" }`.

- [ ] **Step 4: Write the paidagogos changelog entry**

Prepend under `# Changelog` in `plugins/paidagogos/CHANGELOG.md`:

```markdown
## 0.4.0 — 2026-08-16

### Added
- **Packs.** A curriculum is now a directory under `packs/<slug>/` with a `pack.json` manifest validated against `schemas/pack.v1.json`. A manifest declares `surfaces[]`, because a pack can hold more than one renderable tree — the AI Engineering pack ships both its curriculum and its course catalogue.
- **Roadmap index.** `scripts/build-index.mjs` globs the manifests and emits a `gallery` spec whose cards link to each curriculum. Requests that name no subject now render the index.

### Changed
- Curricula moved out of `skills/paidagogos-micro/references/curricula/` into `packs/`. Files were moved with `git mv`; content is byte-identical and **no concept id changed**, so the nikai learning path's wiring is unaffected.
- `paidagogos:path` no longer carries a table of available curricula. It runs the script and reads the answer, so adding a pack requires no skill edit and the list cannot drift from the filesystem.
- Requires `visual-kit ~1.4.0` for the `gallery` `href` field.

### Why discovery is a script
A list of curricula written into a skill is a second source of truth that goes stale silently, and this repository has twice recorded that prose-only steps get skipped under synthesis pressure. `build-index.mjs` fails closed: one invalid manifest aborts the index rather than emitting a directory with a hole in it, because an index missing an entry looks exactly like a complete one.
```

- [ ] **Step 5: Run every gate**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/visual-kit
pnpm build && pnpm vitest run 2>&1 | tail -6 && node scripts/lint-pure-components.mjs
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
node plugins/paidagogos/scripts/build-index.mjs > /dev/null && echo "index ok"
```
Expected: build succeeds, 191 tests pass, lint passes, `index ok`.
Reminder: `pnpm verify` will still fail on `pnpm audit`. That is pre-existing and out of scope.

- [ ] **Step 6: Commit**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
git add plugins/visual-kit/.claude-plugin/plugin.json plugins/visual-kit/package.json \
        plugins/visual-kit/CHANGELOG.md plugins/paidagogos/.claude-plugin/plugin.json \
        plugins/paidagogos/CHANGELOG.md
git commit -m "chore: visual-kit 1.4.0, paidagogos 0.4.0"
```

---

## Verification

After the last task, confirm the whole path end to end:

1. `node plugins/paidagogos/scripts/build-index.mjs --out .paidagogos/content/roadmaps.json`
2. Serve, open `/p/paidagogos/roadmaps`, click a card, land on the roadmap.
3. Add a throwaway `packs/test-pack/pack.json` with one surface, re-run the script, confirm the new card appears **without any file outside `packs/` being touched**. Delete it afterwards. This is the property the whole plan exists to produce — verify it rather than assuming it.

## Out of scope

- Authoring new subject curricula (mathematics, physics). That is content work; this plan builds the shelf, not the books.
- Progress tracking. Curricula stay pure content, per the decision on 2026-08-16 that any progress overlay is a separate file so a curriculum remains reusable by other learners.
- The `pnpm audit` advisories.
- `disclosure: public | internal | confidential` on the tree schema — still an open question for George, deliberately not decided here.

import { html, type TemplateResult } from 'lit';
import { safeUrl } from '../render/escape.js';

/**
 * Tree surface — a navigable hierarchy whose nodes open a detail popover.
 *
 * Two constraints from the codebase shape this renderer:
 *
 *  1. Components may not perform network access (scripts/lint-pure-components.mjs),
 *     so node detail is emitted inline with the tree rather than fetched on demand.
 *  2. Raw-markup injection is allowlisted to the lesson surface only, so detail
 *     bodies are typed blocks mapped to known elements rather than author HTML.
 *
 * Disclosure uses the native Popover API (`popovertarget` / `popover="auto"`).
 * That buys light-dismiss, Esc-to-close, focus restoration and top-layer stacking
 * without a line of component JavaScript — the same reason the ordering switcher
 * below is a CSS-driven radio group rather than a click handler.
 */

export interface TreeResource {
  type: 'video' | 'course' | 'book' | 'paper' | 'article' | 'docs' | 'tool' | 'presentation' | 'exam-guide';
  title: string;
  url?: string;
  artifact_url?: string;
  author?: string;
  institution?: string;
  certification?: string;
  cost?: 'free' | 'freemium' | 'paid';
  lifecycle?: 'current' | 'version-changing' | 'retired';
  provenance?: 'primary' | 'secondary' | 'relayed';
  duration?: string;
  level?: 'beginner' | 'intermediate' | 'advanced';
  note?: string;
  verified_at?: string;
}

export type TreeBlock =
  | { type: 'text'; text: string }
  | { type: 'heading'; text: string }
  | { type: 'list'; ordered?: boolean; items: string[] }
  | { type: 'code'; language?: string; source: string }
  | { type: 'callout'; tone?: 'note' | 'warning' | 'pitfall'; text: string };

export interface TreeDetail {
  summary?: string;
  meta?: Array<{ label: string; value: string }>;
  body?: TreeBlock[];
  resources?: TreeResource[];
}

export interface TreeNode {
  id: string;
  label: string;
  group?: string;
  kind?: 'branch' | 'leaf';
  badges?: string[];
  requires?: string[];
  detail?: TreeDetail;
  children?: TreeNode[];
}

export interface TreeGroup {
  id: string;
  label: string;
  description?: string;
  accent?: string;
}

export interface TreeOrdering {
  id: string;
  label: string;
  description?: string;
  default?: boolean;
  sequence: string[];
}

export interface TreeSpec {
  title?: string;
  subtitle?: string;
  groups?: TreeGroup[];
  orderings?: TreeOrdering[];
  nodes: TreeNode[];
}

/** Authored icons, one consistent 1.5px stroke on a 24-grid. Drawn rather than
 *  borrowed from a glyph so weight and terminals match across the surface. */
const ICON_EXPAND = html`
  <svg class="vk-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
    <path d="M9 6l6 6-6 6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
  </svg>
`;

const ICON_CLOSE = html`
  <svg class="vk-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true" focusable="false">
    <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
  </svg>
`;

const RESOURCE_LABEL: Record<TreeResource['type'], string> = {
  video: 'Video',
  course: 'Course',
  book: 'Book',
  paper: 'Paper',
  article: 'Article',
  docs: 'Docs',
  tool: 'Tool',
  presentation: 'Deck',
  'exam-guide': 'Exam guide',
};

/** Ids reach the DOM as element ids and CSS selector operands. The schema already
 *  constrains them, but the dispatcher can invoke a renderer on an unvalidated spec,
 *  so narrow defensively rather than trusting the caller. */
function safeId(raw: string): string {
  return String(raw).toLowerCase().replace(/[^a-z0-9-]/g, '').slice(0, 64) || 'node';
}

function walk(nodes: TreeNode[], visit: (n: TreeNode) => void): void {
  for (const n of nodes) {
    visit(n);
    if (n.children?.length) walk(n.children, visit);
  }
}

export function renderTree(spec: TreeSpec): TemplateResult {
  const nodes = Array.isArray(spec.nodes) ? spec.nodes : [];

  // Label lookup so `requires` can render readable cross-links, and a de-duplicated
  // node list so a repeated id cannot emit two popovers competing for one DOM id.
  const labels = new Map<string, string>();
  const unique: TreeNode[] = [];
  const seen = new Set<string>();
  walk(nodes, n => {
    const id = safeId(n.id);
    if (!labels.has(id)) labels.set(id, n.label);
    if (!seen.has(id)) {
      seen.add(id);
      unique.push(n);
    }
  });

  const groups = spec.groups ?? [];
  const accents = new Map(groups.map(g => [safeId(g.id), g.accent ?? '1']));

  // Only orderings that reference at least one real node are worth a control.
  const orderings = (spec.orderings ?? []).filter(o =>
    Array.isArray(o.sequence) && o.sequence.some(id => seen.has(safeId(id))),
  );
  const defaultOrdering = orderings.find(o => o.default) ?? orderings[0];

  // nodeId → step number per ordering, positionally aligned to `orderings`.
  //
  // Every node emits one slot per ordering, empty where that ordering omits it. The
  // switcher is CSS-only (`:has(input:nth-of-type(n):checked)` → show `:nth-child(n)`),
  // and CSS cannot read an attribute value into a selector — so the alignment has to
  // be positional, which only holds if the slots are never sparse.
  const steps = new Map<string, Array<number | null>>();
  orderings.forEach((o, index) => {
    let step = 0;
    for (const raw of o.sequence) {
      const id = safeId(raw);
      if (!seen.has(id)) continue;
      step += 1;
      if (!steps.has(id)) steps.set(id, new Array(orderings.length).fill(null));
      steps.get(id)![index] = step;
    }
  });
  // Nodes absent from every ordering still need placeholder slots to keep indices aligned.
  if (orderings.length) {
    for (const id of seen) {
      if (!steps.has(id)) steps.set(id, new Array(orderings.length).fill(null));
    }
  }

  return html`
    <vk-tree>
      ${spec.title
        ? html`<vk-section data-variant="header" slot="header">
            <h1 slot="title">${spec.title}</h1>
            ${spec.subtitle ? html`<p class="vk-tree-subtitle">${spec.subtitle}</p>` : ''}
          </vk-section>`
        : ''}

      ${orderings.length > 1 ? orderingControls(orderings, defaultOrdering) : ''}
      ${groups.length ? legend(groups) : ''}

      <ol class="vk-tree-level" data-depth="0" role="tree">
        ${nodes.map(n => renderNode(n, 0, accents, steps))}
      </ol>

      ${unique.map(n => renderDetail(n, labels, groups))}
    </vk-tree>
  `;
}

function orderingControls(orderings: TreeOrdering[], active?: TreeOrdering): TemplateResult {
  return html`
    <fieldset class="vk-tree-orderings">
      <legend>Study sequence</legend>
      ${orderings.map(o => {
        const oid = safeId(o.id);
        return html`
          <input
            type="radio"
            name="vk-tree-ordering"
            id="vk-ord-${oid}"
            value=${oid}
            class="vk-tree-ordering-input"
            ?checked=${o.id === active?.id}
          />
          <label for="vk-ord-${oid}" class="vk-tree-ordering-label" title=${o.description ?? ''}>
            ${o.label}
          </label>
        `;
      })}
    </fieldset>
  `;
}

function legend(groups: TreeGroup[]): TemplateResult {
  return html`
    <ul class="vk-tree-legend">
      ${groups.map(
        g => html`
          <li class="vk-tree-legend-item" data-accent=${g.accent ?? '1'}>
            <span class="vk-tree-swatch" aria-hidden="true"></span>
            <span class="vk-tree-legend-label">${g.label}</span>
            ${g.description ? html`<span class="vk-tree-legend-desc">${g.description}</span>` : ''}
          </li>
        `,
      )}
    </ul>
  `;
}

function renderNode(
  n: TreeNode,
  depth: number,
  accents: Map<string, string>,
  steps: Map<string, Array<number | null>>,
): TemplateResult {
  const id = safeId(n.id);
  const group = n.group ? safeId(n.group) : '';
  const accent = group ? accents.get(group) ?? '1' : '0';
  const kids = n.children ?? [];
  const hasDetail = Boolean(n.detail);
  const nodeSteps = steps.get(id);

  const inner = html`
    ${nodeSteps?.length
      ? html`<span class="vk-tree-steps" aria-hidden="true">
          ${nodeSteps.map(
            step => html`<span class="vk-tree-step" ?data-empty=${step === null}>${step ?? ''}</span>`,
          )}
        </span>`
      : ''}
    <span class="vk-tree-label">${n.label}</span>
    ${n.badges?.length
      ? html`<span class="vk-tree-badges">
          ${n.badges.map(b => html`<span class="vk-tree-badge">${b}</span>`)}
        </span>`
      : ''}
  `;

  return html`
    <li
      class="vk-tree-item"
      data-accent=${accent}
      data-kind=${n.kind ?? (kids.length ? 'branch' : 'leaf')}
      role="treeitem"
      aria-expanded=${kids.length ? 'true' : 'false'}
    >
      ${hasDetail
        ? html`<button type="button" class="vk-tree-node" popovertarget="vk-detail-${id}">
            ${inner}
            <span class="vk-tree-more">${ICON_EXPAND}</span>
          </button>`
        : html`<span class="vk-tree-node vk-tree-node--static">${inner}</span>`}
      ${kids.length
        ? html`<ol class="vk-tree-level" data-depth=${depth + 1} role="group">
            ${kids.map(c => renderNode(c, depth + 1, accents, steps))}
          </ol>`
        : ''}
    </li>
  `;
}

function renderDetail(
  n: TreeNode,
  labels: Map<string, string>,
  groups: TreeGroup[],
): TemplateResult | '' {
  const d = n.detail;
  if (!d) return '';
  const id = safeId(n.id);
  const group = groups.find(g => safeId(g.id) === safeId(n.group ?? ''));
  const requires = (n.requires ?? []).map(safeId).filter(r => labels.has(r) && r !== id);

  return html`
    <div
      popover="auto"
      id="vk-detail-${id}"
      class="vk-tree-detail"
      data-accent=${group?.accent ?? '0'}
      aria-labelledby="vk-detail-title-${id}"
    >
      <header class="vk-tree-detail-head">
        <div>
          ${group ? html`<p class="vk-tree-detail-group">${group.label}</p>` : ''}
          <h2 id="vk-detail-title-${id}">${n.label}</h2>
        </div>
        <button
          type="button"
          class="vk-tree-close"
          popovertarget="vk-detail-${id}"
          popovertargetaction="hide"
          aria-label="Close"
        >
          ${ICON_CLOSE}
        </button>
      </header>

      <div class="vk-tree-detail-body">
        ${d.summary ? html`<p class="vk-tree-summary">${d.summary}</p>` : ''}
        ${d.meta?.length
          ? html`<dl class="vk-tree-meta">
              ${d.meta.map(m => html`<div><dt>${m.label}</dt><dd>${m.value}</dd></div>`)}
            </dl>`
          : ''}
        ${d.body?.length ? html`${d.body.map(block)}` : ''}
        ${requires.length
          ? html`<section class="vk-tree-requires">
              <h3>Understand first</h3>
              <ul>
                ${requires.map(
                  r => html`<li>
                    <button type="button" class="vk-tree-link" popovertarget="vk-detail-${r}">
                      ${labels.get(r)}
                    </button>
                  </li>`,
                )}
              </ul>
            </section>`
          : ''}
        ${d.resources?.length ? resources(d.resources) : ''}
      </div>
    </div>
  `;
}

function block(b: TreeBlock): TemplateResult | '' {
  switch (b?.type) {
    case 'heading':
      return html`<h3 class="vk-tree-h">${b.text}</h3>`;
    case 'text':
      return html`<p>${b.text}</p>`;
    case 'list':
      return b.ordered
        ? html`<ol class="vk-tree-list">
            ${b.items.map(i => html`<li>${i}</li>`)}
          </ol>`
        : html`<ul class="vk-tree-list">
            ${b.items.map(i => html`<li>${i}</li>`)}
          </ul>`;
    case 'code':
      return html`<vk-code data-language=${b.language ?? 'text'}><pre><code>${b.source}</code></pre></vk-code>`;
    case 'callout':
      return html`<aside class="vk-tree-callout" data-tone=${b.tone ?? 'note'}>${b.text}</aside>`;
    default:
      return '';
  }
}

function resources(list: TreeResource[]): TemplateResult {
  return html`
    <section class="vk-tree-resources">
      <h3>Resources</h3>
      <ul>
        ${list.map(r => {
          // A resource claiming certification affiliation without a verification date is
          // shown as unverified rather than silently presented as fact.
          const unverified = Boolean(r.certification) && !r.verified_at;
          return html`
            <li class="vk-tree-resource" data-type=${r.type}>
              <span class="vk-tree-restype">${RESOURCE_LABEL[r.type] ?? r.type}</span>
              <span class="vk-tree-resmain">
                ${safeUrl(r.url)
                  ? html`<a href=${safeUrl(r.url)} target="_blank" rel="noopener noreferrer">${r.title}</a>`
                  : html`<span>${r.title}</span>`}
                <span class="vk-tree-resmeta">
                  ${[r.institution, r.author, r.duration, r.level, r.cost]
                    .filter(Boolean)
                    .map(x => html`<span>${x}</span>`)}
                  ${r.certification
                    ? html`<span class="vk-tree-cert">${r.certification}</span>`
                    : ''}
                  ${r.lifecycle && r.lifecycle !== 'current'
                    ? html`<span class="vk-tree-lifecycle" data-lifecycle=${r.lifecycle}>
                        ${r.lifecycle === 'retired' ? 'retired' : 'version changing'}
                      </span>`
                    : ''}
                  ${r.provenance && r.provenance !== 'primary'
                    ? html`<span
                        class="vk-tree-provenance"
                        data-provenance=${r.provenance}
                        title=${r.provenance === 'relayed'
                          ? 'Taken from another party’s extraction, not checked independently'
                          : 'Summarised from someone else’s write-up, not read at the source'}
                        >${r.provenance}</span
                      >`
                    : ''}
                  ${unverified
                    ? html`<span class="vk-tree-unverified">unverified</span>`
                    : r.verified_at
                      ? html`<span class="vk-tree-verified">verified ${r.verified_at}</span>`
                      : ''}
                </span>
                ${r.note ? html`<span class="vk-tree-resnote">${r.note}</span>` : ''}
                ${safeUrl(r.artifact_url)
                  ? html`<a class="vk-tree-artifact" href=${safeUrl(r.artifact_url)} target="_blank" rel="noopener noreferrer">retrieved document</a>`
                  : ''}
              </span>
            </li>
          `;
        })}
      </ul>
    </section>
  `;
}

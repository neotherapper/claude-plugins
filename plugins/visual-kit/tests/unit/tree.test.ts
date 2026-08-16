import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';
import { renderTree, type TreeSpec } from '../../src/surfaces/tree.js';
import { renderFragment } from '../../src/render/ssr.js';

beforeAll(async () => { await loadSchemas(); });

const base: TreeSpec = {
  nodes: [
    {
      id: 'track-a',
      label: 'Track A',
      group: 'a',
      kind: 'branch',
      children: [
        { id: 'context-windows', label: 'Context windows', group: 'a', detail: { summary: 'How much fits.' } },
      ],
    },
  ],
};

const spec = (over: Partial<TreeSpec> = {}) => ({ surface: 'tree', version: 1, ...base, ...over });

describe('tree.v1.json', () => {
  it('accepts a minimal tree', () => {
    expect(validateSpec(spec()).ok).toBe(true);
  });

  it('accepts groups, orderings, badges and requires', () => {
    const r = validateSpec(spec({
      groups: [{ id: 'a', label: 'Track A', accent: '1' }],
      orderings: [{ id: 'exam-first', label: 'Exam first', default: true, sequence: ['context-windows'] }],
      nodes: [{
        id: 'context-windows', label: 'Context windows', group: 'a',
        badges: ['45 min'], requires: ['track-a'],
        detail: {
          summary: 'x',
          meta: [{ label: 'Axis', value: 'A' }],
          body: [{ type: 'callout', tone: 'pitfall', text: 'careful' }],
          resources: [{ type: 'paper', title: 'A paper', url: 'https://example.com' }],
        },
      }],
    }));
    expect(r.ok).toBe(true);
  });

  it('rejects an id that is not kebab-case', () => {
    expect(validateSpec(spec({ nodes: [{ id: 'Not Kebab', label: 'x' }] })).ok).toBe(false);
  });

  it('rejects an unknown block type', () => {
    const r = validateSpec(spec({
      nodes: [{ id: 'n', label: 'n', detail: { body: [{ type: 'iframe', src: 'x' } as never] } }],
    }));
    expect(r.ok).toBe(false);
  });

  it('rejects unknown properties on a node', () => {
    const r = validateSpec(spec({ nodes: [{ id: 'n', label: 'n', onclick: 'alert(1)' } as never] }));
    expect(r.ok).toBe(false);
  });

  // The point of the constraint: a certification claim has to be checkable.
  it('rejects a resource claiming a certification without url + verified_at', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: { resources: [{ type: 'course', title: 'Prep', certification: 'CCA-F' }] },
      }],
    }));
    expect(r.ok).toBe(false);
  });

  it('accepts the same resource once it carries url + verified_at', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: {
          resources: [{
            type: 'course', title: 'Prep', certification: 'CCA-F',
            url: 'https://example.com', verified_at: '2026-08-16',
          }],
        },
      }],
    }));
    expect(r.ok).toBe(true);
  });
});

describe('renderTree', () => {
  it('wires each node button to its own popover', () => {
    const out = renderFragment(renderTree(base));
    expect(out).toContain('popovertarget="vk-detail-context-windows"');
    expect(out).toContain('id="vk-detail-context-windows"');
    expect(out).toContain('popover="auto"');
  });

  it('omits the popover trigger for a node with no detail', () => {
    const out = renderFragment(renderTree({ nodes: [{ id: 'bare', label: 'Bare' }] }));
    expect(out).toContain('vk-tree-node--static');
    expect(out).not.toContain('popovertarget');
  });

  it('renders requires as cross-links using the target label, not the id', () => {
    const out = renderFragment(renderTree({
      nodes: [
        { id: 'first', label: 'First concept' },
        { id: 'second', label: 'Second', requires: ['first'], detail: { summary: 's' } },
      ],
    }));
    expect(out).toContain('popovertarget="vk-detail-first"');
    expect(out).toContain('First concept');
  });

  it('drops a requires entry that points at a node that does not exist', () => {
    const out = renderFragment(renderTree({
      nodes: [{ id: 'only', label: 'Only', requires: ['ghost'], detail: { summary: 's' } }],
    }));
    expect(out).not.toContain('vk-detail-ghost');
  });

  it('emits one popover per id even when an id repeats', () => {
    const out = renderFragment(renderTree({
      nodes: [
        { id: 'dup', label: 'A', detail: { summary: 'a' } },
        { id: 'dup', label: 'B', detail: { summary: 'b' } },
      ],
    }));
    expect(out.match(/id="vk-detail-dup"/g)).toHaveLength(1);
  });

  // The CSS switcher pairs the Nth radio with the Nth step slot, so slots must
  // never be sparse — a node missing from an ordering still needs its placeholder.
  it('emits one step slot per ordering for every node, including omitted ones', () => {
    const out = renderFragment(renderTree({
      orderings: [
        { id: 'one', label: 'One', sequence: ['a', 'b'] },
        { id: 'two', label: 'Two', sequence: ['b'] },
      ],
      nodes: [{ id: 'a', label: 'A' }, { id: 'b', label: 'B' }],
    }));
    const groups = out.match(/class="vk-tree-steps"/g) ?? [];
    expect(groups).toHaveLength(2);
    // 'a' is absent from ordering two, so it carries one filled and one empty slot.
    expect(out).toContain('data-empty');
  });

  it('shows the switcher only when more than one ordering is usable', () => {
    const one = renderFragment(renderTree({
      orderings: [{ id: 'only', label: 'Only', sequence: ['a'] }],
      nodes: [{ id: 'a', label: 'A' }],
    }));
    expect(one).not.toContain('vk-tree-orderings');

    const two = renderFragment(renderTree({
      orderings: [
        { id: 'one', label: 'One', sequence: ['a'] },
        { id: 'two', label: 'Two', sequence: ['a'] },
      ],
      nodes: [{ id: 'a', label: 'A' }],
    }));
    expect(two).toContain('vk-tree-orderings');
  });

  it('ignores an ordering whose sequence matches no node', () => {
    const out = renderFragment(renderTree({
      orderings: [
        { id: 'real', label: 'Real', sequence: ['a'] },
        { id: 'bogus', label: 'Bogus', sequence: ['nope'] },
      ],
      nodes: [{ id: 'a', label: 'A' }],
    }));
    expect(out).not.toContain('vk-ord-bogus');
    expect(out).not.toContain('vk-tree-orderings');
  });

  it('marks a certification resource without a verification date as unverified', () => {
    const out = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'course', title: 'Prep', certification: 'CCA-F' }] },
      }],
    }));
    expect(out).toContain('vk-tree-unverified');
  });

  // A verification date says when you looked, not whether the thing still exists.
  it('flags a retired resource, and stays quiet for a current one', () => {
    const retired = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'docs', title: 'Old cert', lifecycle: 'retired' }] },
      }],
    }));
    expect(retired).toContain('data-lifecycle="retired"');
    expect(retired).toContain('retired');

    const changing = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'docs', title: 'Moving cert', lifecycle: 'version-changing' }] },
      }],
    }));
    expect(changing).toContain('version changing');

    const current = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'docs', title: 'Live cert', lifecycle: 'current' }] },
      }],
    }));
    expect(current).not.toContain('vk-tree-lifecycle');
  });

  // Omitting a source does not make an unverified figure safer; it makes it
  // unfalsifiable while the precision still reads as verification.
  it('marks relayed and secondary claims, and stays quiet for first-hand ones', () => {
    const relayed = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'paper', title: 'Someone else read it', provenance: 'relayed' }] },
      }],
    }));
    expect(relayed).toContain('data-provenance="relayed"');

    const primary = renderFragment(renderTree({
      nodes: [{
        id: 'n', label: 'N',
        detail: { resources: [{ type: 'docs', title: 'I read it', provenance: 'primary' }] },
      }],
    }));
    expect(primary).not.toContain('vk-tree-provenance');
  });

  it('rejects an unknown provenance value', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: { resources: [{ type: 'docs', title: 'x', provenance: 'hearsay' } as never] },
      }],
    }));
    expect(r.ok).toBe(false);
  });

  it('rejects an unknown lifecycle value', () => {
    const r = validateSpec(spec({
      nodes: [{
        id: 'n', label: 'n',
        detail: { resources: [{ type: 'docs', title: 'x', lifecycle: 'sunsetting' } as never] },
      }],
    }));
    expect(r.ok).toBe(false);
  });

  it('escapes hostile content rather than emitting markup', () => {
    const out = renderFragment(renderTree({
      nodes: [{
        id: 'x', label: '<script>alert(1)</script>',
        detail: { body: [{ type: 'text', text: '<img src=x onerror=alert(1)>' }] },
      }],
    }));
    // The payload survives as text — what matters is that its angle brackets are
    // entity-encoded, so it can never be parsed as an element.
    expect(out).not.toContain('<script>alert(1)</script>');
    expect(out).not.toContain('<img src=x');
    expect(out).toContain('&lt;img src=x onerror=alert(1)&gt;');
  });

  it('narrows an id that would otherwise escape its attribute', () => {
    const out = renderFragment(renderTree({
      nodes: [{ id: 'a"><b', label: 'X', detail: { summary: 's' } }],
    }));
    expect(out).not.toContain('vk-detail-a"><b');
  });
});

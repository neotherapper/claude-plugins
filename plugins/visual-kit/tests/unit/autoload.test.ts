import { describe, it, expect } from 'vitest';
import { discoverRequiredBundles, resolveBundleRefs } from '../../src/render/autoload.js';

describe('discoverRequiredBundles', () => {
  it('returns empty array when only core tags are present', () => {
    expect(discoverRequiredBundles('<vk-section><vk-code>x</vk-code></vk-section>')).toEqual([]);
  });

  it('discovers <vk-math> and returns ["math"]', () => {
    expect(discoverRequiredBundles('<vk-section><vk-math>a^2</vk-math></vk-section>')).toEqual(['math']);
  });

  it('discovers <vk-chart> and returns ["chart"]', () => {
    expect(discoverRequiredBundles('<vk-chart><script type="application/json">{}</script></vk-chart>')).toEqual(['chart']);
  });

  it('discovers <vk-quiz> and returns ["quiz"]', () => {
    expect(discoverRequiredBundles('<vk-quiz></vk-quiz>')).toEqual(['quiz']);
  });

  it('discovers multiple tags and dedupes', () => {
    const html = '<vk-math>a</vk-math><vk-math>b</vk-math><vk-chart></vk-chart>';
    expect(discoverRequiredBundles(html).sort()).toEqual(['chart', 'math']);
  });

  it('matches self-closing tags', () => {
    expect(discoverRequiredBundles('<vk-math/>')).toEqual(['math']);
  });

  it('does not match tag-like text content (escaped <)', () => {
    expect(discoverRequiredBundles('&lt;vk-math&gt;')).toEqual([]);
  });

  it('does not match attributes whose names start with vk-', () => {
    expect(discoverRequiredBundles('<div data-vk-math="x">hi</div>')).toEqual([]);
  });

  it('throws on unknown tag names that share a known prefix (e.g. <vk-mathlike>)', () => {
    // Both `<vk-mathlike>` and `<vk-unknown>` are unknown tags — either is a typo
    // or a misuse in the fragment, and both must fail loudly rather than silently
    // decide which (if any) bundle to load.
    expect(() => discoverRequiredBundles('<vk-mathlike>x</vk-mathlike>')).toThrow(/Unknown <vk-\*> tag/);
  });

  it('throws on unknown <vk-*> tags', () => {
    expect(() => discoverRequiredBundles('<vk-unknown>x</vk-unknown>')).toThrow(/Unknown <vk-\*> tag/);
  });
});

describe('resolveBundleRefs', () => {
  const caps = {
    bundles: [
      { name: 'core',  url: '/vk/core.js',  sri: 'sha384-core' },
      { name: 'math',  url: '/vk/math.js',  sri: 'sha384-math' },
      { name: 'chart', url: '/vk/chart.js', sri: 'sha384-chart' },
      { name: 'quiz',  url: '/vk/quiz.js',  sri: 'sha384-quiz' },
    ],
  };

  it('always prepends core even when no names requested', async () => {
    const refs = await resolveBundleRefs([], caps);
    expect(refs).toEqual([{ url: '/vk/core.js', sri: 'sha384-core' }]);
  });

  it('prepends core and appends discovered bundles in declaration order', async () => {
    const refs = await resolveBundleRefs(['math', 'chart'], caps);
    expect(refs).toEqual([
      { url: '/vk/core.js',  sri: 'sha384-core' },
      { url: '/vk/math.js',  sri: 'sha384-math' },
      { url: '/vk/chart.js', sri: 'sha384-chart' },
    ]);
  });

  it('silently drops unknown bundle names (should not happen but be defensive)', async () => {
    const refs = await resolveBundleRefs(['math', 'nonsense'], caps);
    expect(refs.length).toBe(2);
  });
});

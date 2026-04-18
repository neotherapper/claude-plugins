import type { BundleRef } from './shell.js';

// Tag → bundle name (resolved to full BundleRef via capabilities at render time).
const TAG_TO_BUNDLE: Record<string, string> = {
  'vk-math':  'math',
  'vk-chart': 'chart',
  'vk-quiz':  'quiz',
  // core-bundle tags are NOT listed — core is always loaded.
};

// Core-bundle tags — used only for the unknown-tag assertion below.
const KNOWN_CORE_TAGS = new Set([
  'vk-section', 'vk-card', 'vk-gallery', 'vk-outline', 'vk-comparison',
  'vk-feedback', 'vk-loader', 'vk-error', 'vk-code',
]);

// Scan rendered HTML for <vk-*> opening tags in tag-name position only.
// Lookahead requires whitespace, '>', or '/' after the tag name —
// prevents false matches on attribute values or similar contexts.
const TAG_PATTERN = /<(vk-[a-z0-9-]+)(?=[\s/>])/g;

export function discoverRequiredBundles(fragmentHtml: string): string[] {
  const tags = new Set<string>();
  for (const match of fragmentHtml.matchAll(TAG_PATTERN)) {
    tags.add(match[1]!);
  }
  const knownBundleTags = new Set(Object.keys(TAG_TO_BUNDLE));
  for (const tag of tags) {
    if (!knownBundleTags.has(tag) && !KNOWN_CORE_TAGS.has(tag)) {
      throw new Error(`Unknown <vk-*> tag in rendered fragment: ${tag}`);
    }
  }
  const bundles = new Set<string>();
  for (const tag of tags) {
    const name = TAG_TO_BUNDLE[tag];
    if (name) bundles.add(name);
  }
  return [...bundles];
}

export async function resolveBundleRefs(
  names: string[],
  capabilities: { bundles: Array<{ name: string; url: string; sri: string }> },
): Promise<BundleRef[]> {
  const refs: BundleRef[] = [];
  const core = capabilities.bundles.find(b => b.name === 'core');
  if (core) refs.push({ url: core.url, sri: core.sri });
  for (const name of names) {
    const found = capabilities.bundles.find(b => b.name === name);
    if (found) refs.push({ url: found.url, sri: found.sri });
  }
  return refs;
}

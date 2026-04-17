import { listSurfaces } from '../render/validate.js';

const COMPONENTS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
];

const BUNDLES = [
  { name: 'core', url: '/vk/core.js', sri: 'sha384-placeholder' },
];

export function buildCapabilities(version: string): object {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => [k, { schema: `/vk/schemas/${k}.v1.json` }]),
    ),
    components: COMPONENTS,
    bundles: BUNDLES,
  };
}

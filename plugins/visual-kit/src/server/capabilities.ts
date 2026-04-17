import { listSurfaces } from '../render/validate.js';

// Injected at build time by scripts/build.mjs via esbuild define.
// Falls back to a dev sentinel when running from source via ts-node / vitest.
declare const __VK_CORE_SRI__: string;
const CORE_SRI: string =
  typeof __VK_CORE_SRI__ !== 'undefined' ? __VK_CORE_SRI__ : 'sha384-dev';

const COMPONENTS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
];

export async function buildCapabilities(version: string): Promise<object> {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => [k, { schema: `/vk/schemas/${k}.v1.json` }]),
    ),
    components: COMPONENTS,
    bundles: [
      { name: 'core', url: '/vk/core.js', sri: CORE_SRI },
    ],
  };
}

import { listSurfaces } from '../render/validate.js';
import type { SurfaceKind } from '../shared/types.js';

// Injected at build time by scripts/build.mjs via esbuild define.
// Falls back to a dev sentinel when running from source via ts-node / vitest.
declare const __VK_CORE_SRI__: string;
declare const __VK_MATH_SRI__: string;
declare const __VK_CHART_SRI__: string;
declare const __VK_QUIZ_SRI__: string;

const CORE_SRI:  string = typeof __VK_CORE_SRI__  !== 'undefined' ? __VK_CORE_SRI__  : 'sha384-dev';
const MATH_SRI:  string = typeof __VK_MATH_SRI__  !== 'undefined' ? __VK_MATH_SRI__  : 'sha384-dev';
const CHART_SRI: string = typeof __VK_CHART_SRI__ !== 'undefined' ? __VK_CHART_SRI__ : 'sha384-dev';
const QUIZ_SRI:  string = typeof __VK_QUIZ_SRI__  !== 'undefined' ? __VK_QUIZ_SRI__  : 'sha384-dev';

const COMPONENTS = [
  'vk-section', 'vk-card', 'vk-gallery', 'vk-outline', 'vk-comparison', 'vk-feedback',
  'vk-loader', 'vk-error', 'vk-code',
  'vk-math', 'vk-chart', 'vk-quiz',
];

const PERMISSIVE: ReadonlySet<SurfaceKind> = new Set(['free-interactive']);

export async function buildCapabilities(version: string): Promise<object> {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => {
        const entry: Record<string, unknown> = { schema: `/vk/schemas/${k}.v1.json` };
        if (PERMISSIVE.has(k)) entry.permissive = true;
        return [k, entry];
      }),
    ),
    components: COMPONENTS,
    bundles: [
      { name: 'core',  url: '/vk/core.js',  sri: CORE_SRI  },
      { name: 'math',  url: '/vk/math.js',  sri: MATH_SRI  },
      { name: 'chart', url: '/vk/chart.js', sri: CHART_SRI },
      { name: 'quiz',  url: '/vk/quiz.js',  sri: QUIZ_SRI  },
    ],
  };
}

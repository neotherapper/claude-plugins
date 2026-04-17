import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { listSurfaces } from '../render/validate.js';

const here = dirname(fileURLToPath(import.meta.url));
const sriPath = join(here, '../../dist/core.js.sri.txt');

let cachedSri: string | undefined;

const COMPONENTS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
];

export async function buildCapabilities(version: string): Promise<object> {
  if (!cachedSri) {
    try { cachedSri = (await readFile(sriPath, 'utf8')).trim(); }
    catch { cachedSri = 'sha384-dev'; }
  }
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => [k, { schema: `/vk/schemas/${k}.v1.json` }]),
    ),
    components: COMPONENTS,
    bundles: [
      { name: 'core', url: '/vk/core.js', sri: cachedSri },
    ],
  };
}

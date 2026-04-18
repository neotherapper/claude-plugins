import { defineConfig, Plugin } from 'vitest/config';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const MARKER = '\0css-raw:';

function cssTextPlugin(): Plugin {
  const resolvedMap = new Map<string, string>();
  let counter = 0;

  return {
    name: 'css-text',
    enforce: 'pre',
    resolveId(id, importer) {
      if (id.endsWith('.css') && importer) {
        const cleanImporter = importer
          .replace(/[?#].*$/, '')
          .replace(MARKER, '');
        const dir = cleanImporter.split('/').slice(0, -1).join('/');
        const abs = id.startsWith('/') ? id : resolve(dir, id);
        const key = MARKER + (counter++);
        resolvedMap.set(key, abs);
        return key;
      }
    },
    load(id) {
      if (id.startsWith(MARKER)) {
        const file = resolvedMap.get(id);
        if (file) {
          const content = readFileSync(file, 'utf-8');
          return `export default ${JSON.stringify(content)};`;
        }
      }
    },
  };
}

export default defineConfig({
  plugins: [cssTextPlugin()],
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'node',
    testTimeout: 10000,
  },
});

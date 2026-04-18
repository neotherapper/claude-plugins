import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/browser',
  testMatch: ['**/*.spec.ts'],
  fullyParallel: false, // tests share a single visual-kit server process
  workers: 1,
  reporter: 'list',
  use: {
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});

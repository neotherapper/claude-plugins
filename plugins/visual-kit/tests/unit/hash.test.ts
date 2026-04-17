import { describe, it, expect } from 'vitest';
import { workspacePort } from '../../src/shared/hash.js';

describe('workspacePort', () => {
  it('derives the same port for the same absolute path', () => {
    const p1 = workspacePort('/Users/demo/proj');
    const p2 = workspacePort('/Users/demo/proj');
    expect(p1).toBe(p2);
  });

  it('derives different ports for different paths', () => {
    const a = workspacePort('/Users/demo/project-a');
    const b = workspacePort('/Users/demo/project-b');
    expect(a).not.toBe(b);
  });

  it('maps into the range [20000, 60000)', () => {
    for (const path of ['/a', '/b', '/c/d/e', '/x'.repeat(50)]) {
      const port = workspacePort(path);
      expect(port).toBeGreaterThanOrEqual(20000);
      expect(port).toBeLessThan(60000);
    }
  });
});

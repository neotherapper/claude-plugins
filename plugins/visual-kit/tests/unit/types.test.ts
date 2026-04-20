import { describe, it, expectTypeOf } from 'vitest';
import type { SurfaceKind } from '../../src/shared/types.js';

describe('SurfaceKind', () => {
  it('includes free-interactive', () => {
    expectTypeOf<'free-interactive'>().toMatchTypeOf<SurfaceKind>();
  });

  it('still includes the existing kinds', () => {
    expectTypeOf<'lesson'>().toMatchTypeOf<SurfaceKind>();
    expectTypeOf<'free'>().toMatchTypeOf<SurfaceKind>();
    expectTypeOf<'outline'>().toMatchTypeOf<SurfaceKind>();
  });
});

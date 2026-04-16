import type { TemplateResult } from 'lit';
import { renderVkError } from './error-fragment.js';
import type { SurfaceKind } from '../shared/types.js';

export type SurfaceRenderer<TSpec = unknown> = (spec: TSpec) => TemplateResult;

const registry = new Map<SurfaceKind, SurfaceRenderer>();

export function registerSurface<TSpec>(kind: SurfaceKind, renderer: SurfaceRenderer<TSpec>): void {
  registry.set(kind, renderer as SurfaceRenderer);
}

export function renderSurface(spec: { surface?: string; version?: number }): TemplateResult {
  if (!spec || typeof spec !== 'object' || typeof spec.surface !== 'string') {
    return renderVkError({ title: 'Invalid SurfaceSpec', detail: 'Missing or malformed "surface" field.' });
  }
  const renderer = registry.get(spec.surface as SurfaceKind);
  if (!renderer) {
    return renderVkError({
      title: 'Unknown surface',
      surface: spec.surface,
      capabilitiesUrl: '/vk/capabilities',
    });
  }
  try {
    return renderer(spec);
  } catch (err) {
    return renderVkError({
      title: 'Surface render failed',
      detail: err instanceof Error ? err.message : String(err),
      surface: spec.surface,
    });
  }
}

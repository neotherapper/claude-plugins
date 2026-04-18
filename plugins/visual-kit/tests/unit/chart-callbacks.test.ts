import { describe, it, expect } from 'vitest';
import { chartConfigContainsCallbackFields } from '../../src/render/chart-callbacks.js';

describe('chartConfigContainsCallbackFields', () => {
  it('returns false for a plain config', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'bar',
      data: { labels: ['a', 'b'], datasets: [{ data: [1, 2] }] },
    })).toBe(false);
  });

  it('returns true when options.plugins.tooltip.callbacks.label is a string', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'bar',
      data: { datasets: [] },
      options: { plugins: { tooltip: { callbacks: { label: 'alert(1)' } } } },
    })).toBe(true);
  });

  it('returns true for onClick set to a string', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'line',
      data: { datasets: [] },
      options: { onClick: 'alert(1)' },
    })).toBe(true);
  });

  it('returns true for filter set to a string', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'pie',
      data: { datasets: [] },
      options: { plugins: { legend: { labels: { filter: 'badfn' } } } },
    })).toBe(true);
  });

  it('returns true for a callback key deep in a dataset', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'bar',
      data: {
        datasets: [{ label: 'ds', data: [], formatter: 'fn' }],
      },
    })).toBe(true);
  });

  it('ignores non-callback string fields', () => {
    expect(chartConfigContainsCallbackFields({
      type: 'bar',
      data: { datasets: [{ label: 'not a callback', data: [1, 2] }] },
      options: { plugins: { title: { text: 'Chart Title' } } },
    })).toBe(false);
  });

  it('ignores null/undefined config', () => {
    expect(chartConfigContainsCallbackFields(null)).toBe(false);
    expect(chartConfigContainsCallbackFields(undefined)).toBe(false);
  });
});

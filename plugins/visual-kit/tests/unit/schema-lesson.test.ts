import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';

beforeAll(async () => { await loadSchemas(); });

const baseLesson = {
  surface: 'lesson', version: 1,
  topic: 'Test', level: 'beginner' as const,
  sections: [] as Array<Record<string, unknown>>,
};

describe('lesson.v1.json — B1 schema tightening', () => {
  it('accepts a math section with display:true', () => {
    const spec = { ...baseLesson, sections: [{ type: 'math', latex: 'a^2', display: true }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });

  it('accepts a chart section with {type,data}', () => {
    const spec = { ...baseLesson, sections: [{ type: 'chart', config: { type: 'bar', data: { labels: [], datasets: [] } } }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });

  it('rejects a chart section missing config.type', () => {
    const spec = { ...baseLesson, sections: [{ type: 'chart', config: { data: {} } }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(false);
  });

  it('rejects a chart section with string-typed callback field', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'chart',
      config: {
        type: 'bar', data: { datasets: [] },
        options: { onClick: 'alert(1)' },
      },
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(false);
  });

  it('accepts a quiz with multiple_choice item', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'quiz',
      items: [{ type: 'multiple_choice', question: 'Q?', options: ['a','b'], answer: 'a', explanation: 'ok' }],
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });

  it('accepts a quiz with fill_blank item', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'quiz',
      items: [{ type: 'fill_blank', question: 'Fill', answer: 'x', explanation: 'y' }],
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });

  it('accepts a quiz with explain item', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'quiz',
      items: [{ type: 'explain', question: 'Why?', answer: 'ref', explanation: 'e' }],
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });

  it('rejects a quiz item with unknown type', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'quiz',
      items: [{ type: 'unknown', question: 'Q', answer: 'x', explanation: 'y' }],
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(false);
  });

  it('rejects a quiz fill_blank item missing "answer"', () => {
    const spec = { ...baseLesson, sections: [{
      type: 'quiz',
      items: [{ type: 'fill_blank', question: 'Q', explanation: 'y' }],
    }] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(false);
  });

  it('still accepts a Plan A lesson (no math display, loose-ish chart)', () => {
    const spec = { ...baseLesson, sections: [
      { type: 'concept', text: 'Hello' },
      { type: 'math', latex: 'a' },
    ] };
    const r = validateSpec(spec);
    expect(r.ok).toBe(true);
  });
});

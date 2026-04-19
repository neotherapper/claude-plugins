import { describe, it, expect } from 'vitest';
import { highlightToHtml } from '../../src/render/highlight.js';

describe('highlightToHtml', () => {
  it('tokenizes JavaScript source', () => {
    const out = highlightToHtml('javascript', 'const x = 1;');
    expect(out).toContain('token');
    expect(out).toContain('keyword');
    expect(out).toContain('const');
  });

  it('tokenizes TypeScript source', () => {
    const out = highlightToHtml('typescript', 'let n: number = 0;');
    expect(out).toContain('token');
  });

  it('tokenizes Python source', () => {
    const out = highlightToHtml('python', 'def hello(): return 1');
    expect(out).toContain('keyword');
    expect(out).toContain('def');
  });

  it('tokenizes CSS source', () => {
    const out = highlightToHtml('css', '.x { color: red; }');
    expect(out).toContain('token');
  });

  it('tokenizes HTML (via markup grammar)', () => {
    const out = highlightToHtml('html', '<p>hi</p>');
    expect(out).toContain('tag');
  });

  it('tokenizes JSON source', () => {
    const out = highlightToHtml('json', '{"a":1}');
    expect(out).toContain('token');
  });

  it('tokenizes Bash source', () => {
    const out = highlightToHtml('bash', 'echo hello');
    expect(out).toContain('token');
  });

  it('tokenizes Markdown source', () => {
    const out = highlightToHtml('markdown', '# Hello');
    expect(out).toContain('title');
  });

  it('tokenizes SQL source', () => {
    const out = highlightToHtml('sql', 'SELECT * FROM t;');
    expect(out).toContain('keyword');
  });

  it('escape-only for unknown languages', () => {
    const out = highlightToHtml('cobol', '<div>');
    expect(out).toBe('&lt;div&gt;');
    expect(out).not.toContain('token');
  });

  it('escape-only when source exceeds 100 KB', () => {
    const big = 'a'.repeat(100_001);
    const out = highlightToHtml('javascript', big);
    expect(out).toBe(big);
    expect(out).not.toContain('token');
  });

  it('never emits raw < or > in output for adversarial source', () => {
    const hostile = '</script><img src=x onerror=alert(1)>';
    const out = highlightToHtml('javascript', hostile);
    const stripTags = out.replace(/<\/?span[^>]*>/g, '');
    expect(stripTags).not.toMatch(/<img/);
    expect(stripTags).not.toMatch(/<\/script/);
  });

  it('escape-only input preserves HTML escapes', () => {
    const out = highlightToHtml('unknown-language', '&<>');
    expect(out).toBe('&amp;&lt;&gt;');
  });
});

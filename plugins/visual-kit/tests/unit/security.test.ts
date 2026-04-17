import { describe, it, expect } from 'vitest';
import {
  makeNonce,
  buildCsp,
  isHostAllowed,
  makeCsrfToken,
  verifyCsrfToken,
  securityHeaders,
} from '../../src/server/security.js';

describe('makeNonce', () => {
  it('returns a 22-char base64url string', () => {
    const n = makeNonce();
    expect(n).toMatch(/^[A-Za-z0-9_-]{22}$/);
  });
  it('returns different values on each call', () => {
    const a = makeNonce();
    const b = makeNonce();
    expect(a).not.toBe(b);
  });
});

describe('buildCsp', () => {
  it('produces a strict CSP with the nonce', () => {
    const csp = buildCsp({ nonce: 'ABCDEF', extraScriptSrc: [] });
    expect(csp).toContain("default-src 'none'");
    expect(csp).toContain("script-src 'self' 'nonce-ABCDEF'");
    expect(csp).toContain("style-src 'self' 'nonce-ABCDEF'");
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).not.toContain('unsafe-inline');
    expect(csp).not.toContain('unsafe-eval');
  });
  it('appends extra script-src tokens when requested (e.g. wasm-unsafe-eval)', () => {
    const csp = buildCsp({ nonce: 'XYZ', extraScriptSrc: ["'wasm-unsafe-eval'"] });
    expect(csp).toMatch(/script-src 'self' 'nonce-XYZ' 'wasm-unsafe-eval'/);
  });
});

describe('isHostAllowed', () => {
  it('accepts loopback hosts on the expected port', () => {
    expect(isHostAllowed('127.0.0.1:34287', { port: 34287, urlHost: 'localhost' })).toBe(true);
    expect(isHostAllowed('localhost:34287', { port: 34287, urlHost: 'localhost' })).toBe(true);
  });
  it('rejects other hosts', () => {
    expect(isHostAllowed('attacker.example:34287', { port: 34287, urlHost: 'localhost' })).toBe(false);
  });
  it('accepts custom url-host', () => {
    expect(isHostAllowed('devbox:34287', { port: 34287, urlHost: 'devbox' })).toBe(true);
  });
  it('rejects missing header', () => {
    expect(isHostAllowed(undefined, { port: 34287, urlHost: 'localhost' })).toBe(false);
  });
});

describe('CSRF', () => {
  const secret = Buffer.alloc(32, 42);
  it('validates a token bound to the same plugin+surface+nonce', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' })).toBe(true);
  });
  it('rejects a token for a different plugin', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'draftloom', surfaceId: 'lesson', nonce: 'N1' })).toBe(false);
  });
  it('rejects a token for a different surface', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'paidagogos', surfaceId: 'other', nonce: 'N1' })).toBe(false);
  });
  it('rejects a tampered token', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    const bad = token.slice(0, -1) + (token.at(-1) === 'a' ? 'b' : 'a');
    expect(verifyCsrfToken(secret, bad, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' })).toBe(false);
  });
});

describe('securityHeaders', () => {
  it('includes all required headers', () => {
    const h = securityHeaders();
    expect(h['X-Content-Type-Options']).toBe('nosniff');
    expect(h['Referrer-Policy']).toBe('no-referrer');
    expect(h['Cross-Origin-Opener-Policy']).toBe('same-origin');
    expect(h['Cross-Origin-Resource-Policy']).toBe('same-origin');
  });
});

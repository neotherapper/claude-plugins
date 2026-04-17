/**
 * Security primitives for the visual-kit dev server.
 *
 * Threat model (V1):
 * - The server binds to loopback only and serves a developer's local agent UI.
 * - Attackers we care about: malicious websites the developer visits in
 *   another tab (DNS rebinding / CSRF), and other users on the same machine.
 * - Out of scope for V1: hostile processes running as the same user, IPv6
 *   loopback literal hosts (`[::1]`), and proxies that rewrite Host headers.
 */
import { randomBytes, createHmac, timingSafeEqual } from 'node:crypto';

/** Minimum acceptable HMAC key length in bytes (matches SHA-256 block-relevant size). */
const MIN_SECRET_BYTES = 32;

/**
 * Generates a 16-byte CSP nonce, encoded as a 22-char unpadded base64url string.
 * 128 bits of entropy is well above the CSP3 recommendation of 128 bits minimum.
 */
export function makeNonce(): string {
  return randomBytes(16).toString('base64url');
}

export interface CspOptions {
  nonce: string;
  /** Extra `script-src` sources, e.g. `'wasm-unsafe-eval'`. Quote sources yourself. */
  extraScriptSrc?: string[];
  /** Extra `connect-src` sources, e.g. for SSE or fetch endpoints on the same origin. */
  extraConnectSrc?: string[];
}

/**
 * Builds a strict, nonce-based Content-Security-Policy header value.
 * The policy denies everything by default and explicitly grants only what the
 * dev server needs. We never include `unsafe-inline` or `unsafe-eval`.
 */
export function buildCsp(opts: CspOptions): string {
  const scriptExtras = (opts.extraScriptSrc ?? []).join(' ');
  const connectExtras = (opts.extraConnectSrc ?? []).join(' ');
  return [
    "default-src 'none'",
    `script-src 'self' 'nonce-${opts.nonce}'${scriptExtras ? ' ' + scriptExtras : ''}`,
    `style-src 'self' 'nonce-${opts.nonce}'`,
    "img-src 'self' data:",
    `connect-src 'self'${connectExtras ? ' ' + connectExtras : ''}`,
    "font-src 'self' data:",
    "frame-ancestors 'none'",
    "base-uri 'none'",
    "form-action 'none'",
  ].join('; ');
}

/**
 * Returns the small set of always-on security response headers we attach to
 * every response. CSP is applied separately because it is per-request (nonce).
 */
export function securityHeaders(): Record<string, string> {
  return {
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Resource-Policy': 'same-origin',
    Vary: 'Origin',
  };
}

export interface HostPolicy {
  port: number;
  /** The host name advertised in the server URL (e.g. `localhost` or a custom devbox name). */
  urlHost: string;
}

const ALWAYS_OK = new Set(['127.0.0.1', 'localhost']);

/**
 * Validates the `Host` request header against an allowlist. This is the
 * primary defense against DNS rebinding attacks: even if a malicious page
 * resolves an attacker-controlled name to 127.0.0.1, the browser still sends
 * `Host: attacker.example` and we reject the request.
 *
 * Limitation: IPv6 literal hosts of the form `[::1]:PORT` are not parsed and
 * will be rejected. V1 binds to IPv4 loopback only, so this is acceptable.
 */
export function isHostAllowed(header: string | undefined, policy: HostPolicy): boolean {
  if (!header) return false;
  // Reject bracketed IPv6 literals explicitly so we never accept them by accident.
  if (header.startsWith('[')) return false;
  const colonIdx = header.lastIndexOf(':');
  let host: string;
  let portStr: string | undefined;
  if (colonIdx < 0) {
    host = header;
    portStr = undefined;
  } else {
    host = header.slice(0, colonIdx);
    portStr = header.slice(colonIdx + 1);
  }
  if (!host) return false;
  if (portStr !== undefined && portStr !== '') {
    const port = Number(portStr);
    if (!Number.isInteger(port) || port !== policy.port) return false;
  }
  if (ALWAYS_OK.has(host)) return true;
  return host === policy.urlHost;
}

export interface CsrfBinding {
  plugin: string;
  surfaceId: string;
  nonce: string;
}

/**
 * Wire format: `base64url(payload) + '.' + base64url(mac)` — an unambiguous
 * two-part token. We deliberately avoid embedding the raw MAC bytes inside a
 * UTF-8 round-trip because the MAC may contain bytes (e.g. 0x3a colons) that
 * would corrupt naive byte-level splitting.
 *
 * Payload is the canonical string `plugin:surfaceId:nonce` UTF-8 encoded.
 * Plugin/surface/nonce values must not contain literal '.' chars or anything
 * that would clash with our binding semantics (the caller supplies them from
 * the URL path, which is validated separately by Task 8).
 */
export function makeCsrfToken(secret: Buffer, b: CsrfBinding): string {
  if (secret.length < MIN_SECRET_BYTES) {
    throw new Error(`CSRF secret must be >= ${MIN_SECRET_BYTES} bytes`);
  }
  const payload = Buffer.from(`${b.plugin}:${b.surfaceId}:${b.nonce}`, 'utf8');
  const mac = createHmac('sha256', secret).update(payload).digest();
  return `${payload.toString('base64url')}.${mac.toString('base64url')}`;
}

/**
 * Verifies a CSRF token bound to (plugin, surfaceId, nonce). Returns false
 * for any malformed input — we deliberately do not throw, so callers can use
 * a single boolean check without wrapping in try/catch.
 *
 * Timing note: the early-exit `payload !== expected` comparison leaks a
 * timing signal about which of (plugin, surfaceId, nonce) matched. Since the
 * expected values are derived from the request URL path that the attacker
 * already controls, this is acceptable in our threat model. The HMAC
 * verification itself uses `timingSafeEqual`.
 */
export function verifyCsrfToken(secret: Buffer, token: string, b: CsrfBinding): boolean {
  if (secret.length < MIN_SECRET_BYTES) return false;
  if (typeof token !== 'string') return false;
  const dot = token.indexOf('.');
  if (dot < 0) return false;
  const payloadB64 = token.slice(0, dot);
  const macB64 = token.slice(dot + 1);
  if (!payloadB64 || !macB64) return false;
  let payload: Buffer;
  let mac: Buffer;
  try {
    payload = Buffer.from(payloadB64, 'base64url');
    mac = Buffer.from(macB64, 'base64url');
  } catch {
    return false;
  }
  const expected = `${b.plugin}:${b.surfaceId}:${b.nonce}`;
  if (payload.toString('utf8') !== expected) return false;
  const check = createHmac('sha256', secret).update(Buffer.from(expected, 'utf8')).digest();
  if (mac.length !== check.length) return false;
  return timingSafeEqual(mac, check);
}

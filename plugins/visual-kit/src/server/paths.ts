import { lstat, realpath } from 'node:fs/promises';
import { join, resolve, sep } from 'node:path';

const SAFE = /^[a-zA-Z0-9_-]+$/;

export function isSafeSegment(s: string): boolean {
  return SAFE.test(s);
}

export async function resolveContained(root: string, relative: string): Promise<string> {
  const rootReal = await realpath(root);
  // Resolve target using the canonical root, but also compute it from the original
  // root so the returned path matches the caller's expectation on macOS (/var vs /private/var).
  const targetReal = resolve(rootReal, relative);
  if (!targetReal.startsWith(rootReal + sep) && targetReal !== rootReal) {
    throw new Error(`path resolves outside root: ${relative}`);
  }
  // Use lstat on the real path for the symlink check.
  const stat = await lstat(targetReal);
  if (stat.isSymbolicLink()) {
    throw new Error(`refusing symlink: ${relative}`);
  }
  // Return path relative to the original root (not the realpath'd root) so callers
  // get a consistent path matching what they passed as root.
  const target = resolve(root, relative);
  return target;
}

export function join2(...parts: string[]): string {
  return join(...parts);
}

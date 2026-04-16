import { createHash } from 'node:crypto';

const PORT_MIN = 20000;
const PORT_RANGE = 40000; // [20000, 60000)

/**
 * Derives a stable port from the absolute workspace path.
 * sha256 → first 4 bytes as u32 → modulo PORT_RANGE → offset PORT_MIN.
 */
export function workspacePort(absolutePath: string): number {
  const hash = createHash('sha256').update(absolutePath).digest();
  const n = hash.readUInt32BE(0);
  return PORT_MIN + (n % PORT_RANGE);
}

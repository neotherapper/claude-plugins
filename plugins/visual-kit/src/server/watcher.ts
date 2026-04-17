import { watch, type FSWatcher } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';

export interface ContentEvent {
  plugin: string;
  surfaceId: string;
  absPath: string;
}

export type ContentListener = (ev: ContentEvent) => void;

/**
 * Watches each plugin's `.<plugin>/content/` directory for `*.json` surface
 * specs and fans out change events to registered listeners.
 *
 * Notes:
 * - On macOS, `fs.watch` can emit multiple events for a single atomic write
 *   (tmp + rename). Listeners should be idempotent.
 * - `watch(dir)` requires `dir` to exist; `watchPlugin` awaits `mkdir` first.
 * - Listener failures must not abort the fan-out to other listeners.
 */
export class ContentWatcher {
  private watchers = new Map<string, FSWatcher>();
  private listeners = new Set<ContentListener>();

  constructor(private readonly projectDir: string) {}

  onChange(fn: ContentListener): () => void {
    this.listeners.add(fn);
    return () => {
      this.listeners.delete(fn);
    };
  }

  async watchPlugin(plugin: string): Promise<void> {
    if (this.watchers.has(plugin)) return;
    const dir = join(this.projectDir, `.${plugin}`, 'content');
    await mkdir(dir, { recursive: true });
    const w = watch(dir, (_eventType, filename) => {
      if (!filename || !filename.endsWith('.json')) return;
      const surfaceId = filename.slice(0, -'.json'.length);
      const ev: ContentEvent = { plugin, surfaceId, absPath: join(dir, filename) };
      for (const fn of this.listeners) {
        try {
          fn(ev);
        } catch {
          /* listener failures must not break the fan-out */
        }
      }
    });
    this.watchers.set(plugin, w);
  }

  close(): void {
    for (const w of this.watchers.values()) w.close();
    this.watchers.clear();
    this.listeners.clear();
  }
}

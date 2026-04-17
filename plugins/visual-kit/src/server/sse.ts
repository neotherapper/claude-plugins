import type { ServerResponse } from 'node:http';

export interface SseClient {
  res: ServerResponse;
  plugin?: string;
  surfaceId?: string;
}

/**
 * Server-sent events hub. Attaches long-lived `text/event-stream` connections
 * and fans out `refresh` events filtered by (plugin, surfaceId) tuple.
 *
 * Filter semantics:
 * - A client with no filters receives every event.
 * - A client with a plugin filter receives only events for that plugin.
 * - A client with both plugin and surfaceId filters receives only events for
 *   that specific surface.
 */
export class SseHub {
  private clients = new Set<SseClient>();

  attach(res: ServerResponse, filter: { plugin?: string; surfaceId?: string }): SseClient {
    res.writeHead(200, {
      'Content-Type':  'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection':    'keep-alive',
    });
    res.write(': vk-sse connected\n\n');
    const client: SseClient = { res, ...filter };
    this.clients.add(client);
    res.once('close', () => {
      this.clients.delete(client);
    });
    return client;
  }

  publish(event: { plugin: string; surfaceId: string }): void {
    for (const c of this.clients) {
      if (c.plugin && c.plugin !== event.plugin) continue;
      if (c.surfaceId && c.surfaceId !== event.surfaceId) continue;
      try {
        c.res.write(`data: refresh\n\n`);
      } catch {
        /* client may have disconnected; the 'close' handler clears it */
      }
    }
  }

  closeAll(): void {
    for (const c of this.clients) {
      try {
        c.res.end();
      } catch {
        /* already ended */
      }
    }
    this.clients.clear();
  }
}

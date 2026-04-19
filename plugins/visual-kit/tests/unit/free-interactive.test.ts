import { describe, it, expect } from 'vitest';
import { renderFreeInteractive, injectReloadScript } from '../../src/surfaces/free-interactive.js';

describe('injectReloadScript', () => {
  it('inserts the reload script immediately before </body>', () => {
    const input = '<html><body><p>hi</p></body></html>';
    const out = injectReloadScript(input);
    const idx = out.indexOf("new EventSource('/events/stream')");
    const bodyEnd = out.indexOf('</body>');
    expect(idx).toBeGreaterThan(-1);
    expect(bodyEnd).toBeGreaterThan(idx);
    expect(out.indexOf('<p>hi</p>')).toBeLessThan(idx);
  });

  it('appends the reload script at the end if </body> is absent', () => {
    const input = '<div>fragment</div>';
    const out = injectReloadScript(input);
    expect(out.startsWith('<div>fragment</div>')).toBe(true);
    expect(out).toContain("new EventSource('/events/stream')");
    expect(out).toContain('location.reload()');
  });

  it('injects at the LAST </body> when multiple exist', () => {
    const input =
      '<html><body><iframe srcdoc="<body>inner</body>"></iframe></body></html>';
    const out = injectReloadScript(input);
    const scriptIdx = out.indexOf("new EventSource('/events/stream')");
    const lastBodyEnd = out.lastIndexOf('</body>');
    expect(scriptIdx).toBeGreaterThan(-1);
    expect(lastBodyEnd).toBeGreaterThan(scriptIdx);
  });

  it('is case-insensitive about </BODY>', () => {
    const input = '<html><BODY>hi</BODY></html>';
    const out = injectReloadScript(input);
    expect(out).toContain("new EventSource('/events/stream')");
    const scriptIdx = out.indexOf("new EventSource('/events/stream')");
    const bodyEnd = out.toLowerCase().indexOf('</body>');
    expect(bodyEnd).toBeGreaterThan(scriptIdx);
  });
});

describe('renderFreeInteractive', () => {
  it('returns the html with the reload script injected', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body>x</body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('<body>x');
    expect(out).toContain("new EventSource('/events/stream')");
  });

  it('preserves inline <script> verbatim (no sanitisation)', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body><script>window.__marker = 42;</script></body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('<script>window.__marker = 42;</script>');
  });

  it('preserves inline event handlers verbatim', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body><button onclick="alert(1)">x</button></body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('onclick="alert(1)"');
  });
});

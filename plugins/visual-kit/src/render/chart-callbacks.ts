// Keys that Chart.js documents as callback/function slots.
// Any of these whose value is a STRING in a JSON-sourced config is a red flag —
// schema rejects them, and this helper is a second-layer guard in the component.
//
// CALLBACK_KEYS: flagged when their *own* value is a string.
// CALLBACK_CONTAINER_KEYS: flagged when any *child* string value is present.
const CALLBACK_KEYS = new Set<string>([
  'onClick', 'onHover', 'onComplete', 'onProgress',
  'filter', 'sort', 'generateLabels', 'labelColor', 'labelTextColor',
  'footer', 'beforeBody', 'afterBody',
  'formatter', 'generateYAxisLabels',
]);

// When these container keys hold an object, any string-valued child is suspicious.
const CALLBACK_CONTAINER_KEYS = new Set<string>([
  'callback', 'callbacks',
]);

export function chartConfigContainsCallbackFields(config: unknown): boolean {
  if (config === null || config === undefined) return false;
  return walk(config, false);
}

function walk(node: unknown, insideCallbackContainer: boolean): boolean {
  if (typeof node !== 'object' || node === null) return false;
  if (Array.isArray(node)) {
    for (const item of node) {
      if (walk(item, insideCallbackContainer)) return true;
    }
    return false;
  }
  const obj = node as Record<string, unknown>;
  for (const [k, v] of Object.entries(obj)) {
    // Inside a callbacks container, any string child is suspicious.
    if (insideCallbackContainer && typeof v === 'string') return true;
    // Direct callback key with a string value.
    if (CALLBACK_KEYS.has(k) && typeof v === 'string') return true;
    // Recurse, marking when we enter a callback container.
    if (typeof v === 'object' && v !== null) {
      const enterContainer = insideCallbackContainer || CALLBACK_CONTAINER_KEYS.has(k);
      if (walk(v, enterContainer)) return true;
    }
  }
  return false;
}

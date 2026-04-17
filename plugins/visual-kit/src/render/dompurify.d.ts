declare module 'dompurify' {
  interface DOMPurifyI {
    sanitize(dirty: string, config?: Record<string, unknown>): string;
    setConfig(config: Record<string, unknown>): void;
  }
  function createDOMPurify(window: Window): DOMPurifyI;
  export default createDOMPurify;
}

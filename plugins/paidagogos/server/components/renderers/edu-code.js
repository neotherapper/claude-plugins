// <edu-code config="{...}"> — syntax-highlighted code, optionally editable.
// Config: { language: string, code: string, editable?: boolean }
// CodeMirror 6 from esm.sh to keep ESM-native CDN imports working.

const { LitElement, html, css } = window.__lit;

const CM_URL = 'https://esm.sh/codemirror@6.0.1?bundle';
const STATE_URL = 'https://esm.sh/@codemirror/state@6.4.1?bundle';
const LANG_URLS = {
  'javascript': 'https://esm.sh/@codemirror/lang-javascript@6.2.2?bundle',
  'typescript': 'https://esm.sh/@codemirror/lang-javascript@6.2.2?bundle',
  'python':     'https://esm.sh/@codemirror/lang-python@6.1.6?bundle',
  'css':        'https://esm.sh/@codemirror/lang-css@6.3.0?bundle',
  'html':       'https://esm.sh/@codemirror/lang-html@6.4.9?bundle',
  'json':       'https://esm.sh/@codemirror/lang-json@6.0.1?bundle',
};

async function loadLang(language) {
  const url = LANG_URLS[language];
  if (!url) return null;
  const mod = await import(url);
  const factoryName = Object.keys(mod).find(k => typeof mod[k] === 'function');
  return factoryName ? mod[factoryName]() : null;
}

class EduCode extends LitElement {
  static properties = {
    config: { type: Object },
  };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { border: 1px solid var(--border, #e9ecef); border-radius: 8px; overflow: hidden; }
    .cm-editor { font-family: "SF Mono", Consolas, monospace; font-size: 0.9rem; }
  `;

  async firstUpdated() {
    if (!this.config?.code) return;
    const [{ EditorView, basicSetup }, { EditorState }] = await Promise.all([
      import(CM_URL),
      import(STATE_URL),
    ]);
    const langExt = await loadLang(this.config.language);
    const container = this.renderRoot.querySelector('.wrap');
    new EditorView({
      state: EditorState.create({
        doc: this.config.code,
        extensions: [
          basicSetup,
          ...(langExt ? [langExt] : []),
          ...(this.config.editable === false ? [EditorState.readOnly.of(true)] : []),
        ],
      }),
      parent: container,
    });
  }

  render() {
    return html`<div class="wrap"></div>`;
  }
}

customElements.define('edu-code', EduCode);

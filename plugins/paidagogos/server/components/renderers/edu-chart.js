// <edu-chart config="{...}"> — renders Chart.js charts from a JSON config.
// Config: { library: "chartjs", type: string, data: object, options?: object }

const { LitElement, html, css } = window.__lit;
const CHARTJS_URL = 'https://esm.sh/chart.js@4.4.1/auto';

class EduChart extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { position: relative; width: 100%; max-width: 720px; }
  `;

  async firstUpdated() {
    if (!this.config) return;
    if (this.config.library !== 'chartjs') {
      console.warn('edu-chart: only "chartjs" library supported in V2');
      return;
    }
    const { default: Chart } = await import(CHARTJS_URL);
    const canvas = this.renderRoot.querySelector('canvas');
    new Chart(canvas, {
      type: this.config.type,
      data: this.config.data,
      options: this.config.options || { responsive: true },
    });
  }

  render() {
    return html`<div class="wrap"><canvas></canvas></div>`;
  }
}

customElements.define('edu-chart', EduChart);

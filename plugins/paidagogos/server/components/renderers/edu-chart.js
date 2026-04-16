// <edu-chart config="{...}"> — renders Chart.js charts from a JSON config.
// Config: { library: "chartjs", type: string, data: object, options?: object }

import { LitElement, html, css } from 'https://esm.sh/lit@3.2.1';
const CHARTJS_URL = 'https://esm.sh/chart.js@4.4.1/auto';

const EDU_CHART_STYLE = `
  edu-chart { display: block; margin: 1rem 0; }
  edu-chart .wrap { position: relative; width: 100%; max-width: 720px; }
`;
if (!document.querySelector('style[data-edu-chart]')) {
  const s = document.createElement('style');
  s.dataset.eduChart = 'true';
  s.textContent = EDU_CHART_STYLE;
  document.head.appendChild(s);
}

class EduChart extends LitElement {
  static properties = { config: { type: Object } };

  createRenderRoot() { return this; }

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

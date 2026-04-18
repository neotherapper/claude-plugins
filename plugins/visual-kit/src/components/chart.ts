import { LitElement, html, css } from 'lit';
import { customElement, state } from 'lit/decorators.js';
import { Chart } from 'chart.js/auto';
import type { ChartConfiguration } from 'chart.js';
import { chartConfigContainsCallbackFields } from '../render/chart-callbacks.js';

@customElement('vk-chart')
export class VkChart extends LitElement {
  // Light DOM so the sibling <script type="application/json"> that paidagogos
  // writes as a direct child of <vk-chart> is reachable via querySelector.
  // Without light DOM the slotted script would be in the slot assignment only,
  // and Chart.js canvas rendering is simpler with light-DOM canvas access.
  protected createRenderRoot(): Element {
    return this;
  }

  static styles = css`:host { display: block; }`;

  @state() private errorMessage?: string;
  @state() private parsedConfig?: ChartConfiguration;
  private chart?: Chart;

  connectedCallback(): void {
    super.connectedCallback();
    // Parse the sibling config BEFORE the first render so error states are
    // reflected in the initial DOM (tests await updateComplete once).
    const configScript = this.querySelector('script[type="application/json"]');
    if (!configScript?.textContent) {
      this.errorMessage = 'vk-chart: missing config script';
      return;
    }
    let config: ChartConfiguration;
    try {
      config = JSON.parse(configScript.textContent);
    } catch (err) {
      console.warn('vk-chart: config JSON parse failed', err);
      this.errorMessage = 'vk-chart: invalid config JSON';
      return;
    }
    if (chartConfigContainsCallbackFields(config)) {
      this.errorMessage = 'vk-chart: config contains disallowed callback fields';
      return;
    }
    this.parsedConfig = config;
  }

  firstUpdated() {
    if (this.errorMessage || !this.parsedConfig) return;
    const canvas = this.querySelector('canvas');
    if (!canvas) return;
    try {
      this.chart = new Chart(canvas as HTMLCanvasElement, this.parsedConfig);
    } catch (err) {
      console.warn('vk-chart: Chart.js init failed', err);
      this.errorMessage = 'vk-chart: render failed';
    }
  }

  disconnectedCallback(): void {
    super.disconnectedCallback();
    this.chart?.destroy();
  }

  render() {
    if (this.errorMessage) {
      return html`<div style="color:var(--vk-warning,#d29922);font-family:monospace;font-size:.85rem;padding:.5rem">${this.errorMessage}</div>`;
    }
    return html`
      <div style="position:relative;width:100%;max-width:720px">
        <canvas></canvas>
      </div>
      <slot></slot>`;
  }
}

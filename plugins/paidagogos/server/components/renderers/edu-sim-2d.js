// <edu-sim-2d config="{...}"> — interactive 2D physics via Matter.js.
// Config: {
//   world: { gravity: {x, y} },
//   bodies: Array<{type, x, y, ...dims, options}>,
//   canvas: { width, height }
// }

const { LitElement, html, css } = window.__lit;
const MATTER_URL = 'https://esm.sh/matter-js@0.20.0';

class EduSim2d extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { border: 1px solid var(--border, #e9ecef); border-radius: 8px; overflow: hidden; background: var(--surface, #f8f9fa); }
    canvas { display: block; max-width: 100%; }
  `;

  async firstUpdated() {
    if (!this.config?.canvas) return;
    const Matter = await import(MATTER_URL);
    const { Engine, Render, Runner, Bodies, Composite, Mouse, MouseConstraint } = Matter;

    const engine = Engine.create({ gravity: this.config.world?.gravity || { x: 0, y: 1 } });
    const container = this.renderRoot.querySelector('.wrap');
    const render = Render.create({
      element: container,
      engine,
      options: {
        width: this.config.canvas.width,
        height: this.config.canvas.height,
        wireframes: false,
        background: 'transparent',
      },
    });

    const bodies = (this.config.bodies || []).map(b => {
      switch (b.type) {
        case 'rectangle': return Bodies.rectangle(b.x, b.y, b.width, b.height, b.options || {});
        case 'circle':    return Bodies.circle(b.x, b.y, b.radius, b.options || {});
        case 'polygon':   return Bodies.polygon(b.x, b.y, b.sides, b.radius, b.options || {});
        default: console.warn('edu-sim-2d: unknown body type', b.type); return null;
      }
    }).filter(Boolean);

    Composite.add(engine.world, bodies);

    const mouse = Mouse.create(render.canvas);
    const mouseConstraint = MouseConstraint.create(engine, {
      mouse,
      constraint: { stiffness: 0.2, render: { visible: false } },
    });
    Composite.add(engine.world, mouseConstraint);
    render.mouse = mouse;

    Render.run(render);
    const runner = Runner.create();
    Runner.run(runner, engine);
  }

  render() {
    return html`<div class="wrap"></div>`;
  }
}

customElements.define('edu-sim-2d', EduSim2d);

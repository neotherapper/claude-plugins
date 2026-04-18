import { LitElement, html, css } from 'lit';
import { customElement, state } from 'lit/decorators.js';

interface QuizItem {
  type: 'multiple_choice' | 'fill_blank' | 'explain';
  question: string;
  options?: string[];
  answer: string;
  explanation: string;
}

interface Answered {
  chosen: string;
  correct: boolean;
}

@customElement('vk-quiz')
export class VkQuiz extends LitElement {
  // Light-DOM render — sibling <script type="application/json"> must be
  // reachable via querySelector, and light-DOM keeps CSS-variable theming
  // transparent to the page.
  protected createRenderRoot(): Element {
    return this;
  }

  static styles = css`:host { display: block; }`;

  @state() private items: QuizItem[] = [];
  @state() private answered: Record<number, Answered> = {};
  @state() private parseError = false;

  // Parse the sibling JSON in connectedCallback so parseError / items are
  // decided BEFORE the first render — avoids a second re-render (and the
  // test-timing trap we hit with <vk-chart>).
  connectedCallback(): void {
    super.connectedCallback();
    const json = this.querySelector('script[type="application/json"]')?.textContent;
    if (!json) { this.parseError = true; return; }
    try {
      const parsed = JSON.parse(json) as { items?: QuizItem[] };
      if (!Array.isArray(parsed.items) || parsed.items.length === 0) {
        this.parseError = true; return;
      }
      this.items = parsed.items;
    } catch (err) {
      console.warn('vk-quiz: config JSON parse failed', err);
      this.parseError = true;
    }
  }

  private emit(index: number, item: QuizItem, chosen: string, correct: boolean) {
    const cappedChosen = chosen.length > 1024 ? chosen.slice(0, 1024) : chosen;
    this.answered = { ...this.answered, [index]: { chosen: cappedChosen, correct } };
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true,
      composed: true,
      detail: {
        type: 'quiz_answer',
        index,
        item_type: item.type,
        chosen: cappedChosen,
        correct,
        ts: new Date().toISOString(),
      },
    }));
  }

  private renderMultipleChoice(item: QuizItem, index: number) {
    const resp = this.answered[index];
    return html`
      <div class="vk-quiz-item">
        <p class="vk-quiz-question">${item.question}</p>
        <div class="vk-quiz-options" role="radiogroup">
          ${(item.options ?? []).map(opt => html`
            <button
              role="radio"
              aria-checked=${resp?.chosen === opt ? 'true' : 'false'}
              data-value=${opt}
              ?disabled=${!!resp}
              @click=${() => this.emit(index, item, opt, opt === item.answer)}
            >${opt}</button>
          `)}
        </div>
        ${resp ? html`
          <p class="vk-quiz-feedback ${resp.correct ? 'correct' : 'wrong'}">
            ${resp.correct ? 'Correct.' : `Incorrect — the answer is "${item.answer}".`}
          </p>
          <p class="vk-quiz-explain">${item.explanation}</p>
        ` : ''}
      </div>
    `;
  }

  private renderFillBlank(item: QuizItem, index: number) {
    const resp = this.answered[index];
    return html`
      <div class="vk-quiz-item">
        <p class="vk-quiz-question">${item.question}</p>
        <input type="text" data-input=${index} ?disabled=${!!resp}>
        <button
          data-submit=${index}
          ?disabled=${!!resp}
          @click=${(e: Event) => {
            const input = (e.currentTarget as HTMLElement).parentElement!
              .querySelector<HTMLInputElement>(`input[data-input="${index}"]`)!;
            const v = input.value.trim();
            this.emit(index, item, v, v.toLowerCase() === item.answer.toLowerCase());
          }}
        >Submit</button>
        ${resp ? html`
          <p class="vk-quiz-feedback ${resp.correct ? 'correct' : 'wrong'}">
            ${resp.correct ? 'Correct.' : `Incorrect — the answer is "${item.answer}".`}
          </p>
          <p class="vk-quiz-explain">${item.explanation}</p>
        ` : ''}
      </div>
    `;
  }

  private renderExplain(item: QuizItem, index: number) {
    const resp = this.answered[index];
    return html`
      <div class="vk-quiz-item">
        <p class="vk-quiz-question">${item.question}</p>
        <textarea rows="4" data-textarea=${index} ?disabled=${!!resp}></textarea>
        <button
          data-submit=${index}
          ?disabled=${!!resp}
          @click=${(e: Event) => {
            const ta = (e.currentTarget as HTMLElement).parentElement!
              .querySelector<HTMLTextAreaElement>(`textarea[data-textarea="${index}"]`)!;
            // Explain is self-grading — record participation, reveal reference.
            this.emit(index, item, ta.value, true);
          }}
        >Submit</button>
        ${resp ? html`
          <p class="vk-quiz-reference"><strong>Reference answer:</strong> ${item.answer}</p>
          <p class="vk-quiz-explain">${item.explanation}</p>
        ` : ''}
      </div>
    `;
  }

  render() {
    if (this.parseError) {
      return html`<vk-error><p slot="detail">vk-quiz: no valid items in config.</p></vk-error>`;
    }
    return html`${this.items.map((item, i) => {
      switch (item.type) {
        case 'multiple_choice': return this.renderMultipleChoice(item, i);
        case 'fill_blank':      return this.renderFillBlank(item, i);
        case 'explain':         return this.renderExplain(item, i);
        default: return html``;
      }
    })}`;
  }
}

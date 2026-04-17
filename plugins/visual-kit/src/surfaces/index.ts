import { registerSurface } from '../render/dispatcher.js';
import { renderLesson } from './lesson.js';
import { renderGallery } from './gallery.js';
import { renderOutline } from './outline.js';
import { renderComparison } from './comparison.js';
import { renderFeedback } from './feedback.js';
import { renderFree } from './free.js';

export function registerAllSurfaces(): void {
  registerSurface('lesson',     renderLesson     as never);
  registerSurface('gallery',    renderGallery    as never);
  registerSurface('outline',    renderOutline    as never);
  registerSurface('comparison', renderComparison as never);
  registerSurface('feedback',   renderFeedback   as never);
  registerSurface('free',       renderFree       as never);
}

import createDomPurify from 'dompurify';
import { JSDOM } from 'jsdom';

const jsdom = new JSDOM('');
const purify = createDomPurify(jsdom.window as unknown as Window);

const ALLOWED_TAGS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
  'p','span','strong','em','code','pre','ul','ol','li','a','br','hr',
  'h1','h2','h3','h4','h5','h6','blockquote',
  'table','thead','tbody','tr','th','td',
  'img','figure','figcaption',
];

const ALLOWED_ATTR = [
  'class','id','slot','title','alt','src','href',
  'data-id','data-title','data-multiselect','data-variant','data-selected','data-tone','data-label',
];

purify.setConfig({
  USE_PROFILES: { html: true },
  ALLOWED_TAGS,
  ALLOWED_ATTR,
  FORBID_ATTR: [],
  ALLOW_DATA_ATTR: false,
});

export function sanitizeFreeHtml(raw: string): string {
  return purify.sanitize(raw);
}

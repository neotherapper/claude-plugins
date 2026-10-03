# SvelteKit Framework Detection

This guide covers fingerprinting and API surface mapping for SvelteKit applications.

## Framework Summary
- **Name**: SvelteKit
- **Type**: Full-stack meta-framework for Svelte
- **Popularity**: Growing adoption for modern web applications
- **Website**: [https://kit.svelte.dev](https://kit.svelte.dev)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| SSR Attributes | `data-sveltekit-*` attributes | HTML source analysis |
| JS Globals | `__SVELTEKIT__`, `$app/*` imports | Browser console evaluation |
| Static Files | `/_app/immutable/*` | Directory enumeration |
| Build Output | `/build/` directory patterns | File discovery |
| Route Files | `src/routes/+page.svelte` patterns | Source file patterns |

### Technology Stack
SvelteKit is commonly paired with:
- Vite for bundling and development
- Node.js, serverless, or edge runtimes
- Tailwind CSS or Svelte-specific styling solutions
- Svelte stores for state management
- Fetch API for data loading
- Various adapters (Node, Vercel, Netlify, Cloudflare)

## API Surface Discovery
SvelteKit applications typically expose:
- `+server.js` API endpoints at corresponding routes
- Form actions via `+page.server.js`
- Load functions in `+page.js`/`+layout.js`
- Server hooks in `src/hooks.server.js`

See [fingerprinting.md](./fingerprinting.md) for detailed API surface mapping techniques.

## Security Considerations
- Implement proper Content Security Policy headers
- Use SvelteKit's built-in CSRF protection
- Validate and sanitize all form inputs
- Use environment variables for secrets
- Implement rate limiting for API endpoints
- Use HTTPS for all communications

## Version Detection
- Check SvelteKit version via package.json if exposed
- Analyze `data-sveltekit` attribute patterns
- Check `/_app/version.json` if exists
- Examine Vite manifest patterns

## Resources
- [Official SvelteKit Documentation](https://kit.svelte.dev/docs)
- [SvelteKit GitHub Repository](https://github.com/sveltejs/kit)
- [Svelte Documentation](https://svelte.dev/docs)
- [Vite + SvelteKit Guide](https://vitejs.dev/guide/ssr.html#sveltekit)
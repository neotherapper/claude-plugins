# SolidJS Framework Detection

This guide covers fingerprinting and API surface mapping for SolidJS applications.

## Framework Summary
- **Name**: SolidJS
- **Type**: Reactive JavaScript framework
- **Popularity**: Growing adoption for performance-critical applications
- **Website**: [https://solidjs.com](https://solidjs.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| JS Globals | `Solid`, `createSignal`, `createEffect` | Browser console evaluation |
| Meta Tags | `framework-solid` in meta | HTML source analysis |
| Static Files | `/src/**/*.jsx`, `/src/**/*.tsx` | Directory enumeration |
| Build Output | `/dist/**/*.js` with Solid patterns | File discovery |
| SSR Output | `data-solid` attributes in HTML | HTML source analysis |

### Technology Stack
SolidJS is commonly paired with:
- Vite or Rollup for bundling
- Express, FastAPI, or custom backend APIs
- TypeScript for type safety
- Tailwind CSS or UnoCSS for styling
- TanStack Query or Solid Query for data fetching
- Solid Router for client-side routing

## API Surface Discovery
SolidJS applications typically interface with:
- RESTful APIs at `/api/*`
- GraphQL endpoints at `/graphql`
- Authentication APIs at `/auth/*`
- Server-side rendering endpoints

See [fingerprinting.md](./fingerprinting.md) for detailed API surface mapping techniques.

## Security Considerations
- Implement proper Content Security Policy headers
- Use Solid's built-in XSS protection through JSX
- Validate and sanitize all user inputs
- Use HTTPS for all API communications
- Implement CSRF protection for forms

## Version Detection
- Check Solid version via `Solid.version` in browser console
- Analyze bundle patterns for version-specific code
- Check package.json if exposed
- Examine Vite/Rollup build output patterns

## Resources
- [Official SolidJS Documentation](https://solidjs.com/docs)
- [SolidJS GitHub Repository](https://github.com/solidjs/solid)
- [SolidStart Documentation](https://start.solidjs.com)
- [Vite + Solid Template](https://github.com/solidjs/templates)
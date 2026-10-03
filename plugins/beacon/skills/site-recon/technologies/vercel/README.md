# Vercel Platform Detection

This guide covers fingerprinting and API surface mapping for applications deployed on Vercel.

## Platform Summary
- **Name**: Vercel
- **Type**: Serverless/Edge deployment platform
- **Popularity**: Leading platform for frontend deployments
- **Website**: [https://vercel.com](https://vercel.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| `vercel.json` config | File discovery | `/.vercel/project.json`, `/vercel.json` |
| Server headers | `server` header | `x-vercel-*` headers, `Vercel` in server header |
| Edge runtime | Response headers | `x-vercel-id`, `x-vercel-deployment-url` |
| Vercel CDN | CDN patterns | `.vercel.app` domains |
| Now CLI traces | Build output | `now-*` references in bundles |

### Technology Stack
Vercel deployments commonly use:
- Next.js (primary framework)
- SvelteKit, Remix, Astro
- Node.js serverless functions
- Edge Functions (V8 isolates)
- Vercel KV, Vercel Postgres, Vercel Blob
- Vercel Analytics, Speed Insights

## API Surface Discovery
Vercel-deployed applications typically expose:
- `/api/*` serverless function routes
- `/api/*` Edge Function routes
- Static assets via Vercel CDN
- Vercel-specific headers and metadata

## Security Considerations
- Environment variables are server-side only
- Use Vercel's built-in authentication
- Implement proper CORS for Edge Functions
- Use `vercel.json` for security configurations
- Rate limiting via Edge Middleware

## Version Detection
- Check `vercel.json` configuration
- Analyze `x-vercel-*` response headers
- Check deployment-specific headers
- Examine serverless function signatures

## Resources
- [Vercel Documentation](https://vercel.com/docs)
- [Vercel GitHub Repository](https://github.com/vercel/vercel)
- [Vercel Edge Runtime](https://vercel.com/docs/edge-network)
- [Serverless Functions](https://vercel.com/docs/functions)
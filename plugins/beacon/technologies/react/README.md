# React Framework Detection

This guide covers fingerprinting and API surface mapping for React applications.

## Framework Summary
- **Name**: React
- **Type**: Frontend JavaScript library/framework
- **Popularity**: 40.58% (Stack Overflow 2023 survey)
- **Website**: [https://react.dev](https://react.dev)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Static Files | `/static/js/main.[hash].js` | Directory enumeration |
| Meta Tags | `create-react-app` in meta | HTML source analysis |
| JS Globals | `React`, `ReactDOM` | Browser console evaluation |
| Next.js Files | `/_next/` directory | Directory enumeration |
| Manifest Files | `asset-manifest.json` | File discovery |

### Technology Stack
React is commonly paired with:
- Node.js backend or serverless functions
- Next.js for full-stack applications
- Express, FastAPI, or custom backend APIs
- Redux, Zustand, or Context API for state management
- Tailwind, CSS Modules, or styled-components for styling
- GraphQL (Apollo, Relay) or REST APIs

## API Surface Discovery
React applications typically interface with:
- RESTful APIs at `/api/*`
- GraphQL endpoints at `/graphql`
- Authentication APIs at `/auth/*`
- Next.js API routes (when using Next.js backend)

See [fingerprinting.md](./fingerprinting.md) for detailed API surface mapping techniques.

## Security Considerations
- Implement proper Content Security Policy headers
- Mask environment variables - don't expose sensitive data client-side
- Use HTTPS for all API communications
- Implement CSRF protection for forms
- Validate and sanitize all user inputs
- Use React's built-in XSS protection

## Version Detection
- Check React version via `React.version` in browser console
- Analyze `asset-manifest.json` structure differences
- Look for version-specific code patterns in bundles
- Examine Next.js build IDs and chunk filenames

## Resources
- [Official React Documentation](https://react.dev/learn)
- [React GitHub Repository](https://github.com/facebook/react)
- [Next.js Documentation](https://nextjs.org/docs)
- [Create React App Documentation](https://create-react-app.dev/)
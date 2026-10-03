# React Native Framework Detection

This guide covers fingerprinting and API surface mapping for React Native applications.

## Framework Summary
- **Name**: React Native
- **Type**: Cross-platform mobile framework
- **Popularity**: Leading cross-platform mobile framework
- **Website**: [https://reactnative.dev](https://reactnative.dev)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| JS Bundle Files | `index.android.bundle`, `index.ios.bundle` | Mobile app binary analysis |
| Hermes Engine | `hermes` patterns in app | Android app analysis |
| Metro Bundler | `localhost:8081` references | App configuration |
| Native Modules | `NativeModules.*` patterns | JavaScript bundle analysis |
| Expo Patterns | `expo-*` packages | Bundle analysis |

### Technology Stack
React Native is commonly paired with:
- Hermes JavaScript engine
- Metro bundler for development
- React Navigation for routing
- Redux/MobX for state management
- Native modules for platform-specific features
- Expo for faster development (optional)

## API Surface Discovery
React Native applications typically interface with:
- RESTful APIs at `/api/*`
- GraphQL endpoints at `/graphql`
- Firebase services
- Platform-specific native APIs
- Push notification services

## Security Considerations
- Store API keys securely (not in bundle)
- Use secure storage for tokens
- Implement certificate pinning
- Use HTTPS for all API communications
- Validate all user inputs

## Version Detection
- Check React Native version via package.json
- Analyze bundle for version strings
- Check Hermes engine version
- Examine native module patterns

## Resources
- [Official React Native Documentation](https://reactnative.dev/docs)
- [React Native GitHub Repository](https://github.com/facebook/react-native)
- [Expo Documentation](https://docs.expo.dev)
- [React Navigation Documentation](https://reactnavigation.org)
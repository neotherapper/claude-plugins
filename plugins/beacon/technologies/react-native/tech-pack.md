---
framework: react-native
version: "0.70+"
last_updated: "2026-05-02"
author: "@opencode"
status: community
---

# React Native — Tech Pack

React Native is a cross-platform mobile framework for building native apps using JavaScript and React.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| Hermes engine | JS bundle analysis | `hermes::` bytecode markers | Definitive |
| `__rnm` or `__d` functions | JS global | Metro bundler runtime | High |
| `ReactNative` global | JS global | Object present in bundle | High |
| `NativeModules` usage | JS bundle | Platform-specific native code | Medium |
| `expo-*` packages | JS bundle | Expo framework usage | Medium |
| Metro bundler references | Config files | `localhost:8081` or `metro.config.js` | Medium |

**Version extraction (bash):**

```bash
# Check for React Native version strings in bundle
curl -s https://target.example.com/index.android.bundle | grep -o '"react-native@[^"]*"' | head -1

# Look for Hermes markers
curl -s https://target.example.com/index.android.bundle | grep -o 'hermes\|Hermes' | head -3

# Check for version comments in bundle
curl -s https://target.example.com/index.android.bundle | grep -o '0\.[0-9]\{2\}\.[0-9]\+' | sort | uniq
```

## 2. Default API Surfaces

| Endpoint Pattern | Method | Auth | Notes |
|------------------|--------|------|-------|
| `/api/` | GET/POST | Varies | Backend REST API |
| `/graphql` | POST | Varies | GraphQL endpoint |
| `/auth/*` | GET/POST | Credentials | Authentication |
| `/users/*` | REST | Auth | User management |
| `/products/*` | REST | Varies | Product catalog |
| Firebase endpoints | Various | API key | Firebase services |
| GraphQL subscriptions | WS | Auth | Real-time features |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.ReactNative` | JS bundle inspection | Framework info |
| `NativeModules` | JS bundle inspection | Native module definitions |
| `__rnm_props` | JavaScript bundle | Runtime props (debug) |
| Environment config | `.env` files if exposed | API keys, endpoints |
| Firebase config | App bundle | Firebase credentials |
| CodePush config | If using MS App Center | Update endpoints |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| JWT tokens | Authorization header | Common for API auth |
| Firebase tokens | Firebase SDK | Firebase Authentication |
| OAuth tokens | Secure storage | Third-party auth |
| API keys | Header or param | Service identification |
| Device tokens | Push service | FCM/APNs tokens |

## 5. Bundle Analysis

| Path Pattern | Content |
|--------------|---------|
| `index.android.bundle` | Main Android bundle |
| `index.ios.bundle` | Main iOS bundle |
| `assets/*` | Static assets |
| `drawable-*` | Android drawables |
| Hermes bytecode | `*.hbc` files | Optimized bundle format |

**Bundle analysis:**

```bash
# Search for API endpoints in React Native bundle
curl -s https://target.example.com/index.android.bundle | grep -o '"/api/[^"]*"' | sort -u

# Look for authentication patterns
curl -s https://target.example.com/index.android.bundle | grep -o 'Authorization\|Bearer\|token\|secret' | sort -u

# Extract base URL configurations
curl -s https://target.example.com/index.android.bundle | grep -o 'https\?://[^"]*api[^"]*' | sort -u
```

## 6. Mobile-Specific Patterns

**Deep linking schemes:**
```bash
# Common React Native deep link schemes
# exp://, myapp://, com.myapp://
curl -sf "https://target.example.com/.well-known/assetlinks.json"
```

**Push notification endpoints:**
- FCM (Firebase Cloud Messaging): `fcm.googleapis.com`
- APNs (Apple Push Notification service): `api.push.apple.com`
- OneSignal: `onesignal.com/api/v1/`
- Expo Push: `exp.host/--/api/v2/push`

**Firebase configuration:**
```bash
# Check for Firebase config exposure
curl -s https://target.example.com/ | grep -o 'firebase[^"]*' | head -5
curl -s https://target.example.com/ | grep -o '"projectId":"[^"]*"' | head -1
```

## 7. Probe Checklist

**Phase 5 probes (React Native API surface):**

```bash
TARGET="target.example.com"

# Standard API endpoints
curl -sf "https://${TARGET}/api/"
curl -sf "https://${TARGET}/api/health"
curl -sf "https://${TARGET}/graphql"

# Authentication endpoints
for endpoint in login register auth token oauth; do
  curl -sf "https://${TARGET}/api/${endpoint}"
  curl -sf "https://${TARGET}/auth/${endpoint}"
done

# Common mobile API patterns
for endpoint in users products orders notifications settings profile; do
  curl -sf "https://${TARGET}/api/${endpoint}"
  curl -sf "https://${TARGET}/api/v1/${endpoint}"
done

# Firebase Realtime Database (if used)
curl -sf "https://${TARGET}.firebaseio.com/.json"
curl -sf "https://${TARGET}-default-rtdb.firebaseio.com/.json"
```

**What to log:**
- `[REACT-NATIVE-DETECTED:{version}]` when React Native is confirmed
- `[REACT-NATIVE-API:{endpoint}:{status}]` for each API probe
- `[REACT-NATIVE-FIREBASE:{found}]` for Firebase configurations
- `[REACT-NATIVE-PUSH:{provider}:{status}]` for push notification services
# React Native Fingerprinting Guide

## Detection Methods

### 1. Mobile App Binary Analysis

React Native apps distributed as APK/AAB (Android) or IPA (iOS) require different analysis:

**Android APK analysis:**
```bash
# Download APK and analyze
curl -s -o app.apk "https://target.com/app.apk"
unzip -q app.apk -d apk_contents
grep -r "hermes\|react-native\|com.facebook.react" apk_contents/
```

**iOS IPA analysis:**
```bash
# Download IPA and analyze (requires extraction)
curl -s -o app.ipa "https://target.com/app.ipa"
unzip -q app.ipa -d ipa_contents
grep -r "hermes\|react-native\|com.facebook" ipa_contents/
```

### 2. Web-Based Detection (React Native Web)

If the app uses React Native for Web or is accessible via browser:

```bash
# Check for React Native Web patterns
curl -s https://target.example.com/ | grep -E 'react-native|RN|Bundle|hermes'

# Check for Hermes bytecode markers
curl -s https://target.example.com/index.android.bundle | grep -c 'hermes' || true
```

### 3. JS Bundle Analysis

```bash
# Download and analyze main bundle
curl -s -o bundle.js "https://target.example.com/index.android.bundle"

# Look for React Native patterns
grep -o '__rnm\|__d\|ReactNative\|hermes\|createElement' bundle.js | sort | uniq

# Extract API endpoints
grep -o '"/api/[^"]*"' bundle.js | sort | uniq

# Look for base URLs
grep -o 'https\?://[^"]*api[^"]*' bundle.js | sort | uniq
```

### 4. Hermes Engine Detection

Hermes is React Native's default JavaScript engine:

```bash
# Check for Hermes bytecode markers
curl -s https://target.example.com/index.android.bundle | grep -o 'hermes::\|::Hermes\|HermesRuntime' | head -5

# Look for compiled Hermes bytecode
curl -s https://target.example.com/index.android.bundle | xxd | grep -i 'hermes\|celtic\|magic' | head -5
```

### 5. Native Module Detection

```bash
# Look for native module patterns
curl -s https://target.example.com/index.android.bundle | grep -o 'NativeModules\.\|\.native\|__Native\|RNN\|TurboModule' | sort | uniq

# Check for specific native modules
for module in geolocation camera image picker push-notification; do
  count=$(curl -s https://target.example.com/index.android.bundle | grep -c -i "$module" || true)
  if [[ $count -gt 0 ]]; then
    echo "NATIVE-MODULE: $module found ($count occurrences)"
  fi
done
```

### 6. Expo Detection

```bash
# Check for Expo patterns
curl -s https://target.example.com/index.android.bundle | grep -o 'expo-\|Expo\|exp://' | sort | uniq

# Look for Expo update endpoints
curl -s https://target.example.com/index.android.bundle | grep -o 'exp.host\|expo.io' | sort | uniq
```

### 7. Firebase Configuration

Many React Native apps use Firebase:

```bash
# Look for Firebase config exposure
curl -s https://target.example.com/index.android.bundle | grep -o '"projectId":"[^"]*"'
curl -s https://target.example.com/index.android.bundle | grep -o '"apiKey":"[^"]*"' | head -1

# Check for Firebase Realtime Database
curl -sf "https://${TARGET}.firebaseio.com/.json" && echo "Firebase DB accessible"
```

### 8. Version Detection

```bash
# Extract React Native version from bundle
curl -s https://target.example.com/index.android.bundle | grep -o '"react-native":"[^"]*"'
curl -s https://target.example.com/index.android.bundle | grep -o '0\.[0-9]\{2\}\.[0-9]\+' | sort | uniq | head -5

# Check Hermes version
curl -s https://target.example.com/index.android.bundle | grep -o 'hermes[^"]*' | head -3
```

### 9. Metro Bundler Detection

Development server patterns:

```bash
# Check for Metro bundler config
curl -sf "https://target.example.com/metro.config.js" && echo "Metro config exposed"
curl -sf "https://target.example.com/package.json" | grep -o '"react-native":"[^"]*"'

# Development server references in bundle
curl -s https://target.example.com/index.android.bundle | grep -o 'localhost:8081\|metro\|bundler' | sort | uniq
```

### 10. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | Hermes bytecode markers, `__rnm` function in bundle |
| **High** | React Native global, Hermes engine references |
| **Medium** | Native module patterns, Expo packages |
| **Low** | Generic mobile patterns, API endpoint discovery |

### 11. False Positive Mitigation

**Not React Native if:**
- Bundle is standard Webpack/Vite output
- Uses Angular, Vue, or other frameworks
- No `hermes` or `__rnm` patterns present
- Standard web JavaScript without mobile framework markers

**Verification command:**
```bash
# Comprehensive React Native check
curl -s https://target.example.com/index.android.bundle 2>/dev/null | python3 -c "
import sys, re
try:
    content = sys.stdin.read()
    indicators = {
        'hermes_engine': 'hermes' in content.lower(),
        'rnm_function': '__rnm' in content or '__d' in content,
        'react_native_global': 'ReactNative' in content or 'reactnative' in content.lower(),
        'native_modules': 'NativeModules' in content,
        'expo_packages': 'expo-' in content,
    }
    score = sum(indicators.values())
    if score >= 2:
        print('[REACT-NATIVE-CONFIRMED] Multiple indicators found')
        for k, v in indicators.items():
            if v: print(f'  - {k}')
    else:
        print('[REACT-NATIVE-NOT-DETECTED] Insufficient evidence')
except Exception as e:
    print(f'[ERROR] {e}')
"
```

### 12. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# React Native detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'react-native|hermes|__rnm|NativeModules'; then
    echo "[FRAMEWORK-DETECTED:react-native]"
    # Trigger tech pack load in Phase 4
fi
```
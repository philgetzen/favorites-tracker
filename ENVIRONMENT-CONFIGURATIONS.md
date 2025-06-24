# Environment Configurations

This document describes the environment configuration system for FavoritesTracker.

## Build Configurations

The project now supports three build configurations:

1. **Debug** - Development environment with debugging enabled
2. **Testing** - Integration testing with Firebase emulators
3. **Release** - Production environment optimized for distribution

## Environment Settings

### Debug Configuration
- Firebase emulators enabled
- Detailed logging enabled
- Analytics disabled
- Development API endpoints
- Bundle ID: `com.favoritesapp.FavoritesTracker`
- iOS Deployment Target: 26.0

### Testing Configuration
- Firebase emulators enabled (for integration tests)
- Detailed logging enabled
- Analytics disabled
- Test API endpoints
- Bundle ID: `com.favoritesapp.FavoritesTracker.testing`
- iOS Deployment Target: 26.0
- Preprocessor macro: `TESTING=1`
- Swift compilation condition: `TESTING`

### Release Configuration
- Live Firebase services
- Logging disabled
- Analytics enabled
- Production API endpoints
- Bundle ID: `com.favoritesapp.FavoritesTracker`
- iOS Deployment Target: 18.5
- Optimized builds (`-Owholemodule`)

## Firebase Emulator Configuration

When using Testing or Debug configurations:

- **Auth Emulator**: `localhost:9099`
- **Firestore Emulator**: `localhost:8080`
- **Storage Emulator**: `localhost:9199`

## Usage in Code

```swift
import Foundation

// Check current environment
let currentEnv = AppConfiguration.shared.currentEnvironment

// Environment-specific logic
if AppConfiguration.shared.isDebugMode {
    // Debug-specific code
} else if AppConfiguration.shared.isTestingMode {
    // Testing-specific code
} else if AppConfiguration.shared.isProductionMode {
    // Production-specific code
}

// Access environment configuration
let config = EnvironmentConfiguration.shared
print("API Base URL: \(config.baseURL)")
print("Use Emulator: \(config.useFirebaseEmulator)")
```

## Build Commands

### Debug Build
```bash
xcodebuild -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -configuration Debug build
```

### Testing Build
```bash
xcodebuild -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -configuration Testing build
```

### Release Build
```bash
xcodebuild -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -configuration Release build
```

## Scheme Selection in Xcode

1. Click the scheme selector next to the Run button
2. Choose "Edit Scheme..."
3. Select the desired Build Configuration for Run/Test/Profile/Archive actions

## Notes

- The Testing configuration is automatically selected when running unit tests
- Firebase emulator setup is handled automatically based on configuration
- Environment detection uses Swift compilation conditions for optimal performance
- All configurations target iOS 26.0 except Release (18.5 for broader compatibility)
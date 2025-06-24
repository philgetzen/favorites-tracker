# Firebase Test Lab Integration

This document describes the Firebase Test Lab integration setup for the FavoritesTracker iOS project.

## Overview

Firebase Test Lab provides cloud-based testing infrastructure for iOS applications, allowing you to run tests on real devices across different iOS versions and device configurations.

## Setup Status

✅ **Firebase Test Lab Configured**: Integration scripts and configuration files created
✅ **Project Connected**: Connected to Firebase project `favorites-tracker-bc071`
✅ **CLI Tools Ready**: Firebase CLI authenticated and configured
⚠️ **Test Targets**: Need to add XCTest targets to Xcode project for full functionality

## Files Created

- `firebase-test-lab.sh` - Main script for Test Lab operations
- `firebase-testlab-config.json` - Test matrix configuration
- `FIREBASE-TESTLAB.md` - This documentation file

## Usage

### Setup (Already Completed)
```bash
./firebase-test-lab.sh setup
```

### Build for Testing (When test targets are available)
```bash
./firebase-test-lab.sh build
```

### Run Tests on Test Lab (When test targets are available)
```bash
./firebase-test-lab.sh test
```

## Test Matrix Configuration

The default configuration tests on:
- iPhone 11 Pro (iOS 15.7)
- iPhone 13 (iOS 16.6)
- Portrait orientation
- English (US) locale
- 5-minute timeout

## Device Coverage

Firebase Test Lab provides access to:
- Physical iOS devices (not simulators)
- Multiple iOS versions (iOS 12.0 - latest)
- Various device models (iPhone, iPad)
- Different screen sizes and resolutions

## Test Types Supported

1. **XCTest**: Standard iOS unit and UI tests
2. **Game Loop Tests**: For game applications
3. **Robo Tests**: Automated UI exploration (Android only)

## Integration with Existing Test Framework

The project already has a comprehensive test framework configured:
- Unit tests in `FavoritesTrackerTests/Unit/`
- Integration tests in `FavoritesTrackerTests/Integration/`
- UI tests in `FavoritesTrackerTests/UI/`

These tests can be executed on Firebase Test Lab once the Xcode project is configured with proper test targets.

## Next Steps

1. **Add Test Targets to Xcode Project**:
   - Open `FavoritesTracker.xcodeproj` in Xcode
   - Add iOS Unit Testing Bundle target
   - Add iOS UI Testing Bundle target
   - Configure test schemes

2. **Update Test Configuration**:
   - Link existing test files to test targets
   - Configure test schemes for Firebase Test Lab
   - Update build settings for testing

3. **Run First Test**:
   - Build test bundle with `./firebase-test-lab.sh build`
   - Submit tests with `./firebase-test-lab.sh test`
   - Monitor results in Firebase Console

## Monitoring Test Results

Test results are available in:
1. **Firebase Console**: https://console.firebase.google.com/project/favorites-tracker-bc071/testlab
2. **CLI Output**: Real-time progress and summary
3. **Test Reports**: Detailed logs, screenshots, and performance metrics

## Cost Considerations

- **Free Tier**: 10 tests/day on physical devices
- **Paid**: $5 per hour per physical device
- **Virtual Devices**: Free unlimited testing on simulators

## Security Notes

- Test Lab runs in isolated environments
- No persistent data between test runs
- Network access controlled per test configuration
- Results stored in Firebase project (encrypted)

## Troubleshooting

### Common Issues:
1. **No test targets**: Add test targets to Xcode project
2. **Build failures**: Check iOS deployment target compatibility
3. **Authentication**: Run `firebase login` if needed
4. **Project access**: Verify Firebase project permissions

### Debug Commands:
```bash
# List available devices
firebase testlab ios models list

# Check project status
firebase projects:list

# View test history
firebase testlab ios runs list
```

## Related Documentation

- [Firebase Test Lab iOS Documentation](https://firebase.google.com/docs/test-lab/ios)
- [Xcode Testing Guide](https://developer.apple.com/documentation/xctest)
- Project testing framework: `TESTING-FRAMEWORK.md`
#!/bin/bash

# Firebase Test Lab Configuration Script for FavoritesTracker
# This script sets up Firebase Test Lab integration for iOS testing

set -e

PROJECT_ID="favorites-tracker-bc071"
SCHEME_NAME="FavoritesTracker"
BUILD_DIR="./build"
TEST_ZIP="FavoritesTracker-Test.zip"

echo "🧪 Firebase Test Lab Setup for FavoritesTracker"
echo "================================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Login to Firebase (if not already logged in)
echo "📱 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Logging into Firebase..."
    firebase login
fi

# Select the project
echo "🎯 Setting Firebase project..."
firebase use $PROJECT_ID

# Create test configuration
echo "⚙️  Creating Test Lab configuration..."

# Function to build for testing
build_for_testing() {
    echo "🔨 Building app for testing..."
    
    # Clean build directory
    rm -rf "$BUILD_DIR"
    
    # Build the app for testing
    xcodebuild clean build-for-testing \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
        -derivedDataPath "$BUILD_DIR" \
        CODE_SIGNING_ALLOWED=NO
        
    echo "✅ Build completed successfully"
}

# Function to create test bundle
create_test_bundle() {
    echo "📦 Creating test bundle..."
    
    # Find the test bundle
    TEST_BUNDLE_PATH=$(find "$BUILD_DIR" -name "*.xctestrun" | head -1)
    
    if [ -z "$TEST_BUNDLE_PATH" ]; then
        echo "❌ Test bundle not found. Creating basic test configuration..."
        return 1
    fi
    
    # Create zip for Test Lab
    BUNDLE_DIR=$(dirname "$TEST_BUNDLE_PATH")
    cd "$BUNDLE_DIR"
    zip -r "../../$TEST_ZIP" *.xctestrun *.app
    cd - > /dev/null
    
    echo "✅ Test bundle created: $TEST_ZIP"
}

# Function to run tests on Test Lab
run_test_lab() {
    echo "🚀 Running tests on Firebase Test Lab..."
    
    # Check if gcloud CLI is available
    if command -v gcloud &> /dev/null; then
        echo "Using gcloud CLI for Firebase Test Lab..."
        gcloud firebase test ios run \
            --test "$TEST_ZIP" \
            --device model=iphone11pro,version=15.7 \
            --device model=iphone13,version=16.6 \
            --timeout 5m \
            --project "$PROJECT_ID"
    else
        echo "⚠️  gcloud CLI not found. Please use Firebase Console to upload tests:"
        echo "   1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/testlab"
        echo "   2. Click 'Run a test'"
        echo "   3. Upload the test bundle: $TEST_ZIP"
        echo "   4. Select devices and run the test"
        echo ""
        echo "Or install gcloud CLI: https://cloud.google.com/sdk/docs/install"
    fi
        
    echo "✅ Test Lab instructions provided"
}

# Function to setup Test Lab without actual tests (for configuration)
setup_test_lab_config() {
    echo "⚙️  Setting up Firebase Test Lab configuration..."
    
    # Create test lab configuration file
    cat > firebase-testlab-config.json << EOF
{
  "project": "$PROJECT_ID",
  "testMatrix": {
    "testSpecification": {
      "iosXcTest": {
        "testsZip": {
          "gcsPath": "gs://$PROJECT_ID-test-lab/$TEST_ZIP"
        }
      }
    },
    "environmentMatrix": {
      "iosDeviceList": {
        "iosDevices": [
          {
            "iosModelId": "iphone11pro",
            "iosVersionId": "15.7",
            "locale": "en_US",
            "orientation": "portrait"
          },
          {
            "iosModelId": "iphone13",
            "iosVersionId": "16.6", 
            "locale": "en_US",
            "orientation": "portrait"
          }
        ]
      }
    }
  }
}
EOF

    echo "✅ Firebase Test Lab configuration created"
}

# Main execution
case "${1:-setup}" in
    "build")
        build_for_testing
        ;;
    "test")
        if create_test_bundle; then
            run_test_lab
        else
            echo "⚠️  No tests configured yet. Use 'setup' to create configuration."
        fi
        ;;
    "setup"|*)
        setup_test_lab_config
        echo ""
        echo "🎉 Firebase Test Lab setup complete!"
        echo ""
        echo "Next steps:"
        echo "1. Add test targets to your Xcode project"
        echo "2. Run './firebase-test-lab.sh build' to build for testing"
        echo "3. Run './firebase-test-lab.sh test' to execute tests on Test Lab"
        echo ""
        echo "Configuration file: firebase-testlab-config.json"
        ;;
esac
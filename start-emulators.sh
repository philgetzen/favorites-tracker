#!/bin/bash

# Firebase Emulator Suite Startup Script
# Run this script to start all Firebase emulators for local development

echo "🔥 Starting Firebase Emulator Suite..."
echo "📱 Project: favorites-tracker-bc071"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install with: npm install -g firebase-tools"
    exit 1
fi

# Start emulators
echo "🚀 Starting emulators..."
echo "   - Auth: http://localhost:9099"
echo "   - Firestore: http://localhost:8080"
echo "   - Storage: http://localhost:9199"
echo "   - Functions: http://localhost:5001"
echo "   - UI: http://localhost:4000"
echo ""

firebase emulators:start --project favorites-tracker-bc071
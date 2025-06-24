# Firebase Emulator Setup

## Overview
The Firebase Emulator Suite allows you to develop and test locally without connecting to production Firebase services.

## Prerequisites
- Node.js and npm installed
- Java Runtime Environment (JRE) - required for Firestore emulator
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase authentication (run `firebase login`)

## Quick Start

### 1. Login to Firebase (if not already logged in)
```bash
firebase login
```

### 2. Start Emulators
```bash
./start-emulators.sh
```

Or manually:
```bash
firebase emulators:start --project favorites-tracker-bc071
```

### 3. Access Emulator UI
Open http://localhost:4000 to access the Firebase Emulator UI

## Emulator Ports
- **Auth**: localhost:9099
- **Firestore**: localhost:8080  
- **Storage**: localhost:9199
- **Functions**: localhost:5001
- **UI Dashboard**: localhost:4000

## iOS App Configuration
The iOS app automatically detects development mode and connects to local emulators when running in DEBUG configuration.

### Development Mode Features:
- All Firebase services connect to local emulators
- Data is isolated from production
- Authentication uses local auth emulator
- File uploads go to local storage emulator

## Files Created
- `firebase.json` - Emulator configuration
- `firestore.rules` - Firestore security rules
- `firestore.indexes.json` - Database indexes
- `storage.rules` - Storage security rules
- `start-emulators.sh` - Convenience startup script
- `FavoritesTracker/Core/Utils/FirebaseConfig.swift` - iOS emulator configuration

## Usage Tips
1. Always start emulators before running iOS app in development
2. Emulator data is ephemeral - restarting clears all data
3. Use the UI dashboard to inspect data and manage auth users
4. Security rules are enforced in emulators just like production

## Troubleshooting
- If ports are in use, modify ports in `firebase.json`
- Clear emulator data: Stop emulators and restart
- Check console output for connection issues
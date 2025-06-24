# CLAUDE.md - Modular Favorites Tracker Development

## Project Overview
iOS native app for enthusiasts to track favorite items across multiple hobbies and interests using modular templates.

## Current Status
- **Phase**: ✅ 1.0 Project Setup and Core Infrastructure COMPLETE → 2.0 Firebase Data Models and Database Layer
- **Tasks Completed**: 1.1 ✅, 1.2 ✅, 1.3 ✅, 1.4 ✅, 1.5 ✅, 1.6 ✅, 1.7 ✅, 1.8 ✅, 1.9 ✅, 1.10 ✅, 1.11 ✅, 1.12 ✅, 1.13 ✅, 1.14 ✅
- **Last Task**: Phase 1 completed - All infrastructure and foundation work finished
- **Next Task**: 2.1 Write tests for Firestore data models (Item, Tracker, Template, Component)
- **Task Progress**: 14/14 Phase 1 tasks completed (100%) → Phase 2: 0/10 tasks

## Task Management
- **Quick Status**: `/tasks/current-status.md` ⭐ (Check this first!)
- **Master Task List**: `/tasks/tasks-prd-modular-favorites-tracker.md`
- **PRD Document**: `/tasks/prd-modular-favorites-tracker.md`
- **Development Process**: Following `/ai-dev-tasks-main/process-task-list.mdc` guidelines
- **Workflow**: One sub-task at a time, mark completed [x], test and commit after each parent task

## Development Environment
- **IDE**: Xcode Beta (xcode-beta.app) - Required for iOS 26 support
- **Target**: iOS 26.0 minimum deployment
- **Architecture**: Universal app (iPhone + iPad)
- **Framework**: SwiftUI with Clean Architecture principles
- **Backend**: Firebase (Firestore, Auth, Storage, Cloud Functions)
- **Development Approach**: Test-First Development (TDD)

## Key Decisions Made
1. **Backend**: Firebase instead of Core Data + CloudKit
2. **Monetization**: $2.99/month subscription model
3. **Template Marketplace**: 70/30 revenue split (creator/platform)
4. **Data Limits**: 5 photos (free), 10 photos (premium)
5. **Moderation**: Automated with manual override
6. **Component System**: Full library approach from start
7. **Testing**: Comprehensive test coverage (Unit, Integration, UI)

## Project Structure
```
FavoritesTracker/
├── FavoritesTracker.xcodeproj/
├── FavoritesTracker/
│   ├── FavoritesTrackerApp.swift
│   ├── ContentView.swift
│   ├── Presentation/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── Domain/
│   │   ├── Entities/
│   │   ├── UseCases/
│   │   └── Repositories/
│   ├── Data/
│   │   ├── Repositories/
│   │   ├── DataSources/
│   │   │   ├── Remote/
│   │   │   └── Local/
│   │   └── Models/
│   └── Core/
│       ├── DependencyInjection/
│       ├── Extensions/
│       └── Utils/
├── FavoritesTrackerTests/
│   ├── Unit/                  # Component isolation tests
│   ├── Integration/           # Cross-layer interaction tests
│   ├── UI/                   # End-to-end UI tests
│   ├── Mocks/                # Mock implementations
│   ├── Helpers/              # Test utilities and extensions
│   └── TestData/             # Sample data and configuration
├── tasks/
│   ├── prd-modular-favorites-tracker.md
│   └── tasks-prd-modular-favorites-tracker.md
├── TESTING-FRAMEWORK.md       # Comprehensive testing guide
├── DI-ARCHITECTURE.md         # Dependency injection documentation
├── EMULATOR-SETUP.md          # Firebase emulator configuration
└── CLAUDE.md (this file)
```

## Current Build Status
✅ Project builds successfully on iOS 26 simulators
✅ Targets iOS 26.0 (Firebase minimum requirement: iOS 13.0)
✅ Runs on iPhone 16, iPad Pro, and other iOS 26+ devices
✅ SwiftUI interface working correctly
✅ Swift 6.0 with strict concurrency enabled
✅ iOS 26 SDK features configured
✅ Clean Architecture folder structure implemented
✅ Firebase SDK dependencies integrated (Analytics, Auth, Firestore, Storage, Functions)
✅ Real Firebase project configured (favorites-tracker-bc071)
✅ GoogleService-Info.plist integrated with live Firebase credentials
✅ Firebase emulator suite configured for local development
✅ Dependency injection container implemented with Clean Architecture
✅ Comprehensive test framework configured (Unit, Integration, UI tests)
✅ Firebase Test Lab integration configured
✅ App icons, launch screen, and basic metadata configured
✅ SwiftUI preview providers configured for development
✅ Environment configurations (Debug/Testing/Release) implemented
✅ iOS 26 simulator compatibility verified across all device types and configurations

## Phase 1 Tasks (Project Setup and Core Infrastructure)
- [x] 1.1 Open Xcode Beta and create new iOS project with SwiftUI
- [x] 1.2 Set iOS Deployment Target to 26.0 in project settings  
- [x] 1.3 Configure project to use latest iOS 26 SDK features
- [x] 1.4 Set up Clean Architecture folder structure (Presentation, Domain, Data layers)
- [x] 1.5 Add Firebase SDK dependencies (Auth, Firestore, Storage, Functions)
- [x] 1.6 Configure Firebase project and add GoogleService-Info.plist
- [x] 1.7 Set up Firebase emulator suite for local development
- [x] 1.8 Set up dependency injection container for Clean Architecture
- [x] 1.9 Configure comprehensive test framework (Unit, Integration, UI tests)
- [x] 1.10 Set up Firebase Test Lab integration
- [x] 1.11 Configure app icons, launch screen, and basic app metadata
- [x] 1.12 Configure SwiftUI preview providers for development
- [x] 1.13 Set up environment configurations (Debug/Release/Testing)
- [x] 1.14 Verify iOS 26 simulator compatibility and device testing setup

**✅ Phase 1 Complete**: All project setup and core infrastructure tasks finished
**🚀 Phase 2 Ready**: Firebase Data Models and Database Layer (10 tasks)

## Upcoming Phases
- **Phase 2**: Firebase Data Models and Database Layer (10 tasks)
- **Phase 3**: Item Management and Core Features (11 tasks)  
- **Phase 4**: Template System and Component Architecture (12 tasks)
- **Phase 5**: Marketplace, Subscription, and Advanced Features (16 tasks)

## Phase 1 Achievements Summary ✅
- **Project Foundation**: iOS 26 native app with SwiftUI + Clean Architecture
- **Firebase Integration**: Complete SDK integration (Auth, Firestore, Storage, Analytics)
- **Development Environment**: Xcode Beta, Firebase emulator, comprehensive testing
- **Architecture**: Clean separation (Presentation/Domain/Data), dependency injection
- **Quality Assurance**: Unit/Integration/UI tests, environment configurations
- **Compatibility**: Universal app (iPhone/iPad), iOS 26 simulator verified
- **Bundle Alignment**: com.favoritestracker.app matches Firebase configuration

## Important Notes
- Use `xcodebuild` with iPhone 16 simulator for iOS 26 testing
- Firebase emulator required for local development (task 1.7)
- Real Firebase project configured: favorites-tracker-bc071
- Template component system is the core differentiator
- Marketplace integration crucial for monetization
- Targeting iOS 26.0 (Firebase minimum: iOS 13.0, so fully compatible)
- Domain entities already implemented in `/Domain/Entities/DomainEntities.swift`

## Development Workflow
- One sub-task at a time with user approval
- Test-first development approach
- Git commits after completing parent tasks
- Maintain updated task list throughout
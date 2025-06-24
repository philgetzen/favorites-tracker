#!/bin/bash

# Setup script to create fresh FavoritesTracker Xcode project
echo "🚀 Setting up fresh FavoritesTracker Xcode project..."

# Create project directory structure
mkdir -p FavoritesTracker.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
mkdir -p FavoritesTracker.xcodeproj/xcuserdata/philgetzen.xcuserdatad/xcschemes

# Create source directory
mkdir -p FavoritesTracker

# Copy source files from backup
echo "📁 Copying source files from backup..."
cp -r project-backup/Core FavoritesTracker/
cp -r project-backup/Domain FavoritesTracker/
cp -r project-backup/Data FavoritesTracker/
cp -r project-backup/Presentation FavoritesTracker/
cp -r project-backup/Assets.xcassets FavoritesTracker/
cp project-backup/FavoritesTrackerApp.swift FavoritesTracker/
cp project-backup/ContentView.swift FavoritesTracker/
cp project-backup/GoogleService-Info.plist FavoritesTracker/
cp project-backup/Info.plist FavoritesTracker/
cp project-backup/LaunchScreen.storyboard FavoritesTracker/

# Create test directories
mkdir -p FavoritesTrackerTests
cp -r project-backup/FavoritesTrackerTests/* FavoritesTrackerTests/

echo "✅ Project structure created successfully!"
echo "📝 Next: Open Xcode Beta and create new project to generate proper project.pbxproj"
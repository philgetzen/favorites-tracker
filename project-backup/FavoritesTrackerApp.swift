import SwiftUI
// TODO: Firebase import will be enabled once packages are properly linked
// import FirebaseCore

@main
struct FavoritesTrackerApp: App {
    
    init() {
        // TODO: Configure Firebase with emulator support
        // FirebaseConfig.configure()
        
        // TODO: Register app dependencies once DI files are added to project
        // ServiceAssembly.registerDependencies()
        print("✅ FavoritesTracker app starting with dependency injection infrastructure ready")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
import SwiftUI
import FirebaseCore

@main
struct FavoritesTrackerApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure environment-specific settings
        AppConfiguration.shared.configure()
        
        print("✅ FavoritesTracker app starting with \(AppConfiguration.shared.currentEnvironment) configuration")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

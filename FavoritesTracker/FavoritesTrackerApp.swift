import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// App Delegate for Firebase authentication callbacks
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase - must be done in App Delegate for proper initialization
        FirebaseApp.configure()
        
        // Configure environment-specific settings
        AppConfiguration.shared.configure()
        
        // Register all dependencies
        ServiceAssembly.registerDependencies()
        
        print("✅ FavoritesTracker app starting with \(AppConfiguration.shared.currentEnvironment) configuration")
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

@main
struct FavoritesTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Firebase configuration now handled in App Delegate
        // This ensures proper initialization timing for GoogleUtilities
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

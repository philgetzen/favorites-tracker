import Foundation
import Firebase

/// Firebase configuration helper for development and production environments
struct FirebaseConfig {
    
    /// Environment types
    enum Environment {
        case development
        case production
        
        var isEmulator: Bool {
            switch self {
            case .development:
                return true
            case .production:
                return false
            }
        }
    }
    
    /// Current environment (defaults to development)
    static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    /// Configure Firebase with appropriate settings
    static func configure() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure emulators for development
        if currentEnvironment.isEmulator {
            configureEmulators()
        }
    }
    
    /// Configure Firebase emulators for local development
    private static func configureEmulators() {
        // Configure Auth emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        
        // Configure Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        // Configure Storage emulator
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        
        print("🔥 Firebase emulators configured for local development")
        print("   - Auth: localhost:9099")
        print("   - Firestore: localhost:8080")
        print("   - Storage: localhost:9199")
    }
}
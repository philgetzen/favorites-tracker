import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

public final class AppConfiguration: @unchecked Sendable {
    public static let shared = AppConfiguration()
    
    private let environmentConfig = EnvironmentConfiguration.shared
    
    private init() {}
    
    public func configure() {
        setupFirebase()
        setupLogging()
    }
    
    private func setupFirebase() {
        if environmentConfig.useFirebaseEmulator {
            setupFirebaseEmulators()
        }
    }
    
    private func setupFirebaseEmulators() {
        // Configure Auth emulator
        Auth.auth().useEmulator(
            withHost: FirebaseConfiguration.emulatorHost,
            port: FirebaseConfiguration.authEmulatorPort
        )
        
        // Configure Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "\(FirebaseConfiguration.emulatorHost):\(FirebaseConfiguration.firestoreEmulatorPort)"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        // Configure Storage emulator
        Storage.storage().useEmulator(
            withHost: FirebaseConfiguration.emulatorHost,
            port: FirebaseConfiguration.storageEmulatorPort
        )
        
        print("🔥 Firebase emulators configured")
        print("📊 Auth: \(FirebaseConfiguration.emulatorHost):\(FirebaseConfiguration.authEmulatorPort)")
        print("🗄️ Firestore: \(FirebaseConfiguration.emulatorHost):\(FirebaseConfiguration.firestoreEmulatorPort)")
        print("💾 Storage: \(FirebaseConfiguration.emulatorHost):\(FirebaseConfiguration.storageEmulatorPort)")
    }
    
    private func setupLogging() {
        if environmentConfig.enableLogging {
            print("📱 App Configuration: \(environmentConfig.environment)")
            print("🌐 Base URL: \(environmentConfig.baseURL)")
            print("🔒 Use Emulator: \(environmentConfig.useFirebaseEmulator)")
            print("📈 Analytics: \(environmentConfig.analyticsEnabled)")
            print("💥 Crash Reporting: \(environmentConfig.crashReportingEnabled)")
        }
    }
    
    public var currentEnvironment: AppEnvironment {
        environmentConfig.environment
    }
    
    public var isDebugMode: Bool {
        environmentConfig.environment == .debug
    }
    
    public var isTestingMode: Bool {
        environmentConfig.environment == .testing
    }
    
    public var isProductionMode: Bool {
        environmentConfig.environment == .release
    }
}
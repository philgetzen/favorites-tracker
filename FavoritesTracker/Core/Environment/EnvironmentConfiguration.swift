import Foundation

public enum AppEnvironment: Sendable {
    case debug
    case testing  
    case release
    
    public static var current: AppEnvironment {
        #if DEBUG
            return .debug
        #elseif TESTING
            return .testing
        #else
            return .release
        #endif
    }
}

public struct EnvironmentConfiguration: Sendable {
    public let environment: AppEnvironment
    public let baseURL: String
    public let apiKey: String
    public let enableLogging: Bool
    public let useFirebaseEmulator: Bool
    public let analyticsEnabled: Bool
    public let crashReportingEnabled: Bool
    
    public static let shared = EnvironmentConfiguration(environment: AppEnvironment.current)
    
    public init(environment: AppEnvironment) {
        self.environment = environment
        
        switch environment {
        case .debug:
            self.baseURL = "https://api-dev.favoritesapp.com"
            self.apiKey = "dev_api_key"
            self.enableLogging = true
            self.useFirebaseEmulator = false  // Disabled - emulator not running
            self.analyticsEnabled = false
            self.crashReportingEnabled = false
            
        case .testing:
            self.baseURL = "https://api-test.favoritesapp.com"
            self.apiKey = "test_api_key"
            self.enableLogging = true
            self.useFirebaseEmulator = true
            self.analyticsEnabled = false
            self.crashReportingEnabled = false
            
        case .release:
            self.baseURL = "https://api.favoritesapp.com"
            self.apiKey = "prod_api_key"
            self.enableLogging = false
            self.useFirebaseEmulator = false
            self.analyticsEnabled = true
            self.crashReportingEnabled = true
        }
    }
}

public struct FirebaseConfiguration {
    public static var shouldUseEmulator: Bool {
        EnvironmentConfiguration.shared.useFirebaseEmulator
    }
    
    public static var emulatorHost: String {
        "localhost"
    }
    
    public static var firestoreEmulatorPort: Int {
        8080
    }
    
    public static var authEmulatorPort: Int {
        9099
    }
    
    public static var storageEmulatorPort: Int {
        9199
    }
}
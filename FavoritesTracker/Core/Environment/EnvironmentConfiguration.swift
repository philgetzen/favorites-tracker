import Foundation

public enum Environment: Sendable {
    case debug
    case testing  
    case release
    
    public static var current: Environment {
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
    public let environment: Environment
    public let baseURL: String
    public let apiKey: String
    public let enableLogging: Bool
    public let useFirebaseEmulator: Bool
    public let analyticsEnabled: Bool
    public let crashReportingEnabled: Bool
    
    public static let shared = EnvironmentConfiguration(environment: Environment.current)
    
    public init(environment: Environment) {
        self.environment = environment
        
        switch environment {
        case .debug:
            self.baseURL = "https://api-dev.favoritesapp.com"
            self.apiKey = "dev_api_key"
            self.enableLogging = true
            self.useFirebaseEmulator = true
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
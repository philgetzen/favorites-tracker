import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

/// Centralized provider for all repository implementations
/// Handles dependency injection and configuration for Firebase repositories
final class RepositoryProvider: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = RepositoryProvider()
    
    // MARK: - Firebase Services
    
    private let firestore: Firestore
    private let auth: Auth
    private let storage: Storage
    
    // MARK: - Repository Instances (Clean Firebase Implementation)
    
    private lazy var _itemRepository: ItemRepositoryProtocol = FirebaseItemRepository(firestore: firestore)
    private lazy var _collectionRepository: CollectionRepositoryProtocol = FirebaseCollectionRepository(firestore: firestore)
    private lazy var _templateRepository: TemplateRepositoryProtocol = FirebaseTemplateRepository(firestore: firestore)
    private lazy var _userRepository: UserRepositoryProtocol = FirebaseUserRepository(firestore: firestore)
    private lazy var _authRepository: AuthRepositoryProtocol = FirebaseAuthRepository(auth: auth, firestore: firestore)
    private lazy var _storageRepository: StorageRepositoryProtocol = FirebaseStorageRepository(storage: storage)
    
    // MARK: - Initialization
    
    private init() {
        self.firestore = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        configureFirestore()
    }
    
    /// Initialize with custom Firebase services (primarily for testing)
    init(firestore: Firestore, auth: Auth, storage: Storage) {
        self.firestore = firestore
        self.auth = auth
        self.storage = storage
        
        configureFirestore()
    }
    
    // MARK: - Repository Access
    
    var itemRepository: ItemRepositoryProtocol {
        return _itemRepository
    }
    
    var collectionRepository: CollectionRepositoryProtocol {
        return _collectionRepository
    }
    
    var templateRepository: TemplateRepositoryProtocol {
        return _templateRepository
    }
    
    var userRepository: UserRepositoryProtocol {
        return _userRepository
    }
    
    var authRepository: AuthRepositoryProtocol {
        return _authRepository
    }
    
    var storageRepository: StorageRepositoryProtocol {
        return _storageRepository
    }
    
    
    // MARK: - Configuration
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        
        #if DEBUG
        // Enhanced cache for development with offline sync
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 200 * 1024 * 1024 as NSNumber) // 200MB cache
        #else
        // Production settings with optimized cache size
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100MB cache
        #endif
        
        firestore.settings = settings
        
        // Enable network logging in debug mode
        #if DEBUG
        // Note: Firebase logging configuration moved to app initialization
        #endif
    }
    
    // MARK: - Environment-Specific Configurations
    
    /// Configure repositories for testing environment
    func configureForTesting() {
        // Use emulator settings
        let emulatorHost = "localhost"
        let firestorePort = 8080
        let authPort = 9099
        let storagePort = 9199
        
        let settings = firestore.settings
        settings.host = "\(emulatorHost):\(firestorePort)"
        settings.isSSLEnabled = false
        firestore.settings = settings
        
        auth.useEmulator(withHost: emulatorHost, port: authPort)
        storage.useEmulator(withHost: emulatorHost, port: storagePort)
    }
    
    /// Configure repositories for production environment
    func configureForProduction() {
        // Production-specific configurations
        let settings = firestore.settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
        firestore.settings = settings
    }
    
    // MARK: - Utility Methods
    
    /// Clear all cached data
    func clearCache() async throws {
        try await firestore.clearPersistence()
    }
    
    /// Enable offline mode
    func enableOfflineMode() async throws {
        try await firestore.disableNetwork()
    }
    
    /// Enable online mode
    func enableOnlineMode() async throws {
        try await firestore.enableNetwork()
    }
    
    /// Wait for pending writes to complete
    func waitForPendingWrites() async throws {
        try await firestore.waitForPendingWrites()
    }
    
    /// Get current network status
    func isOffline() -> Bool {
        // This is a simplified check - in a real implementation,
        // you'd monitor network connectivity
        return false
    }
}

// MARK: - Repository Factory Protocol

/// Protocol for creating repository instances
/// Useful for dependency injection frameworks
protocol RepositoryFactory {
    func makeItemRepository() -> ItemRepositoryProtocol
    func makeCollectionRepository() -> CollectionRepositoryProtocol
    func makeTemplateRepository() -> TemplateRepositoryProtocol
    func makeUserRepository() -> UserRepositoryProtocol
    func makeAuthRepository() -> AuthRepositoryProtocol
    func makeStorageRepository() -> StorageRepositoryProtocol
}

extension RepositoryProvider: RepositoryFactory {
    func makeItemRepository() -> ItemRepositoryProtocol {
        return itemRepository
    }
    
    func makeCollectionRepository() -> CollectionRepositoryProtocol {
        return collectionRepository
    }
    
    func makeTemplateRepository() -> TemplateRepositoryProtocol {
        return templateRepository
    }
    
    func makeUserRepository() -> UserRepositoryProtocol {
        return userRepository
    }
    
    func makeAuthRepository() -> AuthRepositoryProtocol {
        return authRepository
    }
    
    func makeStorageRepository() -> StorageRepositoryProtocol {
        return storageRepository
    }
}

// MARK: - Repository Configuration

/// Configuration options for repositories
struct RepositoryConfiguration {
    let environment: Environment
    let cacheSize: Int64
    let enablePersistence: Bool
    let enableNetworkLogging: Bool
    
    enum Environment {
        case development
        case testing
        case production
    }
    
    static let development = RepositoryConfiguration(
        environment: .development,
        cacheSize: Int64.max,
        enablePersistence: true,
        enableNetworkLogging: true
    )
    
    static let testing = RepositoryConfiguration(
        environment: .testing,
        cacheSize: 50 * 1024 * 1024, // 50MB
        enablePersistence: false,
        enableNetworkLogging: true
    )
    
    static let production = RepositoryConfiguration(
        environment: .production,
        cacheSize: 100 * 1024 * 1024, // 100MB
        enablePersistence: true,
        enableNetworkLogging: false
    )
}

// MARK: - Repository Metrics

/// Metrics and monitoring for repository operations
@MainActor
final class RepositoryMetrics {
    static let shared = RepositoryMetrics()
    
    private var operationCounts: [String: Int] = [:]
    private var errorCounts: [String: Int] = [:]
    
    private init() {}
    
    func recordOperation(_ operation: String) {
        operationCounts[operation, default: 0] += 1
    }
    
    func recordError(_ error: String) {
        errorCounts[error, default: 0] += 1
    }
    
    func getMetrics() -> (operations: [String: Int], errors: [String: Int]) {
        return (operationCounts, errorCounts)
    }
    
    func reset() {
        operationCounts.removeAll()
        errorCounts.removeAll()
    }
}
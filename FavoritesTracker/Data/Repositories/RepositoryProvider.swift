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
    
    /// Clear all cached data (for debugging purposes)
    func clearCache() async throws {
        try await firestore.clearPersistence()
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


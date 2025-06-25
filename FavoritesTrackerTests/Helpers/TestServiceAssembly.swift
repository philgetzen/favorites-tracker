import Foundation
@testable import FavoritesTracker

/// Test assembly for unit testing with mock dependencies
struct TestServiceAssembly {
    
    static func registerTestDependencies() {
        // Clear existing registrations
        DIContainer.shared.clear()
        
        // Register mock implementations
        registerMockRepositories()
        registerMockUseCases()
        registerMockServices()
    }
    
    private static func registerMockRepositories() {
        // Mock repository implementations
        DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
            MockItemRepository()
        })
        
        DIContainer.shared.register(CollectionRepositoryProtocol.self, factory: {
            MockCollectionRepository()
        })
        
        DIContainer.shared.register(TemplateRepositoryProtocol.self, factory: {
            MockTemplateRepository()
        })
        
        DIContainer.shared.register(UserRepositoryProtocol.self, factory: {
            MockUserRepository()
        })
        
        DIContainer.shared.register(AuthRepositoryProtocol.self, factory: {
            MockAuthRepository()
        })
        
        DIContainer.shared.register(StorageRepositoryProtocol.self, factory: {
            MockStorageRepository()
        })
    }
    
    private static func registerMockUseCases() {
        // Mock use cases will be registered here
        // DIContainer.shared.register(GetItemsUseCase.self, factory: {
        //     MockGetItemsUseCase()
        // })
    }
    
    private static func registerMockServices() {
        // Mock services
        DIContainer.shared.register(UserDefaults.self, instance: UserDefaults(suiteName: "test")!)
        
        // Mock configuration for testing
        UserDefaults.standard.set(true, forKey: "IS_TESTING")
    }
    
    /// Register specific mock repository for testing
    static func registerMockRepository<T>(_ type: T.Type, instance: T) {
        DIContainer.shared.register(type, instance: instance)
    }
    
    /// Register specific mock repository with factory for testing
    static func registerMockRepository<T>(_ type: T.Type, factory: @escaping () -> T) {
        DIContainer.shared.register(type, factory: factory)
    }
}
import Foundation
// TODO: Firebase imports will be enabled once packages are properly linked
// import Firebase
// import FirebaseAuth
// import FirebaseFirestore
// import FirebaseStorage

/// Service Assembly for registering all app dependencies
/// Follows Clean Architecture principles with proper layer separation
struct ServiceAssembly {
    
    /// Register all app dependencies
    static func registerDependencies() {
        registerRepositories()
        registerUseCases()
        registerViewModels()
        registerServices()
    }
    
    // MARK: - Data Layer Dependencies
    
    private static func registerRepositories() {
        // TODO: Firebase services will be registered once packages are properly linked
        // DIContainer.shared.register(Auth.self, instance: Auth.auth())
        // DIContainer.shared.register(Firestore.self, instance: Firestore.firestore())
        // DIContainer.shared.register(Storage.self, instance: Storage.storage())
        
        // Repository implementations will be registered here
        // DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
        //     FirebaseItemRepository()
        // })
    }
    
    // MARK: - Domain Layer Dependencies
    
    private static func registerUseCases() {
        // Use case implementations will be registered here
        // DIContainer.shared.register(GetItemsUseCase.self, factory: {
        //     GetItemsUseCase(repository: DIContainer.shared.resolve(ItemRepositoryProtocol.self))
        // })
    }
    
    // MARK: - Presentation Layer Dependencies
    
    private static func registerViewModels() {
        // ViewModels will be registered here
        // DIContainer.shared.register(ItemListViewModel.self, factory: {
        //     ItemListViewModel(getItemsUseCase: DIContainer.shared.resolve(GetItemsUseCase.self))
        // })
    }
    
    // MARK: - Core Services
    
    private static func registerServices() {
        // Core services
        DIContainer.shared.register(UserDefaults.self, instance: UserDefaults.standard)
        
        // Network and utility services will be registered here
        // DIContainer.shared.register(NetworkManager.self, factory: {
        //     NetworkManager()
        // })
    }
}

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
        // Mock repository implementations will be registered here
        // DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
        //     MockItemRepository()
        // })
    }
    
    private static func registerMockUseCases() {
        // Mock use cases will be registered here
    }
    
    private static func registerMockServices() {
        // Mock services
        DIContainer.shared.register(UserDefaults.self, instance: UserDefaults(suiteName: "test")!)
    }
}
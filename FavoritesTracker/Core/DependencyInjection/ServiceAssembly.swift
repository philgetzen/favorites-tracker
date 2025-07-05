import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Service Assembly for registering all app dependencies
/// Follows Clean Architecture principles with proper layer separation
struct ServiceAssembly {
    
    /// Register all app dependencies
    @MainActor
    static func registerDependencies() {
        registerRepositories()
        registerUseCases()
        registerViewModels()
        registerServices()
    }
    
    // MARK: - Data Layer Dependencies
    
    private static func registerRepositories() {
        // Firebase services
        DIContainer.shared.register(Auth.self, instance: Auth.auth())
        DIContainer.shared.register(Firestore.self, instance: Firestore.firestore())
        DIContainer.shared.register(Storage.self, instance: Storage.storage())
        
        // Repository Provider (centralized access to all repositories)
        DIContainer.shared.register(RepositoryProvider.self, instance: RepositoryProvider.shared)
        
        // Individual repository implementations
        DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.itemRepository
        })
        
        DIContainer.shared.register(CollectionRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.collectionRepository
        })
        
        DIContainer.shared.register(TemplateRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.templateRepository
        })
        
        DIContainer.shared.register(UserRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.userRepository
        })
        
        DIContainer.shared.register(AuthRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.authRepository
        })
        
        DIContainer.shared.register(StorageRepositoryProtocol.self, factory: {
            RepositoryProvider.shared.storageRepository
        })
        
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
    
    @MainActor
    private static func registerServices() {
        // Core services
        DIContainer.shared.register(UserDefaults.self, instance: UserDefaults.standard)
        
        // Network monitoring
        DIContainer.shared.register(NetworkMonitor.self, instance: NetworkMonitor())
        
        // Authentication manager
        DIContainer.shared.register(AuthenticationManager.self, instance: AuthenticationManager.shared)
        
        // Photo management service
        DIContainer.shared.register(PhotoManagementServiceProtocol.self, factory: {
            PhotoManagementService(
                storageRepository: DIContainer.shared.resolve(StorageRepositoryProtocol.self),
                configuration: .default
            )
        })
    }
}


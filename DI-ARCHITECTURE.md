# Dependency Injection Architecture

## Overview
The Favorites Tracker app uses a dependency injection (DI) container to manage dependencies and maintain Clean Architecture principles. This ensures loose coupling, testability, and maintainability.

## Architecture Layers

### Data Layer
- **Repositories**: Concrete implementations of repository protocols
- **DataSources**: Remote (Firebase) and Local data sources
- **Models**: Data transfer objects and Firebase-specific models

### Domain Layer  
- **Entities**: Core business objects
- **Repository Protocols**: Interfaces for data access
- **Use Cases**: Business logic implementations

### Presentation Layer
- **ViewModels**: Presentation logic using MVVM pattern
- **Views**: SwiftUI views and components

## Dependency Injection Components

### 1. DIContainer (`Core/DependencyInjection/DIContainer.swift`)
- Singleton container for service registration and resolution
- Supports both singleton and factory registrations
- Thread-safe service resolution
- Property wrapper `@Inject` for automatic injection

### 2. ServiceAssembly (`Core/DependencyInjection/ServiceAssembly.swift`)
- Registers all production dependencies
- Separates registration by architectural layer
- Configures Firebase services and repositories

### 3. TestServiceAssembly (`Core/DependencyInjection/ServiceAssembly.swift`)
- Registers mock dependencies for testing
- Isolated test environment setup
- Mock implementations for all protocols

### 4. DITesting (`Core/DependencyInjection/DITesting.swift`)
- DEBUG-only testing utilities
- Mock service replacement
- Test environment management

## Usage Examples

### Basic Service Registration
```swift
// Register singleton
DIContainer.shared.register(UserDefaults.self, instance: UserDefaults.standard)

// Register factory
DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
    FirebaseItemRepository()
})
```

### Property Wrapper Injection
```swift
class ItemListViewModel: BaseViewModel {
    @Inject private var itemRepository: ItemRepositoryProtocol
    @Inject private var userDefaults: UserDefaults
    
    func loadItems() async {
        let items = try await itemRepository.getItems(for: currentUserId)
        // Update UI
    }
}
```

### Manual Resolution
```swift
let repository = DIContainer.shared.resolve(ItemRepositoryProtocol.self)
let optionalService = DIContainer.shared.resolveOptional(SomeService.self)
```

### Testing Setup
```swift
#if DEBUG
func setupTest() {
    DITesting.setupTestEnvironment()
    DITesting.mock(ItemRepositoryProtocol.self, with: MockItemRepository())
}
#endif
```

## Service Registration Order

### 1. Core Services
- UserDefaults
- Firebase instances (Auth, Firestore, Storage)

### 2. Data Layer
- Repository implementations
- Data source services

### 3. Domain Layer  
- Use case implementations

### 4. Presentation Layer
- ViewModels (typically factory-registered)

## Benefits

### Clean Architecture
- **Separation of Concerns**: Each layer only depends on abstractions
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Interface Segregation**: Protocols define specific contracts

### Testability
- **Mock Injection**: Easy replacement with test doubles
- **Isolated Testing**: Each component can be tested independently
- **Controlled Environment**: Test assembly provides predictable setup

### Maintainability
- **Loose Coupling**: Components are easily replaceable
- **Single Responsibility**: Each service has a focused purpose
- **Configuration Management**: Central registration point

## Best Practices

### 1. Protocol-First Design
- Define protocols before implementations
- Keep protocols focused and cohesive
- Use protocol composition when needed

### 2. Registration Strategy
- Register services at app startup
- Use factories for stateful services
- Use singletons for stateless services

### 3. Dependency Management
- Avoid circular dependencies
- Prefer constructor injection
- Use property wrapper for convenience

### 4. Testing Strategy
- Always provide mock implementations
- Use TestServiceAssembly for test setup
- Reset container between tests

## Files Structure
```
Core/DependencyInjection/
├── DIContainer.swift           # Main DI container
├── ServiceAssembly.swift       # Production service registration
└── DITesting.swift            # Testing utilities

Domain/
├── Entities/                  # Core business entities
├── Repositories/              # Repository protocols
└── UseCases/                  # Business logic interfaces

Data/
├── Repositories/              # Repository implementations
└── DataSources/              # Firebase and local data sources

Presentation/
├── ViewModels/               # MVVM presentation logic
└── Views/                    # SwiftUI views
```

## Future Enhancements
- Automatic dependency scanning
- Dependency graph visualization
- Performance monitoring
- Lazy initialization optimization
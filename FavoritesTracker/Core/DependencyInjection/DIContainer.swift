import Foundation

/// Dependency Injection Container for Clean Architecture
/// Manages service registration and resolution throughout the app
final class DIContainer: @unchecked Sendable {
    
    /// Shared instance for app-wide dependency injection
    static let shared = DIContainer()
    
    /// Internal service registry
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    /// Register a singleton service
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }
    
    /// Register a factory for creating services
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Resolve a service instance
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check for existing singleton
        if let service = services[key] as? T {
            return service
        }
        
        // Check for factory
        if let factory = factories[key] {
            let instance = factory() as! T
            return instance
        }
        
        fatalError("Service of type \(type) not registered")
    }
    
    /// Resolve optional service
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    /// Clear all registrations (useful for testing)
    func clear() {
        services.removeAll()
        factories.removeAll()
    }
}

/// Property wrapper for automatic dependency injection
@propertyWrapper
struct Inject<T> {
    private let type: T.Type
    
    init(_ type: T.Type) {
        self.type = type
    }
    
    var wrappedValue: T {
        DIContainer.shared.resolve(type)
    }
}
import Foundation
@testable import FavoritesTracker

/// Test-specific dependency injection container
/// Provides clean isolation between tests and easy mock injection
final class TestDIContainer {
    
    /// Shared test container instance
    static let shared = TestDIContainer()
    
    private init() {}
    
    /// Set up test environment with clean DI container
    func setupTestEnvironment() {
        DIContainer.shared.clear()
        registerTestDependencies()
    }
    
    /// Clean up after test
    func tearDown() {
        DIContainer.shared.clear()
    }
    
    /// Register default test dependencies
    private func registerTestDependencies() {
        // Core services
        DIContainer.shared.register(UserDefaults.self, instance: TestUserDefaults())
        
        // Mock repositories will be registered here as we create them
        // DIContainer.shared.register(ItemRepositoryProtocol.self, factory: {
        //     MockItemRepository()
        // })
    }
    
    /// Register a mock for a specific test
    func registerMock<T>(_ type: T.Type, mock: T) {
        DIContainer.shared.register(type, instance: mock)
    }
    
    /// Register a mock factory for a specific test
    func registerMockFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        DIContainer.shared.register(type, factory: factory)
    }
}

/// Test-specific UserDefaults implementation
class TestUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    override func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }
    
    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    override func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }
    
    override func synchronize() -> Bool {
        return true
    }
    
    /// Clear all test data
    func clearAll() {
        storage.removeAll()
    }
}
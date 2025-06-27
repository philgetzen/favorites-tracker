import Foundation

#if DEBUG
/// Testing utilities for dependency injection
/// Only available in DEBUG builds for testing purposes
struct DITesting {
    
    /// Replace a service with a mock for testing
    static func mock<T>(_ type: T.Type, with instance: T) {
        DIContainer.shared.register(type, instance: instance)
    }
    
    /// Replace a service with a factory mock for testing
    static func mockFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        DIContainer.shared.register(type, factory: factory)
    }
    
    /// Reset container to clean state for testing
    @MainActor
    static func reset() {
        DIContainer.shared.clear()
        ServiceAssembly.registerDependencies()
    }
    
    /// Set up test environment with mock dependencies
    /// Note: Test assemblies should be set up in test targets
    static func setupTestEnvironment() {
        DIContainer.shared.clear()
        // Test dependencies should be registered in test target
        // via TestServiceAssembly.registerTestDependencies()
    }
    
    /// Verify that a service is registered
    static func isRegistered<T>(_ type: T.Type) -> Bool {
        return DIContainer.shared.resolveOptional(type) != nil
    }
    
    /// Get list of all registered service types (for debugging)
    static func getRegisteredServices() -> [String] {
        // This would require exposing internal state of DIContainer
        // For now, return empty array - can be enhanced if needed
        return []
    }
}

/// Mock implementations for testing
/// These will be expanded as we add more services

final class MockUserDefaults: UserDefaults {
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
    
    override func synchronize() -> Bool {
        return true
    }
}

/// Sample mock repository for testing
/// This demonstrates how to create mock implementations
// class MockItemRepository: ItemRepositoryProtocol {
//     var mockItems: [Item] = []
//     var shouldThrowError = false
//     var errorToThrow: Error = NSError(domain: "MockError", code: 0)
//     
//     func getItems(for userId: String) async throws -> [Item] {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         return mockItems
//     }
//     
//     func getItem(id: String) async throws -> Item? {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         return mockItems.first { $0.id == id }
//     }
//     
//     func createItem(_ item: Item) async throws -> Item {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         mockItems.append(item)
//         return item
//     }
//     
//     func updateItem(_ item: Item) async throws -> Item {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         if let index = mockItems.firstIndex(where: { $0.id == item.id }) {
//             mockItems[index] = item
//         }
//         return item
//     }
//     
//     func deleteItem(id: String) async throws {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         mockItems.removeAll { $0.id == id }
//     }
//     
//     func searchItems(query: String, userId: String) async throws -> [Item] {
//         if shouldThrowError {
//             throw errorToThrow
//         }
//         return mockItems.filter { $0.name.localizedCaseInsensitiveContains(query) }
//     }
// }

#endif
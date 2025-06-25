import Foundation
import Combine
@testable import FavoritesTracker

// MARK: - Mock Repository Implementations

/// Mock implementation of ItemRepositoryProtocol for testing
class MockItemRepository: ItemRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockItems: [Item] = []
    var getItemsCallCount = 0
    var createItemCallCount = 0
    var updateItemCallCount = 0
    var deleteItemCallCount = 0
    var searchItemsCallCount = 0
    
    // MARK: - Captured Parameters
    var lastUserId: String?
    var lastSearchQuery: String?
    var lastCreatedItem: Item?
    var lastUpdatedItem: Item?
    var lastDeletedItemId: String?
    
    // MARK: - ItemRepositoryProtocol Implementation
    
    func getItems(for userId: String) async throws -> [Item] {
        getItemsCallCount += 1
        lastUserId = userId
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockItems.filter { $0.userId == userId }
    }
    
    func getItem(id: String) async throws -> Item? {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockItems.first { $0.id == id }
    }
    
    func createItem(_ item: Item) async throws -> Item {
        createItemCallCount += 1
        lastCreatedItem = item
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockItems.append(item)
        return item
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        updateItemCallCount += 1
        lastUpdatedItem = item
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = mockItems.firstIndex(where: { $0.id == item.id }) {
            mockItems[index] = item
        }
        
        return item
    }
    
    func deleteItem(id: String) async throws {
        deleteItemCallCount += 1
        lastDeletedItemId = id
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockItems.removeAll { $0.id == id }
    }
    
    func searchItems(query: String, userId: String) async throws -> [Item] {
        searchItemsCallCount += 1
        lastSearchQuery = query
        lastUserId = userId
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockItems.filter { item in
            item.userId == userId && item.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockItems.removeAll()
        shouldThrowError = false
        delay = 0
        
        getItemsCallCount = 0
        createItemCallCount = 0
        updateItemCallCount = 0
        deleteItemCallCount = 0
        searchItemsCallCount = 0
        
        lastUserId = nil
        lastSearchQuery = nil
        lastCreatedItem = nil
        lastUpdatedItem = nil
        lastDeletedItemId = nil
    }
}

/// Mock implementation of CollectionRepositoryProtocol for testing
class MockCollectionRepository: CollectionRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockCollections: [Collection] = []
    var getCollectionsCallCount = 0
    var createCollectionCallCount = 0
    var updateCollectionCallCount = 0
    var deleteCollectionCallCount = 0
    
    // MARK: - Captured Parameters
    var lastUserId: String?
    var lastCreatedCollection: Collection?
    var lastUpdatedCollection: Collection?
    var lastDeletedCollectionId: String?
    
    // MARK: - CollectionRepositoryProtocol Implementation
    
    func getCollections(for userId: String) async throws -> [Collection] {
        getCollectionsCallCount += 1
        lastUserId = userId
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCollections.filter { $0.userId == userId }
    }
    
    func getCollection(id: String) async throws -> Collection? {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCollections.first { $0.id == id }
    }
    
    func createCollection(_ collection: Collection) async throws -> Collection {
        createCollectionCallCount += 1
        lastCreatedCollection = collection
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCollections.append(collection)
        return collection
    }
    
    func updateCollection(_ collection: Collection) async throws -> Collection {
        updateCollectionCallCount += 1
        lastUpdatedCollection = collection
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = mockCollections.firstIndex(where: { $0.id == collection.id }) {
            mockCollections[index] = collection
        }
        
        return collection
    }
    
    func deleteCollection(id: String) async throws {
        deleteCollectionCallCount += 1
        lastDeletedCollectionId = id
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCollections.removeAll { $0.id == id }
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockCollections.removeAll()
        shouldThrowError = false
        delay = 0
        
        getCollectionsCallCount = 0
        createCollectionCallCount = 0
        updateCollectionCallCount = 0
        deleteCollectionCallCount = 0
        
        lastUserId = nil
        lastCreatedCollection = nil
        lastUpdatedCollection = nil
        lastDeletedCollectionId = nil
    }
}

/// Mock implementation of AuthRepositoryProtocol for testing
class MockAuthRepository: AuthRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockCurrentUser: User?
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var deleteAccountCallCount = 0
    
    // MARK: - Captured Parameters
    var lastSignInEmail: String?
    var lastSignInPassword: String?
    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    
    // MARK: - AuthRepositoryProtocol Implementation
    
    func signIn(email: String, password: String) async throws -> User {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let user = User(id: "test-user-id", email: email, displayName: "Test User")
        mockCurrentUser = user
        return user
    }
    
    func signUp(email: String, password: String) async throws -> User {
        signUpCallCount += 1
        lastSignUpEmail = email
        lastSignUpPassword = password
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let user = User(id: "new-user-id", email: email, displayName: "New User")
        mockCurrentUser = user
        return user
    }
    
    func signOut() async throws {
        signOutCallCount += 1
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCurrentUser = nil
    }
    
    func getCurrentUser() -> User? {
        return mockCurrentUser
    }
    
    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCurrentUser = nil
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockCurrentUser = nil
        shouldThrowError = false
        delay = 0
        
        signInCallCount = 0
        signUpCallCount = 0
        signOutCallCount = 0
        deleteAccountCallCount = 0
        
        lastSignInEmail = nil
        lastSignInPassword = nil
        lastSignUpEmail = nil
        lastSignUpPassword = nil
    }
}
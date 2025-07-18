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

/// Mock implementation of TemplateRepositoryProtocol for testing
class MockTemplateRepository: TemplateRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockTemplates: [Template] = []
    var getTemplatesCallCount = 0
    var createTemplateCallCount = 0
    var updateTemplateCallCount = 0
    var deleteTemplateCallCount = 0
    var searchTemplatesCallCount = 0
    var getFeaturedTemplatesCallCount = 0
    
    // MARK: - Captured Parameters
    var lastSearchQuery: String?
    var lastSearchCategory: String?
    var lastCreatedTemplate: Template?
    var lastUpdatedTemplate: Template?
    var lastDeletedTemplateId: String?
    
    // MARK: - TemplateRepositoryProtocol Implementation
    
    func getTemplates() async throws -> [Template] {
        getTemplatesCallCount += 1
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTemplates.filter { $0.isPublic }
    }
    
    func getTemplate(id: String) async throws -> Template? {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTemplates.first { $0.id == id }
    }
    
    func createTemplate(_ template: Template) async throws -> Template {
        createTemplateCallCount += 1
        lastCreatedTemplate = template
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockTemplates.append(template)
        return template
    }
    
    func updateTemplate(_ template: Template) async throws -> Template {
        updateTemplateCallCount += 1
        lastUpdatedTemplate = template
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = mockTemplates.firstIndex(where: { $0.id == template.id }) {
            mockTemplates[index] = template
        }
        
        return template
    }
    
    func deleteTemplate(id: String) async throws {
        deleteTemplateCallCount += 1
        lastDeletedTemplateId = id
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockTemplates.removeAll { $0.id == id }
    }
    
    func searchTemplates(query: String, category: String?) async throws -> [Template] {
        searchTemplatesCallCount += 1
        lastSearchQuery = query
        lastSearchCategory = category
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTemplates.filter { template in
            let matchesQuery = template.name.localizedCaseInsensitiveContains(query)
            let matchesCategory = category == nil || template.category == category
            return template.isPublic && matchesQuery && matchesCategory
        }
    }
    
    func getFeaturedTemplates() async throws -> [Template] {
        getFeaturedTemplatesCallCount += 1
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTemplates.filter { $0.isPublic }.sorted { $0.downloadCount > $1.downloadCount }
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockTemplates.removeAll()
        shouldThrowError = false
        delay = 0
        
        getTemplatesCallCount = 0
        createTemplateCallCount = 0
        updateTemplateCallCount = 0
        deleteTemplateCallCount = 0
        searchTemplatesCallCount = 0
        getFeaturedTemplatesCallCount = 0
        
        lastSearchQuery = nil
        lastSearchCategory = nil
        lastCreatedTemplate = nil
        lastUpdatedTemplate = nil
        lastDeletedTemplateId = nil
    }
}

/// Mock implementation of UserRepositoryProtocol for testing
class MockUserRepository: UserRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockProfiles: [UserProfile] = []
    var getUserProfileCallCount = 0
    var updateUserProfileCallCount = 0
    var deleteUserProfileCallCount = 0
    
    // MARK: - Captured Parameters
    var lastProfileId: String?
    var lastUpdatedProfile: UserProfile?
    var lastDeletedProfileId: String?
    
    // MARK: - UserRepositoryProtocol Implementation
    
    func getUserProfile(id: String) async throws -> UserProfile? {
        getUserProfileCallCount += 1
        lastProfileId = id
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockProfiles.first { $0.id == id }
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        updateUserProfileCallCount += 1
        lastUpdatedProfile = profile
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = mockProfiles.firstIndex(where: { $0.id == profile.id }) {
            mockProfiles[index] = profile
        } else {
            mockProfiles.append(profile)
        }
        
        return profile
    }
    
    func deleteUserProfile(id: String) async throws {
        deleteUserProfileCallCount += 1
        lastDeletedProfileId = id
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockProfiles.removeAll { $0.id == id }
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockProfiles.removeAll()
        shouldThrowError = false
        delay = 0
        
        getUserProfileCallCount = 0
        updateUserProfileCallCount = 0
        deleteUserProfileCallCount = 0
        
        lastProfileId = nil
        lastUpdatedProfile = nil
        lastDeletedProfileId = nil
    }
}

/// Mock implementation of StorageRepositoryProtocol for testing
class MockStorageRepository: StorageRepositoryProtocol {
    
    // MARK: - Test Configuration
    var shouldThrowError = false
    var errorToThrow: Error = TestError.mockNotConfigured
    var delay: TimeInterval = 0
    
    // MARK: - Mock Data
    var mockStorage: [String: Data] = [:]
    var uploadImageCallCount = 0
    var deleteImageCallCount = 0
    var downloadImageCallCount = 0
    
    // MARK: - Captured Parameters
    var lastUploadPath: String?
    var lastUploadData: Data?
    var lastDeletePath: String?
    var lastDownloadURL: URL?
    
    // MARK: - StorageRepositoryProtocol Implementation
    
    func uploadImage(_ data: Data, path: String) async throws -> URL {
        uploadImageCallCount += 1
        lastUploadPath = path
        lastUploadData = data
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockStorage[path] = data
        return URL(string: "https://mock-storage.com/\(path)")!
    }
    
    func deleteImage(at path: String) async throws {
        deleteImageCallCount += 1
        lastDeletePath = path
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockStorage.removeValue(forKey: path)
    }
    
    func downloadImage(from url: URL) async throws -> Data {
        downloadImageCallCount += 1
        lastDownloadURL = url
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Extract path from mock URL
        let path = url.lastPathComponent
        guard let data = mockStorage[path] else {
            throw TestError.mockDataNotFound
        }
        
        return data
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockStorage.removeAll()
        shouldThrowError = false
        delay = 0
        
        uploadImageCallCount = 0
        deleteImageCallCount = 0
        downloadImageCallCount = 0
        
        lastUploadPath = nil
        lastUploadData = nil
        lastDeletePath = nil
        lastDownloadURL = nil
    }
}
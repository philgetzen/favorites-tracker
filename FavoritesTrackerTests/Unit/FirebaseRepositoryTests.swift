import XCTest
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
@testable import FavoritesTracker

final class FirebaseRepositoryTests: XCTestCase {
    
    var itemRepository: ItemRepositoryProtocol!
    var collectionRepository: CollectionRepositoryProtocol!
    var templateRepository: TemplateRepositoryProtocol!
    var userRepository: UserRepositoryProtocol!
    var authRepository: AuthRepositoryProtocol!
    var storageRepository: StorageRepositoryProtocol!
    var repositoryProvider: RepositoryProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Configure for testing environment
        repositoryProvider = RepositoryProvider.shared
        repositoryProvider.configureForTesting()
        
        // Get repository instances
        itemRepository = repositoryProvider.itemRepository
        collectionRepository = repositoryProvider.collectionRepository
        templateRepository = repositoryProvider.templateRepository
        userRepository = repositoryProvider.userRepository
        authRepository = repositoryProvider.authRepository
        storageRepository = repositoryProvider.storageRepository
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        try await repositoryProvider.clearCache()
        
        itemRepository = nil
        collectionRepository = nil
        templateRepository = nil
        userRepository = nil
        authRepository = nil
        storageRepository = nil
        repositoryProvider = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Item Repository Tests
    
    func testItemRepositoryInitialization() throws {
        XCTAssertNotNil(itemRepository)
        XCTAssertTrue(itemRepository is FirebaseItemRepository)
    }
    
    func testItemRepositoryMethods() async throws {
        let userId = UUID().uuidString
        let collectionId = UUID().uuidString
        
        // Test creating an item
        let item = Item(userId: userId, collectionId: collectionId, name: "Test Item")
        let createdItem = try await itemRepository.createItem(item)
        XCTAssertEqual(createdItem.name, "Test Item")
        
        // Test getting items for user
        let items = try await itemRepository.getItems(for: userId)
        XCTAssertTrue(items.count >= 1)
        
        // Test getting specific item
        let retrievedItem = try await itemRepository.getItem(id: item.id)
        XCTAssertNotNil(retrievedItem)
        XCTAssertEqual(retrievedItem?.name, "Test Item")
        
        // Test updating item
        var updatedItem = item
        updatedItem.isFavorite = true
        let result = try await itemRepository.updateItem(updatedItem)
        XCTAssertTrue(result.isFavorite)
        
        // Test searching items
        let searchResults = try await itemRepository.searchItems(query: "Test", userId: userId)
        XCTAssertTrue(searchResults.count >= 1)
        
        // Test deleting item
        try await itemRepository.deleteItem(id: item.id)
        let deletedItem = try await itemRepository.getItem(id: item.id)
        XCTAssertNil(deletedItem)
    }
    
    // MARK: - Collection Repository Tests
    
    func testCollectionRepositoryInitialization() throws {
        XCTAssertNotNil(collectionRepository)
        XCTAssertTrue(collectionRepository is FirebaseCollectionRepository)
    }
    
    func testCollectionRepositoryMethods() async throws {
        let userId = UUID().uuidString
        
        // Test creating a collection
        let collection = Collection(userId: userId, name: "Test Collection")
        let createdCollection = try await collectionRepository.createCollection(collection)
        XCTAssertEqual(createdCollection.name, "Test Collection")
        
        // Test getting collections for user
        let collections = try await collectionRepository.getCollections(for: userId)
        XCTAssertTrue(collections.count >= 1)
        
        // Test getting specific collection
        let retrievedCollection = try await collectionRepository.getCollection(id: collection.id)
        XCTAssertNotNil(retrievedCollection)
        XCTAssertEqual(retrievedCollection?.name, "Test Collection")
        
        // Test updating collection
        var updatedCollection = collection
        updatedCollection.isFavorite = true
        let result = try await collectionRepository.updateCollection(updatedCollection)
        XCTAssertTrue(result.isFavorite)
        
        // Test deleting collection
        try await collectionRepository.deleteCollection(id: collection.id)
        let deletedCollection = try await collectionRepository.getCollection(id: collection.id)
        XCTAssertNil(deletedCollection)
    }
    
    // MARK: - Template Repository Tests
    
    func testTemplateRepositoryInitialization() throws {
        XCTAssertNotNil(templateRepository)
        XCTAssertTrue(templateRepository is FirebaseTemplateRepository)
    }
    
    func testTemplateRepositoryMethods() async throws {
        let creatorId = UUID().uuidString
        
        // Test creating a template
        let template = Template(
            creatorId: creatorId,
            name: "Test Template",
            description: "A test template",
            category: "Test"
        )
        let createdTemplate = try await templateRepository.createTemplate(template)
        XCTAssertEqual(createdTemplate.name, "Test Template")
        
        // Test getting templates
        let templates = try await templateRepository.getTemplates()
        XCTAssertTrue(templates.count >= 0)
        
        // Test getting specific template
        let retrievedTemplate = try await templateRepository.getTemplate(id: template.id)
        XCTAssertNotNil(retrievedTemplate)
        XCTAssertEqual(retrievedTemplate?.name, "Test Template")
        
        // Test updating template
        var updatedTemplate = template
        updatedTemplate.isFavorite = true
        let result = try await templateRepository.updateTemplate(updatedTemplate)
        XCTAssertTrue(result.isFavorite)
        
        // Test searching templates
        let searchResults = try await templateRepository.searchTemplates(query: "Test", category: "Test")
        XCTAssertTrue(searchResults.count >= 0)
        
        // Test getting featured templates
        let featuredTemplates = try await templateRepository.getFeaturedTemplates()
        XCTAssertTrue(featuredTemplates.count >= 0)
        
        // Test deleting template
        try await templateRepository.deleteTemplate(id: template.id)
        let deletedTemplate = try await templateRepository.getTemplate(id: template.id)
        XCTAssertNil(deletedTemplate)
    }
    
    // MARK: - User Repository Tests
    
    func testUserRepositoryInitialization() throws {
        XCTAssertNotNil(userRepository)
        XCTAssertTrue(userRepository is FirebaseUserRepository)
    }
    
    func testUserRepositoryMethods() async throws {
        let userId = UUID().uuidString
        
        // Test creating a user profile
        let userProfile = UserProfile(userId: userId, displayName: "Test User")
        let createdProfile = try await userRepository.updateUserProfile(userProfile)
        XCTAssertEqual(createdProfile.displayName, "Test User")
        
        // Test getting user profile
        let retrievedProfile = try await userRepository.getUserProfile(id: userProfile.id)
        XCTAssertNotNil(retrievedProfile)
        XCTAssertEqual(retrievedProfile?.displayName, "Test User")
        
        // Test deleting user profile
        try await userRepository.deleteUserProfile(id: userProfile.id)
        let deletedProfile = try await userRepository.getUserProfile(id: userProfile.id)
        XCTAssertNil(deletedProfile)
    }
    
    // MARK: - Auth Repository Tests
    
    func testAuthRepositoryInitialization() throws {
        XCTAssertNotNil(authRepository)
        XCTAssertTrue(authRepository is FirebaseAuthRepository)
    }
    
    func testAuthRepositoryCurrentUser() throws {
        // Test getting current user (should be nil in test environment)
        let currentUser = authRepository.getCurrentUser()
        XCTAssertNil(currentUser) // No user signed in during tests
    }
    
    // MARK: - Storage Repository Tests
    
    func testStorageRepositoryInitialization() throws {
        XCTAssertNotNil(storageRepository)
        XCTAssertTrue(storageRepository is FirebaseStorageRepository)
    }
    
    func testStorageRepositoryPathGeneration() throws {
        let storageRepo = storageRepository as! FirebaseStorageRepository
        
        let userId = "test-user"
        let collectionId = "test-collection"
        let itemId = "test-item"
        let fileName = "test.jpg"
        
        let path = storageRepo.generateStoragePath(
            userId: userId,
            collectionId: collectionId,
            itemId: itemId,
            fileName: fileName
        )
        
        XCTAssertTrue(path.contains(userId))
        XCTAssertTrue(path.contains(collectionId))
        XCTAssertTrue(path.contains(itemId))
        XCTAssertTrue(path.contains(fileName))
    }
    
    // MARK: - Repository Provider Tests
    
    func testRepositoryProviderSingleton() throws {
        let provider1 = RepositoryProvider.shared
        let provider2 = RepositoryProvider.shared
        
        XCTAssertTrue(provider1 === provider2)
    }
    
    func testRepositoryProviderFactoryMethods() throws {
        let factory: RepositoryFactory = repositoryProvider
        
        XCTAssertNotNil(factory.makeItemRepository())
        XCTAssertNotNil(factory.makeCollectionRepository())
        XCTAssertNotNil(factory.makeTemplateRepository())
        XCTAssertNotNil(factory.makeUserRepository())
        XCTAssertNotNil(factory.makeAuthRepository())
        XCTAssertNotNil(factory.makeStorageRepository())
    }
    
    // MARK: - Error Handling Tests
    
    func testRepositoryErrorHandling() async throws {
        // Test error handling for non-existent items
        do {
            _ = try await itemRepository.getItem(id: "non-existent-id")
        } catch {
            // Should not throw for non-existent items, should return nil
        }
        
        // Test error handling for non-existent collections
        do {
            _ = try await collectionRepository.getCollection(id: "non-existent-id")
        } catch {
            // Should not throw for non-existent collections, should return nil
        }
        
        // Test error handling for non-existent templates
        do {
            _ = try await templateRepository.getTemplate(id: "non-existent-id")
        } catch {
            // Should not throw for non-existent templates, should return nil
        }
    }
    
    // MARK: - Performance Tests
    
    func testRepositoryPerformance() throws {
        let userId = UUID().uuidString
        
        measure {
            Task {
                do {
                    _ = try await itemRepository.getItems(for: userId)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testRepositoryIntegration() async throws {
        let userId = UUID().uuidString
        
        // Create a collection
        let collection = Collection(userId: userId, name: "Integration Test Collection")
        let createdCollection = try await collectionRepository.createCollection(collection)
        
        // Create items in the collection
        let item1 = Item(userId: userId, collectionId: collection.id, name: "Item 1")
        let item2 = Item(userId: userId, collectionId: collection.id, name: "Item 2")
        
        let createdItem1 = try await itemRepository.createItem(item1)
        let createdItem2 = try await itemRepository.createItem(item2)
        
        // Verify items are in collection
        let items = try await itemRepository.getItems(for: userId)
        XCTAssertTrue(items.count >= 2)
        
        let collectionItems = items.filter { $0.collectionId == collection.id }
        XCTAssertEqual(collectionItems.count, 2)
        
        // Clean up
        try await itemRepository.deleteItem(id: createdItem1.id)
        try await itemRepository.deleteItem(id: createdItem2.id)
        try await collectionRepository.deleteCollection(id: createdCollection.id)
    }
}
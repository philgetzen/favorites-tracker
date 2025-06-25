import XCTest
@testable import FavoritesTracker

/// Integration tests for mock repositories
final class MockRepositoryIntegrationTests: XCTestCase {
    
    private var itemRepository: MockItemRepository!
    private var collectionRepository: MockCollectionRepository!
    private var authRepository: MockAuthRepository!
    
    override func setUp() {
        super.setUp()
        TestDIContainer.shared.setupTestEnvironment()
        
        itemRepository = MockItemRepository()
        collectionRepository = MockCollectionRepository()
        authRepository = MockAuthRepository()
    }
    
    override func tearDown() {
        itemRepository = nil
        collectionRepository = nil
        authRepository = nil
        TestDIContainer.shared.tearDown()
        super.tearDown()
    }
    
    // MARK: - ItemRepository Integration Tests
    
    func testItemRepositoryCreateAndGetFlow() async throws {
        // Given
        let userId = "test-user"
        let collectionId = "test-collection"
        let item = TestObjectFactory.createItem(userId: userId, collectionId: collectionId, name: "Test Item")
        
        // When - Create item
        let createdItem = try await itemRepository.createItem(item)
        
        // Then - Verify creation
        XCTAssertEqual(createdItem.id, item.id)
        XCTAssertEqual(itemRepository.createItemCallCount, 1)
        XCTAssertEqual(itemRepository.lastCreatedItem?.id, item.id)
        
        // When - Get items
        let items = try await itemRepository.getItems(for: userId)
        
        // Then - Verify retrieval
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, item.id)
        XCTAssertEqual(itemRepository.getItemsCallCount, 1)
        XCTAssertEqual(itemRepository.lastUserId, userId)
    }
    
    func testItemRepositoryUpdateFlow() async throws {
        // Given
        let item = TestObjectFactory.createItem(name: "Original Name")
        _ = try await itemRepository.createItem(item)
        
        var updatedItem = item
        // Note: In real implementation, we'd create a proper copy with updated fields
        // For now, we'll test the mock behavior
        
        // When
        let result = try await itemRepository.updateItem(updatedItem)
        
        // Then
        XCTAssertEqual(itemRepository.updateItemCallCount, 1)
        XCTAssertEqual(itemRepository.lastUpdatedItem?.id, item.id)
        XCTAssertEqual(result.id, item.id)
    }
    
    func testItemRepositoryDeleteFlow() async throws {
        // Given
        let item = TestObjectFactory.createItem()
        _ = try await itemRepository.createItem(item)
        
        // When
        try await itemRepository.deleteItem(id: item.id)
        
        // Then
        XCTAssertEqual(itemRepository.deleteItemCallCount, 1)
        XCTAssertEqual(itemRepository.lastDeletedItemId, item.id)
        
        // Verify item is removed
        let retrievedItem = try await itemRepository.getItem(id: item.id)
        XCTAssertNil(retrievedItem)
    }
    
    func testItemRepositorySearchFlow() async throws {
        // Given
        let userId = "test-user"
        let item1 = TestObjectFactory.createItem(userId: userId, name: "Coffee Mug")
        let item2 = TestObjectFactory.createItem(userId: userId, name: "Tea Cup")
        let item3 = TestObjectFactory.createItem(userId: userId, name: "Water Bottle")
        
        _ = try await itemRepository.createItem(item1)
        _ = try await itemRepository.createItem(item2)
        _ = try await itemRepository.createItem(item3)
        
        // When
        let searchResults = try await itemRepository.searchItems(query: "c", userId: userId)
        
        // Then
        XCTAssertEqual(searchResults.count, 2) // Coffee and Cup should match
        XCTAssertEqual(itemRepository.searchItemsCallCount, 1)
        XCTAssertEqual(itemRepository.lastSearchQuery, "c")
        XCTAssertEqual(itemRepository.lastUserId, userId)
        
        let resultNames = searchResults.map { $0.name }.sorted()
        XCTAssertEqual(resultNames, ["Coffee Mug", "Tea Cup"])
    }
    
    // MARK: - CollectionRepository Integration Tests
    
    func testCollectionRepositoryCreateAndGetFlow() async throws {
        // Given
        let userId = "test-user"
        let collection = TestObjectFactory.createCollection(userId: userId, name: "My Books")
        
        // When - Create collection
        let createdCollection = try await collectionRepository.createCollection(collection)
        
        // Then - Verify creation
        XCTAssertEqual(createdCollection.id, collection.id)
        XCTAssertEqual(collectionRepository.createCollectionCallCount, 1)
        XCTAssertEqual(collectionRepository.lastCreatedCollection?.id, collection.id)
        
        // When - Get collections
        let collections = try await collectionRepository.getCollections(for: userId)
        
        // Then - Verify retrieval
        XCTAssertEqual(collections.count, 1)
        XCTAssertEqual(collections.first?.id, collection.id)
        XCTAssertEqual(collectionRepository.getCollectionsCallCount, 1)
        XCTAssertEqual(collectionRepository.lastUserId, userId)
    }
    
    // MARK: - AuthRepository Integration Tests
    
    func testAuthRepositorySignInFlow() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        
        // When
        let user = try await authRepository.signIn(email: email, password: password)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(authRepository.signInCallCount, 1)
        XCTAssertEqual(authRepository.lastSignInEmail, email)
        XCTAssertEqual(authRepository.lastSignInPassword, password)
        XCTAssertNotNil(authRepository.getCurrentUser())
    }
    
    func testAuthRepositorySignOutFlow() async throws {
        // Given - Sign in first
        _ = try await authRepository.signIn(email: "test@example.com", password: "password")
        XCTAssertNotNil(authRepository.getCurrentUser())
        
        // When
        try await authRepository.signOut()
        
        // Then
        XCTAssertEqual(authRepository.signOutCallCount, 1)
        XCTAssertNil(authRepository.getCurrentUser())
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testRepositoryErrorHandling() async {
        // Given
        itemRepository.shouldThrowError = true
        itemRepository.errorToThrow = TestError.mockNotConfigured
        
        // When/Then
        await assertThrowsError(TestError.mockNotConfigured) {
            try await itemRepository.getItems(for: "test-user")
        }
    }
    
    func testRepositoryDelaySimulation() async throws {
        // Given
        let delay: TimeInterval = 0.1
        itemRepository.delay = delay
        let startTime = Date()
        
        // When
        _ = try await itemRepository.getItems(for: "test-user")
        
        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsed, delay)
    }
    
    // MARK: - Multi-Repository Integration Tests
    
    func testCompleteUserWorkflow() async throws {
        // Given
        let email = "user@example.com"
        let password = "password123"
        
        // When - Sign in
        let user = try await authRepository.signIn(email: email, password: password)
        
        // Then - User is authenticated
        XCTAssertEqual(user.email, email)
        XCTAssertNotNil(authRepository.getCurrentUser())
        
        // When - Create collection
        let collection = TestObjectFactory.createCollection(userId: user.id, name: "My Collection")
        let createdCollection = try await collectionRepository.createCollection(collection)
        
        // Then - Collection is created
        XCTAssertEqual(createdCollection.userId, user.id)
        
        // When - Create item in collection
        let item = TestObjectFactory.createItem(userId: user.id, collectionId: createdCollection.id, name: "My Item")
        let createdItem = try await itemRepository.createItem(item)
        
        // Then - Item is created
        XCTAssertEqual(createdItem.userId, user.id)
        XCTAssertEqual(createdItem.collectionId, createdCollection.id)
        
        // When - Get user's items
        let userItems = try await itemRepository.getItems(for: user.id)
        
        // Then - Items are retrieved
        XCTAssertEqual(userItems.count, 1)
        XCTAssertEqual(userItems.first?.id, createdItem.id)
        
        // When - Sign out
        try await authRepository.signOut()
        
        // Then - User is signed out
        XCTAssertNil(authRepository.getCurrentUser())
    }
}
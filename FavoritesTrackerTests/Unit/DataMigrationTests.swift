import XCTest
import FirebaseFirestore
import FirebaseFirestoreSwift
@testable import FavoritesTracker

/// Comprehensive tests for data migration strategies
class DataMigrationTests: XCTestCase {
    
    var firestore: Firestore!
    var migrationManager: DataMigrationManager!
    var testCollectionPrefix: String!
    
    override func setUp() {
        super.setUp()
        
        // Use Firebase emulator for testing
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        
        firestore = Firestore.firestore()
        firestore.settings = settings
        
        migrationManager = DataMigrationManager(firestore: firestore)
        testCollectionPrefix = "test_migration_\(UUID().uuidString.prefix(8))"
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up test data
        Task {
            try await cleanupTestData()
        }
    }
    
    // MARK: - Migration Manager Tests
    
    func testMigrationManagerInitialization() {
        XCTAssertNotNil(migrationManager)
    }
    
    func testNeedsMigrationDetection() async throws {
        // Test when no migrations have been run
        let needsMigration = await migrationManager.needsMigration()
        XCTAssertTrue(needsMigration, "Should need migration when starting fresh")
    }
    
    func testMigrationExecution() async throws {
        // Create test migration
        let testMigration = TestMigration(
            version: .v1_1,
            name: "TestMigration",
            description: "Test migration for unit tests"
        )
        
        // Execute migration
        try await testMigration.execute(firestore: firestore)
        
        // Verify migration was executed
        XCTAssertTrue(testMigration.wasExecuted, "Migration should have been executed")
    }
    
    // MARK: - Specific Migration Tests
    
    func testAddSearchTermsMigration() async throws {
        // Setup: Create test collections without search terms
        let testCollections = createTestCollections(count: 5)
        try await saveTestCollections(testCollections)
        
        // Execute migration
        let migration = AddSearchTermsMigration()
        try await migration.execute(firestore: firestore)
        
        // Verify: Check that search terms were added
        let updatedCollections = try await loadTestCollections()
        
        for collection in updatedCollections {
            XCTAssertFalse(collection.searchTerms.isEmpty, "Search terms should have been added")
            XCTAssertTrue(collection.searchTerms.contains(collection.name.lowercased()), 
                         "Search terms should include collection name")
        }
    }
    
    func testLocationFieldsMigration() async throws {
        // Setup: Create test items without location field
        let testItems = createTestItems(count: 3)
        try await saveTestItems(testItems)
        
        // Execute migration
        let migration = AddLocationFieldsMigration()
        try await migration.execute(firestore: firestore)
        
        // Verify: Check that location field was added (as null)
        let updatedItems = try await loadTestItems()
        
        for item in updatedItems {
            // Location should exist as a field (even if null)
            let docRef = firestore.document("test_items/\(item.id)")
            let document = try await docRef.getDocument()
            XCTAssertTrue(document.data()?.keys.contains("location") ?? false, 
                         "Location field should exist")
        }
    }
    
    func testBatchOperationHandling() async throws {
        // Create large dataset to test batching
        let largeDataset = createTestCollections(count: 1250) // More than one batch
        try await saveTestCollections(largeDataset)
        
        let migration = TestBatchMigration(
            version: .v1_2,
            name: "TestBatchMigration",
            description: "Test batch processing"
        )
        
        try await migration.execute(firestore: firestore)
        
        // Verify all items were processed
        XCTAssertEqual(migration.processedItems, largeDataset.count, 
                      "All items should have been processed in batches")
    }
    
    // MARK: - Migration Utilities Tests
    
    func testDataValidation() async throws {
        // Setup test data with validation issues
        try await createDataWithValidationIssues()
        
        let validationRules: [DataValidationRule] = [
            RequiredFieldsValidation(
                collection: testCollectionName("collections"),
                requiredFields: ["id", "userId", "name"]
            ),
            DataTypeValidation(
                collection: testCollectionName("collections"),
                fieldTypeRules: ["itemCount": Int.self]
            )
        ]
        
        let result = try await MigrationUtilities.validateDataIntegrity(
            firestore: firestore,
            validationRules: validationRules
        )
        
        XCTAssertFalse(result.overallPassed, "Validation should fail with test data issues")
        XCTAssertEqual(result.rules.count, 2, "Should have results for both rules")
    }
    
    func testBackupAndRestore() async throws {
        // Setup: Create test data
        let testData = createTestCollections(count: 3)
        try await saveTestCollections(testData)
        
        let collectionName = testCollectionName("collections")
        
        // Create backup
        try await MigrationUtilities.createBackup(
            firestore: firestore,
            collection: collectionName,
            backupSuffix: "_test_backup"
        )
        
        // Verify backup exists
        let backupSnapshot = try await firestore.collection("\(collectionName)_test_backup").getDocuments()
        XCTAssertEqual(backupSnapshot.documents.count, testData.count, "Backup should contain all documents")
        
        // Clear original collection
        try await MigrationUtilities.clearCollection(firestore: firestore, collection: collectionName)
        
        let clearedSnapshot = try await firestore.collection(collectionName).getDocuments()
        XCTAssertTrue(clearedSnapshot.documents.isEmpty, "Collection should be empty after clearing")
        
        // Restore from backup
        try await MigrationUtilities.restoreFromBackup(
            firestore: firestore,
            collection: collectionName,
            backupSuffix: "_test_backup"
        )
        
        // Verify restore
        let restoredSnapshot = try await firestore.collection(collectionName).getDocuments()
        XCTAssertEqual(restoredSnapshot.documents.count, testData.count, "All documents should be restored")
    }
    
    func testProgressTracking() async throws {
        let items = Array(1...100)
        var progressUpdates: [Int] = []
        
        try await MigrationUtilities.trackProgress(
            items: items,
            batchSize: 10
        ) { batch in
            // Simulate processing
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        } progressCallback: { completed, total in
            progressUpdates.append(completed)
        }
        
        XCTAssertEqual(progressUpdates.count, 10, "Should have 10 progress updates for 10 batches")
        XCTAssertEqual(progressUpdates.last, 10, "Final progress should be 10 (total batches)")
    }
    
    // MARK: - Migration Coordinator Tests
    
    @MainActor
    func testMigrationCoordinator() async throws {
        let coordinator = MigrationCoordinator(migrationManager: migrationManager)
        
        // Test initial state
        XCTAssertEqual(coordinator.migrationState, .idle)
        
        // Run migrations
        await coordinator.checkAndRunMigrations()
        
        // Should complete successfully
        XCTAssertEqual(coordinator.migrationState, .completed)
    }
    
    @MainActor
    func testMigrationCoordinatorErrorHandling() async throws {
        // Create a migration manager that will fail
        let failingMigration = FailingTestMigration()
        let mockRegistry = MockMigrationRegistry(migrations: [failingMigration])
        let mockManager = MockMigrationManager(registry: mockRegistry)
        
        let coordinator = MigrationCoordinator(migrationManager: mockManager)
        
        await coordinator.runMigrations()
        
        XCTAssertEqual(coordinator.migrationState, .failed)
        XCTAssertNotNil(coordinator.lastError)
    }
    
    // MARK: - Schema Version Tests
    
    func testSchemaVersionComparison() {
        XCTAssertTrue(SchemaVersion.v1_0 < SchemaVersion.v1_1)
        XCTAssertTrue(SchemaVersion.v1_1 < SchemaVersion.v2_0)
        XCTAssertFalse(SchemaVersion.v1_1 < SchemaVersion.v1_0)
    }
    
    func testSchemaVersionCurrent() {
        XCTAssertEqual(SchemaVersion.current, .v2_0)
    }
    
    // MARK: - Error Handling Tests
    
    func testMigrationErrorHandling() async throws {
        let failingMigration = FailingTestMigration()
        
        do {
            try await failingMigration.execute(firestore: firestore)
            XCTFail("Should have thrown an error")
        } catch let error as MigrationError {
            switch error {
            case .executionFailed(let name, _):
                XCTAssertEqual(name, "FailingTestMigration")
            default:
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func testCollectionName(_ base: String) -> String {
        return "\(testCollectionPrefix!)_\(base)"
    }
    
    private func createTestCollections(count: Int) -> [CollectionDTO] {
        return (1...count).map { index in
            CollectionDTO(
                id: "collection_\(index)",
                userId: "test_user",
                name: "Test Collection \(index)",
                description: "Test description",
                templateId: nil,
                itemCount: 0,
                coverImageURL: nil,
                isFavorite: false,
                tags: ["test", "collection"],
                isPublic: false,
                createdAt: Timestamp(),
                updatedAt: Timestamp(),
                searchTerms: [] // Initially empty for testing
            )
        }
    }
    
    private func createTestItems(count: Int) -> [ItemDTO] {
        return (1...count).map { index in
            ItemDTO(
                id: "item_\(index)",
                userId: "test_user",
                collectionId: "test_collection",
                name: "Test Item \(index)",
                description: "Test description",
                imageURLs: [],
                customFields: [:],
                isFavorite: false,
                tags: ["test"],
                location: nil, // Initially nil for testing
                rating: nil,
                createdAt: Timestamp(),
                updatedAt: Timestamp(),
                searchTerms: []
            )
        }
    }
    
    private func saveTestCollections(_ collections: [CollectionDTO]) async throws {
        let collectionRef = firestore.collection(testCollectionName("collections"))
        
        for collection in collections {
            try await collectionRef.document(collection.id).setData(from: collection)
        }
    }
    
    private func saveTestItems(_ items: [ItemDTO]) async throws {
        let itemsRef = firestore.collection("test_items")
        
        for item in items {
            try await itemsRef.document(item.id).setData(from: item)
        }
    }
    
    private func loadTestCollections() async throws -> [CollectionDTO] {
        let snapshot = try await firestore.collection(testCollectionName("collections")).getDocuments()
        return try snapshot.documents.map { try $0.data(as: CollectionDTO.self) }
    }
    
    private func loadTestItems() async throws -> [ItemDTO] {
        let snapshot = try await firestore.collection("test_items").getDocuments()
        return try snapshot.documents.map { try $0.data(as: ItemDTO.self) }
    }
    
    private func createDataWithValidationIssues() async throws {
        let collectionRef = firestore.collection(testCollectionName("collections"))
        
        // Create document missing required fields
        try await collectionRef.document("invalid_1").setData([
            "userId": "test_user",
            "name": "Test Collection"
            // Missing 'id' field
        ])
        
        // Create document with wrong data type
        try await collectionRef.document("invalid_2").setData([
            "id": "invalid_2",
            "userId": "test_user",
            "name": "Test Collection",
            "itemCount": "not_a_number" // Should be Int
        ])
    }
    
    private func cleanupTestData() async throws {
        // Clean up all test collections
        let collections = [
            testCollectionName("collections"),
            testCollectionName("collections_test_backup"),
            "test_items",
            "test_items_test_backup"
        ]
        
        for collection in collections {
            try await MigrationUtilities.clearCollection(firestore: firestore, collection: collection)
        }
    }
}

// MARK: - Test Migration Classes

class TestMigration: BaseMigration {
    var wasExecuted = false
    
    override func execute(firestore: Firestore) async throws {
        wasExecuted = true
        // Simulate migration work
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
}

class TestBatchMigration: BaseMigration {
    var processedItems = 0
    
    override func execute(firestore: Firestore) async throws {
        // Get test collections
        let snapshot = try await firestore.collection("test_migration_collections").getDocuments()
        let collections = try snapshot.documents.map { try $0.data(as: CollectionDTO.self) }
        
        try await batchOperation(items: collections, firestore: firestore) { batch, writeBatch in
            processedItems += batch.count
            
            // Simulate batch processing
            for collection in batch {
                let docRef = firestore.document("test_collections/\(collection.id)")
                writeBatch.updateData(["processed": true], forDocument: docRef)
            }
        }
    }
}

class FailingTestMigration: BaseMigration {
    init() {
        super.init(
            version: .v1_1,
            name: "FailingTestMigration",
            description: "Migration that always fails for testing"
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        throw MigrationError.executionFailed(
            name,
            NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Intentional test failure"])
        )
    }
}

// MARK: - Mock Classes for Testing

class MockMigrationRegistry {
    let migrations: [Migration]
    
    init(migrations: [Migration]) {
        self.migrations = migrations
    }
}

class MockMigrationManager: DataMigrationManager {
    private let registry: MockMigrationRegistry
    
    init(registry: MockMigrationRegistry) {
        self.registry = registry
        super.init()
    }
    
    override func runMigrations() async throws {
        for migration in registry.migrations {
            try await migration.execute(firestore: Firestore.firestore())
        }
    }
}
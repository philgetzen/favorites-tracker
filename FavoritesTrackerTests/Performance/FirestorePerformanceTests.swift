import XCTest
import FirebaseFirestore
@testable import FavoritesTracker

/// Performance tests for Firestore optimizations
class FirestorePerformanceTests: XCTestCase {
    
    var firestore: Firestore!
    var performanceManager: FirestorePerformanceManager!
    var testDataGenerator: TestDataGenerator!
    var performanceMonitor: FirestorePerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        
        // Configure Firebase emulator for testing
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        
        firestore = Firestore.firestore()
        firestore.settings = settings
        
        performanceManager = FirestorePerformanceManager(firestore: firestore)
        testDataGenerator = TestDataGenerator(firestore: firestore)
        performanceMonitor = FirestorePerformanceMonitor()
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up test data
        Task {
            try await testDataGenerator.cleanupAllTestData()
        }
    }
    
    // MARK: - Batch Operation Performance Tests
    
    func testBatchWritePerformance() async throws {
        // Test batch writing large number of items
        let itemCount = 1000
        let items = testDataGenerator.generateTestItems(count: itemCount)
        
        let startTime = Date()
        
        let operations = items.map { item in
            let dto = ItemDTO.fromDomain(item)
            return BatchWriteOperation<ItemDTO>.create(
                firestore.collection("test_items").document(item.id),
                dto
            )
        }
        
        try await performanceManager.batching.batchWrite(operations: operations)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify performance expectations
        XCTAssertLessThan(duration, 10.0, "Batch write of \(itemCount) items should complete in under 10 seconds")
        
        let throughput = Double(itemCount) / duration
        XCTAssertGreaterThan(throughput, 100.0, "Should achieve at least 100 items/second throughput")
        
        print("Batch write performance: \(itemCount) items in \(duration)s (\(throughput) items/sec)")
    }
    
    func testBatchReadPerformance() async throws {
        // Setup: Create test data
        let itemCount = 500
        let items = testDataGenerator.generateTestItems(count: itemCount)
        try await testDataGenerator.saveTestItems(items)
        
        let references = items.map { item in
            firestore.collection("test_items").document(item.id)
        }
        
        let startTime = Date()
        
        let results = try await performanceManager.batching.batchRead(
            references: references,
            type: ItemDTO.self
        )
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify results and performance
        XCTAssertEqual(results.count, itemCount, "Should read all items")
        XCTAssertLessThan(duration, 5.0, "Batch read should complete in under 5 seconds")
        
        let throughput = Double(itemCount) / duration
        print("Batch read performance: \(itemCount) items in \(duration)s (\(throughput) items/sec)")
    }
    
    func testAtomicTransactionPerformance() async throws {
        // Test atomic transaction with retry logic
        let collectionRef = firestore.collection("test_collections")
        let itemRef = firestore.collection("test_items")
        
        let startTime = Date()
        
        let result = try await performanceManager.batching.atomicTransaction { transaction in
            // Create collection
            let collection = testDataGenerator.generateTestCollections(count: 1)[0]
            let collectionDTO = CollectionDTO.fromDomain(collection)
            let collectionData = try Firestore.Encoder().encode(collectionDTO)
            transaction.setData(collectionData, forDocument: collectionRef.document(collection.id))
            
            // Create items in the collection
            let items = testDataGenerator.generateTestItems(count: 5, collectionId: collection.id)
            for item in items {
                let itemDTO = ItemDTO.fromDomain(item)
                let itemData = try Firestore.Encoder().encode(itemDTO)
                transaction.setData(itemData, forDocument: itemRef.document(item.id))
            }
            
            return items.count
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(result, 5, "Should create 5 items in transaction")
        XCTAssertLessThan(duration, 2.0, "Transaction should complete quickly")
        
        print("Atomic transaction performance: \(duration)s")
    }
    
    // MARK: - Query Optimization Performance Tests
    
    func testOptimizedCollectionQueryPerformance() async throws {
        // Setup: Create large dataset
        let collectionCount = 100
        let collections = testDataGenerator.generateTestCollections(count: collectionCount)
        try await testDataGenerator.saveTestCollections(collections)
        
        let userId = collections[0].userId
        
        // Test various query scenarios
        await measureQueryPerformance("Basic collection query") {
            let query = performanceManager.queries.optimizedCollectionQuery(userId: userId)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Filtered favorite collections") {
            let filters = CollectionFilters(isFavorite: true)
            let query = performanceManager.queries.optimizedCollectionQuery(userId: userId, filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Search collections") {
            let filters = CollectionFilters(searchTerm: "test")
            let query = performanceManager.queries.optimizedCollectionQuery(userId: userId, filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Paginated collections") {
            let pagination = PaginationOptions(limit: 20)
            let query = performanceManager.queries.optimizedCollectionQuery(userId: userId, pagination: pagination)
            _ = try await query.getDocuments()
        }
    }
    
    func testOptimizedItemQueryPerformance() async throws {
        // Setup: Create large dataset with items across multiple collections
        let collectionCount = 10
        let itemsPerCollection = 50
        
        let collections = testDataGenerator.generateTestCollections(count: collectionCount)
        try await testDataGenerator.saveTestCollections(collections)
        
        var allItems: [Item] = []
        for collection in collections {
            let items = testDataGenerator.generateTestItems(count: itemsPerCollection, collectionId: collection.id)
            allItems.append(contentsOf: items)
        }
        try await testDataGenerator.saveTestItems(allItems)
        
        let userId = collections[0].userId
        
        // Test cross-collection queries
        await measureQueryPerformance("Cross-collection item query") {
            let filters = ItemFilters(crossCollection: true)
            let query = performanceManager.queries.optimizedItemsQuery(userId: userId, filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Favorite items across collections") {
            let filters = ItemFilters(crossCollection: true, isFavorite: true)
            let query = performanceManager.queries.optimizedItemsQuery(userId: userId, filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("High-rated items") {
            let filters = ItemFilters(crossCollection: true, minRating: 4.0)
            let query = performanceManager.queries.optimizedItemsQuery(userId: userId, filters: filters)
            _ = try await query.getDocuments()
        }
    }
    
    func testOptimizedTemplateQueryPerformance() async throws {
        // Setup: Create template marketplace data
        let templateCount = 200
        let templates = testDataGenerator.generateTestTemplates(count: templateCount)
        try await testDataGenerator.saveTestTemplates(templates)
        
        await measureQueryPerformance("Public templates") {
            let query = performanceManager.queries.optimizedTemplateQuery()
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Templates by category") {
            let filters = TemplateFilters(category: "Books")
            let query = performanceManager.queries.optimizedTemplateQuery(filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Popular templates") {
            let filters = TemplateFilters(sortBy: .popularity)
            let query = performanceManager.queries.optimizedTemplateQuery(filters: filters)
            _ = try await query.getDocuments()
        }
        
        await measureQueryPerformance("Template search") {
            let filters = TemplateFilters(searchTerm: "book")
            let query = performanceManager.queries.optimizedTemplateQuery(filters: filters)
            _ = try await query.getDocuments()
        }
    }
    
    // MARK: - Cache Performance Tests
    
    func testQueryCachePerformance() async throws {
        // Setup test data
        let collections = testDataGenerator.generateTestCollections(count: 50)
        try await testDataGenerator.saveTestCollections(collections)
        
        let userId = collections[0].userId
        let query = performanceManager.queries.optimizedCollectionQuery(userId: userId)
        
        // First query (no cache)
        let firstQueryStart = Date()
        _ = try await performanceManager.queries.executeWithCache(
            query: query,
            type: CollectionDTO.self,
            cacheKey: "test_cache_key"
        )
        let firstQueryDuration = Date().timeIntervalSince(firstQueryStart)
        
        // Second query (with cache)
        let secondQueryStart = Date()
        _ = try await performanceManager.queries.executeWithCache(
            query: query,
            type: CollectionDTO.self,
            cacheKey: "test_cache_key"
        )
        let secondQueryDuration = Date().timeIntervalSince(secondQueryStart)
        
        // Cache should significantly improve performance
        XCTAssertLessThan(secondQueryDuration, firstQueryDuration * 0.5, "Cached query should be significantly faster")
        
        print("Cache performance: First query \(firstQueryDuration)s, Cached query \(secondQueryDuration)s")
    }
    
    func testOfflinePersistencePerformance() async throws {
        // Enable offline persistence
        performanceManager.cache.enableOfflinePersistence()
        
        // Setup test data and ensure it's cached
        let collections = testDataGenerator.generateTestCollections(count: 30)
        try await testDataGenerator.saveTestCollections(collections)
        
        let userId = collections[0].userId
        
        // Read data to populate cache
        let query = performanceManager.queries.optimizedCollectionQuery(userId: userId)
        _ = try await query.getDocuments(source: .server)
        
        // Test reading from cache
        let cacheQueryStart = Date()
        let cachedResults = try await query.getDocuments(source: .cache)
        let cacheQueryDuration = Date().timeIntervalSince(cacheQueryStart)
        
        XCTAssertFalse(cachedResults.isEmpty, "Should have cached results")
        XCTAssertLessThan(cacheQueryDuration, 0.1, "Cache queries should be very fast")
        
        print("Offline cache performance: \(cacheQueryDuration)s for \(cachedResults.count) documents")
    }
    
    // MARK: - Repository Performance Tests
    
    func testOptimizedRepositoryPerformance() async throws {
        let repository = OptimizedCollectionRepository(performanceManager: performanceManager)
        
        // Test bulk operations
        let collections = testDataGenerator.generateTestCollections(count: 100)
        
        let createStart = Date()
        for collection in collections {
            _ = try await repository.createCollection(collection)
        }
        let createDuration = Date().timeIntervalSince(createStart)
        
        let readStart = Date()
        let retrievedCollections = try await repository.getCollections(for: collections[0].userId)
        let readDuration = Date().timeIntervalSince(readStart)
        
        XCTAssertGreaterThanOrEqual(retrievedCollections.count, collections.count)
        XCTAssertLessThan(createDuration, 15.0, "Creating 100 collections should be reasonably fast")
        XCTAssertLessThan(readDuration, 2.0, "Reading collections should be fast")
        
        print("Repository performance: Create \(createDuration)s, Read \(readDuration)s")
    }
    
    // MARK: - Memory and Resource Tests
    
    func testMemoryUsageDuringBulkOperations() async throws {
        // Monitor memory usage during large batch operations
        let initialMemory = getMemoryUsage()
        
        let largeItemCount = 2000
        let items = testDataGenerator.generateTestItems(count: largeItemCount)
        
        let operations = items.map { item in
            let dto = ItemDTO.fromDomain(item)
            return BatchWriteOperation<ItemDTO>.create(
                firestore.collection("test_items").document(item.id),
                dto
            )
        }
        
        try await performanceManager.batching.batchWrite(operations: operations)
        
        let peakMemory = getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Memory increase should be reasonable
        XCTAssertLessThan(memoryIncrease, 100_000_000, "Memory usage should not increase excessively") // 100MB limit
        
        print("Memory usage: Initial \(initialMemory), Peak \(peakMemory), Increase \(memoryIncrease)")
    }
    
    // MARK: - Index Performance Validation
    
    func testIndexPerformanceValidation() async throws {
        let indexManager = FirestoreIndexManager(firestore: firestore)
        
        // Generate large dataset to test index effectiveness
        let collections = testDataGenerator.generateTestCollections(count: 200)
        try await testDataGenerator.saveTestCollections(collections)
        
        let userId = collections[0].userId
        
        // Test queries that should benefit from indexes
        let indexedQueries = [
            ("userId filter", firestore.collection("test_collections").whereField("userId", isEqualTo: userId)),
            ("favorite filter", firestore.collection("test_collections").whereField("isFavorite", isEqualTo: true)),
            ("date sort", firestore.collection("test_collections").order(by: "createdAt", descending: true)),
            ("compound filter", firestore.collection("test_collections")
                .whereField("userId", isEqualTo: userId)
                .whereField("isFavorite", isEqualTo: true)
                .order(by: "updatedAt", descending: true))
        ]
        
        for (name, query) in indexedQueries {
            await measureQueryPerformance("Index test: \(name)") {
                _ = try await query.getDocuments()
            }
        }
        
        // Validate index recommendations
        let validationResult = await indexManager.validateIndexes()
        print("Index validation: \(validationResult.allIndexesPresent ? "All indexes present" : "Missing indexes: \(validationResult.missingIndexes.count)")")
    }
    
    // MARK: - Helper Methods
    
    private func measureQueryPerformance(_ name: String, operation: () async throws -> Void) async {
        let startTime = Date()
        
        do {
            try await operation()
            let duration = Date().timeIntervalSince(startTime)
            performanceMonitor.recordQuery(
                operation: name,
                duration: duration,
                documentCount: 0, // Would be populated in real implementation
                fromCache: false
            )
            
            print("Query performance [\(name)]: \(duration)s")
            
            // Performance assertions
            XCTAssertLessThan(duration, 5.0, "\(name) should complete in under 5 seconds")
            
            if duration > 1.0 {
                print("⚠️ Slow query detected: \(name) took \(duration)s")
            }
        } catch {
            XCTFail("Query failed [\(name)]: \(error)")
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - Test Data Generator

class TestDataGenerator {
    private let firestore: Firestore
    private let testUserId = "test_user_performance"
    
    init(firestore: Firestore) {
        self.firestore = firestore
    }
    
    func generateTestCollections(count: Int) -> [Collection] {
        return (1...count).map { index in
            Collection(
                id: "perf_collection_\(index)",
                userId: testUserId,
                name: "Performance Test Collection \(index)",
                description: "Collection for performance testing with index \(index)",
                templateId: index % 5 == 0 ? "template_\(index % 3)" : nil,
                itemCount: Int.random(in: 0...50),
                coverImageURL: nil,
                isFavorite: index % 4 == 0,
                tags: generateRandomTags(),
                isPublic: index % 3 == 0,
                createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                updatedAt: Date().addingTimeInterval(-Double(index * 1800))
            )
        }
    }
    
    func generateTestItems(count: Int, collectionId: String? = nil) -> [Item] {
        let defaultCollectionId = collectionId ?? "default_collection"
        
        return (1...count).map { index in
            Item(
                id: "perf_item_\(index)",
                userId: testUserId,
                collectionId: defaultCollectionId,
                name: "Performance Test Item \(index)",
                description: "Item for performance testing with detailed description \(index)",
                imageURLs: [],
                customFields: generateRandomCustomFields(),
                isFavorite: index % 5 == 0,
                tags: generateRandomTags(),
                location: index % 10 == 0 ? generateRandomLocation() : nil,
                rating: index % 3 == 0 ? Double.random(in: 1...5) : nil,
                createdAt: Date().addingTimeInterval(-Double(index * 1800)),
                updatedAt: Date().addingTimeInterval(-Double(index * 900))
            )
        }
    }
    
    func generateTestTemplates(count: Int) -> [Template] {
        let categories = ["Books", "Movies", "Games", "Music", "Food", "Travel"]
        
        return (1...count).map { index in
            Template(
                id: "perf_template_\(index)",
                creatorId: "creator_\(index % 10)",
                name: "Performance Template \(index)",
                description: "Template for performance testing with comprehensive details \(index)",
                category: categories[index % categories.count],
                components: generateRandomComponents(),
                previewImageURL: nil,
                isFavorite: index % 6 == 0,
                tags: generateRandomTags(),
                isPublic: true,
                isPremium: index % 4 == 0,
                downloadCount: Int.random(in: 0...10000),
                rating: Double.random(in: 1...5),
                createdAt: Date().addingTimeInterval(-Double(index * 7200)),
                updatedAt: Date().addingTimeInterval(-Double(index * 3600))
            )
        }
    }
    
    func saveTestCollections(_ collections: [Collection]) async throws {
        let operations = collections.map { collection in
            let dto = CollectionDTO.fromDomain(collection)
            return BatchWriteOperation<CollectionDTO>.create(
                firestore.collection("test_collections").document(collection.id),
                dto
            )
        }
        
        // Use simple batch writes for test setup
        let batches = operations.chunked(into: 500)
        for batch in batches {
            let writeBatch = firestore.batch()
            for operation in batch {
                switch operation {
                case .create(let ref, let data):
                    let encodedData = try Firestore.Encoder().encode(data)
                    writeBatch.setData(encodedData, forDocument: ref)
                default:
                    break
                }
            }
            try await writeBatch.commit()
        }
    }
    
    func saveTestItems(_ items: [Item]) async throws {
        let operations = items.map { item in
            let dto = ItemDTO.fromDomain(item)
            return BatchWriteOperation<ItemDTO>.create(
                firestore.collection("test_items").document(item.id),
                dto
            )
        }
        
        let batches = operations.chunked(into: 500)
        for batch in batches {
            let writeBatch = firestore.batch()
            for operation in batch {
                switch operation {
                case .create(let ref, let data):
                    let encodedData = try Firestore.Encoder().encode(data)
                    writeBatch.setData(encodedData, forDocument: ref)
                default:
                    break
                }
            }
            try await writeBatch.commit()
        }
    }
    
    func saveTestTemplates(_ templates: [Template]) async throws {
        let operations = templates.map { template in
            let dto = TemplateDTO.fromDomain(template)
            return BatchWriteOperation<TemplateDTO>.create(
                firestore.collection("test_templates").document(template.id),
                dto
            )
        }
        
        let batches = operations.chunked(into: 500)
        for batch in batches {
            let writeBatch = firestore.batch()
            for operation in batch {
                switch operation {
                case .create(let ref, let data):
                    let encodedData = try Firestore.Encoder().encode(data)
                    writeBatch.setData(encodedData, forDocument: ref)
                default:
                    break
                }
            }
            try await writeBatch.commit()
        }
    }
    
    func cleanupAllTestData() async throws {
        let collections = ["test_collections", "test_items", "test_templates"]
        
        for collection in collections {
            let snapshot = try await firestore.collection(collection).getDocuments()
            let batches = snapshot.documents.chunked(into: 500)
            
            for batch in batches {
                let writeBatch = firestore.batch()
                for document in batch {
                    writeBatch.deleteDocument(document.reference)
                }
                try await writeBatch.commit()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateRandomTags() -> [String] {
        let allTags = ["test", "performance", "sample", "demo", "benchmark", "data"]
        let count = Int.random(in: 1...3)
        return Array(allTags.shuffled().prefix(count))
    }
    
    private func generateRandomCustomFields() -> [String: CustomFieldValue] {
        let fields = [
            "notes": CustomFieldValue.text("Performance test notes"),
            "priority": CustomFieldValue.number(Double.random(in: 1...5)),
            "completed": CustomFieldValue.boolean(Bool.random())
        ]
        
        let selectedCount = Int.random(in: 0...fields.count)
        return Dictionary(fields.shuffled().prefix(selectedCount), uniquingKeysWith: { first, _ in first })
    }
    
    private func generateRandomLocation() -> Location {
        return Location(
            latitude: Double.random(in: -90...90),
            longitude: Double.random(in: -180...180),
            address: "Test Address \(Int.random(in: 1...1000))",
            name: "Test Location"
        )
    }
    
    private func generateRandomComponents() -> [ComponentDefinition] {
        let types: [ComponentDefinition.ComponentType] = [.textField, .textArea, .numberField, .rating, .toggle]
        let count = Int.random(in: 1...5)
        
        return (1...count).map { index in
            ComponentDefinition(
                id: "component_\(index)",
                type: types.randomElement()!,
                label: "Component \(index)",
                isRequired: Bool.random(),
                defaultValue: nil,
                options: nil,
                validation: nil
            )
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
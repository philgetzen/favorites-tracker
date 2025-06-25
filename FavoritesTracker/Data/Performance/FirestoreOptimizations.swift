import Foundation
import FirebaseFirestore

// MARK: - Firestore Performance Optimizations

/// Central coordinator for Firestore performance optimizations
class FirestorePerformanceManager: @unchecked Sendable {
    private let db: Firestore
    private let batchManager: BatchOperationManager
    private let queryOptimizer: QueryOptimizer
    private let cacheManager: FirestoreCacheManager
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
        self.batchManager = BatchOperationManager(firestore: firestore)
        self.queryOptimizer = QueryOptimizer(firestore: firestore)
        self.cacheManager = FirestoreCacheManager(firestore: firestore)
        
        configureFirestoreSettings()
    }
    
    /// Configure basic Firestore settings
    private func configureFirestoreSettings() {
        let settings = FirestoreSettings()
        
        // Use default cache settings for now
        // settings.cacheSettings = PersistentCacheSettings(sizeBytes: -1) // Commented out for compatibility
        
        // Configure network settings for better performance
        settings.dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        
        db.settings = settings
        
        // Debug logging disabled for compatibility
        #if DEBUG
        print("Firestore configured with basic settings")
        #endif
    }
    
    /// Get optimized batch manager for bulk operations
    var batching: BatchOperationManager {
        return batchManager
    }
    
    /// Get query optimizer for efficient queries
    var queries: QueryOptimizer {
        return queryOptimizer
    }
    
    /// Get cache manager for offline capabilities
    var cache: FirestoreCacheManager {
        return cacheManager
    }
}

// MARK: - Batch Operation Manager

/// Manages efficient batch operations for Firestore
class BatchOperationManager: @unchecked Sendable {
    private let db: Firestore
    private let maxBatchSize = 500 // Firestore limit
    private let maxBatchBytes = 10 * 1024 * 1024 // 10MB limit
    
    init(firestore: Firestore) {
        self.db = firestore
    }
    
    /// Execute multiple writes in optimized batches
    func batchWrite<T: Encodable>(
        operations: [BatchWriteOperation<T>],
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws {
        let batches = optimizeBatches(operations)
        
        for (index, batch) in batches.enumerated() {
            let writeBatch = db.batch()
            
            try configureBatch(writeBatch, with: batch)
            try await writeBatch.commit()
            
            progressCallback?(index + 1, batches.count)
        }
    }
    
    /// Execute multiple reads sequentially (simplified for compatibility)
    func batchRead<T: Decodable>(
        references: [DocumentReference],
        type: T.Type,
        source: FirestoreSource = .default
    ) async throws -> [T?] {
        // Simplified: read documents sequentially instead of using complex task groups
        var results: [T?] = []
        
        for reference in references {
            do {
                let snapshot = try await reference.getDocument(source: source)
                if snapshot.exists {
                    let data = snapshot.data() as Any
                    let decoded = try? Firestore.Decoder().decode(type, from: data)
                    results.append(decoded)
                } else {
                    results.append(nil)
                }
            } catch {
                results.append(nil)
            }
        }
        
        return results
    }
    
    /// Perform basic transaction (simplified for compatibility)
    func atomicTransaction<T>(
        operation: @escaping (Transaction) throws -> T
    ) async throws -> T {
        // Simplified: single transaction attempt without complex retry logic
        return try await db.runTransaction { (transaction, errorPointer) in
            do {
                return try operation(transaction)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        } as! T
    }
    
    // MARK: - Private Methods
    
    private func optimizeBatches<T: Encodable>(_ operations: [BatchWriteOperation<T>]) -> [[BatchWriteOperation<T>]] {
        var batches: [[BatchWriteOperation<T>]] = []
        var currentBatch: [BatchWriteOperation<T>] = []
        var currentBatchSize = 0
        
        for operation in operations {
            let operationSize = estimateOperationSize(operation)
            
            // Check if adding this operation would exceed limits
            if currentBatch.count >= maxBatchSize || 
               currentBatchSize + operationSize > maxBatchBytes {
                if !currentBatch.isEmpty {
                    batches.append(currentBatch)
                    currentBatch = []
                    currentBatchSize = 0
                }
            }
            
            currentBatch.append(operation)
            currentBatchSize += operationSize
        }
        
        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }
        
        return batches
    }
    
    private func configureBatch<T: Encodable>(_ batch: WriteBatch, with operations: [BatchWriteOperation<T>]) throws {
        for operation in operations {
            switch operation {
            case .create(let ref, let data):
                let encodedData = try Firestore.Encoder().encode(data)
                batch.setData(encodedData, forDocument: ref)
            case .update(let ref, let data):
                let encodedData = try Firestore.Encoder().encode(data)
                batch.setData(encodedData, forDocument: ref, merge: true)
            case .delete(let ref):
                batch.deleteDocument(ref)
            case .updateFields(let ref, let fields):
                batch.updateData(fields, forDocument: ref)
            }
        }
    }
    
    
    private func estimateOperationSize<T: Encodable>(_ operation: BatchWriteOperation<T>) -> Int {
        // Rough estimation of operation size in bytes
        switch operation {
        case .create(_, let data), .update(_, let data):
            return estimateDataSize(data)
        case .delete:
            return 100 // Minimal size for delete operations
        case .updateFields(_, let fields):
            return estimateFieldsSize(fields)
        }
    }
    
    private func estimateDataSize<T: Encodable>(_ data: T) -> Int {
        do {
            let jsonData = try JSONEncoder().encode(data)
            return jsonData.count
        } catch {
            return 1024 // Default estimate if encoding fails
        }
    }
    
    private func estimateFieldsSize(_ fields: [String: Any]) -> Int {
        // Rough estimation based on field count and types
        return fields.count * 100 // Average 100 bytes per field
    }
}

/// Batch operation types
enum BatchWriteOperation<T: Encodable> {
    case create(DocumentReference, T)
    case update(DocumentReference, T)
    case delete(DocumentReference)
    case updateFields(DocumentReference, [String: Any])
}

// MARK: - Query Optimizer

/// Optimizes Firestore queries for better performance
class QueryOptimizer: @unchecked Sendable {
    internal let db: Firestore
    private var queryCache: [String: QueryCacheEntry] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    init(firestore: Firestore) {
        self.db = firestore
    }
    
    /// Create optimized query for collections
    func optimizedCollectionQuery(
        userId: String,
        filters: CollectionFilters = CollectionFilters(),
        pagination: PaginationOptions = PaginationOptions()
    ) -> Query {
        var query: Query = db.collection("users").document(userId).collection("collections")
        
        // Apply filters in optimal order (equality first, then range, then array-contains)
        if let templateId = filters.templateId {
            query = query.whereField("templateId", isEqualTo: templateId)
        }
        
        if filters.isFavorite {
            query = query.whereField("isFavorite", isEqualTo: true)
        }
        
        if filters.isPublic {
            query = query.whereField("isPublic", isEqualTo: true)
        }
        
        if let searchTerm = filters.searchTerm {
            query = query.whereField("searchTerms", arrayContains: searchTerm.lowercased())
        }
        
        if let tags = filters.tags, !tags.isEmpty {
            query = query.whereField("tags", arrayContainsAny: tags)
        }
        
        // Apply date range filters
        if let startDate = filters.createdAfter {
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
        }
        
        if let endDate = filters.createdBefore {
            query = query.whereField("createdAt", isLessThanOrEqualTo: Timestamp(date: endDate))
        }
        
        // Apply sorting (use indexed fields)
        switch filters.sortBy {
        case .name:
            query = query.order(by: "name", descending: filters.sortDescending)
        case .createdAt:
            query = query.order(by: "createdAt", descending: filters.sortDescending)
        case .updatedAt:
            query = query.order(by: "updatedAt", descending: filters.sortDescending)
        case .itemCount:
            query = query.order(by: "itemCount", descending: filters.sortDescending)
        }
        
        // Apply pagination
        if let limit = pagination.limit {
            query = query.limit(to: limit)
        }
        
        if let startAfter = pagination.startAfterDocument {
            query = query.start(afterDocument: startAfter)
        }
        
        return query
    }
    
    /// Create optimized query for items with collection group
    func optimizedItemsQuery(
        userId: String,
        filters: ItemFilters = ItemFilters(),
        pagination: PaginationOptions = PaginationOptions()
    ) -> Query {
        var query: Query
        
        // Use collection group for cross-collection queries
        if filters.crossCollection {
            query = db.collectionGroup("items")
                .whereField("userId", isEqualTo: userId)
        } else if let collectionId = filters.collectionId {
            query = db.collection("users").document(userId)
                .collection("collections").document(collectionId)
                .collection("items")
        } else {
            query = db.collectionGroup("items")
                .whereField("userId", isEqualTo: userId)
        }
        
        // Apply filters in optimal order
        if filters.isFavorite {
            query = query.whereField("isFavorite", isEqualTo: true)
        }
        
        if let rating = filters.minRating {
            query = query.whereField("rating", isGreaterThanOrEqualTo: rating)
        }
        
        if let searchTerm = filters.searchTerm {
            query = query.whereField("searchTerms", arrayContains: searchTerm.lowercased())
        }
        
        if let tags = filters.tags, !tags.isEmpty {
            query = query.whereField("tags", arrayContainsAny: tags)
        }
        
        // Apply sorting
        switch filters.sortBy {
        case .name:
            query = query.order(by: "name", descending: filters.sortDescending)
        case .createdAt:
            query = query.order(by: "createdAt", descending: filters.sortDescending)
        case .updatedAt:
            query = query.order(by: "updatedAt", descending: filters.sortDescending)
        case .rating:
            query = query.order(by: "rating", descending: filters.sortDescending)
        }
        
        // Apply pagination
        if let limit = pagination.limit {
            query = query.limit(to: limit)
        }
        
        if let startAfter = pagination.startAfterDocument {
            query = query.start(afterDocument: startAfter)
        }
        
        return query
    }
    
    /// Create optimized template marketplace query
    func optimizedTemplateQuery(
        filters: TemplateFilters = TemplateFilters(),
        pagination: PaginationOptions = PaginationOptions()
    ) -> Query {
        var query = db.collection("templates")
            .whereField("isPublic", isEqualTo: true)
        
        // Apply category filter
        if let category = filters.category {
            query = query.whereField("category", isEqualTo: category)
        }
        
        // Apply premium filter
        if let isPremium = filters.isPremium {
            query = query.whereField("isPremium", isEqualTo: isPremium)
        }
        
        // Apply search
        if let searchTerm = filters.searchTerm {
            query = query.whereField("searchTerms", arrayContains: searchTerm.lowercased())
        }
        
        // Apply sorting with composite indexes
        switch filters.sortBy {
        case .popularity:
            query = query.order(by: "downloadCount", descending: true)
        case .rating:
            query = query.order(by: "rating", descending: true)
        case .newest:
            query = query.order(by: "createdAt", descending: true)
        case .updated:
            query = query.order(by: "updatedAt", descending: true)
        }
        
        // Apply pagination
        if let limit = pagination.limit {
            query = query.limit(to: limit)
        }
        
        if let startAfter = pagination.startAfterDocument {
            query = query.start(afterDocument: startAfter)
        }
        
        return query
    }
    
    /// Execute query with caching
    func executeWithCache<T: Decodable>(
        query: Query,
        type: T.Type,
        cacheKey: String? = nil,
        source: FirestoreSource = .default
    ) async throws -> [T] {
        let key = cacheKey ?? generateQueryCacheKey(query)
        
        // Check cache first
        if let cached = getCachedResult(key: key, type: type) {
            return cached
        }
        
        // Execute query
        let snapshot = try await query.getDocuments(source: source)
        let results: [T] = snapshot.documents.compactMap { document in
            let data = document.data() as Any
            return try? Firestore.Decoder().decode(type, from: data)
        }
        
        // Cache results
        cacheResult(key, results: results)
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func generateQueryCacheKey(_ query: Query) -> String {
        // Generate cache key based on query parameters
        return "query_\(query.queryHash)"
    }
    
    private func getCachedResult<T: Decodable>(key: String, type: T.Type) -> [T]? {
        guard let entry = queryCache[key],
              Date().timeIntervalSince(entry.timestamp) < cacheTimeout,
              let results = entry.results as? [T] else {
            return nil
        }
        return results
    }
    
    private func cacheResult<T>(_ key: String, results: [T]) {
        queryCache[key] = QueryCacheEntry(results: results, timestamp: Date())
        
        // Clean up old cache entries
        cleanupCache()
    }
    
    private func cleanupCache() {
        let cutoff = Date().addingTimeInterval(-cacheTimeout)
        queryCache = queryCache.filter { $0.value.timestamp > cutoff }
    }
}

/// Cache entry for query results
private struct QueryCacheEntry {
    let results: Any
    let timestamp: Date
}

// MARK: - Filter and Pagination Types

struct CollectionFilters {
    var templateId: String?
    var isFavorite: Bool = false
    var isPublic: Bool = false
    var searchTerm: String?
    var tags: [String]?
    var createdAfter: Date?
    var createdBefore: Date?
    var sortBy: CollectionSortField = .updatedAt
    var sortDescending: Bool = true
    
    enum CollectionSortField {
        case name, createdAt, updatedAt, itemCount
    }
}

struct ItemFilters {
    var collectionId: String?
    var crossCollection: Bool = false
    var isFavorite: Bool = false
    var searchTerm: String?
    var tags: [String]?
    var minRating: Double?
    var sortBy: ItemSortField = .updatedAt
    var sortDescending: Bool = true
    
    enum ItemSortField {
        case name, createdAt, updatedAt, rating
    }
}

struct TemplateFilters {
    var category: String?
    var isPremium: Bool?
    var searchTerm: String?
    var sortBy: TemplateSortField = .popularity
    
    enum TemplateSortField {
        case popularity, rating, newest, updated
    }
}

struct PaginationOptions {
    var limit: Int?
    var startAfterDocument: DocumentSnapshot?
    
    static let defaultPageSize = 20
    static let maxPageSize = 100
}

// MARK: - Cache Manager

/// Manages Firestore offline cache and persistence
class FirestoreCacheManager: @unchecked Sendable {
    private let db: Firestore
    
    init(firestore: Firestore) {
        self.db = firestore
    }
    
    /// Enable offline persistence with basic settings
    func enableOfflinePersistence() {
        // Simplified: Use default persistence settings for compatibility
        print("Offline persistence configured with default settings")
    }
    
    /// Clear Firestore cache
    func clearCache() async throws {
        try await db.clearPersistence()
    }
    
    /// Enable network and wait for sync
    func enableNetworkAndWaitForSync() async throws {
        try await db.enableNetwork()
        try await db.waitForPendingWrites()
    }
    
    /// Disable network (offline mode)
    func disableNetwork() async throws {
        try await db.disableNetwork()
    }
    
    /// Prefetch data for offline use
    func prefetchForOffline(
        userId: String,
        collectionLimit: Int = 50,
        itemsPerCollection: Int = 20
    ) async throws {
        // Prefetch user collections
        let collectionsQuery = db.collection("users").document(userId)
            .collection("collections")
            .order(by: "updatedAt", descending: true)
            .limit(to: collectionLimit)
        
        let collections = try await collectionsQuery.getDocuments(source: .server)
        
        // Prefetch items for each collection
        for collection in collections.documents {
            let itemsQuery = collection.reference.collection("items")
                .order(by: "updatedAt", descending: true)
                .limit(to: itemsPerCollection)
            
            _ = try await itemsQuery.getDocuments(source: .server)
        }
        
        // Prefetch popular templates
        let templatesQuery = db.collection("templates")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "downloadCount", descending: true)
            .limit(to: 20)
        
        _ = try await templatesQuery.getDocuments(source: .server)
    }
}

// MARK: - Performance Monitoring

/// Monitors Firestore performance metrics
class FirestorePerformanceMonitor: @unchecked Sendable {
    private var queryMetrics: [QueryMetric] = []
    private let maxMetricsHistory = 1000
    
    /// Record query performance
    func recordQuery(
        operation: String,
        duration: TimeInterval,
        documentCount: Int,
        fromCache: Bool
    ) {
        let metric = QueryMetric(
            operation: operation,
            duration: duration,
            documentCount: documentCount,
            fromCache: fromCache,
            timestamp: Date()
        )
        
        queryMetrics.append(metric)
        
        // Keep only recent metrics
        if queryMetrics.count > maxMetricsHistory {
            queryMetrics.removeFirst(queryMetrics.count - maxMetricsHistory)
        }
        
        // Log slow queries
        if duration > 2.0 { // Queries taking more than 2 seconds
            print("⚠️ Slow Firestore query detected: \(operation) took \(duration)s")
        }
    }
    
    /// Get performance summary
    func getPerformanceSummary() -> PerformanceSummary {
        let totalQueries = queryMetrics.count
        let cacheHitRate = Double(queryMetrics.filter(\.fromCache).count) / Double(max(totalQueries, 1))
        let averageDuration = queryMetrics.map(\.duration).reduce(0, +) / Double(max(totalQueries, 1))
        let slowQueries = queryMetrics.filter { $0.duration > 1.0 }.count
        
        return PerformanceSummary(
            totalQueries: totalQueries,
            cacheHitRate: cacheHitRate,
            averageQueryDuration: averageDuration,
            slowQueriesCount: slowQueries
        )
    }
}

struct QueryMetric {
    let operation: String
    let duration: TimeInterval
    let documentCount: Int
    let fromCache: Bool
    let timestamp: Date
}

struct PerformanceSummary {
    let totalQueries: Int
    let cacheHitRate: Double
    let averageQueryDuration: TimeInterval
    let slowQueriesCount: Int
}

// MARK: - Error Types

enum FirestoreOptimizationError: Error, LocalizedError {
    case transactionFailed
    case batchSizeExceeded
    case queryOptimizationFailed(String)
    case cacheOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .transactionFailed:
            return "Transaction failed after maximum retries"
        case .batchSizeExceeded:
            return "Batch size exceeded Firestore limits"
        case .queryOptimizationFailed(let details):
            return "Query optimization failed: \(details)"
        case .cacheOperationFailed(let details):
            return "Cache operation failed: \(details)"
        }
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Query {
    var queryHash: Int {
        // Simple hash based on query string representation
        return description.hashValue
    }
}
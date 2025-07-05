import Foundation

/// Service for validating data consistency between local and remote storage
/// Ensures data integrity and handles recovery from inconsistent states
@MainActor
final class DataConsistencyService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isValidating = false
    @Published var lastValidationResult: DataConsistencyResult?
    @Published var inconsistenciesFound: [DataInconsistency] = []
    
    // MARK: - Dependencies
    
    private let itemRepository: ItemRepositoryProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    private let syncConflictService: SyncConflictService
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        syncConflictService: SyncConflictService
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.syncConflictService = syncConflictService
    }
    
    // MARK: - Validation Methods
    
    /// Performs a comprehensive data consistency check
    /// - Parameter userId: The user ID to validate data for
    /// - Returns: Result of the consistency validation
    func validateDataConsistency(for userId: String) async throws -> DataConsistencyResult {
        isValidating = true
        inconsistenciesFound.removeAll()
        
        do {
            let result = try await performValidation(for: userId)
            lastValidationResult = result
            isValidating = false
            return result
            
        } catch {
            isValidating = false
            throw error
        }
    }
    
    /// Validates collection item counts against actual item counts
    /// - Parameter userId: The user ID to validate collections for
    /// - Returns: Array of collection count inconsistencies
    func validateCollectionCounts(for userId: String) async throws -> [CollectionCountInconsistency] {
        let collections = try await collectionRepository.getCollections(for: userId)
        var inconsistencies: [CollectionCountInconsistency] = []
        
        for collection in collections {
            let actualItemCount = try await itemRepository.getItemCount(for: collection.id)
            
            if collection.itemCount != actualItemCount {
                let inconsistency = CollectionCountInconsistency(
                    collectionId: collection.id,
                    collectionName: collection.name,
                    storedCount: collection.itemCount,
                    actualCount: actualItemCount,
                    difference: actualItemCount - collection.itemCount
                )
                inconsistencies.append(inconsistency)
            }
        }
        
        return inconsistencies
    }
    
    /// Validates that all items belong to existing collections
    /// - Parameter userId: The user ID to validate items for
    /// - Returns: Array of orphaned item inconsistencies
    func validateOrphanedItems(for userId: String) async throws -> [OrphanedItemInconsistency] {
        let items = try await itemRepository.getItems(for: userId)
        let collections = try await collectionRepository.getCollections(for: userId)
        let collectionIds = Set(collections.map { $0.id })
        
        var inconsistencies: [OrphanedItemInconsistency] = []
        
        for item in items {
            if !collectionIds.contains(item.collectionId) {
                let inconsistency = OrphanedItemInconsistency(
                    itemId: item.id,
                    itemName: item.name,
                    orphanedCollectionId: item.collectionId
                )
                inconsistencies.append(inconsistency)
            }
        }
        
        return inconsistencies
    }
    
    /// Validates data relationships and referential integrity
    /// - Parameter userId: The user ID to validate relationships for
    /// - Returns: Array of relationship inconsistencies
    func validateDataRelationships(for userId: String) async throws -> [RelationshipInconsistency] {
        var inconsistencies: [RelationshipInconsistency] = []
        
        // Check for items with invalid user IDs
        let items = try await itemRepository.getItems(for: userId)
        let invalidUserItems = items.filter { $0.userId != userId }
        
        for item in invalidUserItems {
            let inconsistency = RelationshipInconsistency(
                type: .invalidUserReference,
                entityId: item.id,
                entityType: "Item",
                description: "Item has incorrect user ID: \(item.userId) instead of \(userId)"
            )
            inconsistencies.append(inconsistency)
        }
        
        // Check for collections with invalid user IDs
        let collections = try await collectionRepository.getCollections(for: userId)
        let invalidUserCollections = collections.filter { $0.userId != userId }
        
        for collection in invalidUserCollections {
            let inconsistency = RelationshipInconsistency(
                type: .invalidUserReference,
                entityId: collection.id,
                entityType: "Collection",
                description: "Collection has incorrect user ID: \(collection.userId) instead of \(userId)"
            )
            inconsistencies.append(inconsistency)
        }
        
        return inconsistencies
    }
    
    // MARK: - Recovery Methods
    
    /// Attempts to fix collection count inconsistencies
    /// - Parameter inconsistencies: Array of collection count inconsistencies to fix
    func fixCollectionCountInconsistencies(_ inconsistencies: [CollectionCountInconsistency]) async throws {
        for inconsistency in inconsistencies {
            guard let collection = try await collectionRepository.getCollection(id: inconsistency.collectionId) else {
                continue
            }
            
            let updatedCollection = Collection(
                id: collection.id,
                userId: collection.userId,
                name: collection.name,
                description: collection.description,
                templateId: collection.templateId,
                itemCount: inconsistency.actualCount,
                coverImageURL: collection.coverImageURL,
                isFavorite: collection.isFavorite,
                tags: collection.tags,
                isPublic: collection.isPublic,
                createdAt: collection.createdAt,
                updatedAt: Date()
            )
            
            _ = try await collectionRepository.updateCollection(updatedCollection)
        }
    }
    
    /// Moves orphaned items to a default collection or prompts for manual resolution
    /// - Parameters:
    ///   - inconsistencies: Array of orphaned item inconsistencies
    ///   - defaultCollectionId: Optional default collection to move items to
    func fixOrphanedItems(
        _ inconsistencies: [OrphanedItemInconsistency],
        defaultCollectionId: String? = nil
    ) async throws {
        
        for inconsistency in inconsistencies {
            guard let item = try await itemRepository.getItem(id: inconsistency.itemId) else {
                continue
            }
            
            var targetCollectionId = defaultCollectionId
            
            // If no default collection specified, try to find or create one
            if targetCollectionId == nil {
                // Try to find an "Uncategorized" collection
                let userCollections = try await collectionRepository.getCollections(for: item.userId)
                let uncategorizedCollection = userCollections.first { 
                    $0.name.lowercased().contains("uncategorized") || 
                    $0.name.lowercased().contains("misc") ||
                    $0.name.lowercased().contains("other")
                }
                
                if let uncategorized = uncategorizedCollection {
                    targetCollectionId = uncategorized.id
                } else {
                    // Create a new "Uncategorized" collection
                    let newCollection = Collection(
                        id: UUID().uuidString,
                        userId: item.userId,
                        name: "Uncategorized",
                        description: "Items that need to be organized",
                        templateId: nil,
                        itemCount: 0,
                        coverImageURL: nil,
                        isFavorite: false,
                        tags: [],
                        isPublic: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    let createdCollection = try await collectionRepository.createCollection(newCollection)
                    targetCollectionId = createdCollection.id
                }
            }
            
            guard let finalCollectionId = targetCollectionId else {
                throw DataConsistencyError.noTargetCollectionForOrphanedItem(inconsistency.itemId)
            }
            
            // Move the item to the target collection
            let updatedItem = Item(
                id: item.id,
                userId: item.userId,
                collectionId: finalCollectionId,
                name: item.name,
                description: item.description,
                imageURLs: item.imageURLs,
                customFields: item.customFields,
                isFavorite: item.isFavorite,
                tags: item.tags,
                location: item.location,
                rating: item.rating,
                createdAt: item.createdAt,
                updatedAt: Date()
            )
            
            _ = try await itemRepository.updateItem(updatedItem)
        }
    }
    
    /// Attempts to fix all detected inconsistencies automatically
    /// - Parameter result: The consistency validation result containing inconsistencies
    func autoFixInconsistencies(_ result: DataConsistencyResult) async throws -> DataConsistencyFixResult {
        var fixedCount = 0
        var failedCount = 0
        var errors: [Error] = []
        
        // Fix collection count inconsistencies
        if !result.collectionCountInconsistencies.isEmpty {
            do {
                try await fixCollectionCountInconsistencies(result.collectionCountInconsistencies)
                fixedCount += result.collectionCountInconsistencies.count
            } catch {
                failedCount += result.collectionCountInconsistencies.count
                errors.append(error)
            }
        }
        
        // Fix orphaned items
        if !result.orphanedItemInconsistencies.isEmpty {
            do {
                try await fixOrphanedItems(result.orphanedItemInconsistencies)
                fixedCount += result.orphanedItemInconsistencies.count
            } catch {
                failedCount += result.orphanedItemInconsistencies.count
                errors.append(error)
            }
        }
        
        // Relationship inconsistencies typically require manual intervention
        if !result.relationshipInconsistencies.isEmpty {
            failedCount += result.relationshipInconsistencies.count
        }
        
        return DataConsistencyFixResult(
            totalInconsistencies: result.totalInconsistencies,
            fixedCount: fixedCount,
            failedCount: failedCount,
            errors: errors,
            fixedAt: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func performValidation(for userId: String) async throws -> DataConsistencyResult {
        let startTime = Date()
        
        // Perform all validations concurrently
        async let collectionCountInconsistencies = validateCollectionCounts(for: userId)
        async let orphanedItemInconsistencies = validateOrphanedItems(for: userId)
        async let relationshipInconsistencies = validateDataRelationships(for: userId)
        
        let collectionCounts = try await collectionCountInconsistencies
        let orphanedItems = try await orphanedItemInconsistencies
        let relationships = try await relationshipInconsistencies
        
        // Combine all inconsistencies
        var allInconsistencies: [DataInconsistency] = []
        allInconsistencies.append(contentsOf: collectionCounts.map { .collectionCount($0) })
        allInconsistencies.append(contentsOf: orphanedItems.map { .orphanedItem($0) })
        allInconsistencies.append(contentsOf: relationships.map { .relationship($0) })
        
        inconsistenciesFound = allInconsistencies
        
        let result = DataConsistencyResult(
            userId: userId,
            validatedAt: Date(),
            validationDuration: Date().timeIntervalSince(startTime),
            collectionCountInconsistencies: collectionCounts,
            orphanedItemInconsistencies: orphanedItems,
            relationshipInconsistencies: relationships,
            isConsistent: allInconsistencies.isEmpty
        )
        
        return result
    }
}

// MARK: - Supporting Types

/// Result of a data consistency validation
struct DataConsistencyResult {
    let userId: String
    let validatedAt: Date
    let validationDuration: TimeInterval
    let collectionCountInconsistencies: [CollectionCountInconsistency]
    let orphanedItemInconsistencies: [OrphanedItemInconsistency]
    let relationshipInconsistencies: [RelationshipInconsistency]
    let isConsistent: Bool
    
    var totalInconsistencies: Int {
        return collectionCountInconsistencies.count + 
               orphanedItemInconsistencies.count + 
               relationshipInconsistencies.count
    }
    
    var hasCriticalIssues: Bool {
        return !orphanedItemInconsistencies.isEmpty || !relationshipInconsistencies.isEmpty
    }
}

/// Result of attempting to fix data inconsistencies
struct DataConsistencyFixResult {
    let totalInconsistencies: Int
    let fixedCount: Int
    let failedCount: Int
    let errors: [Error]
    let fixedAt: Date
    
    var successRate: Double {
        guard totalInconsistencies > 0 else { return 1.0 }
        return Double(fixedCount) / Double(totalInconsistencies)
    }
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
}

/// Types of data inconsistencies that can be detected
enum DataInconsistency {
    case collectionCount(CollectionCountInconsistency)
    case orphanedItem(OrphanedItemInconsistency)
    case relationship(RelationshipInconsistency)
}

/// Inconsistency in collection item counts
struct CollectionCountInconsistency {
    let collectionId: String
    let collectionName: String
    let storedCount: Int
    let actualCount: Int
    let difference: Int
    
    var severity: InconsistencySeverity {
        return abs(difference) > 10 ? .high : .medium
    }
}

/// Item that belongs to a non-existent collection
struct OrphanedItemInconsistency {
    let itemId: String
    let itemName: String
    let orphanedCollectionId: String
    
    var severity: InconsistencySeverity {
        return .high // Orphaned items are always high severity
    }
}

/// Inconsistency in data relationships
struct RelationshipInconsistency {
    let type: RelationshipInconsistencyType
    let entityId: String
    let entityType: String
    let description: String
    
    var severity: InconsistencySeverity {
        switch type {
        case .invalidUserReference:
            return .high
        case .brokenReference:
            return .medium
        case .duplicateReference:
            return .low
        }
    }
}

/// Types of relationship inconsistencies
enum RelationshipInconsistencyType {
    case invalidUserReference
    case brokenReference
    case duplicateReference
}

/// Severity levels for inconsistencies
enum InconsistencySeverity {
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

/// Errors that can occur during data consistency operations
enum DataConsistencyError: LocalizedError {
    case validationFailed(String)
    case noTargetCollectionForOrphanedItem(String)
    case fixOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let reason):
            return "Data consistency validation failed: \(reason)"
        case .noTargetCollectionForOrphanedItem(let itemId):
            return "Cannot find target collection for orphaned item: \(itemId)"
        case .fixOperationFailed(let reason):
            return "Failed to fix data inconsistency: \(reason)"
        }
    }
}
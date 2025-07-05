import Foundation

/// Service for handling bulk operations on items
/// Provides functionality for bulk edit, delete, and other batch operations
@MainActor
final class BulkOperationsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var operationProgress: Double = 0.0
    @Published var lastError: Error?
    @Published var lastOperationResult: BulkOperationResult?
    
    // MARK: - Dependencies
    
    private let itemRepository: ItemRepositoryProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
    }
    
    // MARK: - Bulk Edit Operations
    
    /// Applies bulk edits to multiple items
    /// - Parameters:
    ///   - items: Array of items to edit
    ///   - edits: The edits to apply to all items
    /// - Returns: Result of the bulk operation
    func bulkEditItems(
        _ items: [Item],
        with edits: BulkEditOperations
    ) async throws -> BulkOperationResult {
        isProcessing = true
        operationProgress = 0.0
        lastError = nil
        
        var successCount = 0
        var failedItems: [Item] = []
        var updatedItems: [Item] = []
        
        let totalItems = items.count
        
        for (index, item) in items.enumerated() {
            do {
                let updatedItem = try await applyBulkEdits(to: item, with: edits)
                let savedItem = try await itemRepository.updateItem(updatedItem)
                updatedItems.append(savedItem)
                successCount += 1
            } catch {
                failedItems.append(item)
            }
            
            // Update progress
            operationProgress = Double(index + 1) / Double(totalItems)
        }
        
        let result = BulkOperationResult(
            operation: .edit,
            totalItems: totalItems,
            successCount: successCount,
            failedCount: failedItems.count,
            failedItems: failedItems,
            updatedItems: updatedItems
        )
        
        lastOperationResult = result
        isProcessing = false
        operationProgress = 1.0
        
        return result
    }
    
    /// Bulk deletes multiple items with confirmation
    /// - Parameters:
    ///   - items: Array of items to delete
    ///   - updateCollectionCounts: Whether to update collection item counts
    /// - Returns: Result of the bulk operation
    func bulkDeleteItems(
        _ items: [Item],
        updateCollectionCounts: Bool = true
    ) async throws -> BulkOperationResult {
        isProcessing = true
        operationProgress = 0.0
        lastError = nil
        
        do {
            var successCount = 0
            var failedItems: [Item] = []
            var deletedItems: [Item] = []
            
            let totalItems = items.count
            
            // Group items by collection for efficient count updates
            let itemsByCollection = Dictionary(grouping: items, by: { $0.collectionId })
            
            for (index, item) in items.enumerated() {
                do {
                    try await itemRepository.deleteItem(id: item.id)
                    deletedItems.append(item)
                    successCount += 1
                } catch {
                    failedItems.append(item)
                }
                
                // Update progress
                operationProgress = Double(index + 1) / Double(totalItems)
            }
            
            // Update collection item counts
            if updateCollectionCounts && successCount > 0 {
                for (collectionId, collectionItems) in itemsByCollection {
                    let deletedFromThisCollection = collectionItems.filter { item in
                        deletedItems.contains { $0.id == item.id }
                    }
                    
                    if !deletedFromThisCollection.isEmpty {
                        try await decrementCollectionItemCount(
                            collectionId,
                            by: deletedFromThisCollection.count
                        )
                    }
                }
            }
            
            let result = BulkOperationResult(
                operation: .delete,
                totalItems: totalItems,
                successCount: successCount,
                failedCount: failedItems.count,
                failedItems: failedItems,
                deletedItems: deletedItems
            )
            
            lastOperationResult = result
            isProcessing = false
            operationProgress = 1.0
            
            return result
            
        } catch {
            self.lastError = error
            isProcessing = false
            operationProgress = 0.0
            throw error
        }
    }
    
    /// Moves multiple items to a different collection
    /// - Parameters:
    ///   - items: Array of items to move
    ///   - targetCollectionId: ID of the target collection
    /// - Returns: Result of the bulk operation
    func bulkMoveItems(
        _ items: [Item],
        to targetCollectionId: String
    ) async throws -> BulkOperationResult {
        isProcessing = true
        operationProgress = 0.0
        lastError = nil
        
        do {
            // Verify target collection exists
            guard try await collectionRepository.getCollection(id: targetCollectionId) != nil else {
                throw BulkOperationError.targetCollectionNotFound(targetCollectionId)
            }
            
            var successCount = 0
            var failedItems: [Item] = []
            var movedItems: [Item] = []
            
            let totalItems = items.count
            let sourceCollections = Dictionary(grouping: items, by: { $0.collectionId })
            
            for (index, item) in items.enumerated() {
                do {
                    let movedItem = Item(
                        id: item.id,
                        userId: item.userId,
                        collectionId: targetCollectionId,
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
                    
                    let savedItem = try await itemRepository.updateItem(movedItem)
                    movedItems.append(savedItem)
                    successCount += 1
                } catch {
                    failedItems.append(item)
                }
                
                operationProgress = Double(index + 1) / Double(totalItems)
            }
            
            // Update collection item counts
            if successCount > 0 {
                // Increment target collection
                try await incrementCollectionItemCount(targetCollectionId, by: successCount)
                
                // Decrement source collections
                for (sourceCollectionId, sourceItems) in sourceCollections {
                    let movedFromSource = sourceItems.filter { item in
                        movedItems.contains { $0.id == item.id }
                    }
                    
                    if !movedFromSource.isEmpty {
                        try await decrementCollectionItemCount(
                            sourceCollectionId,
                            by: movedFromSource.count
                        )
                    }
                }
            }
            
            let result = BulkOperationResult(
                operation: .move,
                totalItems: totalItems,
                successCount: successCount,
                failedCount: failedItems.count,
                failedItems: failedItems,
                movedItems: movedItems
            )
            
            lastOperationResult = result
            isProcessing = false
            operationProgress = 1.0
            
            return result
            
        } catch {
            self.lastError = error
            isProcessing = false
            operationProgress = 0.0
            throw error
        }
    }
    
    /// Applies bulk tags to multiple items
    /// - Parameters:
    ///   - items: Array of items to tag
    ///   - tags: Tags to add to all items
    ///   - mode: Whether to add, replace, or remove tags
    /// - Returns: Result of the bulk operation
    func bulkApplyTags(
        to items: [Item],
        tags: [String],
        mode: BulkTagMode
    ) async throws -> BulkOperationResult {
        isProcessing = true
        operationProgress = 0.0
        lastError = nil
        
        var successCount = 0
        var failedItems: [Item] = []
        var updatedItems: [Item] = []
        
        let totalItems = items.count
        
        for (index, item) in items.enumerated() {
            do {
                let updatedTags = applyTagChanges(to: item.tags, with: tags, mode: mode)
                
                let updatedItem = Item(
                    id: item.id,
                    userId: item.userId,
                    collectionId: item.collectionId,
                    name: item.name,
                    description: item.description,
                    imageURLs: item.imageURLs,
                    customFields: item.customFields,
                    isFavorite: item.isFavorite,
                    tags: updatedTags,
                    location: item.location,
                    rating: item.rating,
                    createdAt: item.createdAt,
                    updatedAt: Date()
                )
                
                let savedItem = try await itemRepository.updateItem(updatedItem)
                updatedItems.append(savedItem)
                successCount += 1
            } catch {
                failedItems.append(item)
            }
            
            operationProgress = Double(index + 1) / Double(totalItems)
        }
        
        let result = BulkOperationResult(
            operation: .tag,
            totalItems: totalItems,
            successCount: successCount,
            failedCount: failedItems.count,
            failedItems: failedItems,
            updatedItems: updatedItems
        )
        
        lastOperationResult = result
        isProcessing = false
        operationProgress = 1.0
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func applyBulkEdits(to item: Item, with edits: BulkEditOperations) async throws -> Item {
        var updatedItem = item
        
        // Apply field updates
        if let rating = edits.rating {
            updatedItem = Item(
                id: item.id,
                userId: item.userId,
                collectionId: item.collectionId,
                name: item.name,
                description: item.description,
                imageURLs: item.imageURLs,
                customFields: item.customFields,
                isFavorite: item.isFavorite,
                tags: item.tags,
                location: item.location,
                rating: rating,
                createdAt: item.createdAt,
                updatedAt: Date()
            )
        }
        
        if let isFavorite = edits.isFavorite {
            updatedItem = Item(
                id: updatedItem.id,
                userId: updatedItem.userId,
                collectionId: updatedItem.collectionId,
                name: updatedItem.name,
                description: updatedItem.description,
                imageURLs: updatedItem.imageURLs,
                customFields: updatedItem.customFields,
                isFavorite: isFavorite,
                tags: updatedItem.tags,
                location: updatedItem.location,
                rating: updatedItem.rating,
                createdAt: updatedItem.createdAt,
                updatedAt: Date()
            )
        }
        
        if let customFieldUpdates = edits.customFieldUpdates {
            var updatedFields = updatedItem.customFields
            for (key, value) in customFieldUpdates {
                if let value = value {
                    updatedFields[key] = value
                } else {
                    updatedFields.removeValue(forKey: key)
                }
            }
            
            updatedItem = Item(
                id: updatedItem.id,
                userId: updatedItem.userId,
                collectionId: updatedItem.collectionId,
                name: updatedItem.name,
                description: updatedItem.description,
                imageURLs: updatedItem.imageURLs,
                customFields: updatedFields,
                isFavorite: updatedItem.isFavorite,
                tags: updatedItem.tags,
                location: updatedItem.location,
                rating: updatedItem.rating,
                createdAt: updatedItem.createdAt,
                updatedAt: Date()
            )
        }
        
        return updatedItem
    }
    
    private func applyTagChanges(to currentTags: [String], with tags: [String], mode: BulkTagMode) -> [String] {
        var result = currentTags
        
        switch mode {
        case .add:
            for tag in tags {
                if !result.contains(tag) {
                    result.append(tag)
                }
            }
        case .replace:
            result = tags
        case .remove:
            result = result.filter { !tags.contains($0) }
        }
        
        return result
    }
    
    private func incrementCollectionItemCount(_ collectionId: String, by count: Int) async throws {
        guard let collection = try await collectionRepository.getCollection(id: collectionId) else {
            throw BulkOperationError.collectionNotFound(collectionId)
        }
        
        let updatedCollection = Collection(
            id: collection.id,
            userId: collection.userId,
            name: collection.name,
            description: collection.description,
            templateId: collection.templateId,
            itemCount: collection.itemCount + count,
            coverImageURL: collection.coverImageURL,
            isFavorite: collection.isFavorite,
            tags: collection.tags,
            isPublic: collection.isPublic,
            createdAt: collection.createdAt,
            updatedAt: Date()
        )
        
        _ = try await collectionRepository.updateCollection(updatedCollection)
    }
    
    private func decrementCollectionItemCount(_ collectionId: String, by count: Int) async throws {
        guard let collection = try await collectionRepository.getCollection(id: collectionId) else {
            throw BulkOperationError.collectionNotFound(collectionId)
        }
        
        let newCount = max(0, collection.itemCount - count)
        
        let updatedCollection = Collection(
            id: collection.id,
            userId: collection.userId,
            name: collection.name,
            description: collection.description,
            templateId: collection.templateId,
            itemCount: newCount,
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

// MARK: - Supporting Types

/// Operations that can be applied in bulk to items
struct BulkEditOperations {
    var rating: Double?
    var isFavorite: Bool?
    var customFieldUpdates: [String: CustomFieldValue?]? // nil value removes the field
}

/// Modes for bulk tag operations
enum BulkTagMode {
    case add     // Add tags to existing tags
    case replace // Replace all tags with new tags
    case remove  // Remove specified tags from existing tags
}

/// Types of bulk operations
enum BulkOperationType {
    case edit
    case delete
    case move
    case tag
    case duplicate
}

/// Result of a bulk operation
struct BulkOperationResult {
    let operation: BulkOperationType
    let totalItems: Int
    let successCount: Int
    let failedCount: Int
    let failedItems: [Item]
    
    // Optional result arrays based on operation type
    let updatedItems: [Item]?
    let deletedItems: [Item]?
    let movedItems: [Item]?
    let duplicatedItems: [Item]?
    
    init(
        operation: BulkOperationType,
        totalItems: Int,
        successCount: Int,
        failedCount: Int,
        failedItems: [Item],
        updatedItems: [Item]? = nil,
        deletedItems: [Item]? = nil,
        movedItems: [Item]? = nil,
        duplicatedItems: [Item]? = nil
    ) {
        self.operation = operation
        self.totalItems = totalItems
        self.successCount = successCount
        self.failedCount = failedCount
        self.failedItems = failedItems
        self.updatedItems = updatedItems
        self.deletedItems = deletedItems
        self.movedItems = movedItems
        self.duplicatedItems = duplicatedItems
    }
    
    var successRate: Double {
        guard totalItems > 0 else { return 0 }
        return Double(successCount) / Double(totalItems)
    }
    
    var hasFailures: Bool {
        return failedCount > 0
    }
}

/// Errors that can occur during bulk operations
enum BulkOperationError: LocalizedError {
    case collectionNotFound(String)
    case targetCollectionNotFound(String)
    case operationFailed(String)
    case invalidOperation
    
    var errorDescription: String? {
        switch self {
        case .collectionNotFound(let id):
            return "Collection with ID \(id) not found"
        case .targetCollectionNotFound(let id):
            return "Target collection with ID \(id) not found"
        case .operationFailed(let reason):
            return "Bulk operation failed: \(reason)"
        case .invalidOperation:
            return "Invalid bulk operation"
        }
    }
}
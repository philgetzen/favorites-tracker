import Foundation

/// Service for handling item duplication operations
/// Provides functionality to duplicate items with field modification options
@MainActor
final class ItemDuplicationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
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
    
    // MARK: - Duplication Operations
    
    /// Duplicates an item with optional field modifications
    /// - Parameters:
    ///   - item: The original item to duplicate
    ///   - modifications: Optional modifications to apply during duplication
    ///   - targetCollectionId: Optional target collection ID (defaults to same collection)
    /// - Returns: The newly created duplicated item
    func duplicateItem(
        _ item: Item,
        with modifications: ItemDuplicationModifications? = nil,
        to targetCollectionId: String? = nil
    ) async throws -> Item {
        isProcessing = true
        lastError = nil
        
        do {
            // Create new item with duplicated data
            let duplicatedItem = try await createDuplicatedItem(
                from: item,
                with: modifications,
                targetCollectionId: targetCollectionId
            )
            
            // Save the duplicated item
            let savedItem = try await itemRepository.createItem(duplicatedItem)
            
            // Update collection item count if moved to different collection
            if let targetId = targetCollectionId, targetId != item.collectionId {
                try await incrementCollectionItemCount(targetId)
            } else {
                try await incrementCollectionItemCount(item.collectionId)
            }
            
            isProcessing = false
            return savedItem
            
        } catch {
            self.lastError = error
            isProcessing = false
            throw error
        }
    }
    
    /// Duplicates multiple items with the same modifications
    /// - Parameters:
    ///   - items: Array of items to duplicate
    ///   - modifications: Optional modifications to apply to all items
    ///   - targetCollectionId: Optional target collection ID
    /// - Returns: Array of newly created duplicated items
    func duplicateItems(
        _ items: [Item],
        with modifications: ItemDuplicationModifications? = nil,
        to targetCollectionId: String? = nil
    ) async throws -> [Item] {
        isProcessing = true
        lastError = nil
        
        do {
            var duplicatedItems: [Item] = []
            
            for item in items {
                let duplicatedItem = try await createDuplicatedItem(
                    from: item,
                    with: modifications,
                    targetCollectionId: targetCollectionId
                )
                
                let savedItem = try await itemRepository.createItem(duplicatedItem)
                duplicatedItems.append(savedItem)
            }
            
            // Update collection item counts
            if let targetId = targetCollectionId {
                try await incrementCollectionItemCount(targetId, by: items.count)
            } else {
                // Group items by collection and update counts
                let collectionCounts = Dictionary(grouping: items, by: { $0.collectionId })
                    .mapValues { $0.count }
                
                for (collectionId, count) in collectionCounts {
                    try await incrementCollectionItemCount(collectionId, by: count)
                }
            }
            
            isProcessing = false
            return duplicatedItems
            
        } catch {
            self.lastError = error
            isProcessing = false
            throw error
        }
    }
    
    /// Creates a smart duplicate of an item with suggested modifications
    /// - Parameter item: The original item to duplicate
    /// - Returns: Suggested modifications for the duplicate
    func generateSmartDuplicationSuggestions(for item: Item) -> ItemDuplicationModifications {
        var modifications = ItemDuplicationModifications()
        
        // Suggest appending "Copy" to the name
        modifications.name = "\(item.name) Copy"
        
        // Clear rating to allow fresh evaluation
        modifications.rating = nil
        modifications.isFavorite = false
        
        // Suggest clearing purchase-related fields for re-evaluation
        var updatedFields = item.customFields
        
        // Clear price-related fields
        let priceKeys = ["price", "price_paid", "cost", "value"]
        for key in updatedFields.keys {
            if priceKeys.contains(where: { key.lowercased().contains($0) }) {
                updatedFields.removeValue(forKey: key)
            }
        }
        
        // Clear date-related fields that shouldn't be duplicated
        let dateKeys = ["purchase_date", "acquired_date", "date_added"]
        for key in updatedFields.keys {
            if dateKeys.contains(where: { key.lowercased().contains($0) }) {
                updatedFields.removeValue(forKey: key)
            }
        }
        
        modifications.customFields = updatedFields
        
        return modifications
    }
    
    // MARK: - Private Methods
    
    private func createDuplicatedItem(
        from original: Item,
        with modifications: ItemDuplicationModifications?,
        targetCollectionId: String?
    ) async throws -> Item {
        
        let finalCollectionId = targetCollectionId ?? original.collectionId
        
        // Start with original item data
        var name = original.name
        var description = original.description
        var imageURLs = original.imageURLs
        var customFields = original.customFields
        var rating = original.rating
        var isFavorite = original.isFavorite
        var tags = original.tags
        var location = original.location
        
        // Apply modifications if provided
        if let mods = modifications {
            if let newName = mods.name { name = newName }
            if let newDescription = mods.description { description = newDescription }
            if let newImageURLs = mods.imageURLs { imageURLs = newImageURLs }
            if let newCustomFields = mods.customFields { customFields = newCustomFields }
            if let newRating = mods.rating { rating = newRating }
            if let newIsFavorite = mods.isFavorite { isFavorite = newIsFavorite }
            if let newTags = mods.tags { tags = newTags }
            if let newLocation = mods.location { location = newLocation }
        }
        
        // Create new item with duplicated data
        return Item(
            id: UUID().uuidString,
            userId: original.userId,
            collectionId: finalCollectionId,
            name: name,
            description: description,
            imageURLs: imageURLs,
            customFields: customFields,
            isFavorite: isFavorite,
            tags: tags,
            location: location,
            rating: rating,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func incrementCollectionItemCount(_ collectionId: String, by count: Int = 1) async throws {
        guard let collection = try await collectionRepository.getCollection(id: collectionId) else {
            throw ItemDuplicationError.collectionNotFound(collectionId)
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
}

// MARK: - Supporting Types

/// Modifications to apply during item duplication
struct ItemDuplicationModifications {
    var name: String?
    var description: String?
    var imageURLs: [URL]?
    var customFields: [String: CustomFieldValue]?
    var rating: Double?
    var isFavorite: Bool?
    var tags: [String]?
    var location: Location?
}

/// Errors that can occur during item duplication
enum ItemDuplicationError: LocalizedError {
    case collectionNotFound(String)
    case duplicateCreationFailed
    case invalidModifications
    
    var errorDescription: String? {
        switch self {
        case .collectionNotFound(let id):
            return "Collection with ID \(id) not found"
        case .duplicateCreationFailed:
            return "Failed to create duplicate item"
        case .invalidModifications:
            return "Invalid modifications provided for duplication"
        }
    }
}
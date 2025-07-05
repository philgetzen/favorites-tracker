import Foundation

/// Service implementation for item form business logic
final class ItemFormService: ItemFormServiceProtocol, @unchecked Sendable {
    private nonisolated let itemRepository: ItemRepositoryProtocol
    private nonisolated let storageRepository: StorageRepositoryProtocol
    
    init(
        itemRepository: ItemRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self.itemRepository = itemRepository
        self.storageRepository = storageRepository
    }
    
    func createItem(_ item: Item) async throws -> Item {
        return try await itemRepository.createItem(item)
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        return try await itemRepository.updateItem(item)
    }
    
    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        return try await storageRepository.uploadImage(imageData, path: path)
    }
    
    func getSuggestedTags() -> [String] {
        return [
            "favorite", "new", "used", "vintage", "rare", "classic", "modern", "expensive", "cheap", "bargain",
            "electronics", "books", "clothing", "food", "toys", "tools", "art", "music", "sports", "hobby",
            "excellent", "good", "fair", "poor", "mint", "damaged", "restored", "working", "broken",
            "home", "work", "travel", "store", "online", "local", "imported", "handmade", "custom",
            "owned", "wanted", "sold", "given-away", "missing", "loaned", "returned", "wishlist"
        ]
    }
    
    func validateItem(name: String, imageCount: Int) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyName)
        }
        
        let maxImages = 5
        if imageCount > maxImages {
            errors.append(.tooManyImages(max: maxImages))
        }
        
        return errors
    }
}
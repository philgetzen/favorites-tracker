import Foundation

/// Concrete implementation of ItemDetailServiceProtocol that handles business logic for Item Detail functionality
final class ItemDetailService: ItemDetailServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let itemRepository: ItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(itemRepository: ItemRepositoryProtocol) {
        self.itemRepository = itemRepository
    }
    
    // MARK: - ItemDetailServiceProtocol Implementation
    
    func loadItem(id itemId: String) async throws -> Item? {
        return try await itemRepository.getItem(id: itemId)
    }
    
    func toggleItemFavorite(_ item: Item) async throws -> Item {
        var updatedItem = item
        updatedItem.isFavorite.toggle()
        return try await itemRepository.updateItem(updatedItem)
    }
    
    func deleteItem(id itemId: String) async throws {
        try await itemRepository.deleteItem(id: itemId)
    }
    
    @MainActor
    func createEditViewModel(
        for item: Item,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) -> ItemFormViewModelRefactored {
        return ItemFormViewModelRefactored(
            userId: item.userId,
            collectionId: item.collectionId,
            editingItem: item,
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        )
    }
    
    func formatUpdatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
import SwiftUI
import Combine

/// ViewModel for displaying and managing a single item's details
@MainActor
class ItemDetailViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var item: Item?
    @Published var showingDeleteAlert: Bool = false
    @Published var showingEditSheet: Bool = false
    @Published var showingImageViewer: Bool = false
    @Published var selectedImageIndex: Int = 0
    
    // MARK: - Properties
    
    private nonisolated let itemRepository: ItemRepositoryProtocol
    private nonisolated let collectionRepository: CollectionRepositoryProtocol
    private nonisolated let storageRepository: StorageRepositoryProtocol
    private let itemId: String
    
    // MARK: - Computed Properties
    
    var hasImages: Bool {
        !(item?.imageURLs.isEmpty ?? true)
    }
    
    var hasTags: Bool {
        !(item?.tags.isEmpty ?? true)
    }
    
    var hasDescription: Bool {
        !(item?.description?.isEmpty ?? true)
    }
    
    var hasRating: Bool {
        item?.rating != nil && item?.rating ?? 0 > 0
    }
    
    var ratingStars: [Bool] {
        let rating = item?.rating ?? 0
        return (1...5).map { $0 <= Int(rating.rounded()) }
    }
    
    var formattedCreatedDate: String {
        guard let item = item else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.createdAt)
    }
    
    var formattedUpdatedDate: String {
        guard let item = item else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.updatedAt)
    }
    
    // MARK: - Initialization
    
    init(
        itemId: String,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self.itemId = itemId
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.storageRepository = storageRepository
        
        super.init()
    }
    
    // MARK: - Data Loading
    
    func loadItem() async {
        setLoading(true)
        
        do {
            let fetchedItem = try await itemRepository.getItem(id: itemId)
            item = fetchedItem
            
            if item == nil {
                print("Item with ID \(itemId) not found")
            }
        } catch {
            handleError(error)
        }
        
        setLoading(false)
    }
    
    func refreshItem() async {
        await loadItem()
    }
    
    // MARK: - Actions
    
    func toggleFavorite() async {
        guard var currentItem = item else { return }
        
        currentItem.isFavorite.toggle()
        
        do {
            let updatedItem = try await itemRepository.updateItem(currentItem)
            item = updatedItem
        } catch {
            handleError(error)
            // Revert the UI change if the update failed
            currentItem.isFavorite.toggle()
            item = currentItem
        }
    }
    
    func editItem() {
        showingEditSheet = true
    }
    
    func deleteItem() {
        showingDeleteAlert = true
    }
    
    func confirmDelete() async -> Bool {
        guard let currentItem = item else { return false }
        
        setLoading(true)
        
        do {
            try await itemRepository.deleteItem(id: currentItem.id)
            setLoading(false)
            return true
        } catch {
            handleError(error)
            return false
        }
    }
    
    func showImage(at index: Int) {
        selectedImageIndex = index
        showingImageViewer = true
    }
    
    // MARK: - Navigation
    
    func getEditViewModel() -> ItemFormViewModel? {
        guard let currentItem = item else { return nil }
        
        return ItemFormViewModel(
            userId: currentItem.userId,
            collectionId: currentItem.collectionId,
            editingItem: currentItem,
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        )
    }
    
    // MARK: - Private Methods
    // Note: Error handling is provided by BaseViewModel
}

// MARK: - Preview Support

#if DEBUG
extension ItemDetailViewModel {
    static func preview() -> ItemDetailViewModel {
        let viewModel = ItemDetailViewModel(
            itemId: "preview-item",
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        
        // Set a sample item for preview
        viewModel.item = Item(
            id: "preview-item",
            userId: "preview-user",
            collectionId: "preview-collection",
            name: "Sample Book",
            description: "A fascinating book about Swift development and iOS app architecture. This book covers advanced topics including Clean Architecture, MVVM patterns, and modern SwiftUI development techniques.",
            imageURLs: [
                URL(string: "https://picsum.photos/400/600?random=1")!,
                URL(string: "https://picsum.photos/400/600?random=2")!
            ],
            customFields: [
                "Author": .text("John Smith"), 
                "ISBN": .text("978-0123456789"), 
                "Pages": .text("324")
            ],
            isFavorite: true,
            tags: ["swift", "ios", "programming", "architecture"],
            location: nil,
            rating: 4.5,
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        )
        
        return viewModel
    }
}
#endif
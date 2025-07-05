import SwiftUI
import Combine

/// ViewModel responsible for item display and data loading
@MainActor
final class ItemDisplayViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var item: Item?
    
    // MARK: - Properties
    
    private let itemId: String
    private let service: ItemDetailServiceProtocol
    
    // MARK: - Computed Properties
    
    var formattedUpdatedDate: String {
        guard let item = item else { return "" }
        return service.formatUpdatedDate(item.updatedAt)
    }
    
    // MARK: - Initialization
    
    init(itemId: String, service: ItemDetailServiceProtocol) {
        self.itemId = itemId
        self.service = service
        super.init()
    }
    
    // MARK: - Data Loading
    
    func loadItem() async {
        setLoading(true)
        
        do {
            let fetchedItem = try await service.loadItem(id: itemId)
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
    
    // MARK: - Item Access
    
    var hasItem: Bool {
        item != nil
    }
    
    var itemName: String {
        item?.name ?? ""
    }
    
    var itemDescription: String {
        item?.description ?? ""
    }
    
    var itemImageURLs: [URL] {
        item?.imageURLs ?? []
    }
    
    var itemTags: [String] {
        item?.tags ?? []
    }
    
    var itemRating: Double? {
        item?.rating
    }
    
    var itemIsFavorite: Bool {
        item?.isFavorite ?? false
    }
    
    var itemCustomFields: [String: CustomFieldValue] {
        item?.customFields ?? [:]
    }
}
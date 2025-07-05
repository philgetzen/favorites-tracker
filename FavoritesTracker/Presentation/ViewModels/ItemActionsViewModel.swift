import SwiftUI
import Combine

/// ViewModel responsible for item actions (favorite, edit, delete)
@MainActor
final class ItemActionsViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var showingDeleteAlert: Bool = false
    @Published var showingEditSheet: Bool = false
    
    // MARK: - Properties
    
    private let service: ItemDetailServiceProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    private let storageRepository: StorageRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        service: ItemDetailServiceProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self.service = service
        self.collectionRepository = collectionRepository
        self.storageRepository = storageRepository
        super.init()
    }
    
    // MARK: - Actions
    
    /// Toggles the favorite status of an item
    /// - Parameter item: The item to toggle
    /// - Returns: The updated item or nil if failed
    func toggleFavorite(for item: Item) async -> Item? {
        do {
            let updatedItem = try await service.toggleItemFavorite(item)
            return updatedItem
        } catch {
            handleError(error)
            return nil
        }
    }
    
    /// Shows the edit sheet
    func editItem() {
        showingEditSheet = true
    }
    
    /// Shows the delete confirmation alert
    func deleteItem() {
        showingDeleteAlert = true
    }
    
    /// Confirms and executes item deletion
    /// - Parameter item: The item to delete
    /// - Returns: True if deletion was successful
    func confirmDelete(for item: Item) async -> Bool {
        setLoading(true)
        
        do {
            try await service.deleteItem(id: item.id)
            setLoading(false)
            return true
        } catch {
            handleError(error)
            setLoading(false)
            return false
        }
    }
    
    // MARK: - Navigation Support
    
    /// Creates the edit ViewModel for the given item
    /// - Parameter item: The item to edit
    /// - Returns: Configured ItemFormViewModelRefactored
    func createEditViewModel(for item: Item) -> ItemFormViewModelRefactored {
        return service.createEditViewModel(
            for: item,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        )
    }
}
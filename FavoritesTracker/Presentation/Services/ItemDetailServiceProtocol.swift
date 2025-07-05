import Foundation

/// Protocol defining the business logic interface for Item Detail functionality
protocol ItemDetailServiceProtocol: Sendable {
    
    // MARK: - Data Operations
    
    /// Loads an item by ID
    /// - Parameter itemId: The item ID to load
    /// - Returns: The loaded item or nil if not found
    func loadItem(id itemId: String) async throws -> Item?
    
    /// Updates an item's favorite status
    /// - Parameter item: The item to update
    /// - Returns: The updated item
    func toggleItemFavorite(_ item: Item) async throws -> Item
    
    /// Deletes an item
    /// - Parameter itemId: The item ID to delete
    func deleteItem(id itemId: String) async throws
    
    // MARK: - Navigation Support
    
    /// Creates edit ViewModel for an item
    /// - Parameters:
    ///   - item: The item to edit
    ///   - collectionRepository: Collection repository dependency
    ///   - storageRepository: Storage repository dependency
    /// - Returns: Configured ItemFormViewModelRefactored for editing
    @MainActor
    func createEditViewModel(
        for item: Item,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) -> ItemFormViewModelRefactored
    
    // MARK: - Display Formatting
    
    /// Formats the updated date for display
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    func formatUpdatedDate(_ date: Date) -> String
}
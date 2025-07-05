import SwiftUI
import Combine

/// Coordinator ViewModel that manages the decomposed Item Detail ViewModels
@MainActor
final class ItemDetailViewModelRefactored: BaseViewModel {
    
    // MARK: - Child ViewModels
    
    let displayViewModel: ItemDisplayViewModel
    let actionsViewModel: ItemActionsViewModel
    let imageViewModel: ItemImageViewModel
    
    // MARK: - Properties
    
    private let service: ItemDetailServiceProtocol
    
    // MARK: - Computed Properties
    
    var item: Item? {
        displayViewModel.item
    }
    
    var combinedIsLoading: Bool {
        displayViewModel.isLoading || actionsViewModel.isLoading
    }
    
    var combinedErrorMessage: String? {
        displayViewModel.errorMessage ?? actionsViewModel.errorMessage
    }
    
    // MARK: - Initialization
    
    init(
        itemId: String,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        // Create service
        self.service = ItemDetailService(itemRepository: itemRepository)
        
        // Create child ViewModels
        self.displayViewModel = ItemDisplayViewModel(itemId: itemId, service: service)
        self.actionsViewModel = ItemActionsViewModel(
            service: service,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        )
        self.imageViewModel = ItemImageViewModel()
        
        super.init()
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Update image URLs when item changes
        displayViewModel.$item
            .compactMap { $0?.imageURLs }
            .sink { [weak self] imageURLs in
                self?.imageViewModel.updateImageURLs(imageURLs)
            }
            .store(in: &cancellables)
        
        // Propagate loading state from child ViewModels
        Publishers.CombineLatest(
            displayViewModel.$isLoading,
            actionsViewModel.$isLoading
        )
        .map { $0 || $1 }
        .sink { [weak self] isLoading in
            self?.setLoading(isLoading)
        }
        .store(in: &cancellables)
        
        // Propagate error messages from child ViewModels
        Publishers.CombineLatest(
            displayViewModel.$errorMessage,
            actionsViewModel.$errorMessage
        )
        .map { displayError, actionsError in
            displayError ?? actionsError
        }
        .sink { [weak self] errorMessage in
            self?.errorMessage = errorMessage
            self?.showError = errorMessage != nil
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads the item data
    func loadItem() async {
        await displayViewModel.loadItem()
    }
    
    /// Refreshes the item data
    func refreshItem() async {
        await displayViewModel.refreshItem()
    }
    
    /// Toggles the favorite status
    func toggleFavorite() async {
        guard let currentItem = item else { return }
        
        if let updatedItem = await actionsViewModel.toggleFavorite(for: currentItem) {
            displayViewModel.item = updatedItem
        } else {
            // If toggle failed, revert the UI by refreshing the item
            await displayViewModel.refreshItem()
        }
    }
    
    /// Shows the edit sheet
    func editItem() {
        actionsViewModel.editItem()
    }
    
    /// Shows the delete confirmation
    func deleteItem() {
        actionsViewModel.deleteItem()
    }
    
    /// Confirms item deletion
    /// - Returns: True if deletion was successful
    func confirmDelete() async -> Bool {
        guard let currentItem = item else { return false }
        return await actionsViewModel.confirmDelete(for: currentItem)
    }
    
    /// Shows an image at the specified index
    /// - Parameter index: The index of the image to show
    func showImage(at index: Int) {
        imageViewModel.showImage(at: index)
    }
    
    /// Gets the edit ViewModel for the current item
    /// - Returns: ItemFormViewModelRefactored configured for editing
    func getEditViewModel() -> ItemFormViewModelRefactored? {
        guard let currentItem = item else { return nil }
        return actionsViewModel.createEditViewModel(for: currentItem)
    }
    
    // MARK: - Convenience Properties
    
    var showingDeleteAlert: Bool {
        get { actionsViewModel.showingDeleteAlert }
        set { actionsViewModel.showingDeleteAlert = newValue }
    }
    
    var showingEditSheet: Bool {
        get { actionsViewModel.showingEditSheet }
        set { actionsViewModel.showingEditSheet = newValue }
    }
    
    var showingImageViewer: Bool {
        get { imageViewModel.showingImageViewer }
        set { imageViewModel.showingImageViewer = newValue }
    }
    
    var selectedImageIndex: Int {
        get { imageViewModel.selectedImageIndex }
        set { imageViewModel.selectedImageIndex = newValue }
    }
    
    var formattedUpdatedDate: String {
        displayViewModel.formattedUpdatedDate
    }
}

// MARK: - Preview Support

#if DEBUG
extension ItemDetailViewModelRefactored {
    static func preview() -> ItemDetailViewModelRefactored {
        let viewModel = ItemDetailViewModelRefactored(
            itemId: "preview-item",
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        
        // Set a sample item for preview
        viewModel.displayViewModel.item = Item(
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
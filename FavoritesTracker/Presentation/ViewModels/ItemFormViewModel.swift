import SwiftUI
import Combine

/// ViewModel for item creation and editing forms
@MainActor
class ItemFormViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var rating: Double = 0.0
    @Published var isFavorite: Bool = false
    @Published var tags: [String] = []
    @Published var selectedImageURLs: [URL] = []
    @Published var newTag: String = ""
    
    // Form state
    @Published var showingImagePicker: Bool = false
    @Published var validationErrors: [String] = []
    
    // MARK: - Properties
    
    nonisolated let itemRepository: ItemRepositoryProtocol
    nonisolated let collectionRepository: CollectionRepositoryProtocol
    nonisolated let storageRepository: StorageRepositoryProtocol
    
    var editingItem: Item?
    let userId: String
    let collectionId: String
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        editingItem != nil
    }
    
    var formTitle: String {
        isEditing ? "Edit Item" : "Add New Item"
    }
    
    var submitButtonTitle: String {
        isEditing ? "Update Item" : "Create Item"
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(
        userId: String,
        collectionId: String,
        editingItem: Item? = nil,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self.userId = userId
        self.collectionId = collectionId
        self.editingItem = editingItem
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.storageRepository = storageRepository
        
        super.init()
        
        // Populate form if editing existing item
        if let item = editingItem {
            populateForm(with: item)
        }
    }
    
    // MARK: - Form Actions
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTag.isEmpty else { return }
        guard !tags.contains(trimmedTag) else {
            newTag = ""
            return
        }
        
        tags.append(trimmedTag)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func selectImages() {
        showingImagePicker = true
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImageURLs.count else { return }
        selectedImageURLs.remove(at: index)
    }
    
    // MARK: - Submit Actions
    
    func submitForm() async {
        guard isFormValid else {
            validationErrors = ["Name is required"]
            return
        }
        
        setLoading(true)
        validationErrors = []
        
        do {
            if isEditing {
                try await updateExistingItem()
            } else {
                try await createNewItem()
            }
        } catch {
            handleError(error) // Uses BaseViewModel's error handling
            setValidationError(error) // Also set form-specific validation errors
        }
        
        setLoading(false)
    }
    
    func cancelForm() {
        // Reset form or dismiss
        resetForm()
    }
    
    // MARK: - Private Methods
    
    private func populateForm(with item: Item) {
        name = item.name
        description = item.description ?? ""
        rating = item.rating ?? 0.0
        isFavorite = item.isFavorite
        tags = item.tags
        selectedImageURLs = item.imageURLs
    }
    
    private func createNewItem() async throws {
        var newItem = Item(
            userId: userId,
            collectionId: collectionId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Apply form values using the complete initializer
        newItem = Item(
            id: newItem.id,
            userId: userId,
            collectionId: collectionId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            imageURLs: selectedImageURLs,
            customFields: [:], // TODO: Add custom fields support
            isFavorite: isFavorite,
            tags: tags,
            location: nil, // TODO: Add location support
            rating: rating > 0 ? rating : nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let createdItem = try await itemRepository.createItem(newItem)
        
        // Successfully created - form will be dismissed by parent view
        print("Successfully created item: \(createdItem.name)")
    }
    
    private func updateExistingItem() async throws {
        guard let existingItem = editingItem else { return }
        
        let updatedItem = Item(
            id: existingItem.id,
            userId: existingItem.userId,
            collectionId: existingItem.collectionId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            imageURLs: selectedImageURLs,
            customFields: existingItem.customFields, // Preserve existing custom fields
            isFavorite: isFavorite,
            tags: tags,
            location: existingItem.location, // Preserve existing location
            rating: rating > 0 ? rating : nil,
            createdAt: existingItem.createdAt,
            updatedAt: Date()
        )
        
        let result = try await itemRepository.updateItem(updatedItem)
        
        // Successfully updated - form will be dismissed by parent view
        print("Successfully updated item: \(result.name)")
    }
    
    private func resetForm() {
        name = ""
        description = ""
        rating = 0.0
        isFavorite = false
        tags = []
        selectedImageURLs = []
        newTag = ""
        validationErrors = []
    }
    
    private func setValidationError(_ error: Error) {
        validationErrors = [error.localizedDescription]
    }
}

// MARK: - Preview Support

#if DEBUG
extension ItemFormViewModel {
    static func preview(editing: Bool = false) -> ItemFormViewModel {
        let mockItem = editing ? Item(
            id: "preview-item",
            userId: "preview-user",
            collectionId: "preview-collection",
            name: "Sample Book",
            description: "A great book I'm reading",
            imageURLs: [],
            customFields: [:],
            isFavorite: true,
            tags: ["fiction", "sci-fi"],
            location: nil,
            rating: 4.5,
            createdAt: Date(),
            updatedAt: Date()
        ) : nil
        
        return ItemFormViewModel(
            userId: "preview-user",
            collectionId: "preview-collection",
            editingItem: mockItem,
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
    }
}
#endif
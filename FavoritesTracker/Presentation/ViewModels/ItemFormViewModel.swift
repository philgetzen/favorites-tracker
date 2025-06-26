import SwiftUI
import Combine
import PhotosUI

// MARK: - Upload Result Types

enum UploadResult {
    case success(index: Int, url: URL)
    case failure(index: Int, error: Error)
    
    var index: Int {
        switch self {
        case .success(let index, _):
            return index
        case .failure(let index, _):
            return index
        }
    }
}

enum UploadError: Error, LocalizedError {
    case invalidImageData
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Failed to convert image to data"
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
}

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
    @Published var customFields: [String: CustomFieldValue] = [:]
    
    // Photo picker state
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    @Published var isUploadingImages: Bool = false
    
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
        
        // Observe photo picker changes
        setupPhotoPickerObserver()
    }
    
    // MARK: - Form Actions
    
    // MARK: - Computed Properties for Tags
    
    var availableTags: [String] {
        // Return common tags for suggestions
        // In a real app, this could come from a service that tracks popular tags
        return [
            "favorite", "new", "used", "vintage", "rare", "classic", "modern", "expensive", "cheap", "bargain",
            "electronics", "books", "clothing", "food", "toys", "tools", "art", "music", "sports", "hobby",
            "excellent", "good", "fair", "poor", "mint", "damaged", "restored", "working", "broken",
            "home", "work", "travel", "store", "online", "local", "imported", "handmade", "custom",
            "owned", "wanted", "sold", "given-away", "missing", "loaned", "returned", "wishlist"
        ]
    }
    
    func selectImages() {
        // PhotosPicker handles image selection automatically
        // This method can be removed in a future refactor
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
    
    // MARK: - Photo Handling
    
    private func setupPhotoPickerObserver() {
        $selectedPhotoItems
            .dropFirst() // Skip initial empty value
            .sink { [weak self] items in
                Task { @MainActor in
                    await self?.processSelectedPhotos(items)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        // Validate image count limit
        let maxImages = 5
        let currentImageCount = selectedImageURLs.count
        let newImageCount = min(items.count, maxImages - currentImageCount)
        
        guard newImageCount > 0 else {
            validationErrors = ["Maximum of \(maxImages) images allowed"]
            return
        }
        
        isUploadingImages = true
        var newImages: [UIImage] = []
        
        // Convert PhotosPickerItems to UIImages
        for (index, item) in items.enumerated() {
            if index >= newImageCount { break } // Respect limit
            
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    
                    // Validate image size (optional compression happens in upload)
                    if data.count > 10 * 1024 * 1024 { // 10MB limit
                        print("Image too large: \(data.count) bytes, skipping")
                        continue
                    }
                    
                    newImages.append(image)
                }
            } catch {
                print("Failed to load image data: \(error)")
                // Continue with other images
            }
        }
        
        // Upload images to Firebase Storage
        await uploadImagesToFirebase(newImages)
        
        isUploadingImages = false
        
        // Clear the picker selection for next use
        selectedPhotoItems = []
    }
    
    private func uploadImagesToFirebase(_ images: [UIImage]) async {
        // Use TaskGroup for concurrent uploads
        let results = await withTaskGroup(of: UploadResult.self, returning: [UploadResult].self) { group in
            var allResults: [UploadResult] = []
            
            for (index, image) in images.enumerated() {
                group.addTask {
                    do {
                        let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
                        
                        // Ensure we have valid image data
                        guard !imageData.isEmpty else {
                            return UploadResult.failure(index: index, error: UploadError.invalidImageData)
                        }
                        
                        let imagePath = "items/\(UUID().uuidString).jpg"
                        
                        let downloadURL = try await self.storageRepository.uploadImage(
                            imageData,
                            path: imagePath
                        )
                        
                        return UploadResult.success(index: index, url: downloadURL)
                    } catch {
                        return UploadResult.failure(index: index, error: error)
                    }
                }
            }
            
            for await result in group {
                allResults.append(result)
            }
            
            return allResults
        }
        
        // Process results and update UI
        var successfulURLs: [URL] = []
        var failedUploads = 0
        
        // Sort results by original index to maintain order
        let sortedResults = results.sorted { $0.index < $1.index }
        
        for result in sortedResults {
            switch result {
            case .success(_, let url):
                successfulURLs.append(url)
            case .failure(_, let error):
                failedUploads += 1
                print("Failed to upload image: \(error)")
                handleError(error)
            }
        }
        
        // Update selected URLs with successful uploads
        selectedImageURLs.append(contentsOf: successfulURLs)
        
        // Show summary message if there were failures
        if failedUploads > 0 {
            let successfulUploads = images.count - failedUploads
            if successfulUploads > 0 {
                print("Uploaded \(successfulUploads) of \(images.count) images successfully")
            } else {
                validationErrors.append("Failed to upload images. Please try again.")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func populateForm(with item: Item) {
        name = item.name
        description = item.description ?? ""
        rating = item.rating ?? 0.0
        isFavorite = item.isFavorite
        tags = item.tags
        selectedImageURLs = item.imageURLs
        customFields = item.customFields
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
            customFields: customFields,
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
            customFields: customFields,
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
        customFields = [:]
        validationErrors = []
        selectedPhotoItems = []
        selectedImages = []
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
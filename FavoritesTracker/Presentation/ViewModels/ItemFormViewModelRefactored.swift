import SwiftUI
import Combine
import PhotosUI

/// Refactored ViewModel that coordinates form operations using focused sub-ViewModels
@MainActor
final class ItemFormViewModelRefactored: BaseViewModel {
    
    // MARK: - Child ViewModels
    
    @Published var formState: ItemFormStateViewModel
    @Published var photoUpload: PhotoUploadViewModel
    @Published var validation: ItemFormValidationViewModel
    
    // MARK: - Published Properties
    
    @Published var showingImagePicker: Bool = false
    @Published var isSubmitting: Bool = false
    
    // MARK: - Properties
    
    private let service: ItemFormServiceProtocol
    private let userId: String
    private let collectionId: String
    
    // MARK: - Computed Properties
    
    var availableTags: [String] {
        service.getSuggestedTags()
    }
    
    var canSubmit: Bool {
        formState.hasValidName && 
        validation.isFormValid && 
        !isSubmitting && 
        !photoUpload.isUploadingImages
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
        
        // Initialize service
        self.service = ItemFormService(
            itemRepository: itemRepository,
            storageRepository: storageRepository
        )
        
        // Initialize photo management service
        let photoService = PhotoManagementService(
            storageRepository: storageRepository,
            configuration: .default
        )
        
        // Initialize child ViewModels
        self.formState = ItemFormStateViewModel(editingItem: editingItem)
        self.photoUpload = PhotoUploadViewModel(
            photoService: photoService,
            initialImageURLs: editingItem?.imageURLs ?? []
        )
        self.validation = ItemFormValidationViewModel(service: service)
        
        super.init()
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func submitForm() async {
        guard canSubmit else {
            validation.validateForm(
                name: formState.name,
                imageCount: photoUpload.uploadedImageURLs.count
            )
            return
        }
        
        isSubmitting = true
        setLoading(true)
        validation.clearErrors()
        
        do {
            let item = formState.buildItem(
                userId: userId,
                collectionId: collectionId,
                imageURLs: photoUpload.uploadedImageURLs
            )
            
            if formState.isEditing {
                let _ = try await service.updateItem(item)
                print("Successfully updated item: \(item.name)")
            } else {
                let _ = try await service.createItem(item)
                print("Successfully created item: \(item.name)")
            }
            
            // Success - parent view will handle dismissal
        } catch {
            handleError(error)
            validation.addError(error)
        }
        
        isSubmitting = false
        setLoading(false)
    }
    
    func cancelForm() {
        formState.reset()
        validation.clearErrors()
    }
    
    func selectTag(_ tag: String) {
        formState.addTag(tag)
    }
    
    func removeTag(_ tag: String) {
        formState.removeTag(tag)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Set up real-time validation
        validation.setupRealTimeValidation(
            namePublisher: formState.$name.eraseToAnyPublisher(),
            imageCountPublisher: photoUpload.$uploadedImageURLs
                .map { $0.count }
                .eraseToAnyPublisher()
        )
        
        // Forward photo upload errors to main error handling
        photoUpload.$uploadErrors
            .sink { [weak self] errors in
                for error in errors {
                    self?.handleError(NSError(
                        domain: "PhotoUpload",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: error]
                    ))
                }
            }
            .store(in: &cancellables)
        
        // Update loading state based on child ViewModels
        Publishers.CombineLatest(
            photoUpload.$isUploadingImages,
            $isSubmitting
        )
        .map { uploading, submitting in
            uploading || submitting
        }
        .sink { [weak self] isLoading in
            self?.setLoading(isLoading)
        }
        .store(in: &cancellables)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ItemFormViewModelRefactored {
    static func preview(editing: Bool = false) -> ItemFormViewModelRefactored {
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
        
        return ItemFormViewModelRefactored(
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
import SwiftUI
import PhotosUI
import Combine

/// ViewModel dedicated to photo selection and upload functionality
@MainActor
final class PhotoUploadViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var uploadedImageURLs: [URL] = []
    @Published var isUploadingImages: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadErrors: [String] = []
    @Published var detailedProgress: PhotoUploadProgress = PhotoUploadProgress(
        completedUploads: 0,
        totalUploads: 0,
        currentlyUploading: false,
        failedUploads: 0,
        successfulURLs: [],
        errors: []
    )
    
    // MARK: - Properties
    
    private let photoService: PhotoManagementServiceProtocol
    
    // MARK: - Computed Properties
    
    private var maxImages: Int {
        photoService.configuration.maxImages
    }
    
    // MARK: - Initialization
    
    init(photoService: PhotoManagementServiceProtocol, initialImageURLs: [URL] = []) {
        self.photoService = photoService
        self.uploadedImageURLs = initialImageURLs
        super.init()
        setupPhotoPickerObserver()
    }
    
    // MARK: - Public Methods
    
    func removeImage(at index: Int) {
        guard index < uploadedImageURLs.count else { return }
        uploadedImageURLs.remove(at: index)
    }
    
    var canAddMoreImages: Bool {
        uploadedImageURLs.count < maxImages
    }
    
    var remainingImageSlots: Int {
        max(0, maxImages - uploadedImageURLs.count)
    }
    
    // MARK: - Private Methods
    
    private func setupPhotoPickerObserver() {
        $selectedPhotoItems
            .dropFirst()
            .sink { [weak self] items in
                Task { @MainActor in
                    await self?.processSelectedPhotos(items)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        uploadErrors = []
        isUploadingImages = true
        uploadProgress = 0.0
        
        do {
            // Use PhotoManagementService to process and upload photos
            let processedImages = try await photoService.processSelectedPhotos(
                items,
                currentImageCount: uploadedImageURLs.count
            )
            
            // Upload images using PhotoManagementService
            let uploadResults = await photoService.uploadImages(processedImages)
            
            // Update detailed progress
            detailedProgress = photoService.getCurrentProgress()
            
            // Process results and update UI
            var newURLs: [URL] = []
            var errorMessages: [String] = []
            
            // Sort results by index to maintain order
            let sortedResults = uploadResults.sorted { $0.index < $1.index }
            
            for result in sortedResults {
                switch result {
                case .success(_, let url):
                    newURLs.append(url)
                case .failure(_, let error):
                    errorMessages.append(error.localizedDescription)
                }
            }
            
            // Update uploaded URLs
            uploadedImageURLs.append(contentsOf: newURLs)
            
            // Update progress percentage
            uploadProgress = 1.0 // Complete
            
            // Set error messages if any uploads failed
            if !errorMessages.isEmpty {
                let successCount = newURLs.count
                let totalAttempted = processedImages.count
                
                if successCount > 0 {
                    uploadErrors = ["Uploaded \(successCount) of \(totalAttempted) images successfully. Some uploads failed."]
                } else {
                    uploadErrors = ["Failed to upload images. Please try again."]
                }
            }
            
        } catch let error as PhotoManagementError {
            uploadErrors = [error.localizedDescription]
            handleError(error)
        } catch {
            uploadErrors = ["Failed to process selected photos"]
            handleError(error)
        }
        
        isUploadingImages = false
        selectedPhotoItems = []
    }
}

// MARK: - Preview Support

#if DEBUG
extension PhotoUploadViewModel {
    static func preview() -> PhotoUploadViewModel {
        return PhotoUploadViewModel(
            photoService: PhotoManagementService.preview()
        )
    }
    
    static func previewWithImages() -> PhotoUploadViewModel {
        let viewModel = PhotoUploadViewModel(
            photoService: PhotoManagementService.preview(),
            initialImageURLs: [
                URL(string: "https://example.com/image1.jpg")!,
                URL(string: "https://example.com/image2.jpg")!
            ]
        )
        return viewModel
    }
}
#endif


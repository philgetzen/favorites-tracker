import Foundation
import SwiftUI
import PhotosUI
import Combine

/// Production implementation of PhotoManagementServiceProtocol
@MainActor
final class PhotoManagementService: PhotoManagementServiceProtocol {
    
    // MARK: - Properties
    
    let configuration: PhotoManagementConfiguration
    private let storageRepository: StorageRepositoryProtocol
    
    // Progress tracking
    @Published private var currentProgress = PhotoUploadProgress(
        completedUploads: 0,
        totalUploads: 0,
        currentlyUploading: false,
        failedUploads: 0,
        successfulURLs: [],
        errors: []
    )
    
    // MARK: - Initialization
    
    init(
        storageRepository: StorageRepositoryProtocol,
        configuration: PhotoManagementConfiguration = .default
    ) {
        self.storageRepository = storageRepository
        self.configuration = configuration
    }
    
    // MARK: - PhotoManagementServiceProtocol Implementation
    
    func processSelectedPhotos(_ items: [PhotosPickerItem], currentImageCount: Int) async throws -> [UIImage] {
        guard !items.isEmpty else { return [] }
        
        // Validate image count limit
        let newImageCount = min(items.count, configuration.maxImages - currentImageCount)
        
        guard newImageCount > 0 else {
            throw PhotoManagementError.maximumImagesExceeded(limit: configuration.maxImages)
        }
        
        var processedImages: [UIImage] = []
        
        // Convert PhotosPickerItems to UIImages
        for (index, item) in items.enumerated() {
            if index >= newImageCount { break } // Respect limit
            
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // Validate image data
                    try validateImage(data, currentImageCount: currentImageCount + processedImages.count)
                    
                    if let image = UIImage(data: data) {
                        processedImages.append(image)
                    } else {
                        print("Warning: Failed to create UIImage from valid data, skipping")
                    }
                }
            } catch let error as PhotoManagementError {
                // Re-throw our custom errors
                throw error
            } catch {
                print("Failed to load image data: \(error)")
                // Continue with other images instead of failing completely
                continue
            }
        }
        
        return processedImages
    }
    
    func validateImage(_ imageData: Data, currentImageCount: Int) throws {
        // Check if adding this image would exceed the limit
        if currentImageCount >= configuration.maxImages {
            throw PhotoManagementError.maximumImagesExceeded(limit: configuration.maxImages)
        }
        
        // Check image size
        if imageData.count > configuration.maxImageSizeBytes {
            throw PhotoManagementError.imageTooLarge(sizeInBytes: imageData.count)
        }
        
        // Validate image data is not empty
        if imageData.isEmpty {
            throw PhotoManagementError.invalidImageData
        }
    }
    
    func uploadImages(_ images: [UIImage]) async -> [PhotoUploadResult] {
        guard !images.isEmpty else { return [] }
        
        // Update progress tracking
        updateProgress(
            completedUploads: 0,
            totalUploads: images.count,
            currentlyUploading: true,
            failedUploads: 0,
            successfulURLs: [],
            errors: []
        )
        
        // Use TaskGroup for concurrent uploads
        let results = await withTaskGroup(of: PhotoUploadResult.self, returning: [PhotoUploadResult].self) { group in
            var allResults: [PhotoUploadResult] = []
            
            for (index, image) in images.enumerated() {
                group.addTask { [weak self] in
                    await self?.uploadImageWithResult(image, index: index) ?? .failure(index: index, error: PhotoManagementError.invalidImageData)
                }
            }
            
            for await result in group {
                allResults.append(result)
                
                // Update progress as each upload completes
                await updateProgressFromResult(result, totalUploads: images.count)
            }
            
            return allResults
        }
        
        // Final progress update
        let successfulUploads = results.compactMap { result in
            if case .success(_, let url) = result { return url }
            return nil
        }
        
        let failedUploads = results.compactMap { result in
            if case .failure(_, let error) = result { return error as? PhotoManagementError }
            return nil
        }
        
        updateProgress(
            completedUploads: results.count,
            totalUploads: images.count,
            currentlyUploading: false,
            failedUploads: failedUploads.count,
            successfulURLs: successfulUploads,
            errors: failedUploads
        )
        
        return results
    }
    
    func uploadSingleImage(_ image: UIImage) async throws -> URL {
        let imageData = try compressImage(image, quality: configuration.compressionQuality)
        let imagePath = generateImagePath()
        
        do {
            return try await storageRepository.uploadImage(imageData, path: imagePath)
        } catch {
            throw PhotoManagementError.uploadFailed(underlyingError: error)
        }
    }
    
    func getCurrentProgress() -> PhotoUploadProgress {
        return currentProgress
    }
    
    func removeImage(at url: URL) async throws {
        // Extract path from URL for storage deletion
        let path = url.lastPathComponent
        try await storageRepository.deleteImage(at: path)
    }
    
    func generateImagePath(fileExtension: String = "jpg") -> String {
        return "items/\(UUID().uuidString).\(fileExtension)"
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: quality), !imageData.isEmpty else {
            throw PhotoManagementError.compressionFailed
        }
        return imageData
    }
    
    // MARK: - Private Methods
    
    private func uploadImageWithResult(_ image: UIImage, index: Int) async -> PhotoUploadResult {
        do {
            let url = try await uploadSingleImage(image)
            return .success(index: index, url: url)
        } catch {
            let photoError = error as? PhotoManagementError ?? PhotoManagementError.uploadFailed(underlyingError: error)
            return .failure(index: index, error: photoError)
        }
    }
    
    private func updateProgressFromResult(_ result: PhotoUploadResult, totalUploads: Int) async {
        let completedUploads = currentProgress.completedUploads + 1
        let failedUploads = currentProgress.failedUploads + (result.isFailure ? 1 : 0)
        
        var successfulURLs = currentProgress.successfulURLs
        var errors = currentProgress.errors
        
        switch result {
        case .success(_, let url):
            successfulURLs.append(url)
        case .failure(_, let error):
            if let photoError = error as? PhotoManagementError {
                errors.append(photoError)
            }
        }
        
        updateProgress(
            completedUploads: completedUploads,
            totalUploads: totalUploads,
            currentlyUploading: completedUploads < totalUploads,
            failedUploads: failedUploads,
            successfulURLs: successfulURLs,
            errors: errors
        )
    }
    
    private func updateProgress(
        completedUploads: Int,
        totalUploads: Int,
        currentlyUploading: Bool,
        failedUploads: Int,
        successfulURLs: [URL],
        errors: [PhotoManagementError]
    ) {
        currentProgress = PhotoUploadProgress(
            completedUploads: completedUploads,
            totalUploads: totalUploads,
            currentlyUploading: currentlyUploading,
            failedUploads: failedUploads,
            successfulURLs: successfulURLs,
            errors: errors
        )
    }
}

// MARK: - PhotoUploadResult Extensions

private extension PhotoUploadResult {
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

// MARK: - Preview Support

#if DEBUG
extension PhotoManagementService {
    static func preview() -> PhotoManagementService {
        return PhotoManagementService(
            storageRepository: PreviewRepositoryProvider.shared.storageRepository,
            configuration: .default
        )
    }
}
#endif
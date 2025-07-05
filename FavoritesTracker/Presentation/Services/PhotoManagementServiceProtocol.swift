import Foundation
import SwiftUI
import PhotosUI

// MARK: - Photo Management Types

/// Result of a photo upload operation
enum PhotoUploadResult {
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

/// Errors specific to photo management operations
enum PhotoManagementError: Error, LocalizedError {
    case invalidImageData
    case compressionFailed
    case imageTooLarge(sizeInBytes: Int)
    case maximumImagesExceeded(limit: Int)
    case uploadFailed(underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Failed to convert image to data"
        case .compressionFailed:
            return "Failed to compress image"
        case .imageTooLarge(let sizeInBytes):
            let sizeMB = sizeInBytes / (1024 * 1024)
            return "Image too large (\(sizeMB)MB). Maximum size is 10MB."
        case .maximumImagesExceeded(let limit):
            return "Maximum of \(limit) images allowed"
        case .uploadFailed(let underlyingError):
            return "Upload failed: \(underlyingError.localizedDescription)"
        }
    }
}

/// Configuration for photo management operations
struct PhotoManagementConfiguration {
    let maxImages: Int
    let maxImageSizeBytes: Int
    let compressionQuality: CGFloat
    let allowedFormats: [String]
    
    static let `default` = PhotoManagementConfiguration(
        maxImages: 5,
        maxImageSizeBytes: 10 * 1024 * 1024, // 10MB
        compressionQuality: 0.8,
        allowedFormats: ["jpg", "jpeg", "png"]
    )
}

/// Progress information for photo uploads
struct PhotoUploadProgress {
    let completedUploads: Int
    let totalUploads: Int
    let currentlyUploading: Bool
    let failedUploads: Int
    let successfulURLs: [URL]
    let errors: [PhotoManagementError]
    
    var isComplete: Bool {
        completedUploads == totalUploads && !currentlyUploading
    }
    
    var progressPercentage: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(completedUploads) / Double(totalUploads)
    }
}

/// Protocol defining photo management service capabilities
@MainActor
protocol PhotoManagementServiceProtocol {
    
    // MARK: - Configuration
    
    /// Configuration for photo management operations
    var configuration: PhotoManagementConfiguration { get }
    
    // MARK: - Photo Processing
    
    /// Process selected PhotosPicker items and validate them
    /// - Parameters:
    ///   - items: Array of PhotosPickerItem from PhotosPicker
    ///   - currentImageCount: Number of images already selected
    /// - Returns: Array of validated UIImages ready for upload
    /// - Throws: PhotoManagementError for validation failures
    func processSelectedPhotos(_ items: [PhotosPickerItem], currentImageCount: Int) async throws -> [UIImage]
    
    /// Validate an individual image before processing
    /// - Parameters:
    ///   - imageData: Raw image data
    ///   - currentImageCount: Number of images already selected
    /// - Throws: PhotoManagementError for validation failures
    func validateImage(_ imageData: Data, currentImageCount: Int) throws
    
    // MARK: - Image Upload
    
    /// Upload multiple images concurrently to Firebase Storage
    /// - Parameter images: Array of UIImages to upload
    /// - Returns: Array of PhotoUploadResult containing success/failure information
    func uploadImages(_ images: [UIImage]) async -> [PhotoUploadResult]
    
    /// Upload a single image to Firebase Storage
    /// - Parameter image: UIImage to upload
    /// - Returns: URL of uploaded image
    /// - Throws: PhotoManagementError for upload failures
    func uploadSingleImage(_ image: UIImage) async throws -> URL
    
    // MARK: - Progress Tracking
    
    /// Get current upload progress information
    /// - Returns: PhotoUploadProgress with current status
    func getCurrentProgress() -> PhotoUploadProgress
    
    // MARK: - Image Management
    
    /// Remove image from storage by URL
    /// - Parameter url: URL of image to remove
    /// - Throws: Error if removal fails
    func removeImage(at url: URL) async throws
    
    /// Generate unique image path for upload
    /// - Parameter fileExtension: File extension (e.g., "jpg", "png")
    /// - Returns: Unique path for image storage
    func generateImagePath(fileExtension: String) -> String
    
    /// Compress image data with specified quality
    /// - Parameters:
    ///   - image: UIImage to compress
    ///   - quality: Compression quality (0.0 to 1.0)
    /// - Returns: Compressed image data
    /// - Throws: PhotoManagementError.compressionFailed if compression fails
    func compressImage(_ image: UIImage, quality: CGFloat) throws -> Data
}

// MARK: - Default Implementation Extensions

extension PhotoManagementServiceProtocol {
    
    /// Default image path generation
    func generateImagePath(fileExtension: String = "jpg") -> String {
        return "items/\(UUID().uuidString).\(fileExtension)"
    }
    
    /// Default image compression
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: quality), !imageData.isEmpty else {
            throw PhotoManagementError.compressionFailed
        }
        return imageData
    }
}
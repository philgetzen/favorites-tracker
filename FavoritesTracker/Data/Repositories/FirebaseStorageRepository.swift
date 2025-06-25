import Foundation
@preconcurrency import FirebaseStorage
import UIKit

/// Firebase implementation of StorageRepositoryProtocol
/// Handles Firebase Storage operations for images and files
final class FirebaseStorageRepository: StorageRepositoryProtocol, @unchecked Sendable {
    
    private let storage: Storage
    private let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }
    
    // MARK: - StorageRepositoryProtocol Implementation
    
    func uploadImage(_ data: Data, path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        
        // Add metadata for better file management
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "platform": "iOS"
        ]
        
        // Upload the data
        let uploadTask = storageRef.putData(data, metadata: metadata)
        
        // Wait for upload completion
        _ = try await uploadTask
        
        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
    
    func deleteImage(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
    
    func downloadImage(from url: URL) async throws -> Data {
        let storageRef = storage.reference(forURL: url.absoluteString)
        let data = try await storageRef.data(maxSize: maxImageSize)
        return data
    }
    
    // MARK: - Additional Storage Methods
    
    /// Upload image with compression and optimization
    func uploadOptimizedImage(_ image: UIImage, path: String, quality: CGFloat = 0.8) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw StorageError.invalidImageFormat
        }
        
        return try await uploadImage(imageData, path: path)
    }
    
    /// Upload multiple images in batch
    func uploadImages(_ images: [Data], basePath: String) async throws -> [URL] {
        var uploadTasks: [Task<URL, Error>] = []
        
        for (index, imageData) in images.enumerated() {
            let path = "\(basePath)/image_\(index)_\(UUID().uuidString).jpg"
            let task = Task { [self] in
                try await uploadImage(imageData, path: path)
            }
            uploadTasks.append(task)
        }
        
        var urls: [URL] = []
        for task in uploadTasks {
            let url = try await task.value
            urls.append(url)
        }
        
        return urls
    }
    
    /// Get upload progress for large files
    func uploadImageWithProgress(_ data: Data, path: String) -> AsyncThrowingStream<UploadProgress, Error> {
        return AsyncThrowingStream { continuation in
            let storageRef = storage.reference().child(path)
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let uploadTask = storageRef.putData(data, metadata: metadata)
            
            // Observe upload progress
            uploadTask.observe(.progress) { snapshot in
                let progress = UploadProgress(
                    bytesTransferred: snapshot.progress?.completedUnitCount ?? 0,
                    totalBytes: snapshot.progress?.totalUnitCount ?? 0
                )
                continuation.yield(progress)
            }
            
            // Handle completion
            uploadTask.observe(.success) { snapshot in
                Task {
                    do {
                        let downloadURL = try await storageRef.downloadURL()
                        let finalProgress = UploadProgress(
                            bytesTransferred: snapshot.progress?.totalUnitCount ?? 0,
                            totalBytes: snapshot.progress?.totalUnitCount ?? 0,
                            downloadURL: downloadURL
                        )
                        continuation.yield(finalProgress)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            // Handle failure
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish(throwing: StorageError.uploadFailed)
                }
            }
            
            continuation.onTermination = { @Sendable [uploadTask] _ in
                uploadTask.cancel()
            }
        }
    }
    
    /// Generate secure storage path for user content
    func generateStoragePath(userId: String, collectionId: String?, itemId: String?, fileName: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString
        
        if let collectionId = collectionId, let itemId = itemId {
            return "users/\(userId)/collections/\(collectionId)/items/\(itemId)/\(timestamp)_\(uuid)_\(fileName)"
        } else if let collectionId = collectionId {
            return "users/\(userId)/collections/\(collectionId)/\(timestamp)_\(uuid)_\(fileName)"
        } else {
            return "users/\(userId)/profile/\(timestamp)_\(uuid)_\(fileName)"
        }
    }
    
    /// Get image metadata
    func getImageMetadata(from url: URL) async throws -> StorageMetadata {
        let storageRef = storage.reference(forURL: url.absoluteString)
        return try await storageRef.getMetadata()
    }
    
    /// List all files in a directory
    func listFiles(at path: String, maxResults: Int = 100) async throws -> [StorageReference] {
        let storageRef = storage.reference().child(path)
        let result = try await storageRef.list(maxResults: Int64(maxResults))
        return result.items
    }
    
    /// Delete all files in a directory (for cleanup)
    func deleteDirectory(at path: String) async throws {
        let files = try await listFiles(at: path, maxResults: 1000)
        
        for file in files {
            try await file.delete()
        }
    }
    
    /// Check if file exists
    func fileExists(at path: String) async throws -> Bool {
        let storageRef = storage.reference().child(path)
        
        do {
            _ = try await storageRef.getMetadata()
            return true
        } catch {
            return false
        }
    }
    
    /// Resize and upload image with multiple sizes
    func uploadImageWithSizes(_ image: UIImage, path: String, sizes: [ImageSize] = ImageSize.defaultSizes) async throws -> [ImageSize: URL] {
        var uploadTasks: [ImageSize: Task<URL, Error>] = [:]
        
        for size in sizes {
            let resizedImage = image.resized(to: size.size)
            let imagePath = "\(path)_\(size.name).jpg"
            
            let task = Task { [self] in
                try await uploadOptimizedImage(resizedImage, path: imagePath, quality: size.quality)
            }
            uploadTasks[size] = task
        }
        
        var results: [ImageSize: URL] = [:]
        for (size, task) in uploadTasks {
            let url = try await task.value
            results[size] = url
        }
        
        return results
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case invalidImageFormat
    case fileTooLarge
    case uploadFailed
    case downloadFailed
    case fileNotFound
    case insufficientPermissions
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat:
            return "Invalid image format"
        case .fileTooLarge:
            return "File is too large"
        case .uploadFailed:
            return "Upload failed"
        case .downloadFailed:
            return "Download failed"
        case .fileNotFound:
            return "File not found"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Storage error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Types

struct UploadProgress {
    let bytesTransferred: Int64
    let totalBytes: Int64
    let downloadURL: URL?
    
    var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }
    
    var isComplete: Bool {
        return bytesTransferred >= totalBytes && downloadURL != nil
    }
    
    init(bytesTransferred: Int64, totalBytes: Int64, downloadURL: URL? = nil) {
        self.bytesTransferred = bytesTransferred
        self.totalBytes = totalBytes
        self.downloadURL = downloadURL
    }
}

struct ImageSize: Hashable {
    let name: String
    let size: CGSize
    let quality: CGFloat
    
    static let thumbnail = ImageSize(name: "thumb", size: CGSize(width: 150, height: 150), quality: 0.7)
    static let medium = ImageSize(name: "medium", size: CGSize(width: 400, height: 400), quality: 0.8)
    static let large = ImageSize(name: "large", size: CGSize(width: 800, height: 800), quality: 0.9)
    
    static let defaultSizes: [ImageSize] = [.thumbnail, .medium, .large]
}

// MARK: - UIImage Extensions

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func aspectFitResized(to maxSize: CGSize) -> UIImage {
        let aspectRatio = self.size.width / self.size.height
        let maxAspectRatio = maxSize.width / maxSize.height
        
        var newSize: CGSize
        if aspectRatio > maxAspectRatio {
            newSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
        }
        
        return resized(to: newSize)
    }
}
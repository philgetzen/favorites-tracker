import Foundation

/// Protocol defining the business logic for item form operations
protocol ItemFormServiceProtocol: Sendable {
    /// Create a new item
    func createItem(_ item: Item) async throws -> Item
    
    /// Update an existing item
    func updateItem(_ item: Item) async throws -> Item
    
    /// Upload an image and return the download URL
    func uploadImage(_ imageData: Data, path: String) async throws -> URL
    
    /// Get suggested tags for items
    func getSuggestedTags() -> [String]
    
    /// Validate item data before submission
    func validateItem(name: String, imageCount: Int) -> [ValidationError]
}

/// Validation errors for item forms
enum ValidationError: Error, LocalizedError {
    case emptyName
    case tooManyImages(max: Int)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name is required"
        case .tooManyImages(let max):
            return "Maximum of \(max) images allowed"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}
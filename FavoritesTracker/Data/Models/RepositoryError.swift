import Foundation

// MARK: - Consolidated Repository Error

/// Consolidated error type for all repository operations
enum RepositoryError: Error, LocalizedError {
    // Specific not found cases
    case itemNotFound
    case collectionNotFound
    case templateNotFound
    case userNotFound
    
    // Generic not found with message
    case notFound(String)
    
    // Data issues
    case invalidData
    case dataCorruption(String)
    
    // Network and external errors
    case networkError(Error)
    case firestoreError(Error)
    
    // Access control
    case unauthorized
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found"
        case .collectionNotFound:
            return "Collection not found"
        case .templateNotFound:
            return "Template not found"
        case .userNotFound:
            return "User not found"
        case .notFound(let message):
            return "Not found: \(message)"
        case .invalidData:
            return "Invalid data format"
        case .dataCorruption(let message):
            return "Data corruption: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .firestoreError(let error):
            return "Database error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimited:
            return "Rate limited. Please try again later."
        }
    }
}
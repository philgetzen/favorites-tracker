import Foundation
import FirebaseFirestore

// MARK: - Firestore Data Transfer Objects (DTOs)

/// Firestore DTO for User documents
/// Collection: users/{userId}
struct UserDTO: Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String? // URL stored as string in Firestore
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let isEmailVerified: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, email, displayName, photoURL, createdAt, updatedAt, isEmailVerified
    }
}

/// Firestore DTO for UserProfile documents
/// Collection: users/{userId}/profile/{profileId}
struct UserProfileDTO: Codable {
    let id: String
    let userId: String
    let displayName: String
    let bio: String?
    let profileImageURL: String? // URL stored as string
    let preferences: UserPreferencesDTO
    let subscription: SubscriptionInfoDTO?
    let createdAt: Timestamp
    let updatedAt: Timestamp
}

/// Firestore DTO for UserPreferences (embedded document)
struct UserPreferencesDTO: Codable {
    let theme: String // Enum stored as string
    let notifications: NotificationPreferencesDTO
    let privacy: PrivacyPreferencesDTO
}

/// Firestore DTO for NotificationPreferences (embedded document)
struct NotificationPreferencesDTO: Codable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let reminderEnabled: Bool
}

/// Firestore DTO for PrivacyPreferences (embedded document)
struct PrivacyPreferencesDTO: Codable {
    let profilePublic: Bool
    let collectionsPublic: Bool
    let analyticsEnabled: Bool
}

/// Firestore DTO for SubscriptionInfo (embedded document)
struct SubscriptionInfoDTO: Codable {
    let isActive: Bool
    let plan: String // Enum stored as string
    let startDate: Timestamp
    let expiryDate: Timestamp
    let autoRenew: Bool
}

/// Firestore DTO for Collection documents
/// Collection: users/{userId}/collections/{collectionId}
struct CollectionDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let templateId: String?
    let itemCount: Int
    let coverImageURL: String? // URL stored as string
    let isFavorite: Bool
    let tags: [String]
    let isPublic: Bool
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    // Fields for Firestore indexing and querying
    let searchTerms: [String] // Lowercase name + tags for text search
}

/// Firestore DTO for Item documents
/// Collection: users/{userId}/collections/{collectionId}/items/{itemId}
struct ItemDTO: Codable {
    let id: String
    let userId: String
    let collectionId: String
    let name: String
    let description: String?
    let imageURLs: [String] // URLs stored as strings
    let customFields: [String: CustomFieldValueDTO]
    let isFavorite: Bool
    let tags: [String]
    let location: LocationDTO?
    let rating: Double?
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    // Fields for Firestore indexing and querying
    let searchTerms: [String] // Lowercase name + tags for text search
}

/// Firestore DTO for CustomFieldValue (embedded document)
struct CustomFieldValueDTO: Codable {
    let type: String // "text", "number", "date", "boolean", "url"
    let stringValue: String? // All values stored as strings for consistency
    let numberValue: Double?
    let dateValue: Timestamp?
    let booleanValue: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case type, stringValue, numberValue, dateValue, booleanValue
    }
}

/// Firestore DTO for Location (embedded document)
struct LocationDTO: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let name: String?
    
    // GeoPoint for Firestore geo queries
    var geoPoint: GeoPoint {
        return GeoPoint(latitude: latitude, longitude: longitude)
    }
}

/// Firestore DTO for Template documents
/// Collection: templates/{templateId} (Global collection for marketplace)
struct TemplateDTO: Codable {
    let id: String
    let creatorId: String
    let name: String
    let description: String
    let category: String
    let components: [ComponentDefinitionDTO]
    let previewImageURL: String? // URL stored as string
    let isFavorite: Bool
    let tags: [String]
    let isPublic: Bool
    let isPremium: Bool
    let downloadCount: Int
    let rating: Double?
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    // Fields for Firestore indexing and querying
    let searchTerms: [String] // Lowercase name + tags + category for text search
    let creatorDisplayName: String? // Denormalized for display without additional query
}

/// Firestore DTO for ComponentDefinition (embedded document)
struct ComponentDefinitionDTO: Codable {
    let id: String
    let type: String // ComponentType enum stored as string
    let label: String
    let isRequired: Bool
    let defaultValue: CustomFieldValueDTO?
    let options: [String]?
    let validation: ValidationRuleDTO?
}

/// Firestore DTO for ValidationRule (embedded document)
struct ValidationRuleDTO: Codable {
    let minLength: Int?
    let maxLength: Int?
    let pattern: String? // Regex pattern as string
}

// MARK: - Firestore Collection Names and Paths

/// Constants for Firestore collection names and document paths
enum FirestoreCollection {
    static let users = "users"
    static let profiles = "profile"
    static let collections = "collections"
    static let items = "items"
    static let templates = "templates"
    
    /// Collection group names for cross-collection queries
    enum Groups {
        static let items = "items"
        static let collections = "collections"
    }
    
    /// Document path builders
    enum Paths {
        static func user(_ userId: String) -> String {
            return "\(users)/\(userId)"
        }
        
        static func userProfile(_ userId: String, profileId: String) -> String {
            return "\(users)/\(userId)/\(profiles)/\(profileId)"
        }
        
        static func userCollection(_ userId: String, collectionId: String) -> String {
            return "\(users)/\(userId)/\(collections)/\(collectionId)"
        }
        
        static func collectionItem(_ userId: String, collectionId: String, itemId: String) -> String {
            return "\(users)/\(userId)/\(collections)/\(collectionId)/\(items)/\(itemId)"
        }
        
        static func template(_ templateId: String) -> String {
            return "\(templates)/\(templateId)"
        }
    }
}

// MARK: - Firestore Document Size Limits

/// Firestore constraints and limits
enum FirestoreConstraints {
    /// Maximum document size (1MB)
    static let maxDocumentSize = 1_048_576
    
    /// Maximum array elements
    static let maxArrayElements = 20_000
    
    /// Maximum nested depth
    static let maxNestedDepth = 20
    
    /// Maximum field name length
    static let maxFieldNameLength = 1500
    
    /// Photo limits
    enum PhotoLimits {
        static let freeUser = 5
        static let premiumUser = 10
    }
    
    /// Text field limits
    enum TextLimits {
        static let name = 255
        static let description = 2000
        static let bio = 2000
        static let customFieldValue = 1000
    }
}

// MARK: - Firestore Index Configuration

/// Index requirements for efficient queries
enum FirestoreIndexes {
    /// Composite indexes required for common query patterns
    static let compositeIndexes = [
        // User collections ordered by update time
        CompositeIndex(
            collection: FirestoreCollection.collections,
            fields: [("userId", false), ("updatedAt", true)]
        ),
        
        // Favorite items across collections
        CompositeIndex(
            collection: FirestoreCollection.Groups.items,
            fields: [("userId", false), ("isFavorite", false), ("updatedAt", true)]
        ),
        
        // Public templates by category and popularity
        CompositeIndex(
            collection: FirestoreCollection.templates,
            fields: [("isPublic", false), ("category", false), ("downloadCount", true)]
        ),
        
        // Items by collection and creation date
        CompositeIndex(
            collection: FirestoreCollection.Groups.items,
            fields: [("collectionId", false), ("createdAt", true)]
        ),
        
        // Templates by creator and public status
        CompositeIndex(
            collection: FirestoreCollection.templates,
            fields: [("creatorId", false), ("isPublic", false), ("updatedAt", true)]
        ),
        
        // Search functionality
        CompositeIndex(
            collection: FirestoreCollection.templates,
            fields: [("isPublic", false), ("searchTerms", false), ("downloadCount", true)]
        )
    ]
    
    /// Single field indexes (automatically created by Firestore for most fields)
    static let singleFieldIndexes = [
        "userId", "createdAt", "updatedAt", "isFavorite", "isPublic", "category", "tags"
    ]
}

/// Composite index definition
struct CompositeIndex {
    let collection: String
    let fields: [(String, Bool)] // (fieldName, descending)
}
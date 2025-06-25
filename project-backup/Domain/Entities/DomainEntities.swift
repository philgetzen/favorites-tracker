import Foundation

// MARK: - Core Domain Entities

/// User entity for authentication and profile management
struct User: Entity, Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: URL?
    let createdAt: Date
    let updatedAt: Date
    let isEmailVerified: Bool
    
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// User profile entity for extended user information
struct UserProfile: Entity, Codable {
    let id: String
    let userId: String
    let displayName: String
    let bio: String?
    let profileImageURL: URL?
    let preferences: UserPreferences
    let subscription: SubscriptionInfo?
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, displayName: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.displayName = displayName
        self.bio = nil
        self.profileImageURL = nil
        self.preferences = UserPreferences()
        self.subscription = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// User preferences for app configuration
struct UserPreferences: Codable {
    let theme: Theme
    let notifications: NotificationSettings
    let privacy: PrivacySettings
    
    init() {
        self.theme = .system
        self.notifications = NotificationSettings()
        self.privacy = PrivacySettings()
    }
    
    enum Theme: String, Codable, CaseIterable {
        case light, dark, system
    }
}

/// Notification settings
struct NotificationSettings: Codable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let reminderEnabled: Bool
    
    init() {
        self.pushEnabled = true
        self.emailEnabled = true
        self.reminderEnabled = true
    }
}

/// Privacy settings
struct PrivacySettings: Codable {
    let profilePublic: Bool
    let collectionsPublic: Bool
    let analyticsEnabled: Bool
    
    init() {
        self.profilePublic = false
        self.collectionsPublic = false
        self.analyticsEnabled = true
    }
}

/// Subscription information
struct SubscriptionInfo: Codable {
    let plan: SubscriptionPlan
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    
    enum SubscriptionPlan: String, Codable {
        case free, premium
    }
    
    enum SubscriptionStatus: String, Codable {
        case active, expired, cancelled, trial
    }
}

/// Collection entity for grouping items
struct Collection: Entity, Codable, Favoritable, Taggable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let templateId: String?
    let itemCount: Int
    let coverImageURL: URL?
    var isFavorite: Bool
    var tags: [String]
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, name: String, templateId: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.name = name
        self.description = nil
        self.templateId = templateId
        self.itemCount = 0
        self.coverImageURL = nil
        self.isFavorite = false
        self.tags = []
        self.isPublic = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Item entity for individual trackable items
struct Item: Entity, Codable, Favoritable, Taggable {
    let id: String
    let userId: String
    let collectionId: String
    let name: String
    let description: String?
    let imageURLs: [URL]
    let customFields: [String: CustomFieldValue]
    var isFavorite: Bool
    var tags: [String]
    let location: Location?
    let rating: Double?
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, collectionId: String, name: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.collectionId = collectionId
        self.name = name
        self.description = nil
        self.imageURLs = []
        self.customFields = [:]
        self.isFavorite = false
        self.tags = []
        self.location = nil
        self.rating = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Template entity for collection templates
struct Template: Entity, Codable, Favoritable, Taggable {
    let id: String
    let creatorId: String
    let name: String
    let description: String
    let category: String
    let components: [ComponentDefinition]
    let previewImageURL: URL?
    var isFavorite: Bool
    var tags: [String]
    let isPublic: Bool
    let isPremium: Bool
    let downloadCount: Int
    let rating: Double?
    let createdAt: Date
    let updatedAt: Date
    
    init(creatorId: String, name: String, description: String, category: String) {
        self.id = UUID().uuidString
        self.creatorId = creatorId
        self.name = name
        self.description = description
        self.category = category
        self.components = []
        self.previewImageURL = nil
        self.isFavorite = false
        self.tags = []
        self.isPublic = false
        self.isPremium = false
        self.downloadCount = 0
        self.rating = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supporting Types

/// Location information for items
struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let name: String?
}

/// Custom field value types
enum CustomFieldValue: Codable {
    case text(String)
    case number(Double)
    case date(Date)
    case boolean(Bool)
    case url(URL)
    case image(URL)
    
    var stringValue: String {
        switch self {
        case .text(let value): return value
        case .number(let value): return String(value)
        case .date(let value): return ISO8601DateFormatter().string(from: value)
        case .boolean(let value): return String(value)
        case .url(let value): return value.absoluteString
        case .image(let value): return value.absoluteString
        }
    }
}

/// Component definition for templates
struct ComponentDefinition: Codable {
    let id: String
    let type: ComponentType
    let label: String
    let isRequired: Bool
    let defaultValue: CustomFieldValue?
    let options: [String]?
    let validation: ValidationRule?
    
    enum ComponentType: String, Codable {
        case textField, textArea, numberField, dateField, toggle, picker, rating, image, location
    }
}

/// Validation rules for components
struct ValidationRule: Codable {
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let pattern: String?
    let required: Bool
}
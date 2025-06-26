import Foundation

// MARK: - Core Domain Entities

/// User entity for authentication and profile management
struct User: Entity, Codable, Sendable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: URL?
    let createdAt: Date
    let updatedAt: Date
    let isEmailVerified: Bool
    
    // Minimal initializer for new users
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Complete initializer for Firestore data restoration
    init(id: String, email: String, displayName: String?, photoURL: URL?, createdAt: Date, updatedAt: Date, isEmailVerified: Bool) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isEmailVerified = isEmailVerified
    }
}

/// User profile entity for extended user information
struct UserProfile: Entity, Codable, Sendable {
    let id: String
    let userId: String
    let displayName: String
    let bio: String?
    let profileImageURL: URL?
    let preferences: UserPreferences
    let subscription: SubscriptionInfo?
    let createdAt: Date
    let updatedAt: Date
    
    // Minimal initializer for new profiles
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
    
    // Complete initializer for Firestore data restoration
    init(id: String, userId: String, displayName: String, bio: String?, profileImageURL: URL?, preferences: UserPreferences, subscription: SubscriptionInfo?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.preferences = preferences
        self.subscription = subscription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// User preferences for app configuration
struct UserPreferences: Codable, Sendable {
    let theme: Theme
    let notifications: NotificationSettings
    let privacy: PrivacySettings
    
    // Default initializer
    init() {
        self.theme = .system
        self.notifications = NotificationSettings()
        self.privacy = PrivacySettings()
    }
    
    // Complete initializer for Firestore data restoration
    init(theme: Theme, notifications: NotificationSettings, privacy: PrivacySettings) {
        self.theme = theme
        self.notifications = notifications
        self.privacy = privacy
    }
    
    enum Theme: String, Codable, CaseIterable {
        case light, dark, system
    }
}

/// Notification settings
struct NotificationSettings: Codable, Sendable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let reminderEnabled: Bool
    
    // Default initializer
    init() {
        self.pushEnabled = true
        self.emailEnabled = true
        self.reminderEnabled = true
    }
    
    // Complete initializer for Firestore data restoration
    init(pushEnabled: Bool, emailEnabled: Bool, reminderEnabled: Bool) {
        self.pushEnabled = pushEnabled
        self.emailEnabled = emailEnabled
        self.reminderEnabled = reminderEnabled
    }
}

/// Privacy settings
struct PrivacySettings: Codable, Sendable {
    let profilePublic: Bool
    let collectionsPublic: Bool
    let analyticsEnabled: Bool
    
    // Default initializer
    init() {
        self.profilePublic = false
        self.collectionsPublic = false
        self.analyticsEnabled = true
    }
    
    // Complete initializer for Firestore data restoration
    init(profilePublic: Bool, collectionsPublic: Bool, analyticsEnabled: Bool) {
        self.profilePublic = profilePublic
        self.collectionsPublic = collectionsPublic
        self.analyticsEnabled = analyticsEnabled
    }
}

/// Subscription information
struct SubscriptionInfo: Codable, Sendable {
    let plan: SubscriptionPlan
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    
    // Complete initializer for Firestore data restoration
    init(plan: SubscriptionPlan, status: SubscriptionStatus, startDate: Date, endDate: Date?, autoRenew: Bool) {
        self.plan = plan
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.autoRenew = autoRenew
    }
    
    enum SubscriptionPlan: String, Codable {
        case free, premium
    }
    
    enum SubscriptionStatus: String, Codable {
        case active, expired, cancelled, trial
    }
}

/// Collection entity for grouping items
struct Collection: Entity, Codable, Sendable, Favoritable, Taggable {
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
    
    // Minimal initializer for new collections
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
    
    // Complete initializer for Firestore data restoration
    init(id: String, userId: String, name: String, description: String?, templateId: String?, itemCount: Int, coverImageURL: URL?, isFavorite: Bool, tags: [String], isPublic: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.templateId = templateId
        self.itemCount = itemCount
        self.coverImageURL = coverImageURL
        self.isFavorite = isFavorite
        self.tags = tags
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Item entity for individual trackable items
struct Item: Entity, Codable, Sendable, Favoritable, Taggable {
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
    
    // Minimal initializer for new items
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
    
    // Complete initializer for Firestore data restoration
    init(id: String, userId: String, collectionId: String, name: String, description: String?, imageURLs: [URL], customFields: [String: CustomFieldValue], isFavorite: Bool, tags: [String], location: Location?, rating: Double?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.collectionId = collectionId
        self.name = name
        self.description = description
        self.imageURLs = imageURLs
        self.customFields = customFields
        self.isFavorite = isFavorite
        self.tags = tags
        self.location = location
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Template entity for collection templates
struct Template: Entity, Codable, Sendable, Favoritable, Taggable {
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
    
    // Minimal initializer for new templates
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
    
    // Complete initializer for Firestore data restoration
    init(id: String, creatorId: String, name: String, description: String, category: String, components: [ComponentDefinition], previewImageURL: URL?, isFavorite: Bool, tags: [String], isPublic: Bool, isPremium: Bool, downloadCount: Int, rating: Double?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.creatorId = creatorId
        self.name = name
        self.description = description
        self.category = category
        self.components = components
        self.previewImageURL = previewImageURL
        self.isFavorite = isFavorite
        self.tags = tags
        self.isPublic = isPublic
        self.isPremium = isPremium
        self.downloadCount = downloadCount
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Types

/// Location information for items
struct Location: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let name: String?
}

/// Custom field value types
enum CustomFieldValue: Codable, Sendable, Equatable {
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
struct ComponentDefinition: Codable, Sendable {
    let id: String
    let type: ComponentType
    let label: String
    let isRequired: Bool
    let defaultValue: CustomFieldValue?
    let options: [String]?
    let validation: ValidationRule?
    
    // Complete initializer
    init(id: String, type: ComponentType, label: String, isRequired: Bool, defaultValue: CustomFieldValue? = nil, options: [String]? = nil, validation: ValidationRule? = nil) {
        self.id = id
        self.type = type
        self.label = label
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.options = options
        self.validation = validation
    }
    
    enum ComponentType: String, Codable {
        case textField, textArea, numberField, dateField, toggle, picker, rating, image, location
    }
}

/// Validation rules for components
struct ValidationRule: Codable, Sendable {
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let pattern: String?
    let required: Bool
    
    // Complete initializer
    init(minLength: Int? = nil, maxLength: Int? = nil, minValue: Double? = nil, maxValue: Double? = nil, pattern: String? = nil, required: Bool = false) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.minValue = minValue
        self.maxValue = maxValue
        self.pattern = pattern
        self.required = required
    }
}
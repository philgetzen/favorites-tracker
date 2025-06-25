import Foundation
import FirebaseFirestore

// MARK: - Domain to Firestore Mapping

/// Protocol for mapping between domain entities and Firestore DTOs
protocol FirestoreMapper {
    associatedtype DomainType
    associatedtype FirestoreType
    
    static func toFirestore(_ domain: DomainType) -> FirestoreType
    static func toDomain(_ firestore: FirestoreType) -> DomainType
}

// MARK: - User Mapping

struct UserMapper: FirestoreMapper {
    typealias DomainType = User
    typealias FirestoreType = UserDTO
    
    static func toFirestore(_ domain: User) -> UserDTO {
        return UserDTO(
            id: domain.id,
            email: domain.email,
            displayName: domain.displayName,
            photoURL: domain.photoURL?.absoluteString,
            createdAt: Timestamp(date: domain.createdAt),
            updatedAt: Timestamp(date: domain.updatedAt),
            isEmailVerified: domain.isEmailVerified
        )
    }
    
    static func toDomain(_ firestore: UserDTO) -> User {
        return User(
            id: firestore.id,
            email: firestore.email,
            displayName: firestore.displayName,
            photoURL: firestore.photoURL.flatMap { URL(string: $0) },
            createdAt: firestore.createdAt.dateValue(),
            updatedAt: firestore.updatedAt.dateValue(),
            isEmailVerified: firestore.isEmailVerified
        )
    }
}

// MARK: - UserProfile Mapping

struct UserProfileMapper: FirestoreMapper {
    typealias DomainType = UserProfile
    typealias FirestoreType = UserProfileDTO
    
    static func toFirestore(_ domain: UserProfile) -> UserProfileDTO {
        return UserProfileDTO(
            id: domain.id,
            userId: domain.userId,
            displayName: domain.displayName,
            bio: domain.bio,
            profileImageURL: domain.profileImageURL?.absoluteString,
            preferences: UserPreferencesMapper.toFirestore(domain.preferences),
            subscription: domain.subscription.map { SubscriptionInfoMapper.toFirestore($0) },
            createdAt: Timestamp(date: domain.createdAt),
            updatedAt: Timestamp(date: domain.updatedAt)
        )
    }
    
    static func toDomain(_ firestore: UserProfileDTO) -> UserProfile {
        return UserProfile(
            id: firestore.id,
            userId: firestore.userId,
            displayName: firestore.displayName,
            bio: firestore.bio,
            profileImageURL: firestore.profileImageURL.flatMap { URL(string: $0) },
            preferences: UserPreferencesMapper.toDomain(firestore.preferences),
            subscription: firestore.subscription.map { SubscriptionInfoMapper.toDomain($0) },
            createdAt: firestore.createdAt.dateValue(),
            updatedAt: firestore.updatedAt.dateValue()
        )
    }
}

// MARK: - UserPreferences Mapping

struct UserPreferencesMapper: FirestoreMapper {
    typealias DomainType = UserPreferences
    typealias FirestoreType = UserPreferencesDTO
    
    static func toFirestore(_ domain: UserPreferences) -> UserPreferencesDTO {
        return UserPreferencesDTO(
            theme: domain.theme.rawValue,
            notifications: NotificationPreferencesMapper.toFirestore(domain.notifications),
            privacy: PrivacyPreferencesMapper.toFirestore(domain.privacy)
        )
    }
    
    static func toDomain(_ firestore: UserPreferencesDTO) -> UserPreferences {
        return UserPreferences(
            theme: UserPreferences.Theme(rawValue: firestore.theme) ?? .system,
            notifications: NotificationPreferencesMapper.toDomain(firestore.notifications),
            privacy: PrivacyPreferencesMapper.toDomain(firestore.privacy)
        )
    }
}

// MARK: - NotificationPreferences Mapping

struct NotificationPreferencesMapper: FirestoreMapper {
    typealias DomainType = NotificationSettings
    typealias FirestoreType = NotificationPreferencesDTO
    
    static func toFirestore(_ domain: NotificationSettings) -> NotificationPreferencesDTO {
        return NotificationPreferencesDTO(
            pushEnabled: domain.pushEnabled,
            emailEnabled: domain.emailEnabled,
            reminderEnabled: domain.reminderEnabled
        )
    }
    
    static func toDomain(_ firestore: NotificationPreferencesDTO) -> NotificationSettings {
        return NotificationSettings(
            pushEnabled: firestore.pushEnabled,
            emailEnabled: firestore.emailEnabled,
            reminderEnabled: firestore.reminderEnabled
        )
    }
}

// MARK: - PrivacyPreferences Mapping

struct PrivacyPreferencesMapper: FirestoreMapper {
    typealias DomainType = PrivacySettings
    typealias FirestoreType = PrivacyPreferencesDTO
    
    static func toFirestore(_ domain: PrivacySettings) -> PrivacyPreferencesDTO {
        return PrivacyPreferencesDTO(
            profilePublic: domain.profilePublic,
            collectionsPublic: domain.collectionsPublic,
            analyticsEnabled: domain.analyticsEnabled
        )
    }
    
    static func toDomain(_ firestore: PrivacyPreferencesDTO) -> PrivacySettings {
        return PrivacySettings(
            profilePublic: firestore.profilePublic,
            collectionsPublic: firestore.collectionsPublic,
            analyticsEnabled: firestore.analyticsEnabled
        )
    }
}

// MARK: - SubscriptionInfo Mapping

struct SubscriptionInfoMapper: FirestoreMapper {
    typealias DomainType = SubscriptionInfo
    typealias FirestoreType = SubscriptionInfoDTO
    
    static func toFirestore(_ domain: SubscriptionInfo) -> SubscriptionInfoDTO {
        return SubscriptionInfoDTO(
            isActive: domain.status == .active,
            plan: domain.plan.rawValue,
            startDate: Timestamp(date: domain.startDate),
            expiryDate: Timestamp(date: domain.endDate ?? Date()),
            autoRenew: domain.autoRenew
        )
    }
    
    static func toDomain(_ firestore: SubscriptionInfoDTO) -> SubscriptionInfo {
        return SubscriptionInfo(
            plan: SubscriptionInfo.SubscriptionPlan(rawValue: firestore.plan) ?? .free,
            status: firestore.isActive ? .active : .expired,
            startDate: firestore.startDate.dateValue(),
            endDate: firestore.expiryDate.dateValue(),
            autoRenew: firestore.autoRenew
        )
    }
}

// MARK: - Collection Mapping

struct CollectionMapper: FirestoreMapper {
    typealias DomainType = Collection
    typealias FirestoreType = CollectionDTO
    
    static func toFirestore(_ domain: Collection) -> CollectionDTO {
        return CollectionDTO(
            id: domain.id,
            userId: domain.userId,
            name: domain.name,
            description: domain.description,
            templateId: domain.templateId,
            itemCount: domain.itemCount,
            coverImageURL: domain.coverImageURL?.absoluteString,
            isFavorite: domain.isFavorite,
            tags: domain.tags,
            isPublic: domain.isPublic,
            createdAt: Timestamp(date: domain.createdAt),
            updatedAt: Timestamp(date: domain.updatedAt),
            searchTerms: generateSearchTerms(name: domain.name, tags: domain.tags)
        )
    }
    
    static func toDomain(_ firestore: CollectionDTO) -> Collection {
        return Collection(
            id: firestore.id,
            userId: firestore.userId,
            name: firestore.name,
            description: firestore.description,
            templateId: firestore.templateId,
            itemCount: firestore.itemCount,
            coverImageURL: firestore.coverImageURL.flatMap { URL(string: $0) },
            isFavorite: firestore.isFavorite,
            tags: firestore.tags,
            isPublic: firestore.isPublic,
            createdAt: firestore.createdAt.dateValue(),
            updatedAt: firestore.updatedAt.dateValue()
        )
    }
}

// MARK: - Item Mapping

struct ItemMapper: FirestoreMapper {
    typealias DomainType = Item
    typealias FirestoreType = ItemDTO
    
    static func toFirestore(_ domain: Item) -> ItemDTO {
        return ItemDTO(
            id: domain.id,
            userId: domain.userId,
            collectionId: domain.collectionId,
            name: domain.name,
            description: domain.description,
            imageURLs: domain.imageURLs.map { $0.absoluteString },
            customFields: domain.customFields.mapValues { CustomFieldValueMapper.toFirestore($0) },
            isFavorite: domain.isFavorite,
            tags: domain.tags,
            location: domain.location.map { LocationMapper.toFirestore($0) },
            rating: domain.rating,
            createdAt: Timestamp(date: domain.createdAt),
            updatedAt: Timestamp(date: domain.updatedAt),
            searchTerms: generateSearchTerms(name: domain.name, tags: domain.tags)
        )
    }
    
    static func toDomain(_ firestore: ItemDTO) -> Item {
        return Item(
            id: firestore.id,
            userId: firestore.userId,
            collectionId: firestore.collectionId,
            name: firestore.name,
            description: firestore.description,
            imageURLs: firestore.imageURLs.compactMap { URL(string: $0) },
            customFields: firestore.customFields.mapValues { CustomFieldValueMapper.toDomain($0) },
            isFavorite: firestore.isFavorite,
            tags: firestore.tags,
            location: firestore.location.map { LocationMapper.toDomain($0) },
            rating: firestore.rating,
            createdAt: firestore.createdAt.dateValue(),
            updatedAt: firestore.updatedAt.dateValue()
        )
    }
}

// MARK: - CustomFieldValue Mapping

struct CustomFieldValueMapper: FirestoreMapper {
    typealias DomainType = CustomFieldValue
    typealias FirestoreType = CustomFieldValueDTO
    
    static func toFirestore(_ domain: CustomFieldValue) -> CustomFieldValueDTO {
        switch domain {
        case .text(let value):
            return CustomFieldValueDTO(
                type: "text",
                stringValue: value,
                numberValue: nil,
                dateValue: nil,
                booleanValue: nil
            )
        case .number(let value):
            return CustomFieldValueDTO(
                type: "number",
                stringValue: String(value),
                numberValue: value,
                dateValue: nil,
                booleanValue: nil
            )
        case .date(let value):
            return CustomFieldValueDTO(
                type: "date",
                stringValue: ISO8601DateFormatter().string(from: value),
                numberValue: nil,
                dateValue: Timestamp(date: value),
                booleanValue: nil
            )
        case .boolean(let value):
            return CustomFieldValueDTO(
                type: "boolean",
                stringValue: String(value),
                numberValue: nil,
                dateValue: nil,
                booleanValue: value
            )
        case .url(let value):
            return CustomFieldValueDTO(
                type: "url",
                stringValue: value.absoluteString,
                numberValue: nil,
                dateValue: nil,
                booleanValue: nil
            )
        case .image(let value):
            return CustomFieldValueDTO(
                type: "image",
                stringValue: value.absoluteString,
                numberValue: nil,
                dateValue: nil,
                booleanValue: nil
            )
        }
    }
    
    static func toDomain(_ firestore: CustomFieldValueDTO) -> CustomFieldValue {
        switch firestore.type {
        case "text":
            return .text(firestore.stringValue ?? "")
        case "number":
            return .number(firestore.numberValue ?? 0.0)
        case "date":
            return .date(firestore.dateValue?.dateValue() ?? Date())
        case "boolean":
            return .boolean(firestore.booleanValue ?? false)
        case "url":
            let url = URL(string: firestore.stringValue ?? "") ?? URL(string: "https://example.com")!
            return .url(url)
        case "image":
            let url = URL(string: firestore.stringValue ?? "") ?? URL(string: "https://example.com/image.jpg")!
            return .image(url)
        default:
            return .text("")
        }
    }
}

// MARK: - Location Mapping

struct LocationMapper: FirestoreMapper {
    typealias DomainType = Location
    typealias FirestoreType = LocationDTO
    
    static func toFirestore(_ domain: Location) -> LocationDTO {
        return LocationDTO(
            latitude: domain.latitude,
            longitude: domain.longitude,
            address: domain.address,
            name: domain.name
        )
    }
    
    static func toDomain(_ firestore: LocationDTO) -> Location {
        return Location(
            latitude: firestore.latitude,
            longitude: firestore.longitude,
            address: firestore.address,
            name: firestore.name
        )
    }
}

// MARK: - Template Mapping

struct TemplateMapper: FirestoreMapper {
    typealias DomainType = Template
    typealias FirestoreType = TemplateDTO
    
    static func toFirestore(_ domain: Template) -> TemplateDTO {
        return toFirestore(domain, creatorDisplayName: nil)
    }
    
    static func toFirestore(_ domain: Template, creatorDisplayName: String? = nil) -> TemplateDTO {
        return TemplateDTO(
            id: domain.id,
            creatorId: domain.creatorId,
            name: domain.name,
            description: domain.description,
            category: domain.category,
            components: domain.components.map { ComponentDefinitionMapper.toFirestore($0) },
            previewImageURL: domain.previewImageURL?.absoluteString,
            isFavorite: domain.isFavorite,
            tags: domain.tags,
            isPublic: domain.isPublic,
            isPremium: domain.isPremium,
            downloadCount: domain.downloadCount,
            rating: domain.rating,
            createdAt: Timestamp(date: domain.createdAt),
            updatedAt: Timestamp(date: domain.updatedAt),
            searchTerms: generateSearchTerms(name: domain.name, tags: domain.tags, category: domain.category),
            creatorDisplayName: creatorDisplayName
        )
    }
    
    static func toDomain(_ firestore: TemplateDTO) -> Template {
        return Template(
            id: firestore.id,
            creatorId: firestore.creatorId,
            name: firestore.name,
            description: firestore.description,
            category: firestore.category,
            components: firestore.components.map { ComponentDefinitionMapper.toDomain($0) },
            previewImageURL: firestore.previewImageURL.flatMap { URL(string: $0) },
            isFavorite: firestore.isFavorite,
            tags: firestore.tags,
            isPublic: firestore.isPublic,
            isPremium: firestore.isPremium,
            downloadCount: firestore.downloadCount,
            rating: firestore.rating,
            createdAt: firestore.createdAt.dateValue(),
            updatedAt: firestore.updatedAt.dateValue()
        )
    }
}

// MARK: - ComponentDefinition Mapping

struct ComponentDefinitionMapper: FirestoreMapper {
    typealias DomainType = ComponentDefinition
    typealias FirestoreType = ComponentDefinitionDTO
    
    static func toFirestore(_ domain: ComponentDefinition) -> ComponentDefinitionDTO {
        return ComponentDefinitionDTO(
            id: domain.id,
            type: domain.type.rawValue,
            label: domain.label,
            isRequired: domain.isRequired,
            defaultValue: domain.defaultValue.map { CustomFieldValueMapper.toFirestore($0) },
            options: domain.options,
            validation: domain.validation.map { ValidationRuleMapper.toFirestore($0) }
        )
    }
    
    static func toDomain(_ firestore: ComponentDefinitionDTO) -> ComponentDefinition {
        return ComponentDefinition(
            id: firestore.id,
            type: ComponentDefinition.ComponentType(rawValue: firestore.type) ?? .textField,
            label: firestore.label,
            isRequired: firestore.isRequired,
            defaultValue: firestore.defaultValue.flatMap { CustomFieldValueMapper.toDomain($0) },
            options: firestore.options,
            validation: firestore.validation.map { ValidationRuleMapper.toDomain($0) }
        )
    }
}

// MARK: - ValidationRule Mapping

struct ValidationRuleMapper: FirestoreMapper {
    typealias DomainType = ValidationRule
    typealias FirestoreType = ValidationRuleDTO
    
    static func toFirestore(_ domain: ValidationRule) -> ValidationRuleDTO {
        return ValidationRuleDTO(
            minLength: domain.minLength,
            maxLength: domain.maxLength,
            pattern: domain.pattern
        )
    }
    
    static func toDomain(_ firestore: ValidationRuleDTO) -> ValidationRule {
        return ValidationRule(
            minLength: firestore.minLength,
            maxLength: firestore.maxLength,
            minValue: nil,
            maxValue: nil,
            pattern: firestore.pattern,
            required: false
        )
    }
}

// MARK: - Helper Functions

/// Generate search terms for Firestore text search
private func generateSearchTerms(name: String, tags: [String], category: String? = nil) -> [String] {
    var searchTerms: [String] = []
    
    // Add lowercased name words
    searchTerms.append(contentsOf: name.lowercased().components(separatedBy: .whitespacesAndNewlines))
    
    // Add lowercased tags
    searchTerms.append(contentsOf: tags.map { $0.lowercased() })
    
    // Add category if provided
    if let category = category {
        searchTerms.append(category.lowercased())
    }
    
    // Remove duplicates and empty strings
    return Array(Set(searchTerms.filter { !$0.isEmpty }))
}

// MARK: - Batch Mapping Utilities

/// Utilities for batch operations and mapping collections
enum FirestoreBatchMapper {
    
    /// Map array of domain entities to Firestore DTOs
    static func toFirestore<T: FirestoreMapper>(_ domains: [T.DomainType], using mapper: T.Type) -> [T.FirestoreType] {
        return domains.map { mapper.toFirestore($0) }
    }
    
    /// Map array of Firestore DTOs to domain entities
    static func toDomain<T: FirestoreMapper>(_ firestoreDTOs: [T.FirestoreType], using mapper: T.Type) -> [T.DomainType] {
        return firestoreDTOs.map { mapper.toDomain($0) }
    }
    
    /// Map array of Firestore DTOs to domain entities with optional filtering
    static func toDomainFiltered<T: FirestoreMapper>(_ firestoreDTOs: [T.FirestoreType], using mapper: T.Type, filter: (T.DomainType) -> Bool) -> [T.DomainType] {
        return firestoreDTOs.map { mapper.toDomain($0) }.filter(filter)
    }
}
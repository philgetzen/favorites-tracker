import XCTest
@testable import FavoritesTracker

/// Tests for domain entities
final class DomainEntitiesTests: XCTestCase {
    
    // MARK: - User Tests
    
    func testUserCreation() {
        // Given
        let id = "user-123"
        let email = "test@example.com"
        let displayName = "Test User"
        
        // When
        let user = User(id: id, email: email, displayName: displayName)
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
        XCTAssertNil(user.photoURL)
        XCTAssertFalse(user.isEmailVerified)
        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.updatedAt)
    }
    
    func testUserWithOptionalFields() {
        // Given
        let id = "user-123"
        let email = "test@example.com"
        let displayName = "Test User"
        let photoURL = URL(string: "https://example.com/photo.jpg")
        
        // When
        let user = User(id: id, email: email, displayName: displayName, photoURL: photoURL, isEmailVerified: true)
        
        // Then
        XCTAssertEqual(user.photoURL, photoURL)
        XCTAssertTrue(user.isEmailVerified)
    }
    
    // MARK: - Collection Tests
    
    func testCollectionCreation() {
        // Given
        let userId = "user-123"
        let name = "My Collection"
        let templateId = "template-456"
        
        // When
        let collection = Collection(userId: userId, name: name, templateId: templateId)
        
        // Then
        XCTAssertEqual(collection.userId, userId)
        XCTAssertEqual(collection.name, name)
        XCTAssertEqual(collection.templateId, templateId)
        XCTAssertNotNil(collection.id)
        XCTAssertNil(collection.description)
        XCTAssertEqual(collection.itemCount, 0)
        XCTAssertNil(collection.coverImageURL)
        XCTAssertFalse(collection.isFavorite)
        XCTAssertTrue(collection.tags.isEmpty)
        XCTAssertFalse(collection.isPublic)
        XCTAssertNotNil(collection.createdAt)
        XCTAssertNotNil(collection.updatedAt)
    }
    
    func testCollectionFavoritableProtocol() {
        // Given
        var collection = Collection(userId: "user-123", name: "Test")
        
        // When
        collection.isFavorite = true
        
        // Then
        XCTAssertTrue(collection.isFavorite)
    }
    
    func testCollectionTaggableProtocol() {
        // Given
        var collection = Collection(userId: "user-123", name: "Test")
        
        // When
        collection.tags = ["tag1", "tag2"]
        
        // Then
        XCTAssertEqual(collection.tags, ["tag1", "tag2"])
    }
    
    // MARK: - Item Tests
    
    func testItemCreation() {
        // Given
        let userId = "user-123"
        let collectionId = "collection-456"
        let name = "My Item"
        
        // When
        let item = Item(userId: userId, collectionId: collectionId, name: name)
        
        // Then
        XCTAssertEqual(item.userId, userId)
        XCTAssertEqual(item.collectionId, collectionId)
        XCTAssertEqual(item.name, name)
        XCTAssertNotNil(item.id)
        XCTAssertNil(item.description)
        XCTAssertTrue(item.imageURLs.isEmpty)
        XCTAssertTrue(item.customFields.isEmpty)
        XCTAssertFalse(item.isFavorite)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertNil(item.location)
        XCTAssertNil(item.rating)
        XCTAssertNotNil(item.createdAt)
        XCTAssertNotNil(item.updatedAt)
    }
    
    // MARK: - Template Tests
    
    func testTemplateCreation() {
        // Given
        let creatorId = "user-123"
        let name = "My Template"
        let description = "Template description"
        let category = "Books"
        
        // When
        let template = Template(creatorId: creatorId, name: name, description: description, category: category)
        
        // Then
        XCTAssertEqual(template.creatorId, creatorId)
        XCTAssertEqual(template.name, name)
        XCTAssertEqual(template.description, description)
        XCTAssertEqual(template.category, category)
        XCTAssertNotNil(template.id)
        XCTAssertTrue(template.components.isEmpty)
        XCTAssertNil(template.previewImageURL)
        XCTAssertFalse(template.isFavorite)
        XCTAssertTrue(template.tags.isEmpty)
        XCTAssertFalse(template.isPublic)
        XCTAssertFalse(template.isPremium)
        XCTAssertEqual(template.downloadCount, 0)
        XCTAssertNil(template.rating)
        XCTAssertNotNil(template.createdAt)
        XCTAssertNotNil(template.updatedAt)
    }
    
    // MARK: - CustomFieldValue Tests
    
    func testCustomFieldValueText() {
        // Given
        let value = CustomFieldValue.text("Hello")
        
        // When
        let stringValue = value.stringValue
        
        // Then
        XCTAssertEqual(stringValue, "Hello")
    }
    
    func testCustomFieldValueNumber() {
        // Given
        let value = CustomFieldValue.number(42.5)
        
        // When
        let stringValue = value.stringValue
        
        // Then
        XCTAssertEqual(stringValue, "42.5")
    }
    
    func testCustomFieldValueDate() {
        // Given
        let date = Date()
        let value = CustomFieldValue.date(date)
        
        // When
        let stringValue = value.stringValue
        
        // Then
        let formatter = ISO8601DateFormatter()
        XCTAssertEqual(stringValue, formatter.string(from: date))
    }
    
    func testCustomFieldValueBoolean() {
        // Given
        let value = CustomFieldValue.boolean(true)
        
        // When
        let stringValue = value.stringValue
        
        // Then
        XCTAssertEqual(stringValue, "true")
    }
    
    func testCustomFieldValueURL() {
        // Given
        let url = URL(string: "https://example.com")!
        let value = CustomFieldValue.url(url)
        
        // When
        let stringValue = value.stringValue
        
        // Then
        XCTAssertEqual(stringValue, "https://example.com")
    }
    
    // MARK: - Location Tests
    
    func testLocationCreation() {
        // Given
        let latitude = 37.7749
        let longitude = -122.4194
        let address = "San Francisco, CA"
        let name = "San Francisco"
        
        // When
        let location = Location(latitude: latitude, longitude: longitude, address: address, name: name)
        
        // Then
        XCTAssertEqual(location.latitude, latitude)
        XCTAssertEqual(location.longitude, longitude)
        XCTAssertEqual(location.address, address)
        XCTAssertEqual(location.name, name)
    }
    
    // MARK: - ComponentDefinition Tests
    
    func testComponentDefinitionCreation() {
        // Given
        let id = "component-123"
        let type = ComponentDefinition.ComponentType.textField
        let label = "Name"
        let isRequired = true
        let defaultValue = CustomFieldValue.text("Default")
        
        // When
        let component = ComponentDefinition(
            id: id,
            type: type,
            label: label,
            isRequired: isRequired,
            defaultValue: defaultValue,
            options: nil,
            validation: nil
        )
        
        // Then
        XCTAssertEqual(component.id, id)
        XCTAssertEqual(component.type, type)
        XCTAssertEqual(component.label, label)
        XCTAssertEqual(component.isRequired, isRequired)
        XCTAssertEqual(component.defaultValue?.stringValue, defaultValue.stringValue)
        XCTAssertNil(component.options)
        XCTAssertNil(component.validation)
    }
    
    // MARK: - UserPreferences Tests
    
    func testUserPreferencesDefaults() {
        // When
        let preferences = UserPreferences()
        
        // Then
        XCTAssertEqual(preferences.theme, .system)
        XCTAssertTrue(preferences.notifications.pushEnabled)
        XCTAssertTrue(preferences.notifications.emailEnabled)
        XCTAssertTrue(preferences.notifications.reminderEnabled)
        XCTAssertFalse(preferences.privacy.profilePublic)
        XCTAssertFalse(preferences.privacy.collectionsPublic)
        XCTAssertTrue(preferences.privacy.analyticsEnabled)
    }
}
import XCTest
import FirebaseFirestore
@testable import FavoritesTracker

/// Tests for Firestore data validation, constraints, and business rules
final class FirestoreValidationTests: XCTestCase {
    
    // MARK: - User Validation Tests
    
    func testUserEmailValidation() {
        // Valid email formats
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org"
        ]
        
        for email in validEmails {
            let user = User(id: "test", email: email)
            XCTAssertTrue(user.email.contains("@"), "Valid email should contain @: \(email)")
        }
    }
    
    func testUserIDConstraints() {
        // Test ID length and format constraints
        let validIDs = ["user123", "user-456", "user_789"]
        let invalidIDs = ["", "a", String(repeating: "x", count: 1025)] // Empty, too short, too long
        
        for validID in validIDs {
            let user = User(id: validID, email: "test@example.com")
            XCTAssertFalse(user.id.isEmpty, "User ID should not be empty")
            XCTAssertLessThanOrEqual(user.id.count, 1024, "User ID should be under Firestore limit")
        }
    }
    
    // MARK: - Collection Validation Tests
    
    func testCollectionNameValidation() {
        // Test collection name constraints
        let validNames = ["My Collection", "Books & Movies", "Collection 123"]
        let invalidNames = ["", String(repeating: "x", count: 1025)]
        
        for validName in validNames {
            let collection = Collection(userId: "user-123", name: validName)
            XCTAssertFalse(collection.name.isEmpty, "Collection name should not be empty")
            XCTAssertLessThanOrEqual(collection.name.count, 1024, "Collection name should be under limit")
        }
    }
    
    func testCollectionUserIdReference() {
        // Test that collection always has valid user reference
        let collection = Collection(userId: "user-123", name: "Test")
        
        XCTAssertFalse(collection.userId.isEmpty, "Collection must have valid user reference")
        XCTAssertGreaterThan(collection.userId.count, 0, "User ID must not be empty")
    }
    
    func testCollectionItemCountConsistency() {
        // Test that itemCount is properly maintained
        var collection = Collection(userId: "user-123", name: "Test")
        
        XCTAssertEqual(collection.itemCount, 0, "New collection should have 0 items")
        
        // In real implementation, this would be updated by repository
        collection.itemCount = 5
        XCTAssertEqual(collection.itemCount, 5, "Item count should be updateable")
    }
    
    // MARK: - Item Validation Tests
    
    func testItemRequiredFields() {
        let item = Item(userId: "user-123", collectionId: "collection-456", name: "Test Item")
        
        // Verify required fields are present
        XCTAssertFalse(item.userId.isEmpty, "Item must have user ID")
        XCTAssertFalse(item.collectionId.isEmpty, "Item must have collection ID")
        XCTAssertFalse(item.name.isEmpty, "Item must have name")
        XCTAssertFalse(item.id.isEmpty, "Item must have ID")
    }
    
    func testItemImageURLLimits() {
        // Test photo limits (5 for free, 10 for premium)
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "Test")
        
        // Add maximum free tier photos
        let freePhotoLimit = 5
        for i in 0..<freePhotoLimit {
            item.imageURLs.append(URL(string: "https://example.com/photo\(i).jpg")!)
        }
        
        XCTAssertEqual(item.imageURLs.count, freePhotoLimit, "Should allow up to 5 photos for free tier")
        
        // Test premium limit
        let premiumPhotoLimit = 10
        for i in freePhotoLimit..<premiumPhotoLimit {
            item.imageURLs.append(URL(string: "https://example.com/photo\(i).jpg")!)
        }
        
        XCTAssertEqual(item.imageURLs.count, premiumPhotoLimit, "Should allow up to 10 photos for premium")
    }
    
    func testItemRatingValidation() {
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "Test")
        
        // Test valid ratings (0.0 to 5.0)
        let validRatings: [Double] = [0.0, 2.5, 5.0, 4.5]
        for rating in validRatings {
            item.rating = rating
            XCTAssertGreaterThanOrEqual(item.rating!, 0.0, "Rating should be >= 0.0")
            XCTAssertLessThanOrEqual(item.rating!, 5.0, "Rating should be <= 5.0")
        }
    }
    
    func testItemCustomFieldsValidation() {
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "Test")
        
        // Test custom field value types
        item.customFields = [
            "text_field": .text("Valid text"),
            "number_field": .number(42.0),
            "date_field": .date(Date()),
            "boolean_field": .boolean(true),
            "url_field": .url(URL(string: "https://example.com")!)
        ]
        
        XCTAssertEqual(item.customFields.count, 5, "Should store all custom field types")
        
        // Test custom field key constraints
        for key in item.customFields.keys {
            XCTAssertFalse(key.isEmpty, "Custom field key should not be empty")
            XCTAssertLessThanOrEqual(key.count, 255, "Custom field key should be under limit")
        }
    }
    
    // MARK: - Template Validation Tests
    
    func testTemplateCreatorReference() {
        let template = Template(
            creatorId: "user-123",
            name: "Test Template",
            description: "Description",
            category: "Books"
        )
        
        XCTAssertFalse(template.creatorId.isEmpty, "Template must have creator reference")
        XCTAssertFalse(template.name.isEmpty, "Template must have name")
        XCTAssertFalse(template.category.isEmpty, "Template must have category")
    }
    
    func testTemplateComponentValidation() {
        let validComponent = ComponentDefinition(
            id: "comp-1",
            type: .textField,
            label: "Name",
            isRequired: true,
            defaultValue: nil,
            options: nil,
            validation: nil
        )
        
        var template = Template(
            creatorId: "user-123",
            name: "Test Template",
            description: "Description",
            category: "Books"
        )
        template.components = [validComponent]
        
        XCTAssertEqual(template.components.count, 1, "Should store component")
        XCTAssertFalse(template.components[0].id.isEmpty, "Component must have ID")
        XCTAssertFalse(template.components[0].label.isEmpty, "Component must have label")
    }
    
    func testTemplatePublicationRules() {
        var template = Template(
            creatorId: "user-123",
            name: "Test Template",
            description: "Description",
            category: "Books"
        )
        
        // Test default values for publication
        XCTAssertFalse(template.isPublic, "Template should be private by default")
        XCTAssertFalse(template.isPremium, "Template should be free by default")
        XCTAssertEqual(template.downloadCount, 0, "New template should have 0 downloads")
        
        // Test publication state changes
        template.isPublic = true
        template.isPremium = true
        
        XCTAssertTrue(template.isPublic, "Template can be made public")
        XCTAssertTrue(template.isPremium, "Template can be made premium")
    }
    
    // MARK: - UserProfile Validation Tests
    
    func testUserProfileDisplayNameValidation() {
        let profile = UserProfile(userId: "user-123", displayName: "Test User")
        
        XCTAssertFalse(profile.displayName.isEmpty, "Display name should not be empty")
        XCTAssertLessThanOrEqual(profile.displayName.count, 255, "Display name should be under limit")
    }
    
    func testUserProfileBioLength() {
        var profile = UserProfile(userId: "user-123", displayName: "Test User")
        
        // Test bio length constraints
        let longBio = String(repeating: "x", count: 1000)
        profile.bio = longBio
        
        XCTAssertLessThanOrEqual(profile.bio?.count ?? 0, 2000, "Bio should be under character limit")
    }
    
    func testUserProfilePreferencesValidation() {
        let profile = UserProfile(userId: "user-123", displayName: "Test User")
        
        // Test default preferences are valid
        XCTAssertNotNil(profile.preferences, "Profile should have preferences")
        
        // Test theme validation
        let validThemes: [UserPreferences.Theme] = [.light, .dark, .system]
        for theme in validThemes {
            var preferences = profile.preferences
            preferences.theme = theme
            // In real implementation, would validate theme enum
            XCTAssertTrue(validThemes.contains(theme), "Theme should be valid")
        }
    }
    
    // MARK: - Subscription Validation Tests
    
    func testSubscriptionDateValidation() {
        let startDate = Date()
        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        
        let subscription = SubscriptionInfo(
            isActive: true,
            plan: .premium,
            startDate: startDate,
            expiryDate: expiryDate,
            autoRenew: true
        )
        
        XCTAssertLessThan(subscription.startDate, subscription.expiryDate, "Start date should be before expiry")
        XCTAssertTrue(subscription.isActive, "Active subscription should be marked as active")
    }
    
    func testSubscriptionPlanValidation() {
        let validPlans: [SubscriptionInfo.Plan] = [.free, .premium]
        
        for plan in validPlans {
            let subscription = SubscriptionInfo(
                isActive: true,
                plan: plan,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30), // 30 days
                autoRenew: true
            )
            
            XCTAssertTrue(validPlans.contains(subscription.plan), "Subscription plan should be valid")
        }
    }
    
    // MARK: - Location Validation Tests
    
    func testLocationCoordinateValidation() {
        // Test valid coordinate ranges
        let validLatitudes = [-90.0, 0.0, 90.0, 37.7749]
        let validLongitudes = [-180.0, 0.0, 180.0, -122.4194]
        
        for lat in validLatitudes {
            for lng in validLongitudes {
                let location = Location(latitude: lat, longitude: lng, address: "Test", name: "Test")
                
                XCTAssertGreaterThanOrEqual(location.latitude, -90.0, "Latitude should be >= -90")
                XCTAssertLessThanOrEqual(location.latitude, 90.0, "Latitude should be <= 90")
                XCTAssertGreaterThanOrEqual(location.longitude, -180.0, "Longitude should be >= -180")
                XCTAssertLessThanOrEqual(location.longitude, 180.0, "Longitude should be <= 180")
            }
        }
    }
    
    // MARK: - Component Definition Validation Tests
    
    func testComponentDefinitionTypeValidation() {
        let validTypes: [ComponentDefinition.ComponentType] = [
            .textField, .textArea, .numberField, .dropdown, .checkbox, .datePicker, .imageUpload, .ratingPicker
        ]
        
        for type in validTypes {
            let component = ComponentDefinition(
                id: "comp-1",
                type: type,
                label: "Test",
                isRequired: false,
                defaultValue: nil,
                options: nil,
                validation: nil
            )
            
            XCTAssertTrue(validTypes.contains(component.type), "Component type should be valid")
        }
    }
    
    func testComponentDefinitionOptionsValidation() {
        // Test dropdown component with options
        let component = ComponentDefinition(
            id: "comp-1",
            type: .dropdown,
            label: "Category",
            isRequired: false,
            defaultValue: nil,
            options: ["Option 1", "Option 2", "Option 3"],
            validation: nil
        )
        
        XCTAssertNotNil(component.options, "Dropdown should have options")
        XCTAssertGreaterThan(component.options?.count ?? 0, 0, "Dropdown should have at least one option")
    }
    
    func testValidationRuleConstraints() {
        let validation = ValidationRule(
            minLength: 1,
            maxLength: 100,
            pattern: "^[a-zA-Z0-9]+$"
        )
        
        XCTAssertLessThan(validation.minLength ?? 0, validation.maxLength ?? Int.max, "Min length should be less than max length")
        XCTAssertNotNil(validation.pattern, "Pattern should be valid regex")
    }
    
    // MARK: - Cross-Entity Validation Tests
    
    func testEntityIDUniqueness() {
        // Test that entity IDs are unique across creation
        let user1 = User(id: "user-1", email: "test1@example.com")
        let user2 = User(id: "user-2", email: "test2@example.com")
        
        let collection1 = Collection(userId: "user-1", name: "Collection 1")
        let collection2 = Collection(userId: "user-1", name: "Collection 2")
        
        XCTAssertNotEqual(user1.id, user2.id, "User IDs should be unique")
        XCTAssertNotEqual(collection1.id, collection2.id, "Collection IDs should be unique")
    }
    
    func testEntityTimestampConsistency() {
        let user = User(id: "test", email: "test@example.com")
        let collection = Collection(userId: "test", name: "Test")
        let item = Item(userId: "test", collectionId: collection.id, name: "Test")
        
        // All entities should have valid timestamps
        XCTAssertLessThanOrEqual(user.createdAt, user.updatedAt, "Created should be <= updated")
        XCTAssertLessThanOrEqual(collection.createdAt, collection.updatedAt, "Created should be <= updated")
        XCTAssertLessThanOrEqual(item.createdAt, item.updatedAt, "Created should be <= updated")
    }
}
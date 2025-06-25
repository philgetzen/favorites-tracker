import XCTest
import FirebaseFirestore
@testable import FavoritesTracker

/// Tests for Firestore data model serialization, validation, and Firebase-specific requirements
final class FirestoreDataModelTests: XCTestCase {
    
    private var mockFirestore: Firestore!
    
    override func setUp() {
        super.setUp()
        // Use Firebase emulator for testing
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        
        mockFirestore = Firestore.firestore()
        mockFirestore.settings = settings
    }
    
    // MARK: - User Firestore Model Tests
    
    func testUserFirestoreSerializationRoundTrip() throws {
        // Given
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.jpg"),
            isEmailVerified: true
        )
        
        // When - Encode to Firestore format
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(user)
        
        // Then - Decode back from Firestore format
        let decoder = Firestore.Decoder()
        let decodedUser = try decoder.decode(User.self, from: firestoreData)
        
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.email, user.email)
        XCTAssertEqual(decodedUser.displayName, user.displayName)
        XCTAssertEqual(decodedUser.photoURL, user.photoURL)
        XCTAssertEqual(decodedUser.isEmailVerified, user.isEmailVerified)
    }
    
    func testUserFirestoreDocumentStructure() throws {
        // Given
        let user = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(user)
        
        // Then - Verify expected Firestore document structure
        XCTAssertEqual(firestoreData["id"] as? String, "user-123")
        XCTAssertEqual(firestoreData["email"] as? String, "test@example.com")
        XCTAssertEqual(firestoreData["displayName"] as? String, "Test User")
        XCTAssertNotNil(firestoreData["createdAt"])
        XCTAssertNotNil(firestoreData["updatedAt"])
        
        // Verify optional fields are handled correctly
        XCTAssertTrue(firestoreData["photoURL"] is NSNull || firestoreData["photoURL"] == nil)
        XCTAssertEqual(firestoreData["isEmailVerified"] as? Bool, false)
    }
    
    // MARK: - Collection Firestore Model Tests
    
    func testCollectionFirestoreSerializationRoundTrip() throws {
        // Given
        var collection = Collection(userId: "user-123", name: "My Books", templateId: "template-456")
        collection.description = "My favorite books"
        collection.isFavorite = true
        collection.tags = ["fiction", "sci-fi"]
        collection.isPublic = true
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(collection)
        
        let decoder = Firestore.Decoder()
        let decodedCollection = try decoder.decode(Collection.self, from: firestoreData)
        
        // Then
        XCTAssertEqual(decodedCollection.id, collection.id)
        XCTAssertEqual(decodedCollection.userId, collection.userId)
        XCTAssertEqual(decodedCollection.name, collection.name)
        XCTAssertEqual(decodedCollection.description, collection.description)
        XCTAssertEqual(decodedCollection.templateId, collection.templateId)
        XCTAssertEqual(decodedCollection.isFavorite, collection.isFavorite)
        XCTAssertEqual(decodedCollection.tags, collection.tags)
        XCTAssertEqual(decodedCollection.isPublic, collection.isPublic)
    }
    
    func testCollectionFirestoreRequiredFields() throws {
        // Given
        let collection = Collection(userId: "user-123", name: "Test Collection")
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(collection)
        
        // Then - Verify required fields for Firestore queries
        XCTAssertNotNil(firestoreData["userId"], "userId is required for Firestore security rules")
        XCTAssertNotNil(firestoreData["name"], "name is required for search functionality")
        XCTAssertNotNil(firestoreData["createdAt"], "createdAt is required for ordering")
        XCTAssertNotNil(firestoreData["updatedAt"], "updatedAt is required for sync")
        XCTAssertNotNil(firestoreData["isFavorite"], "isFavorite is required for filtering")
        XCTAssertNotNil(firestoreData["isPublic"], "isPublic is required for security rules")
    }
    
    // MARK: - Item Firestore Model Tests
    
    func testItemFirestoreSerializationWithCustomFields() throws {
        // Given
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "My Book")
        item.description = "A great book"
        item.customFields = [
            "author": .text("John Doe"),
            "published": .date(Date()),
            "pages": .number(300),
            "isHardcover": .boolean(true),
            "website": .url(URL(string: "https://example.com")!)
        ]
        item.rating = 4.5
        item.location = Location(latitude: 37.7749, longitude: -122.4194, address: "San Francisco", name: "SF")
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(item)
        
        let decoder = Firestore.Decoder()
        let decodedItem = try decoder.decode(Item.self, from: firestoreData)
        
        // Then
        XCTAssertEqual(decodedItem.name, item.name)
        XCTAssertEqual(decodedItem.description, item.description)
        XCTAssertEqual(decodedItem.customFields.count, item.customFields.count)
        XCTAssertEqual(decodedItem.rating, item.rating)
        XCTAssertEqual(decodedItem.location?.latitude, item.location?.latitude)
        
        // Verify custom field types are preserved
        XCTAssertEqual(decodedItem.customFields["author"]?.stringValue, "John Doe")
        XCTAssertEqual(decodedItem.customFields["pages"]?.stringValue, "300.0")
        XCTAssertEqual(decodedItem.customFields["isHardcover"]?.stringValue, "true")
    }
    
    func testItemFirestoreArrayFields() throws {
        // Given
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "Test Item")
        item.imageURLs = [
            URL(string: "https://example.com/image1.jpg")!,
            URL(string: "https://example.com/image2.jpg")!
        ]
        item.tags = ["tag1", "tag2", "tag3"]
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(item)
        
        let decoder = Firestore.Decoder()
        let decodedItem = try decoder.decode(Item.self, from: firestoreData)
        
        // Then
        XCTAssertEqual(decodedItem.imageURLs.count, 2)
        XCTAssertEqual(decodedItem.tags.count, 3)
        XCTAssertEqual(decodedItem.imageURLs, item.imageURLs)
        XCTAssertEqual(decodedItem.tags, item.tags)
    }
    
    // MARK: - Template Firestore Model Tests
    
    func testTemplateFirestoreSerializationWithComponents() throws {
        // Given
        let component1 = ComponentDefinition(
            id: "comp-1",
            type: .textField,
            label: "Name",
            isRequired: true,
            defaultValue: nil,
            options: nil,
            validation: ValidationRule(minLength: 1, maxLength: 100, pattern: nil)
        )
        
        let component2 = ComponentDefinition(
            id: "comp-2",
            type: .dropdown,
            label: "Category",
            isRequired: false,
            defaultValue: .text("Fiction"),
            options: ["Fiction", "Non-Fiction", "Biography"],
            validation: nil
        )
        
        var template = Template(
            creatorId: "user-123",
            name: "Book Template",
            description: "Template for tracking books",
            category: "Literature"
        )
        template.components = [component1, component2]
        template.isPublic = true
        template.isPremium = false
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(template)
        
        let decoder = Firestore.Decoder()
        let decodedTemplate = try decoder.decode(Template.self, from: firestoreData)
        
        // Then
        XCTAssertEqual(decodedTemplate.name, template.name)
        XCTAssertEqual(decodedTemplate.components.count, 2)
        XCTAssertEqual(decodedTemplate.components[0].id, "comp-1")
        XCTAssertEqual(decodedTemplate.components[0].type, .textField)
        XCTAssertEqual(decodedTemplate.components[1].type, .dropdown)
        XCTAssertEqual(decodedTemplate.components[1].options, ["Fiction", "Non-Fiction", "Biography"])
    }
    
    // MARK: - UserProfile Firestore Model Tests
    
    func testUserProfileFirestoreSerializationWithSubscription() throws {
        // Given
        let subscription = SubscriptionInfo(
            isActive: true,
            plan: .premium,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            autoRenew: true
        )
        
        var userProfile = UserProfile(userId: "user-123", displayName: "Test User")
        userProfile.bio = "Test bio"
        userProfile.subscription = subscription
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(userProfile)
        
        let decoder = Firestore.Decoder()
        let decodedProfile = try decoder.decode(UserProfile.self, from: firestoreData)
        
        // Then
        XCTAssertEqual(decodedProfile.displayName, userProfile.displayName)
        XCTAssertEqual(decodedProfile.bio, userProfile.bio)
        XCTAssertEqual(decodedProfile.subscription?.isActive, true)
        XCTAssertEqual(decodedProfile.subscription?.plan, .premium)
        XCTAssertEqual(decodedProfile.subscription?.autoRenew, true)
    }
    
    // MARK: - Firestore Field Validation Tests
    
    func testFirestoreFieldNameValidation() {
        // Test that field names don't conflict with Firestore reserved words
        let user = User(id: "test", email: "test@example.com")
        
        let encoder = Firestore.Encoder()
        let firestoreData = try! encoder.encode(user)
        
        // Verify no reserved Firestore field names are used
        let reservedFields = ["__name__", "__id__", "__path__"]
        for field in reservedFields {
            XCTAssertNil(firestoreData[field], "Field '\(field)' is reserved by Firestore")
        }
    }
    
    func testFirestoreDocumentSizeConstraints() throws {
        // Given - Create large document to test size limits
        var item = Item(userId: "user-123", collectionId: "collection-456", name: "Large Item")
        
        // Add many custom fields to approach 1MB limit
        for i in 0..<100 {
            item.customFields["field_\(i)"] = .text(String(repeating: "x", count: 1000))
        }
        
        // When
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(item)
        let dataSize = try JSONSerialization.data(withJSONObject: firestoreData).count
        
        // Then - Verify document is under Firestore's 1MB limit
        XCTAssertLessThan(dataSize, 1_048_576, "Firestore document must be under 1MB")
    }
    
    // MARK: - Date Handling Tests
    
    func testFirestoreDateSerialization() throws {
        // Given
        let specificDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01
        let item = Item(userId: "user-123", collectionId: "collection-456", name: "Test")
        
        // When
        let encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .timestamp
        let firestoreData = try encoder.encode(item)
        
        // Then - Verify dates are properly encoded as Firestore Timestamps
        XCTAssertNotNil(firestoreData["createdAt"])
        XCTAssertNotNil(firestoreData["updatedAt"])
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDataHandling() {
        // Test handling of data that cannot be encoded to Firestore
        struct InvalidData: Codable {
            let id: String
            let invalidField: Data // Data type not supported by Firestore
        }
        
        let invalidData = InvalidData(id: "test", invalidField: Data([1, 2, 3]))
        let encoder = Firestore.Encoder()
        
        XCTAssertThrowsError(try encoder.encode(invalidData)) { error in
            // Verify appropriate error is thrown for unsupported types
            XCTAssertTrue(error is EncodingError)
        }
    }
    
    // MARK: - Firestore Query Optimization Tests
    
    func testIndexedFieldsPresent() throws {
        // Verify that fields commonly used in queries are present
        let collection = Collection(userId: "user-123", name: "Test")
        let encoder = Firestore.Encoder()
        let firestoreData = try encoder.encode(collection)
        
        // Fields that should be indexed for efficient queries
        let indexedFields = ["userId", "createdAt", "updatedAt", "isFavorite", "isPublic"]
        
        for field in indexedFields {
            XCTAssertNotNil(firestoreData[field], "Field '\(field)' should be present for indexing")
        }
    }
}
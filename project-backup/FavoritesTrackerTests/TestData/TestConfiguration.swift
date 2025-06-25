import Foundation
@testable import FavoritesTracker

/// Test configuration and sample data
struct TestConfiguration {
    
    /// Test environment setup
    static func configureTestEnvironment() {
        // Configure test-specific settings
        UserDefaults.standard.set(true, forKey: "IS_TESTING")
        
        // Disable animations for faster testing
        UIView.setAnimationsEnabled(false)
        
        // Set up test logging
        print("🧪 Test environment configured")
    }
    
    /// Clean up test environment
    static func cleanupTestEnvironment() {
        UserDefaults.standard.removeObject(forKey: "IS_TESTING")
        UIView.setAnimationsEnabled(true)
        print("🧪 Test environment cleaned up")
    }
}

/// Sample test data for consistent testing
struct TestData {
    
    // MARK: - User Data
    
    static let sampleUsers: [User] = [
        User(id: "user-1", email: "alice@example.com", displayName: "Alice Smith"),
        User(id: "user-2", email: "bob@example.com", displayName: "Bob Johnson"),
        User(id: "user-3", email: "carol@example.com", displayName: "Carol Williams")
    ]
    
    static var defaultUser: User {
        return sampleUsers[0]
    }
    
    // MARK: - Collection Data
    
    static let sampleCollections: [Collection] = [
        Collection(userId: "user-1", name: "My Books", templateId: "template-books"),
        Collection(userId: "user-1", name: "Wine Collection", templateId: "template-wine"),
        Collection(userId: "user-2", name: "Board Games", templateId: "template-games")
    ]
    
    static var defaultCollection: Collection {
        return sampleCollections[0]
    }
    
    // MARK: - Item Data
    
    static let sampleItems: [Item] = [
        Item(userId: "user-1", collectionId: "collection-1", name: "The Great Gatsby"),
        Item(userId: "user-1", collectionId: "collection-1", name: "To Kill a Mockingbird"),
        Item(userId: "user-1", collectionId: "collection-2", name: "Chateau Margaux 2010"),
        Item(userId: "user-2", collectionId: "collection-3", name: "Settlers of Catan")
    ]
    
    static var defaultItem: Item {
        return sampleItems[0]
    }
    
    // MARK: - Template Data
    
    static let sampleTemplates: [Template] = [
        Template(creatorId: "user-1", name: "Book Collection", description: "Track your favorite books", category: "Literature"),
        Template(creatorId: "user-1", name: "Wine Cellar", description: "Manage your wine collection", category: "Food & Drink"),
        Template(creatorId: "user-2", name: "Board Game Library", description: "Catalog your board games", category: "Games")
    ]
    
    static var defaultTemplate: Template {
        return sampleTemplates[0]
    }
    
    // MARK: - Component Data
    
    static let sampleComponents: [ComponentDefinition] = [
        ComponentDefinition(
            id: "comp-title",
            type: .textField,
            label: "Title",
            isRequired: true,
            defaultValue: nil,
            options: nil,
            validation: ValidationRule(minLength: 1, maxLength: 100, minValue: nil, maxValue: nil, pattern: nil, required: true)
        ),
        ComponentDefinition(
            id: "comp-rating",
            type: .rating,
            label: "Rating",
            isRequired: false,
            defaultValue: CustomFieldValue.number(0),
            options: nil,
            validation: ValidationRule(minLength: nil, maxLength: nil, minValue: 0, maxValue: 5, pattern: nil, required: false)
        ),
        ComponentDefinition(
            id: "comp-notes",
            type: .textArea,
            label: "Notes",
            isRequired: false,
            defaultValue: nil,
            options: nil,
            validation: ValidationRule(minLength: nil, maxLength: 500, minValue: nil, maxValue: nil, pattern: nil, required: false)
        ),
        ComponentDefinition(
            id: "comp-category",
            type: .picker,
            label: "Category",
            isRequired: true,
            defaultValue: nil,
            options: ["Fiction", "Non-Fiction", "Biography", "Science"],
            validation: ValidationRule(minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, required: true)
        )
    ]
    
    // MARK: - Custom Field Data
    
    static let sampleCustomFields: [String: CustomFieldValue] = [
        "title": .text("Sample Book Title"),
        "author": .text("Sample Author"),
        "rating": .number(4.5),
        "pages": .number(320),
        "published": .date(Date()),
        "read": .boolean(true),
        "website": .url(URL(string: "https://example.com")!),
        "cover": .image(URL(string: "https://example.com/cover.jpg")!)
    ]
    
    // MARK: - Location Data
    
    static let sampleLocations: [Location] = [
        Location(latitude: 37.7749, longitude: -122.4194, address: "San Francisco, CA", name: "San Francisco"),
        Location(latitude: 40.7128, longitude: -74.0060, address: "New York, NY", name: "New York City"),
        Location(latitude: 34.0522, longitude: -118.2437, address: "Los Angeles, CA", name: "Los Angeles")
    ]
    
    // MARK: - Error Test Data
    
    enum TestErrorCases {
        static let networkError = NSError(domain: "TestNetworkError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])
        static let authenticationError = NSError(domain: "TestAuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        static let validationError = NSError(domain: "TestValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid input data"])
        static let notFoundError = NSError(domain: "TestNotFoundError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource not found"])
    }
    
    // MARK: - Test Scenarios
    
    /// Generate a complete test scenario with related data
    static func createTestScenario() -> TestScenario {
        let user = defaultUser
        let collection = defaultCollection
        let items = [defaultItem]
        let template = defaultTemplate
        
        return TestScenario(
            user: user,
            collection: collection,
            items: items,
            template: template
        )
    }
}

/// A complete test scenario with related entities
struct TestScenario {
    let user: User
    let collection: Collection
    let items: [Item]
    let template: Template
    
    /// Create a scenario with custom data
    static func custom(
        user: User? = nil,
        collection: Collection? = nil,
        items: [Item]? = nil,
        template: Template? = nil
    ) -> TestScenario {
        return TestScenario(
            user: user ?? TestData.defaultUser,
            collection: collection ?? TestData.defaultCollection,
            items: items ?? [TestData.defaultItem],
            template: template ?? TestData.defaultTemplate
        )
    }
}

/// Test utilities for common operations
extension TestData {
    
    /// Create a user with random data
    static func randomUser() -> User {
        let id = UUID().uuidString
        let email = "\(id.prefix(8))@example.com"
        let displayName = "Test User \(id.prefix(4))"
        return User(id: id, email: email, displayName: displayName)
    }
    
    /// Create a collection with random data
    static func randomCollection(userId: String? = nil) -> Collection {
        let names = ["Books", "Movies", "Games", "Wines", "Collectibles"]
        let name = names.randomElement()!
        return Collection(userId: userId ?? defaultUser.id, name: name)
    }
    
    /// Create an item with random data
    static func randomItem(userId: String? = nil, collectionId: String? = nil) -> Item {
        let names = ["Item A", "Item B", "Item C", "Special Item", "Rare Find"]
        let name = names.randomElement()!
        return Item(
            userId: userId ?? defaultUser.id,
            collectionId: collectionId ?? defaultCollection.id,
            name: name
        )
    }
}
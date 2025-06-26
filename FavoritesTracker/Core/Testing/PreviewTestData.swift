import Foundation

/// Preview test data helper for SwiftUI previews and development
/// Provides quick access to sample data for UI development
struct PreviewTestData {
    
    // MARK: - Quick Access Sample Data
    
    /// Sample user for previews
    static let sampleUser = User(
        id: "preview-user-1",
        email: "demo@example.com",
        displayName: "Demo User",
        photoURL: URL(string: "https://randomuser.me/api/portraits/men/1.jpg"),
        createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
        updatedAt: Date().addingTimeInterval(-86400 * 1),   // 1 day ago
        isEmailVerified: true
    )
    
    /// Sample user profile for previews
    static let sampleUserProfile = UserProfile(
        id: "preview-profile-1",
        userId: sampleUser.id,
        displayName: "Demo User",
        bio: "Passionate collector and enthusiast exploring various hobbies",
        profileImageURL: sampleUser.photoURL,
        preferences: UserPreferences(
            theme: .system,
            notifications: NotificationSettings(
                pushEnabled: true,
                emailEnabled: true,
                reminderEnabled: true
            ),
            privacy: PrivacySettings(
                profilePublic: true,
                collectionsPublic: true,
                analyticsEnabled: true
            )
        ),
        subscription: SubscriptionInfo(
            plan: .premium,
            status: .active,
            startDate: Date().addingTimeInterval(-86400 * 15),
            endDate: Date().addingTimeInterval(86400 * 350),
            autoRenew: true
        ),
        createdAt: sampleUser.createdAt,
        updatedAt: Date()
    )
    
    /// Sample collections for previews
    static let sampleCollections: [Collection] = [
        Collection(
            id: "preview-collection-1",
            userId: sampleUser.id,
            name: "Wine Collection",
            description: "My favorite wines from around the world",
            templateId: "wine-template-1",
            itemCount: 12,
            coverImageURL: URL(string: "https://picsum.photos/400/300?random=wine"),
            isFavorite: true,
            tags: ["wine", "favorites", "premium"],
            isPublic: true,
            createdAt: Date().addingTimeInterval(-86400 * 20),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Collection(
            id: "preview-collection-2",
            userId: sampleUser.id,
            name: "Board Game Library",
            description: "Strategy games and party favorites",
            templateId: nil,
            itemCount: 8,
            coverImageURL: URL(string: "https://picsum.photos/400/300?random=boardgames"),
            isFavorite: false,
            tags: ["games", "strategy", "family"],
            isPublic: false,
            createdAt: Date().addingTimeInterval(-86400 * 15),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Collection(
            id: "preview-collection-3",
            userId: sampleUser.id,
            name: "Coffee Shops",
            description: "Great coffee spots around the city",
            templateId: "location-template-1",
            itemCount: 15,
            coverImageURL: URL(string: "https://picsum.photos/400/300?random=coffee"),
            isFavorite: true,
            tags: ["coffee", "local", "recommendations"],
            isPublic: true,
            createdAt: Date().addingTimeInterval(-86400 * 10),
            updatedAt: Date()
        )
    ]
    
    /// Sample items for previews
    static let sampleItems: [Item] = [
        Item(
            id: "preview-item-1",
            userId: sampleUser.id,
            collectionId: sampleCollections[0].id,
            name: "2019 Caymus Cabernet Sauvignon",
            description: "Exceptional Napa Valley Cabernet with rich berry flavors and smooth tannins. Perfect for special occasions.",
            imageURLs: [
                URL(string: "https://picsum.photos/400/300?random=wine1")!,
                URL(string: "https://picsum.photos/400/300?random=wine2")!
            ],
            customFields: [
                "vintage": .number(2019),
                "region": .text("Napa Valley"),
                "price_paid": .number(45.99),
                "alcohol_content": .number(14.5),
                "tasting_notes": .text("Rich blackberry, vanilla, and oak")
            ],
            isFavorite: true,
            tags: ["cabernet", "napa", "premium", "favorite"],
            location: Location(
                latitude: 38.2975,
                longitude: -122.4114,
                address: "Napa Valley, CA",
                name: "Caymus Vineyards"
            ),
            rating: 4.5,
            createdAt: Date().addingTimeInterval(-86400 * 18),
            updatedAt: Date().addingTimeInterval(-86400 * 1)
        ),
        Item(
            id: "preview-item-2",
            userId: sampleUser.id,
            collectionId: sampleCollections[1].id,
            name: "Wingspan",
            description: "Beautiful engine-building game about birds. Great artwork and engaging gameplay for 1-5 players.",
            imageURLs: [
                URL(string: "https://picsum.photos/400/300?random=wingspan")!
            ],
            customFields: [
                "min_players": .number(1),
                "max_players": .number(5),
                "play_time": .number(70),
                "complexity": .number(2.4),
                "price_paid": .number(55.00),
                "designer": .text("Elizabeth Hargrave")
            ],
            isFavorite: true,
            tags: ["strategy", "engine-building", "birds", "award-winner"],
            location: nil,
            rating: 5.0,
            createdAt: Date().addingTimeInterval(-86400 * 12),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Item(
            id: "preview-item-3",
            userId: sampleUser.id,
            collectionId: sampleCollections[2].id,
            name: "Blue Bottle Coffee",
            description: "Exceptional single-origin coffee with notes of chocolate and citrus. Great atmosphere for working.",
            imageURLs: [
                URL(string: "https://picsum.photos/400/300?random=bluebottle")!
            ],
            customFields: [
                "coffee_origin": .text("Ethiopia"),
                "roast_level": .text("Medium"),
                "price_range": .text("$$"),
                "wifi_available": .boolean(true),
                "recommended_drink": .text("Single Origin Pour Over")
            ],
            isFavorite: false,
            tags: ["coffee", "single-origin", "work-friendly", "san-francisco"],
            location: Location(
                latitude: 37.7749,
                longitude: -122.4194,
                address: "315 Linden St, San Francisco, CA",
                name: "Blue Bottle Coffee - Hayes Valley"
            ),
            rating: 4.0,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date()
        )
    ]
    
    /// Sample templates for previews
    static let sampleTemplates: [Template] = [
        Template(
            id: "preview-template-1",
            creatorId: sampleUser.id,
            name: "Wine Collection Tracker",
            description: "Perfect template for wine enthusiasts to track their collection with detailed tasting notes and vintage information.",
            category: "Wine Collecting",
            components: [
                ComponentDefinition(
                    id: "comp-1",
                    type: .textField,
                    label: "Wine Name",
                    isRequired: true,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-2",
                    type: .numberField,
                    label: "Vintage Year",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-3",
                    type: .picker,
                    label: "Region",
                    isRequired: false,
                    defaultValue: nil,
                    options: ["Napa Valley", "Bordeaux", "Tuscany", "Burgundy", "Champagne"],
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-4",
                    type: .rating,
                    label: "Rating",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-5",
                    type: .textArea,
                    label: "Tasting Notes",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                )
            ],
            previewImageURL: URL(string: "https://picsum.photos/300/200?random=winetemplate"),
            isFavorite: false,
            tags: ["wine", "collection", "tasting"],
            isPublic: true,
            isPremium: false,
            downloadCount: 234,
            rating: 4.7,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date().addingTimeInterval(-86400 * 5)
        ),
        Template(
            id: "preview-template-2",
            creatorId: "other-user-1",
            name: "Board Game Library",
            description: "Track your board game collection with player counts, complexity ratings, and play time.",
            category: "Board Games",
            components: [
                ComponentDefinition(
                    id: "comp-bg-1",
                    type: .textField,
                    label: "Game Name",
                    isRequired: true,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-bg-2",
                    type: .numberField,
                    label: "Min Players",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-bg-3",
                    type: .numberField,
                    label: "Max Players",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: "comp-bg-4",
                    type: .numberField,
                    label: "Play Time (minutes)",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                )
            ],
            previewImageURL: URL(string: "https://picsum.photos/300/200?random=gametemplate"),
            isFavorite: true,
            tags: ["games", "strategy", "family"],
            isPublic: true,
            isPremium: true,
            downloadCount: 156,
            rating: 4.3,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 7)
        )
    ]
    
    // MARK: - Convenience Methods
    
    /// Returns a complete test data set for previews
    static func completeDataSet() -> TestDataSet {
        return TestDataSet(
            users: [sampleUser],
            userProfiles: [sampleUserProfile],
            collections: sampleCollections,
            items: sampleItems,
            templates: sampleTemplates
        )
    }
    
    /// Returns sample items for a specific collection
    static func sampleItems(for collectionId: String) -> [Item] {
        return sampleItems.filter { $0.collectionId == collectionId }
    }
    
    /// Returns a random sample item
    static func randomSampleItem() -> Item {
        return sampleItems.randomElement() ?? sampleItems[0]
    }
    
    /// Returns sample data for specific hobby categories
    static func sampleData(for category: String) -> (collection: Collection, items: [Item]) {
        switch category.lowercased() {
        case "wine", "wine collecting":
            return (sampleCollections[0], [sampleItems[0]])
        case "board games", "games":
            return (sampleCollections[1], [sampleItems[1]])
        case "coffee", "coffee shops":
            return (sampleCollections[2], [sampleItems[2]])
        default:
            return (sampleCollections[0], [sampleItems[0]])
        }
    }
}

// MARK: - Development Environment Helper

extension PreviewTestData {
    
    /// Generates a larger set of preview data for development
    static func developmentDataSet() -> TestDataSet {
        let generator = TestDataGenerator.self
        
        // Generate a moderate amount of data for development
        let users = generator.generateUsers(count: 5)
        let userProfiles = generator.generateUserProfiles(for: users)
        let collections = generator.generateCollections(for: users, count: 12)
        let items = generator.generateItems(for: collections, itemsPerCollection: 8)
        let templates = generator.generateTemplates(creatorIds: users.map { $0.id }, count: 6)
        
        return TestDataSet(
            users: users,
            userProfiles: userProfiles,
            collections: collections,
            items: items,
            templates: templates
        )
    }
    
    /// Returns edge case data for testing UI robustness
    static func edgeCaseData() -> EdgeCaseTestData {
        return TestDataGenerator.generateEdgeCaseTestData()
    }
}
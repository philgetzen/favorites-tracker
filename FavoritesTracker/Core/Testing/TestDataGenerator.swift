import Foundation
import CoreLocation

/// Comprehensive test data generator for all domain entities
/// Provides realistic sample data across multiple hobby categories
struct TestDataGenerator {
    
    // MARK: - Static Data Collections
    
    private static let userNames = [
        "Alex Johnson", "Sarah Chen", "Mike Rodriguez", "Emma Thompson", "David Kim",
        "Lisa Park", "James Wilson", "Maria Garcia", "Tom Anderson", "Rachel Lee",
        "Chris Martinez", "Jennifer Taylor", "Kevin Brown", "Amy Davis", "Ryan Miller"
    ]
    
    private static let hobbiesWithItems: [String: [String]] = [
        "Wine Collecting": [
            "2019 Cabernet Sauvignon", "2018 Pinot Noir", "2020 Chardonnay", "2017 Merlot",
            "2021 Sauvignon Blanc", "2016 Syrah", "2019 Riesling", "2018 Bordeaux"
        ],
        "Craft Beer": [
            "New England IPA", "Belgian Tripel", "Imperial Stout", "Wheat Beer",
            "Sour Ale", "Porter", "Lager", "Pale Ale", "Double IPA", "Pilsner"
        ],
        "Board Games": [
            "Wingspan", "Azul", "Ticket to Ride", "Catan", "Splendor",
            "7 Wonders", "Pandemic", "Carcassonne", "King of Tokyo", "Dominion"
        ],
        "Books": [
            "The Midnight Library", "Project Hail Mary", "Klara and the Sun", "The Seven Husbands of Evelyn Hugo",
            "Where the Crawdads Sing", "Educated", "Becoming", "The Silent Patient", "Circe"
        ],
        "Movies": [
            "Dune", "Spider-Man: No Way Home", "The Batman", "Top Gun: Maverick",
            "Everything Everywhere All at Once", "Black Panther", "Parasite", "Nomadland"
        ],
        "Restaurants": [
            "Le Bernardin", "Eleven Madison Park", "The French Laundry", "Alinea",
            "Noma", "Osteria Francescana", "El Celler de Can Roca", "Mirazur"
        ],
        "Coffee Shops": [
            "Blue Bottle Coffee", "Stumptown Coffee", "Intelligentsia", "Counter Culture",
            "La Colombe", "Ritual Coffee", "Verve Coffee", "Four Barrel Coffee"
        ],
        "Art Galleries": [
            "MoMA", "The Met", "Guggenheim", "Whitney Museum", "Tate Modern",
            "Centre Pompidou", "Uffizi Gallery", "Louvre Museum"
        ],
        "Video Games": [
            "The Legend of Zelda: Tears of the Kingdom", "Elden Ring", "God of War Ragnarök",
            "Horizon Forbidden West", "Hades", "Ghost of Tsushima", "Cyberpunk 2077"
        ],
        "Podcasts": [
            "This American Life", "Serial", "Radiolab", "99% Invisible", "Reply All",
            "The Daily", "Conan O'Brien Needs a Friend", "WTF with Marc Maron"
        ]
    ]
    
    private static let descriptions = [
        "Absolutely fantastic experience! Highly recommend.",
        "Good quality, though a bit pricey for what you get.",
        "Not bad, but I've had better. Worth trying once.",
        "Exceeded my expectations in every way possible.",
        "Solid choice. Would definitely come back again.",
        "Mixed feelings about this one. Some parts were great.",
        "Outstanding! One of the best I've ever experienced.",
        "Decent, but nothing special. Average experience overall.",
        "Blown away by the quality and attention to detail.",
        "Disappointing. Expected much more based on the reviews."
    ]
    
    private static let tags = [
        "favorite", "recommended", "expensive", "budget-friendly", "unique",
        "classic", "modern", "vintage", "rare", "limited-edition",
        "local", "imported", "organic", "artisanal", "premium",
        "must-try", "overrated", "hidden-gem", "popular", "trending"
    ]
    
    private static let locations = [
        ("New York, NY", 40.7128, -74.0060),
        ("San Francisco, CA", 37.7749, -122.4194),
        ("Los Angeles, CA", 34.0522, -118.2437),
        ("Chicago, IL", 41.8781, -87.6298),
        ("Austin, TX", 30.2672, -97.7431),
        ("Seattle, WA", 47.6062, -122.3321),
        ("Boston, MA", 42.3601, -71.0589),
        ("Portland, OR", 45.5152, -122.6784),
        ("Denver, CO", 39.7392, -104.9903),
        ("Miami, FL", 25.7617, -80.1918)
    ]
    
    // MARK: - User Generation
    
    static func generateUsers(count: Int = 10) -> [User] {
        return (0..<count).map { index in
            let name = userNames[index % userNames.count]
            let photoURL = URL(string: "https://randomuser.me/api/portraits/\(index % 2 == 0 ? "men" : "women")/\(index + 1).jpg")
            return User(
                id: UUID().uuidString,
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                displayName: name,
                photoURL: photoURL,
                createdAt: randomPastDate(),
                updatedAt: randomRecentDate(),
                isEmailVerified: Bool.random()
            )
        }
    }
    
    // MARK: - UserProfile Generation
    
    static func generateUserProfiles(for users: [User]) -> [UserProfile] {
        return users.map { user in
            UserProfile(
                id: UUID().uuidString,
                userId: user.id,
                displayName: user.displayName ?? "User",
                bio: generateBio(),
                profileImageURL: user.photoURL,
                preferences: generateUserPreferences(),
                subscription: Bool.random() ? generateSubscriptionInfo() : nil,
                createdAt: user.createdAt,
                updatedAt: randomRecentDate()
            )
        }
    }
    
    // MARK: - Collection Generation
    
    static func generateCollections(for users: [User], count: Int = 50) -> [Collection] {
        var collections: [Collection] = []
        
        for _ in 0..<count {
            let user = users.randomElement()!
            let hobby = hobbiesWithItems.keys.randomElement()!
            
            let coverImageURL = URL(string: "https://picsum.photos/400/300?random=\(collections.count)")
            let collection = Collection(
                id: UUID().uuidString,
                userId: user.id,
                name: "\(user.displayName ?? "User")'s \(hobby)",
                description: "My curated collection of \(hobby.lowercased()) favorites",
                templateId: Bool.random() ? UUID().uuidString : nil,
                itemCount: Int.random(in: 0...25),
                coverImageURL: coverImageURL,
                isFavorite: Bool.random(),
                tags: generateRandomTags(),
                isPublic: Bool.random(),
                createdAt: randomPastDate(),
                updatedAt: randomRecentDate()
            )
            
            collections.append(collection)
        }
        
        return collections
    }
    
    // MARK: - Item Generation
    
    static func generateItems(for collections: [Collection], itemsPerCollection: Int = 15) -> [Item] {
        var items: [Item] = []
        
        for collection in collections {
            let hobby = extractHobbyFromCollectionName(collection.name)
            let hobbyItems = hobbiesWithItems[hobby] ?? ["Sample Item"]
            
            let itemCount = min(itemsPerCollection, hobbyItems.count)
            let selectedItems = Array(hobbyItems.shuffled().prefix(itemCount))
            
            for itemName in selectedItems {
                let item = Item(
                    id: UUID().uuidString,
                    userId: collection.userId,
                    collectionId: collection.id,
                    name: itemName,
                    description: descriptions.randomElement(),
                    imageURLs: generateImageURLs(),
                    customFields: generateCustomFields(for: hobby),
                    isFavorite: Bool.random(),
                    tags: generateRandomTags(),
                    location: Bool.random() ? generateRandomLocation() : nil,
                    rating: Bool.random() ? Double.random(in: 1.0...5.0) : nil,
                    createdAt: randomPastDate(),
                    updatedAt: randomRecentDate()
                )
                
                items.append(item)
            }
        }
        
        return items
    }
    
    // MARK: - Template Generation
    
    static func generateTemplates(creatorIds: [String], count: Int = 20) -> [Template] {
        let templateCategories = Array(hobbiesWithItems.keys)
        
        return (0..<count).map { index in
            let category = templateCategories[index % templateCategories.count]
            let previewImageURL = URL(string: "https://picsum.photos/300/200?random=template\(index)")
            
            return Template(
                id: UUID().uuidString,
                creatorId: creatorIds.randomElement()!,
                name: "\(category) Tracker",
                description: "Perfect template for tracking your \(category.lowercased()) collection",
                category: category,
                components: generateComponentDefinitions(for: category),
                previewImageURL: previewImageURL,
                isFavorite: false,
                tags: generateRandomTags(),
                isPublic: Bool.random(),
                isPremium: Bool.random(),
                downloadCount: Int.random(in: 0...1000),
                rating: Bool.random() ? Double.random(in: 3.0...5.0) : nil,
                createdAt: randomPastDate(),
                updatedAt: randomRecentDate()
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private static func generateBio() -> String? {
        let bios = [
            "Passionate collector and enthusiast",
            "Always looking for the next great discovery",
            "Sharing my favorites with the world",
            "Quality over quantity is my motto",
            "Building curated collections since 2020"
        ]
        return Bool.random() ? bios.randomElement() : nil
    }
    
    private static func generateUserPreferences() -> UserPreferences {
        UserPreferences(
            theme: [UserPreferences.Theme.light, .dark, .system].randomElement()!,
            notifications: NotificationSettings(
                pushEnabled: Bool.random(),
                emailEnabled: Bool.random(),
                reminderEnabled: Bool.random()
            ),
            privacy: PrivacySettings(
                profilePublic: Bool.random(),
                collectionsPublic: Bool.random(),
                analyticsEnabled: Bool.random()
            )
        )
    }
    
    private static func generateSubscriptionInfo() -> SubscriptionInfo {
        SubscriptionInfo(
            plan: .premium,
            status: .active,
            startDate: randomPastDate(),
            endDate: randomFutureDate(),
            autoRenew: Bool.random()
        )
    }
    
    private static func generateRandomTags(count: Int = 3) -> [String] {
        return Array(tags.shuffled().prefix(count))
    }
    
    private static func generateImageURLs(count: Int = 3) -> [URL] {
        return (0..<count).compactMap { index in
            URL(string: "https://picsum.photos/400/300?random=\(UUID().uuidString.prefix(8))")
        }
    }
    
    private static func generateRandomLocation() -> Location {
        let locationData = locations.randomElement()!
        return Location(
            latitude: locationData.1,
            longitude: locationData.2,
            address: locationData.0,
            name: "\(locationData.0) Location"
        )
    }
    
    private static func generateCustomFields(for hobby: String) -> [String: CustomFieldValue] {
        var fields: [String: CustomFieldValue] = [:]
        
        switch hobby {
        case "Wine Collecting":
            fields["vintage"] = .number(Double(Int.random(in: 2010...2023)))
            fields["region"] = .text(["Napa Valley", "Bordeaux", "Tuscany", "Burgundy"].randomElement()!)
            fields["price_paid"] = .number(Double.random(in: 15.99...299.99))
            fields["alcohol_content"] = .number(Double.random(in: 11.5...15.5))
            
        case "Craft Beer":
            fields["brewery"] = .text(["Stone Brewing", "Dogfish Head", "Russian River", "Tree House"].randomElement()!)
            fields["abv"] = .number(Double.random(in: 3.5...12.0))
            fields["style"] = .text(["IPA", "Stout", "Pilsner", "Wheat Beer"].randomElement()!)
            fields["price"] = .number(Double.random(in: 4.99...19.99))
            
        case "Board Games":
            fields["min_players"] = .number(Double(Int.random(in: 1...4)))
            fields["max_players"] = .number(Double(Int.random(in: 2...8)))
            fields["play_time"] = .number(Double(Int.random(in: 30...180)))
            fields["complexity"] = .number(Double.random(in: 1.0...5.0))
            fields["price_paid"] = .number(Double.random(in: 19.99...99.99))
            
        case "Books":
            fields["author"] = .text(["Brandon Sanderson", "Tara Westover", "Michelle Obama"].randomElement()!)
            fields["pages"] = .number(Double(Int.random(in: 200...800)))
            fields["publication_year"] = .number(Double(Int.random(in: 2015...2023)))
            fields["genre"] = .text(["Fiction", "Non-Fiction", "Biography", "Fantasy"].randomElement()!)
            
        default:
            fields["notes"] = .text("Additional notes about this item")
            fields["price"] = .number(Double.random(in: 9.99...199.99))
        }
        
        return fields
    }
    
    private static func generateComponentDefinitions(for category: String) -> [ComponentDefinition] {
        var components: [ComponentDefinition] = [
            ComponentDefinition(
                id: UUID().uuidString,
                type: .textField,
                label: "Name",
                isRequired: true,
                defaultValue: nil,
                options: nil,
                validation: nil
            ),
            ComponentDefinition(
                id: UUID().uuidString,
                type: .rating,
                label: "Rating",
                isRequired: false,
                defaultValue: nil,
                options: nil,
                validation: nil
            )
        ]
        
        switch category {
        case "Wine Collecting":
            components.append(contentsOf: [
                ComponentDefinition(
                    id: UUID().uuidString,
                    type: .numberField,
                    label: "Vintage Year",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: UUID().uuidString,
                    type: .picker,
                    label: "Region",
                    isRequired: false,
                    defaultValue: nil,
                    options: ["Napa Valley", "Bordeaux", "Tuscany", "Burgundy"],
                    validation: nil
                )
            ])
            
        case "Board Games":
            components.append(contentsOf: [
                ComponentDefinition(
                    id: UUID().uuidString,
                    type: .numberField,
                    label: "Play Time (minutes)",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                ),
                ComponentDefinition(
                    id: UUID().uuidString,
                    type: .numberField,
                    label: "Player Count",
                    isRequired: false,
                    defaultValue: nil,
                    options: nil,
                    validation: nil
                )
            ])
            
        default:
            components.append(ComponentDefinition(
                id: UUID().uuidString,
                type: .textArea,
                label: "Notes",
                isRequired: false,
                defaultValue: nil,
                options: nil,
                validation: nil
            ))
        }
        
        return components
    }
    
    private static func extractHobbyFromCollectionName(_ name: String) -> String {
        for hobby in hobbiesWithItems.keys {
            if name.contains(hobby) {
                return hobby
            }
        }
        return hobbiesWithItems.keys.first ?? "General"
    }
    
    // MARK: - Date Helpers
    
    private static func randomPastDate() -> Date {
        let daysAgo = Int.random(in: 30...365)
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
    
    private static func randomRecentDate() -> Date {
        let daysAgo = Int.random(in: 1...30)
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
    
    private static func randomFutureDate() -> Date {
        let daysFromNow = Int.random(in: 30...365)
        return Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }
}

// MARK: - Test Data Generation Convenience Methods

extension TestDataGenerator {
    
    /// Generates a complete set of test data for development and testing
    static func generateCompleteTestDataSet() -> TestDataSet {
        let users = generateUsers(count: 15)
        let userProfiles = generateUserProfiles(for: users)
        let collections = generateCollections(for: users, count: 30)
        let items = generateItems(for: collections, itemsPerCollection: 12)
        let templates = generateTemplates(creatorIds: users.map { $0.id }, count: 15)
        
        return TestDataSet(
            users: users,
            userProfiles: userProfiles,
            collections: collections,
            items: items,
            templates: templates
        )
    }
    
    /// Generates edge case data for testing validation and error handling
    static func generateEdgeCaseTestData() -> EdgeCaseTestData {
        // User with minimal data
        let minimalUser = User(
            id: UUID().uuidString,
            email: "minimal@example.com",
            displayName: nil,
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isEmailVerified: false
        )
        
        // Collection with maximum field lengths
        let maxFieldsCollection = Collection(
            id: UUID().uuidString,
            userId: minimalUser.id,
            name: String(repeating: "A", count: 255), // Max name length
            description: String(repeating: "B", count: 2000), // Max description length
            templateId: nil,
            itemCount: 0,
            coverImageURL: nil,
            isFavorite: false,
            tags: Array(repeating: "max-tag", count: 10), // Many tags
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Item with all possible custom field types
        let allFieldTypesItem = Item(
            id: UUID().uuidString,
            userId: minimalUser.id,
            collectionId: maxFieldsCollection.id,
            name: "Test Item with All Field Types",
            description: "Item for testing all custom field value types",
            imageURLs: [],
            customFields: [
                "text_field": .text("Sample text"),
                "number_field": .number(123.45),
                "date_field": .date(Date()),
                "boolean_field": .boolean(true),
                "url_field": .url(URL(string: "https://example.com")!),
                "image_field": .image(URL(string: "https://example.com/image.jpg")!)
            ],
            isFavorite: true,
            tags: ["edge-case", "testing", "validation"],
            location: Location(
                latitude: 90.0, // Edge case: North Pole
                longitude: 180.0, // Edge case: International Date Line
                address: "North Pole",
                name: "Edge Location"
            ),
            rating: 5.0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return EdgeCaseTestData(
            minimalUser: minimalUser,
            maxFieldsCollection: maxFieldsCollection,
            allFieldTypesItem: allFieldTypesItem
        )
    }
}

// MARK: - Supporting Data Structures

struct TestDataSet {
    let users: [User]
    let userProfiles: [UserProfile]
    let collections: [Collection]
    let items: [Item]
    let templates: [Template]
}

struct EdgeCaseTestData {
    let minimalUser: User
    let maxFieldsCollection: Collection
    let allFieldTypesItem: Item
}
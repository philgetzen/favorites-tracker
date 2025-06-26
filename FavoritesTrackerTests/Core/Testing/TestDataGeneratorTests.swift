import XCTest
@testable import FavoritesTracker

final class TestDataGeneratorTests: XCTestCase {

    // MARK: - User Generation Tests
    
    func testGenerateUsers() {
        let users = TestDataGenerator.generateUsers(count: 5)
        
        XCTAssertEqual(users.count, 5)
        
        for user in users {
            XCTAssertFalse(user.id.isEmpty)
            XCTAssertFalse(user.email.isEmpty)
            XCTAssertTrue(user.email.contains("@"))
            XCTAssertTrue(user.email.contains("."))
            XCTAssertNotNil(user.displayName)
            XCTAssertNotNil(user.photoURL)
            XCTAssertTrue(user.createdAt <= user.updatedAt)
        }
        
        // Ensure unique IDs
        let uniqueIds = Set(users.map { $0.id })
        XCTAssertEqual(uniqueIds.count, users.count)
    }
    
    // MARK: - UserProfile Generation Tests
    
    func testGenerateUserProfiles() {
        let users = TestDataGenerator.generateUsers(count: 3)
        let profiles = TestDataGenerator.generateUserProfiles(for: users)
        
        XCTAssertEqual(profiles.count, users.count)
        
        for (index, profile) in profiles.enumerated() {
            let correspondingUser = users[index]
            
            XCTAssertEqual(profile.userId, correspondingUser.id)
            XCTAssertEqual(profile.displayName, correspondingUser.displayName)
            XCTAssertEqual(profile.profileImageURL, correspondingUser.photoURL)
            XCTAssertNotNil(profile.preferences)
            XCTAssertTrue(profile.createdAt <= profile.updatedAt)
        }
    }
    
    // MARK: - Collection Generation Tests
    
    func testGenerateCollections() {
        let users = TestDataGenerator.generateUsers(count: 2)
        let collections = TestDataGenerator.generateCollections(for: users, count: 10)
        
        XCTAssertEqual(collections.count, 10)
        
        for collection in collections {
            XCTAssertFalse(collection.id.isEmpty)
            XCTAssertTrue(users.contains { $0.id == collection.userId })
            XCTAssertFalse(collection.name.isEmpty)
            XCTAssertTrue(collection.itemCount >= 0)
            XCTAssertTrue(collection.createdAt <= collection.updatedAt)
            XCTAssertTrue(collection.tags.count <= 5) // Reasonable tag count
        }
    }
    
    // MARK: - Item Generation Tests
    
    func testGenerateItems() {
        let users = TestDataGenerator.generateUsers(count: 2)
        let collections = TestDataGenerator.generateCollections(for: users, count: 3)
        let items = TestDataGenerator.generateItems(for: collections, itemsPerCollection: 5)
        
        XCTAssertTrue(items.count <= collections.count * 5) // May be less due to hobby item limits
        
        for item in items {
            XCTAssertFalse(item.id.isEmpty)
            XCTAssertTrue(users.contains { $0.id == item.userId })
            XCTAssertTrue(collections.contains { $0.id == item.collectionId })
            XCTAssertFalse(item.name.isEmpty)
            XCTAssertTrue(item.createdAt <= item.updatedAt)
            
            // Validate rating if present
            if let rating = item.rating {
                XCTAssertTrue(rating >= 1.0 && rating <= 5.0)
            }
            
            // Validate custom fields
            for (_, value) in item.customFields {
                switch value {
                case .text(let text):
                    XCTAssertFalse(text.isEmpty)
                case .number(let number):
                    XCTAssertTrue(number.isFinite)
                case .date(let date):
                    XCTAssertTrue(date <= Date())
                case .boolean(_):
                    break // Always valid
                case .url(let url):
                    XCTAssertFalse(url.absoluteString.isEmpty)
                case .image(let url):
                    XCTAssertFalse(url.absoluteString.isEmpty)
                }
            }
            
            // Validate location if present
            if let location = item.location {
                XCTAssertTrue(location.latitude >= -90 && location.latitude <= 90)
                XCTAssertTrue(location.longitude >= -180 && location.longitude <= 180)
            }
        }
    }
    
    // MARK: - Template Generation Tests
    
    func testGenerateTemplates() {
        let users = TestDataGenerator.generateUsers(count: 3)
        let creatorIds = users.map { $0.id }
        let templates = TestDataGenerator.generateTemplates(creatorIds: creatorIds, count: 8)
        
        XCTAssertEqual(templates.count, 8)
        
        for template in templates {
            XCTAssertFalse(template.id.isEmpty)
            XCTAssertTrue(creatorIds.contains(template.creatorId))
            XCTAssertFalse(template.name.isEmpty)
            XCTAssertFalse(template.description.isEmpty)
            XCTAssertFalse(template.category.isEmpty)
            XCTAssertTrue(template.components.count >= 2) // At least name and rating
            XCTAssertTrue(template.downloadCount >= 0)
            XCTAssertTrue(template.createdAt <= template.updatedAt)
            
            // Validate rating if present
            if let rating = template.rating {
                XCTAssertTrue(rating >= 3.0 && rating <= 5.0) // Generator creates high ratings
            }
            
            // Validate components
            for component in template.components {
                XCTAssertFalse(component.id.isEmpty)
                XCTAssertFalse(component.label.isEmpty)
            }
        }
    }
    
    // MARK: - Complete Data Set Tests
    
    func testGenerateCompleteTestDataSet() {
        let dataSet = TestDataGenerator.generateCompleteTestDataSet()
        
        XCTAssertEqual(dataSet.users.count, 15)
        XCTAssertEqual(dataSet.userProfiles.count, 15)
        XCTAssertEqual(dataSet.collections.count, 30)
        XCTAssertEqual(dataSet.templates.count, 15)
        
        // Verify relationships
        XCTAssertEqual(dataSet.users.count, dataSet.userProfiles.count)
        
        // All collections should belong to existing users
        for collection in dataSet.collections {
            XCTAssertTrue(dataSet.users.contains { $0.id == collection.userId })
        }
        
        // All items should belong to existing collections and users
        for item in dataSet.items {
            XCTAssertTrue(dataSet.collections.contains { $0.id == item.collectionId })
            XCTAssertTrue(dataSet.users.contains { $0.id == item.userId })
        }
        
        // All templates should have valid creator IDs
        for template in dataSet.templates {
            XCTAssertTrue(dataSet.users.contains { $0.id == template.creatorId })
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testGenerateEdgeCaseTestData() {
        let edgeCaseData = TestDataGenerator.generateEdgeCaseTestData()
        
        // Test minimal user
        let minimalUser = edgeCaseData.minimalUser
        XCTAssertFalse(minimalUser.id.isEmpty)
        XCTAssertFalse(minimalUser.email.isEmpty)
        XCTAssertNil(minimalUser.displayName)
        XCTAssertNil(minimalUser.photoURL)
        XCTAssertFalse(minimalUser.isEmailVerified)
        
        // Test max fields collection
        let maxCollection = edgeCaseData.maxFieldsCollection
        XCTAssertEqual(maxCollection.name.count, 255)
        XCTAssertEqual(maxCollection.description?.count, 2000)
        XCTAssertTrue(maxCollection.tags.count > 5)
        
        // Test all field types item
        let allFieldsItem = edgeCaseData.allFieldTypesItem
        XCTAssertTrue(allFieldsItem.customFields.count >= 6)
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("text_field"))
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("number_field"))
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("date_field"))
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("boolean_field"))
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("url_field"))
        XCTAssertTrue(allFieldsItem.customFields.keys.contains("image_field"))
        
        // Test edge location values
        XCTAssertNotNil(allFieldsItem.location)
        XCTAssertEqual(allFieldsItem.location?.latitude, 90.0)
        XCTAssertEqual(allFieldsItem.location?.longitude, 180.0)
    }
    
    // MARK: - Preview Data Tests
    
    func testPreviewTestData() {
        let sampleUser = PreviewTestData.sampleUser
        let sampleCollections = PreviewTestData.sampleCollections
        let sampleItems = PreviewTestData.sampleItems
        
        XCTAssertFalse(sampleUser.id.isEmpty)
        XCTAssertEqual(sampleCollections.count, 3)
        XCTAssertEqual(sampleItems.count, 3)
        
        // Test relationships
        for collection in sampleCollections {
            XCTAssertEqual(collection.userId, sampleUser.id)
        }
        
        for item in sampleItems {
            XCTAssertEqual(item.userId, sampleUser.id)
            XCTAssertTrue(sampleCollections.contains { $0.id == item.collectionId })
        }
    }
    
    func testPreviewDataCompleteSet() {
        let dataSet = PreviewTestData.completeDataSet()
        
        XCTAssertEqual(dataSet.users.count, 1)
        XCTAssertEqual(dataSet.userProfiles.count, 1)
        XCTAssertEqual(dataSet.collections.count, 3)
        XCTAssertEqual(dataSet.items.count, 3)
        XCTAssertEqual(dataSet.templates.count, 2)
    }
    
    func testPreviewDataDevelopmentSet() {
        let dataSet = PreviewTestData.developmentDataSet()
        
        XCTAssertEqual(dataSet.users.count, 5)
        XCTAssertEqual(dataSet.userProfiles.count, 5)
        XCTAssertEqual(dataSet.collections.count, 12)
        XCTAssertEqual(dataSet.templates.count, 6)
        XCTAssertTrue(dataSet.items.count > 0)
    }
    
    // MARK: - Performance Tests
    
    func testGenerationPerformance() {
        measure {
            let _ = TestDataGenerator.generateCompleteTestDataSet()
        }
    }
    
    func testLargeDataSetGeneration() {
        let users = TestDataGenerator.generateUsers(count: 50)
        let collections = TestDataGenerator.generateCollections(for: users, count: 200)
        let items = TestDataGenerator.generateItems(for: collections, itemsPerCollection: 20)
        
        XCTAssertEqual(users.count, 50)
        XCTAssertEqual(collections.count, 200)
        XCTAssertTrue(items.count > 1000) // Should generate substantial item data
    }
    
    // MARK: - Data Variety Tests
    
    func testHobbyCategoryVariety() {
        let users = TestDataGenerator.generateUsers(count: 10)
        let collections = TestDataGenerator.generateCollections(for: users, count: 50)
        
        // Extract hobby categories from collection names
        let hobbies = Set(collections.compactMap { collection in
            for hobby in ["Wine Collecting", "Craft Beer", "Board Games", "Books", "Movies", "Restaurants", "Coffee Shops", "Art Galleries", "Video Games", "Podcasts"] {
                if collection.name.contains(hobby) {
                    return hobby
                }
            }
            return nil
        })
        
        // Should have variety in hobby categories
        XCTAssertTrue(hobbies.count >= 5, "Should generate variety in hobby categories")
    }
    
    func testCustomFieldVariety() {
        let users = TestDataGenerator.generateUsers(count: 5)
        let collections = TestDataGenerator.generateCollections(for: users, count: 10)
        let items = TestDataGenerator.generateItems(for: collections, itemsPerCollection: 10)
        
        // Check for custom field variety
        var allFieldTypes: Set<String> = []
        
        for item in items {
            for (_, value) in item.customFields {
                switch value {
                case .text(_): allFieldTypes.insert("text")
                case .number(_): allFieldTypes.insert("number")
                case .date(_): allFieldTypes.insert("date")
                case .boolean(_): allFieldTypes.insert("boolean")
                case .url(_): allFieldTypes.insert("url")
                case .image(_): allFieldTypes.insert("image")
                }
            }
        }
        
        // Should have variety in custom field types
        XCTAssertTrue(allFieldTypes.count >= 3, "Should generate variety in custom field types")
    }
}
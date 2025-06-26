import SwiftUI

#if DEBUG
/// Preview helpers for SwiftUI development
/// Provides mock data and configuration for Xcode previews
struct PreviewHelpers {
    
    // MARK: - Mock Data
    
    /// Sample users for previews
    static let sampleUsers: [User] = [
        User(id: "preview-user-id", email: "john@example.com", displayName: "John Doe", isEmailVerified: true),
        User(id: "2", email: "jane@example.com", displayName: "Jane Smith", isEmailVerified: false)
    ]
    
    /// Sample collections for previews
    static let sampleCollections: [Collection] = [
        Collection(userId: "preview-user-id", name: "Favorite Books", templateId: "books-template"),
        Collection(userId: "preview-user-id", name: "Coffee Shops", templateId: "places-template"),
        Collection(userId: "preview-user-id", name: "Board Games", templateId: nil)
    ]
    
    /// Sample items for previews
    static let sampleItems: [Item] = [
        Item(userId: "preview-user-id", collectionId: "1", name: "The Great Gatsby"),
        Item(userId: "preview-user-id", collectionId: "1", name: "To Kill a Mockingbird"),
        Item(userId: "preview-user-id", collectionId: "2", name: "Blue Bottle Coffee")
    ]
    
    /// Sample templates for previews
    static let sampleTemplates: [Template] = [
        Template(creatorId: "1", name: "Book Collection", description: "Track your favorite books", category: "Entertainment"),
        Template(creatorId: "1", name: "Coffee Shop Tracker", description: "Discover and rate coffee shops", category: "Food & Drink")
    ]
    
    // MARK: - Mock Services
    
    /// Mock dependency injection setup for previews
    static func setupPreviewDI() {
        DITesting.setupTestEnvironment()
        
        // Register mock UserDefaults
        DITesting.mock(UserDefaults.self, with: MockUserDefaults())
    }
    
    // MARK: - Preview Modifiers
    
    /// Standard preview modifier with consistent setup
    static func standardPreview<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
    
    /// Dark mode preview modifier
    static func darkPreview<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
    
    /// Preview with different device sizes
    static func devicePreviews<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            content()
                .previewDevice("iPhone 16")
                .previewDisplayName("iPhone 16")
            
            content()
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad Pro")
        }
    }
}

// MARK: - Preview Extensions

extension View {
    /// Apply standard preview configuration
    func standardPreview() -> some View {
        PreviewHelpers.standardPreview { self }
    }
    
    /// Apply dark mode preview configuration
    func darkPreview() -> some View {
        PreviewHelpers.darkPreview { self }
    }
    
    /// Apply device-specific preview configuration
    func devicePreviews() -> some View {
        PreviewHelpers.devicePreviews { self }
    }
    
    /// Apply comprehensive preview suite (light, dark, devices)
    func comprehensivePreview() -> some View {
        Group {
            standardPreview()
            darkPreview()
            devicePreviews()
        }
    }
}

// MARK: - Sample View Models for Previews

/// Sample view model with mock data for previews
@MainActor
final class PreviewSampleViewModel: BaseViewModel {
    @Published var items: [Item] = []
    @Published var collections: [Collection] = []
    
    override init() {
        super.init()
        // Pre-populate with sample data for previews
        self.items = PreviewHelpers.sampleItems
        self.collections = PreviewHelpers.sampleCollections
    }
    
    func loadItems() {
        // Mock implementation for previews
        items = PreviewHelpers.sampleItems
    }
    
    func loadCollections() {
        // Mock implementation for previews
        collections = PreviewHelpers.sampleCollections
    }
}

// MARK: - Preview Repository Provider

/// Simple mock repositories for previews only
final class PreviewItemRepository: ItemRepositoryProtocol, @unchecked Sendable {
    var items: [Item] = PreviewHelpers.sampleItems
    
    func getItems(for userId: String) async throws -> [Item] {
        return items.filter { $0.userId == userId }
    }
    
    func getItem(id: String) async throws -> Item? {
        return items.first { $0.id == id }
    }
    
    func createItem(_ item: Item) async throws -> Item {
        items.append(item)
        return item
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
        return item
    }
    
    func deleteItem(id: String) async throws {
        items.removeAll { $0.id == id }
    }
    
    func searchItems(query: String, userId: String) async throws -> [Item] {
        return items.filter { $0.userId == userId && $0.name.contains(query) }
    }
}

final class PreviewCollectionRepository: CollectionRepositoryProtocol, @unchecked Sendable {
    var collections: [Collection] = PreviewHelpers.sampleCollections
    
    func getCollections(for userId: String) async throws -> [Collection] {
        return collections.filter { $0.userId == userId }
    }
    
    func getCollection(id: String) async throws -> Collection? {
        return collections.first { $0.id == id }
    }
    
    func createCollection(_ collection: Collection) async throws -> Collection {
        collections.append(collection)
        return collection
    }
    
    func updateCollection(_ collection: Collection) async throws -> Collection {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        }
        return collection
    }
    
    func deleteCollection(id: String) async throws {
        collections.removeAll { $0.id == id }
    }
}

final class PreviewTemplateRepository: TemplateRepositoryProtocol, @unchecked Sendable {
    var templates: [Template] = PreviewHelpers.sampleTemplates
    
    func getTemplates() async throws -> [Template] {
        return templates
    }
    
    func getTemplate(id: String) async throws -> Template? {
        return templates.first { $0.id == id }
    }
    
    func createTemplate(_ template: Template) async throws -> Template {
        templates.append(template)
        return template
    }
    
    func updateTemplate(_ template: Template) async throws -> Template {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        }
        return template
    }
    
    func deleteTemplate(id: String) async throws {
        templates.removeAll { $0.id == id }
    }
    
    func searchTemplates(query: String, category: String?) async throws -> [Template] {
        return templates.filter { $0.name.contains(query) }
    }
    
    func getFeaturedTemplates() async throws -> [Template] {
        return templates
    }
}

final class PreviewUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    func getUserProfile(id: String) async throws -> UserProfile? {
        return nil
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        return profile
    }
    
    func deleteUserProfile(id: String) async throws {
        // No-op for previews
    }
}

final class PreviewAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    func signIn(email: String, password: String) async throws -> User {
        return User(id: "preview-user", email: email, displayName: "Preview User")
    }
    
    func signUp(email: String, password: String) async throws -> User {
        return User(id: "preview-user", email: email, displayName: "Preview User")
    }
    
    func signOut() async throws {
        // No-op for previews
    }
    
    func getCurrentUser() -> User? {
        return User(id: "preview-user", email: "preview@example.com", displayName: "Preview User")
    }
    
    func deleteAccount() async throws {
        // No-op for previews
    }
}

final class PreviewStorageRepository: StorageRepositoryProtocol, @unchecked Sendable {
    func uploadImage(_ data: Data, path: String) async throws -> URL {
        return URL(string: "https://picsum.photos/400/600")!
    }
    
    func deleteImage(at path: String) async throws {
        // No-op for previews
    }
    
    func downloadImage(from url: URL) async throws -> Data {
        return Data()
    }
}

/// Preview repository provider using simple mock implementations
@MainActor
final class PreviewRepositoryProvider {
    static let shared = PreviewRepositoryProvider()
    
    lazy var itemRepository: ItemRepositoryProtocol = PreviewItemRepository()
    lazy var collectionRepository: CollectionRepositoryProtocol = PreviewCollectionRepository()
    lazy var templateRepository: TemplateRepositoryProtocol = PreviewTemplateRepository()
    lazy var userRepository: UserRepositoryProtocol = PreviewUserRepository()
    lazy var authRepository: AuthRepositoryProtocol = PreviewAuthRepository()
    lazy var storageRepository: StorageRepositoryProtocol = PreviewStorageRepository()
    
    private init() {}
}

#endif
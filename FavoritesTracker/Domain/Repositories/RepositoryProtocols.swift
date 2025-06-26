import Foundation
import Combine

// MARK: - Repository Protocol Definitions
// These protocols define the contract for data access without exposing implementation details

/// Protocol for user authentication operations
protocol AuthRepositoryProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() -> User?
    func deleteAccount() async throws
}

/// Protocol for item data operations
protocol ItemRepositoryProtocol: Sendable {
    func getItems(for userId: String) async throws -> [Item]
    func getItem(id: String) async throws -> Item?
    func getItemCount(for collectionId: String) async throws -> Int
    func createItem(_ item: Item) async throws -> Item
    func updateItem(_ item: Item) async throws -> Item
    func deleteItem(id: String) async throws
    func searchItems(query: String, userId: String) async throws -> [Item]
}

/// Protocol for collection data operations
protocol CollectionRepositoryProtocol: Sendable {
    func getCollections(for userId: String) async throws -> [Collection]
    func getCollection(id: String) async throws -> Collection?
    func createCollection(_ collection: Collection) async throws -> Collection
    func updateCollection(_ collection: Collection) async throws -> Collection
    func deleteCollection(id: String) async throws
}

/// Protocol for template data operations
protocol TemplateRepositoryProtocol: Sendable {
    func getTemplates() async throws -> [Template]
    func getTemplate(id: String) async throws -> Template?
    func createTemplate(_ template: Template) async throws -> Template
    func updateTemplate(_ template: Template) async throws -> Template
    func deleteTemplate(id: String) async throws
    func searchTemplates(query: String, category: String?) async throws -> [Template]
    func getFeaturedTemplates() async throws -> [Template]
}

/// Protocol for storage operations (images, files)
protocol StorageRepositoryProtocol: Sendable {
    func uploadImage(_ data: Data, path: String) async throws -> URL
    func deleteImage(at path: String) async throws
    func downloadImage(from url: URL) async throws -> Data
}

/// Protocol for user profile operations
protocol UserRepositoryProtocol: Sendable {
    func getUserProfile(id: String) async throws -> UserProfile?
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func deleteUserProfile(id: String) async throws
}

// MARK: - Base Entity Protocols

/// Base protocol for all domain entities
protocol Entity {
    var id: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

/// Protocol for entities that can be favorited
protocol Favoritable {
    var isFavorite: Bool { get set }
}

/// Protocol for entities that support tagging
protocol Taggable {
    var tags: [String] { get set }
}
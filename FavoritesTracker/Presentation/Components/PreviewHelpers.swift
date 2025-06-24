import SwiftUI

#if DEBUG
/// Preview helpers for SwiftUI development
/// Provides mock data and configuration for Xcode previews
struct PreviewHelpers {
    
    // MARK: - Mock Data
    
    /// Sample users for previews
    static let sampleUsers: [User] = [
        User(id: "1", email: "john@example.com", displayName: "John Doe", isEmailVerified: true),
        User(id: "2", email: "jane@example.com", displayName: "Jane Smith", isEmailVerified: false)
    ]
    
    /// Sample collections for previews
    static let sampleCollections: [Collection] = [
        Collection(userId: "1", name: "Favorite Books", templateId: "books-template"),
        Collection(userId: "1", name: "Coffee Shops", templateId: "places-template"),
        Collection(userId: "1", name: "Board Games", templateId: nil)
    ]
    
    /// Sample items for previews
    static let sampleItems: [Item] = [
        Item(userId: "1", collectionId: "1", name: "The Great Gatsby"),
        Item(userId: "1", collectionId: "1", name: "To Kill a Mockingbird"),
        Item(userId: "1", collectionId: "2", name: "Blue Bottle Coffee")
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

#endif
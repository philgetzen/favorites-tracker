import SwiftUI
import Combine

/// ViewModel responsible for data loading and collection management in the Home screen
@MainActor
final class HomeDataViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var collections: [Collection] = []
    @Published var items: [Item] = []
    
    // MARK: - Properties
    
    private let homeService: HomeServiceProtocol
    private let userId: String
    
    // MARK: - Computed Properties
    
    /// Gets the collection ID to use for new items
    var defaultCollectionId: String? {
        return collections.first?.id
    }
    
    /// Indicates whether collections exist for the user
    var hasCollections: Bool {
        return !collections.isEmpty
    }
    
    // MARK: - Initialization
    
    init(homeService: HomeServiceProtocol, userId: String = "preview-user-id") {
        self.homeService = homeService
        self.userId = userId
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Loads collections and items for the user
    func loadData() async {
        setLoading(true)
        
        do {
            let (fetchedCollections, fetchedItems) = try await homeService.fetchData(for: userId)
            collections = fetchedCollections
            items = fetchedItems
        } catch {
            print("Failed to load data: \(error)")
            handleError(error)
        }
        
        setLoading(false)
    }
    
    /// Refreshes data after item creation
    func refreshAfterItemCreation() {
        Task {
            await loadData()
        }
    }
    
    /// Ensures there's at least one collection for creating items
    func ensureDefaultCollection() async {
        // If we already have collections, no need to create one
        guard collections.isEmpty else { return }
        
        do {
            let createdCollection = try await homeService.createDefaultCollection(for: userId)
            collections = [createdCollection]
            print("Created default collection: \(createdCollection.name)")
        } catch {
            print("Failed to create default collection: \(error)")
            handleError(error)
        }
    }
    
    /// Refreshes only collections
    func refreshCollections() async {
        do {
            collections = try await homeService.fetchCollections(for: userId)
        } catch {
            print("Failed to refresh collections: \(error)")
            handleError(error)
        }
    }
    
    /// Refreshes only items
    func refreshItems() async {
        do {
            items = try await homeService.fetchItems(for: userId)
        } catch {
            print("Failed to refresh items: \(error)")
            handleError(error)
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeDataViewModel {
    static func preview() -> HomeDataViewModel {
        let viewModel = HomeDataViewModel(
            homeService: HomeService.preview(),
            userId: "preview-user-id"
        )
        
        // Pre-populate with sample data for previews
        viewModel.collections = PreviewHelpers.sampleCollections
        viewModel.items = PreviewHelpers.sampleItems
        
        return viewModel
    }
}
#endif
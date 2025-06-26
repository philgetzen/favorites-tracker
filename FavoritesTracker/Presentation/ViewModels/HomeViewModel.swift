import SwiftUI
import Combine

/// ViewModel for the HomeView managing collections and recent items
@MainActor
final class HomeViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var selectedTab = 0
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var searchResults: [Item] = []
    @Published var showFavoritesOnly = false
    @Published var minimumRating: Double = 0.0
    @Published var collections: [Collection] = []
    @Published var items: [Item] = []
    @Published var showingItemForm = false
    @Published var showingAdvancedSearch = false
    @Published var searchFilters = SearchFilters()
    
    // MARK: - Properties
    
    nonisolated let itemRepository: ItemRepositoryProtocol
    nonisolated let collectionRepository: CollectionRepositoryProtocol
    nonisolated let storageRepository: StorageRepositoryProtocol
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        showFavoritesOnly || minimumRating > 0.0 || !searchFilters.isEmpty
    }
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.storageRepository = storageRepository
        
        super.init()
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        setLoading(true)
        
        do {
            // Using a placeholder user ID - in real app this would come from auth
            let userId = "preview-user-id"
            
            // Load collections and items concurrently
            async let collectionsTask = collectionRepository.getCollections(for: userId)
            async let itemsTask = itemRepository.getItems(for: userId)
            
            collections = try await collectionsTask
            items = try await itemsTask
        } catch {
            print("Failed to load data: \(error)")
            handleError(error)
        }
        
        setLoading(false)
    }
    
    // MARK: - Item Form Presentation
    
    /// Shows the item creation form
    func showItemForm() {
        // Create a default collection if none exist
        if collections.isEmpty {
            Task {
                await ensureDefaultCollection()
                await MainActor.run {
                    showingItemForm = true
                }
            }
        } else {
            showingItemForm = true
        }
    }
    
    /// Gets the collection ID to use for new items
    var defaultCollectionId: String? {
        // Use the first available collection, or nil if none exist
        return collections.first?.id
    }
    
    /// Refreshes data after item creation
    func refreshAfterItemCreation() {
        Task {
            await loadData()
        }
    }
    
    /// Ensures there's at least one collection for creating items
    @MainActor
    private func ensureDefaultCollection() async {
        // If we already have collections, no need to create one
        guard collections.isEmpty else { return }
        
        do {
            let defaultCollection = Collection(
                userId: "preview-user-id",
                name: "My Collection"
            )
            
            let createdCollection = try await collectionRepository.createCollection(defaultCollection)
            collections = [createdCollection]
            print("Created default collection: \(createdCollection.name)")
        } catch {
            print("Failed to create default collection: \(error)")
            handleError(error)
        }
    }
    
    // MARK: - Search Methods
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        
        Task {
            do {
                // Using a placeholder user ID - in real app this would come from auth
                let results = try await itemRepository.searchItems(
                    query: searchText,
                    userId: "preview-user-id"
                )
                
                // Apply client-side filters
                let filteredResults = results.filter { item in
                    var passes = true
                    
                    // Apply favorites filter
                    if showFavoritesOnly {
                        passes = passes && item.isFavorite
                    }
                    
                    // Apply minimum rating filter
                    if minimumRating > 0.0 {
                        let itemRating = item.rating ?? 0.0
                        passes = passes && itemRating >= minimumRating
                    }
                    
                    return passes
                }
                
                await MainActor.run {
                    searchResults = filteredResults
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    print("Search failed: \(error)")
                    handleError(error)
                }
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = []
        searchFilters = SearchFilters()
    }
    
    // MARK: - Advanced Search
    
    func performAdvancedSearch(query: String, filters: SearchFilters) {
        Task {
            await advancedSearch(query: query, filters: filters)
        }
    }
    
    func showAdvancedSearch() {
        showingAdvancedSearch = true
    }
    
    @MainActor
    private func advancedSearch(query: String, filters: SearchFilters) async {
        setLoading(true)
        isSearching = true
        
        do {
            // Get all items first
            let allItems = try await itemRepository.searchItems(
                query: query.isEmpty ? "*" : query,
                userId: "preview-user-id"
            )
            
            // Apply comprehensive filters
            let filteredResults = allItems.filter { item in
                applyAdvancedFilters(to: item, with: filters)
            }
            
            // Sort results
            let sortedResults = sortItems(filteredResults, by: filters.sortBy)
            
            searchResults = sortedResults
            setLoading(false)
        } catch {
            searchResults = []
            setLoading(false)
            print("Advanced search failed: \(error)")
            handleError(error)
        }
    }
    
    private func applyAdvancedFilters(to item: Item, with filters: SearchFilters) -> Bool {
        // Favorites filter
        if filters.favoritesOnly && !item.isFavorite {
            return false
        }
        
        // Recent items filter (last 30 days)
        if filters.recentItemsOnly {
            let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            if item.createdAt < thirtyDaysAgo {
                return false
            }
        }
        
        // Has images filter
        if filters.hasImagesOnly && item.imageURLs.isEmpty {
            return false
        }
        
        // Has notes filter
        if filters.hasNotesOnly && (item.description?.isEmpty ?? true) {
            return false
        }
        
        // Rating range filter
        let itemRating = item.rating ?? 0.0
        if itemRating < filters.minimumRating || itemRating > filters.maximumRating {
            return false
        }
        
        // Date range filter
        if let dateFrom = filters.dateFrom, item.createdAt < dateFrom {
            return false
        }
        if let dateTo = filters.dateTo, item.createdAt > dateTo {
            return false
        }
        
        // Tags filter (item must have ALL specified tags)
        if !filters.includeTags.isEmpty {
            let hasAllTags = filters.includeTags.allSatisfy { requiredTag in
                item.tags.contains(requiredTag)
            }
            if !hasAllTags {
                return false
            }
        }
        
        return true
    }
    
    private func sortItems(_ items: [Item], by sortOption: SortOption) -> [Item] {
        switch sortOption {
        case .newest:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return items.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .ratingHigh:
            return items.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .ratingLow:
            return items.sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }
        case .recentlyUpdated:
            return items.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeViewModel {
    static func preview() -> HomeViewModel {
        let viewModel = HomeViewModel(
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        
        // Pre-populate with sample data for previews
        viewModel.collections = PreviewHelpers.sampleCollections
        viewModel.items = PreviewHelpers.sampleItems
        
        return viewModel
    }
}
#endif
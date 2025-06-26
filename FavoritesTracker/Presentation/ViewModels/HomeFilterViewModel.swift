import SwiftUI
import Combine

/// State container for filter criteria
struct FilterState {
    var showFavoritesOnly: Bool = false
    var minimumRating: Double = 0.0
    var searchFilters: SearchFilters = SearchFilters()
    
    /// Indicates whether any filters are currently active
    var hasActiveFilters: Bool {
        showFavoritesOnly || minimumRating > 0.0 || !searchFilters.isEmpty
    }
    
    /// Resets all filters to their default values
    mutating func reset() {
        showFavoritesOnly = false
        minimumRating = 0.0
        searchFilters = SearchFilters()
    }
}

/// ViewModel responsible for filtering functionality in the Home screen
@MainActor
final class HomeFilterViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var filterState = FilterState()
    
    // MARK: - Properties
    
    private let homeService: HomeServiceProtocol
    private let filterMemoizer = PerformanceMemoizer<String, [Item]>(name: "ItemFiltering")
    private let sortMemoizer = PerformanceMemoizer<String, [Item]>(name: "ItemSorting")
    
    // MARK: - Computed Properties
    
    /// Convenience property for favorites-only filter
    var showFavoritesOnly: Bool {
        get { filterState.showFavoritesOnly }
        set { filterState.showFavoritesOnly = newValue }
    }
    
    /// Convenience property for minimum rating filter
    var minimumRating: Double {
        get { filterState.minimumRating }
        set { filterState.minimumRating = newValue }
    }
    
    /// Convenience property for advanced search filters
    var searchFilters: SearchFilters {
        get { filterState.searchFilters }
        set { filterState.searchFilters = newValue }
    }
    
    /// Indicates whether any filters are currently active
    var hasActiveFilters: Bool {
        return filterState.hasActiveFilters
    }
    
    // MARK: - Initialization
    
    init(homeService: HomeServiceProtocol) {
        self.homeService = homeService
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Applies current filters to a list of items (memoized for performance)
    func applyFilters(to items: [Item]) -> [Item] {
        // Create cache key from filter state and item identifiers
        let itemIds = items.map { $0.id }.sorted().joined(separator: ",")
        let filterKey = "\(itemIds)_\(showFavoritesOnly)_\(minimumRating)_\(searchFilters.cacheKey)"
        
        return filterMemoizer.value(for: filterKey) {
            applyFiltersInternal(to: items)
        }
    }
    
    /// Internal filter application without memoization
    private func applyFiltersInternal(to items: [Item]) -> [Item] {
        var filteredItems = items
        
        // Apply basic filters (favorites and rating)
        if showFavoritesOnly || minimumRating > 0.0 {
            filteredItems = filteredItems.filter { item in
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
        }
        
        // Apply advanced filters using the service
        if !searchFilters.isEmpty {
            filteredItems = homeService.applyFilters(to: filteredItems, with: searchFilters)
        }
        
        return filteredItems
    }
    
    /// Sorts items based on the current sort criteria (memoized for performance)
    func sortItems(_ items: [Item]) -> [Item] {
        // Create cache key from item identifiers and sort option
        let itemIds = items.map { $0.id }.sorted().joined(separator: ",")
        let sortKey = "\(itemIds)_\(searchFilters.sortBy.rawValue)"
        
        return sortMemoizer.value(for: sortKey) {
            homeService.sortItems(items, by: searchFilters.sortBy)
        }
    }
    
    /// Applies filters and sorting to a list of items
    func processItems(_ items: [Item]) -> [Item] {
        let filteredItems = applyFilters(to: items)
        return sortItems(filteredItems)
    }
    
    /// Resets all filters to their default values
    func resetFilters() {
        filterState.reset()
    }
    
    /// Updates the advanced search filters
    func updateSearchFilters(_ filters: SearchFilters) {
        searchFilters = filters
    }
    
    /// Toggles the favorites-only filter
    func toggleFavoritesOnly() {
        showFavoritesOnly.toggle()
    }
    
    /// Updates the minimum rating filter
    func updateMinimumRating(_ rating: Double) {
        minimumRating = rating
    }
    
    /// Gets a summary of active filters for display
    func getActiveFiltersSummary() -> String {
        var summary: [String] = []
        
        if showFavoritesOnly {
            summary.append("Favorites")
        }
        
        if minimumRating > 0.0 {
            summary.append("Rating ≥ \(String(format: "%.1f", minimumRating))")
        }
        
        if searchFilters.recentItemsOnly {
            summary.append("Recent items")
        }
        
        if searchFilters.hasImagesOnly {
            summary.append("With images")
        }
        
        if searchFilters.hasNotesOnly {
            summary.append("With notes")
        }
        
        if !searchFilters.includeTags.isEmpty {
            summary.append("Tags: \(searchFilters.includeTags.joined(separator: ", "))")
        }
        
        return summary.joined(separator: " • ")
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeFilterViewModel {
    static func preview() -> HomeFilterViewModel {
        let viewModel = HomeFilterViewModel(homeService: HomeService.preview())
        
        // Pre-configure some filters for preview
        viewModel.showFavoritesOnly = true
        viewModel.minimumRating = 3.0
        
        return viewModel
    }
}
#endif
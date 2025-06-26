import SwiftUI
import Combine

/// ViewModel responsible for search functionality in the Home screen
@MainActor
final class HomeSearchViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var searchResults: [Item] = []
    
    // MARK: - Properties
    
    private let homeService: HomeServiceProtocol
    private let userId: String
    private let searchDebouncer = AsyncDebouncer(delay: 0.5)
    
    // MARK: - Computed Properties
    
    /// Indicates whether a search is currently active
    var hasActiveSearch: Bool {
        return isSearching || !searchResults.isEmpty
    }
    
    /// Indicates whether search has results
    var hasSearchResults: Bool {
        return !searchResults.isEmpty
    }
    
    /// Gets the search results count for display
    var searchResultsCount: Int {
        return searchResults.count
    }
    
    // MARK: - Initialization
    
    init(homeService: HomeServiceProtocol, userId: String = "preview-user-id") {
        self.homeService = homeService
        self.userId = userId
        super.init()
        setupSearchDebouncing()
    }
    
    // MARK: - Setup
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task { @MainActor in
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self?.clearSearch()
                    } else if searchText.count >= 2 {
                        await self?.performDebouncedSearch()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Performs a basic search for items (called manually, not debounced)
    func performSearch() {
        Task {
            await performDebouncedSearch()
        }
    }
    
    /// Internal debounced search method
    private func performDebouncedSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        
        do {
            let results = try await homeService.searchItems(
                query: query,
                userId: userId
            )
            
            searchResults = results
            isSearching = false
        } catch {
            searchResults = []
            isSearching = false
            print("Search failed: \(error)")
            handleError(error)
        }
    }
    
    /// Performs an advanced search with filters
    func performAdvancedSearch(query: String, filters: SearchFilters) {
        Task {
            await advancedSearch(query: query, filters: filters)
        }
    }
    
    /// Clears the current search
    func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = []
    }
    
    /// Updates search results with filtered items (for client-side filtering)
    func updateSearchResults(with items: [Item]) {
        searchResults = items
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func advancedSearch(query: String, filters: SearchFilters) async {
        setLoading(true)
        isSearching = true
        
        do {
            let results = try await homeService.advancedSearch(
                query: query,
                filters: filters,
                userId: userId
            )
            
            searchResults = results
            isSearching = false
            setLoading(false)
        } catch {
            searchResults = []
            isSearching = false
            setLoading(false)
            print("Advanced search failed: \(error)")
            handleError(error)
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeSearchViewModel {
    static func preview() -> HomeSearchViewModel {
        let viewModel = HomeSearchViewModel(
            homeService: HomeService.preview(),
            userId: "preview-user-id"
        )
        
        // Pre-populate with sample search results for previews
        viewModel.searchResults = Array(PreviewHelpers.sampleItems.prefix(3))
        
        return viewModel
    }
}
#endif
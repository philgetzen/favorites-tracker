import SwiftUI
import Combine

/// Coordinator ViewModel that manages the decomposed Home ViewModels
@MainActor
final class HomeViewModelRefactored: BaseViewModel {
    
    // MARK: - Child ViewModels
    
    let dataViewModel: HomeDataViewModel
    let searchViewModel: HomeSearchViewModel
    let filterViewModel: HomeFilterViewModel
    let formViewModel: HomeFormViewModel
    
    // MARK: - Properties
    
    @Published var selectedTab = 0
    private let homeService: HomeServiceProtocol
    
    // MARK: - Computed Properties
    
    var collections: [Collection] {
        dataViewModel.collections
    }
    
    var items: [Item] {
        dataViewModel.items
    }
    
    var searchText: String {
        get { searchViewModel.searchText }
        set { searchViewModel.searchText = newValue }
    }
    
    var isSearching: Bool {
        searchViewModel.isSearching
    }
    
    var searchResults: [Item] {
        searchViewModel.searchResults
    }
    
    var showFavoritesOnly: Bool {
        get { filterViewModel.showFavoritesOnly }
        set { filterViewModel.showFavoritesOnly = newValue }
    }
    
    var minimumRating: Double {
        get { filterViewModel.minimumRating }
        set { filterViewModel.minimumRating = newValue }
    }
    
    var searchFilters: SearchFilters {
        get { filterViewModel.filterState.searchFilters }
        set { filterViewModel.filterState.searchFilters = newValue }
    }
    
    var showingItemForm: Bool {
        get { formViewModel.showingItemForm }
        set { formViewModel.showingItemForm = newValue }
    }
    
    var showingAdvancedSearch: Bool {
        get { formViewModel.showingAdvancedSearch }
        set { formViewModel.showingAdvancedSearch = newValue }
    }
    
    var hasActiveFilters: Bool {
        filterViewModel.filterState.hasActiveFilters
    }
    
    var defaultCollectionId: String? {
        dataViewModel.defaultCollectionId
    }
    
    var combinedIsLoading: Bool {
        dataViewModel.isLoading || searchViewModel.isLoading || filterViewModel.isLoading
    }
    
    var combinedErrorMessage: String? {
        dataViewModel.errorMessage ?? searchViewModel.errorMessage ?? filterViewModel.errorMessage
    }
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol,
        userId: String = "preview-user-id"
    ) {
        // Create service
        self.homeService = HomeService(
            itemRepository: itemRepository,
            collectionRepository: collectionRepository
        )
        
        // Create child ViewModels
        self.dataViewModel = HomeDataViewModel(homeService: homeService, userId: userId)
        self.searchViewModel = HomeSearchViewModel(homeService: homeService, userId: userId)
        self.filterViewModel = HomeFilterViewModel(homeService: homeService)
        self.formViewModel = HomeFormViewModel(dataViewModel: dataViewModel)
        
        super.init()
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Propagate loading state from child ViewModels
        Publishers.CombineLatest4(
            dataViewModel.$isLoading,
            searchViewModel.$isLoading,
            filterViewModel.$isLoading,
            formViewModel.$isLoading
        )
        .map { $0 || $1 || $2 || $3 }
        .sink { [weak self] isLoading in
            self?.setLoading(isLoading)
        }
        .store(in: &cancellables)
        
        // Propagate error messages from child ViewModels
        Publishers.CombineLatest4(
            dataViewModel.$errorMessage,
            searchViewModel.$errorMessage,
            filterViewModel.$errorMessage,
            formViewModel.$errorMessage
        )
        .map { dataError, searchError, filterError, formError in
            dataError ?? searchError ?? filterError ?? formError
        }
        .sink { [weak self] errorMessage in
            self?.errorMessage = errorMessage
            self?.showError = errorMessage != nil
        }
        .store(in: &cancellables)
        
        // Auto-trigger search when search text changes
        searchViewModel.$searchText
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    Task {
                        await self?.performSearch()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Auto-apply filters when filter state changes
        filterViewModel.$filterState
            .sink { [weak self] _ in
                Task {
                    await self?.applyFiltersToSearchResults()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads the initial data
    func loadData() async {
        await dataViewModel.loadData()
    }
    
    /// Performs a search with current search text
    func performSearch() async {
        await searchViewModel.performSearch()
        await applyFiltersToSearchResults()
    }
    
    /// Clears the current search
    func clearSearch() {
        searchViewModel.clearSearch()
        filterViewModel.filterState.reset()
    }
    
    /// Applies current filters to search results
    private func applyFiltersToSearchResults() async {
        guard searchViewModel.hasActiveSearch else { return }
        
        let filteredResults = filterViewModel.applyFilters(
            to: searchViewModel.searchResults
        )
        searchViewModel.searchResults = filteredResults
    }
    
    /// Performs advanced search with filters
    func performAdvancedSearch(query: String, filters: SearchFilters) async {
        await searchViewModel.performAdvancedSearch(query: query, filters: filters)
    }
    
    /// Shows the advanced search view
    func showAdvancedSearch() {
        formViewModel.showAdvancedSearch()
    }
    
    /// Shows the item creation form
    func showItemForm() {
        formViewModel.showItemForm()
    }
    
    /// Refreshes data after item creation
    func refreshAfterItemCreation() {
        Task {
            await dataViewModel.loadData()
        }
    }
    
    /// Ensures there's at least one collection for creating items
    func ensureDefaultCollection() async {
        await dataViewModel.ensureDefaultCollection()
    }
    
    // MARK: - Filter Management
    
    /// Resets all filters to default values
    func resetFilters() {
        filterViewModel.filterState.reset()
    }
    
    /// Toggles the favorites-only filter
    func toggleFavoritesFilter() {
        filterViewModel.showFavoritesOnly.toggle()
    }
    
    /// Sets the minimum rating filter
    func setMinimumRating(_ rating: Double) {
        filterViewModel.minimumRating = rating
    }
    
    // MARK: - Navigation
    
    /// Switches to a specific tab
    func switchToTab(_ tabIndex: Int) {
        selectedTab = tabIndex
    }
    
    /// Closes any open forms
    func closeAllForms() {
        formViewModel.hideItemForm()
        formViewModel.hideAdvancedSearch()
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeViewModelRefactored {
    static func preview() -> HomeViewModelRefactored {
        let viewModel = HomeViewModelRefactored(
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        
        // Load preview data
        Task {
            await viewModel.loadData()
        }
        
        return viewModel
    }
}
#endif
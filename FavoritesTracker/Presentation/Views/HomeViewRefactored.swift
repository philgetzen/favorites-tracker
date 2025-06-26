import SwiftUI

/// Refactored main home screen using separated ViewModels for better maintainability
struct HomeViewRefactored: View {
    
    // MARK: - ViewModels
    
    @StateObject private var dataViewModel: HomeDataViewModel
    @StateObject private var searchViewModel: HomeSearchViewModel
    @StateObject private var filterViewModel: HomeFilterViewModel
    @StateObject private var formViewModel: HomeFormViewModel
    
    // MARK: - State
    
    @State private var selectedTab = 0
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol = PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: CollectionRepositoryProtocol = PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: StorageRepositoryProtocol = PreviewRepositoryProvider.shared.storageRepository
    ) {
        let homeService = HomeService(
            itemRepository: itemRepository,
            collectionRepository: collectionRepository
        )
        
        let dataVM = HomeDataViewModel(homeService: homeService)
        
        self._dataViewModel = StateObject(wrappedValue: dataVM)
        self._searchViewModel = StateObject(wrappedValue: HomeSearchViewModel(homeService: homeService))
        self._filterViewModel = StateObject(wrappedValue: HomeFilterViewModel(homeService: homeService))
        self._formViewModel = StateObject(wrappedValue: HomeFormViewModel(dataViewModel: dataVM))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                TabView(selection: $selectedTab) {
                    collectionsView
                        .tabItem {
                            Image(systemName: "folder")
                            Text("Collections")
                        }
                        .tag(0)
                    
                    recentItemsView
                        .tabItem {
                            Image(systemName: "clock")
                            Text("Recent")
                        }
                        .tag(1)
                    
                    templatesView
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("Templates")
                        }
                        .tag(2)
                }
            }
            .navigationTitle("Favorites Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        formViewModel.showItemForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await dataViewModel.loadData()
            }
            .sheet(isPresented: $formViewModel.showingItemForm) {
                if let collectionId = dataViewModel.defaultCollectionId {
                    ItemFormView(
                        userId: "preview-user-id",
                        collectionId: collectionId,
                        itemRepository: DIContainer.shared.resolve(ItemRepositoryProtocol.self),
                        collectionRepository: DIContainer.shared.resolve(CollectionRepositoryProtocol.self),
                        storageRepository: DIContainer.shared.resolve(StorageRepositoryProtocol.self)
                    )
                    .onDisappear {
                        formViewModel.handleItemFormDismissal()
                    }
                } else {
                    Text("No collections available. Create a collection first.")
                        .padding()
                }
            }
            .sheet(isPresented: $formViewModel.showingAdvancedSearch) {
                AdvancedSearchView(
                    searchQuery: $searchViewModel.searchText,
                    searchFilters: $filterViewModel.searchFilters,
                    isPresented: $formViewModel.showingAdvancedSearch,
                    onSearch: { query, filters in
                        searchViewModel.performAdvancedSearch(query: query, filters: filters)
                    },
                    onClear: {
                        searchViewModel.clearSearch()
                        filterViewModel.resetFilters()
                    }
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.headline)
                    Text("You have \(dataViewModel.collections.count) collections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    // Profile action
                } label: {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("JD")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search items...", text: $searchViewModel.searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performFilteredSearch()
                        }
                        .onChange(of: searchViewModel.searchText) { oldValue, newValue in
                            if newValue.isEmpty {
                                searchViewModel.clearSearch()
                            } else if newValue.count >= 2 {
                                performFilteredSearch()
                            }
                        }
                    
                    if !searchViewModel.searchText.isEmpty {
                        Button(action: {
                            searchViewModel.clearSearch()
                            filterViewModel.resetFilters()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Advanced search button
                Button(action: { formViewModel.showAdvancedSearch() }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                }
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Filter button
                Menu {
                    Section("Filters") {
                        Toggle("Favorites Only", isOn: $filterViewModel.showFavoritesOnly)
                            .onChange(of: filterViewModel.showFavoritesOnly) { _, _ in
                                if searchViewModel.hasActiveSearch {
                                    performFilteredSearch()
                                }
                            }
                        
                        VStack {
                            Text("Minimum Rating: \(filterViewModel.minimumRating, specifier: "%.1f")")
                            Slider(value: $filterViewModel.minimumRating, in: 0...5, step: 0.5)
                                .onChange(of: filterViewModel.minimumRating) { _, _ in
                                    if searchViewModel.hasActiveSearch {
                                        performFilteredSearch()
                                    }
                                }
                        }
                    }
                    
                    Section {
                        Button("Clear Filters") {
                            filterViewModel.resetFilters()
                            if searchViewModel.hasActiveSearch {
                                performFilteredSearch()
                            }
                        }
                    }
                } label: {
                    Image(systemName: filterViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(filterViewModel.hasActiveFilters ? .blue : .secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Collections View
    
    private var collectionsView: some View {
        ScrollView {
            if dataViewModel.collections.isEmpty {
                EmptyStateView(
                    title: "No Collections Yet",
                    message: "Start organizing your favorites by creating your first collection.",
                    systemImage: "folder.badge.plus",
                    actionTitle: "Create Collection",
                    action: { }
                )
                .frame(minHeight: 400)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(dataViewModel.collections, id: \.id) { collection in
                        CollectionCardView(collection: collection)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Recent Items View
    
    private var recentItemsView: some View {
        return ScrollView {
            let itemsToShow = searchViewModel.hasActiveSearch ? searchViewModel.searchResults : dataViewModel.items
            let emptyTitle = searchViewModel.hasActiveSearch ? "No Search Results" : "No Recent Items"
            let emptyMessage = searchViewModel.hasActiveSearch ? "Try different search terms or check your spelling." : "Items you add or view will appear here."
            let emptyIcon = searchViewModel.hasActiveSearch ? "magnifyingglass" : "clock"
            
            if itemsToShow.isEmpty {
                EmptyStateView(
                    title: emptyTitle,
                    message: emptyMessage,
                    systemImage: emptyIcon,
                    actionTitle: searchViewModel.hasActiveSearch ? "Clear Search" : "Browse Collections",
                    action: { 
                        if searchViewModel.hasActiveSearch {
                            searchViewModel.clearSearch()
                            filterViewModel.resetFilters()
                        } else {
                            selectedTab = 0 
                        }
                    }
                )
                .frame(minHeight: 400)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Search results header
                    if searchViewModel.hasActiveSearch {
                        HStack {
                            Text("Search Results (\(searchViewModel.searchResultsCount))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Clear") {
                                searchViewModel.clearSearch()
                                filterViewModel.resetFilters()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(itemsToShow, id: \.id) { item in
                            ItemCardView(
                                item: item,
                                itemRepository: DIContainer.shared.resolve(ItemRepositoryProtocol.self),
                                collectionRepository: DIContainer.shared.resolve(CollectionRepositoryProtocol.self),
                                storageRepository: DIContainer.shared.resolve(StorageRepositoryProtocol.self)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Templates View
    
    private var templatesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Popular Templates")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(PreviewHelpers.sampleTemplates, id: \.id) { template in
                        TemplateCardView(template: template)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performFilteredSearch() {
        Task {
            // First perform the basic search
            await searchViewModel.performSearch()
            
            // Then apply filters to the search results
            let filteredResults = filterViewModel.applyFilters(to: searchViewModel.searchResults)
            await MainActor.run {
                searchViewModel.updateSearchResults(with: filteredResults)
            }
        }
    }
}

// MARK: - Previews

#Preview("Refactored Home with Data") {
    HomeViewRefactored()
}

#Preview("Refactored Empty State") {
    HomeViewRefactored()
        .onAppear {
            // This would normally clear data, but PreviewSampleViewModel 
            // already has sample data, so this demonstrates the loaded state
        }
}

#Preview("Refactored Dark Mode") {
    HomeViewRefactored()
        .preferredColorScheme(.dark)
}

#Preview("Refactored iPad", traits: .landscapeLeft) {
    HomeViewRefactored()
}
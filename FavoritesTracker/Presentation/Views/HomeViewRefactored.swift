import SwiftUI

/// Refactored main home screen using the coordinator ViewModel pattern
struct HomeViewRefactored: View {
    
    // MARK: - Coordinator ViewModel
    
    @StateObject private var viewModel: HomeViewModelRefactored
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingProfileModal = false
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol = PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: CollectionRepositoryProtocol = PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: StorageRepositoryProtocol = PreviewRepositoryProvider.shared.storageRepository
    ) {
        self._viewModel = StateObject(wrappedValue: HomeViewModelRefactored(
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                TabView(selection: $viewModel.selectedTab) {
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
                        viewModel.showItemForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    UserInitialsView(
                        displayName: authManager.currentUser?.displayName
                    )
                    .onTapGesture {
                        showingProfileModal = true
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingItemForm) {
                if let collectionId = viewModel.defaultCollectionId {
                    ItemFormViewRefactored(
                        userId: "preview-user-id",
                        collectionId: collectionId,
                        itemRepository: DIContainer.shared.resolve(ItemRepositoryProtocol.self),
                        collectionRepository: DIContainer.shared.resolve(CollectionRepositoryProtocol.self),
                        storageRepository: DIContainer.shared.resolve(StorageRepositoryProtocol.self)
                    )
                    .onDisappear {
                        viewModel.refreshAfterItemCreation()
                    }
                } else {
                    Text("No collections available. Create a collection first.")
                        .padding()
                }
            }
            .sheet(isPresented: $viewModel.showingAdvancedSearch) {
                AdvancedSearchView(
                    searchQuery: $viewModel.searchText,
                    searchFilters: $viewModel.searchFilters,
                    isPresented: $viewModel.showingAdvancedSearch,
                    onSearch: { query, filters in
                        Task {
                            await viewModel.performAdvancedSearch(query: query, filters: filters)
                        }
                    },
                    onClear: {
                        viewModel.clearSearch()
                    }
                )
            }
            .sheet(isPresented: $showingProfileModal) {
                ProfileModal(
                    isPresented: $showingProfileModal,
                    currentUser: authManager.currentUser,
                    onSignOut: {
                        await signOut()
                    },
                    onUpdateDisplayName: { newDisplayName in
                        try await updateDisplayName(newDisplayName)
                    }
                )
            }
        }
        .overlay {
            if viewModel.combinedIsLoading {
                LoadingStateView()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.combinedErrorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Profile Actions
    
    private func signOut() async {
        do {
            try await authManager.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
    }
    
    private func updateDisplayName(_ newDisplayName: String) async throws {
        try await authManager.updateDisplayName(newDisplayName)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search items...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                if viewModel.isSearching || !viewModel.searchText.isEmpty {
                    Button("Cancel") {
                        viewModel.clearSearch()
                    }
                    .foregroundColor(.accentColor)
                }
                
                Button {
                    viewModel.showAdvancedSearch()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            
            // Filter Pills
            if viewModel.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if viewModel.showFavoritesOnly {
                            FilterPill(title: "Favorites", isActive: true) {
                                viewModel.toggleFavoritesFilter()
                            }
                        }
                        
                        if viewModel.minimumRating > 0 {
                            FilterPill(title: "Rating \(Int(viewModel.minimumRating))+", isActive: true) {
                                viewModel.setMinimumRating(0)
                            }
                        }
                        
                        Button("Clear All") {
                            viewModel.resetFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Collections View
    
    private var collectionsView: some View {
        VStack {
            if viewModel.isSearching && !viewModel.searchResults.isEmpty {
                searchResultsView
            } else if viewModel.collections.isEmpty {
                emptyCollectionsView
            } else {
                CollectionGridView(collections: viewModel.collections)
            }
        }
        .padding()
    }
    
    // MARK: - Recent Items View
    
    private var recentItemsView: some View {
        VStack {
            if viewModel.isSearching && !viewModel.searchResults.isEmpty {
                searchResultsView
            } else if viewModel.items.isEmpty {
                emptyItemsView
            } else {
                ItemGridView(items: viewModel.items)
            }
        }
        .padding()
    }
    
    // MARK: - Templates View
    
    private var templatesView: some View {
        VStack {
            Text("Templates")
                .font(.title2)
                .padding()
            
            Text("Template functionality coming soon!")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.searchResults.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ItemGridView(items: viewModel.searchResults)
        }
    }
    
    // MARK: - Empty State Views
    
    private var emptyCollectionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Collections Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Create your first collection to start organizing your favorite items")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.showItemForm()
            } label: {
                Text("Add First Item")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var emptyItemsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recent Items")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Items you create or update will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Supporting Views

private struct FilterPill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isActive {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(12)
        }
    }
}

private struct CollectionGridView: View {
    let collections: [Collection]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ], spacing: 16) {
            ForEach(collections, id: \.id) { collection in
                CollectionCardView(collection: collection)
            }
        }
    }
}

private struct ItemGridView: View {
    let items: [Item]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ], spacing: 16) {
            ForEach(items, id: \.id) { item in
                ItemCardView(
                    item: item,
                    itemRepository: DIContainer.shared.resolve(ItemRepositoryProtocol.self),
                    collectionRepository: DIContainer.shared.resolve(CollectionRepositoryProtocol.self),
                    storageRepository: DIContainer.shared.resolve(StorageRepositoryProtocol.self)
                )
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct HomeViewRefactored_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewRefactored()
    }
}
#endif
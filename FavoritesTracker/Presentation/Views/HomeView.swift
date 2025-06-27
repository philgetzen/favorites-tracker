import SwiftUI

/// Main home screen showing user's collections and recent items
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingProfileModal = false
    
    init(
        itemRepository: ItemRepositoryProtocol = PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: CollectionRepositoryProtocol = PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: StorageRepositoryProtocol = PreviewRepositoryProvider.shared.storageRepository
    ) {
        self._viewModel = StateObject(wrappedValue: HomeViewModel(
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
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingItemForm) {
                if let collectionId = viewModel.defaultCollectionId {
                    ItemFormView(
                        userId: "preview-user-id",
                        collectionId: collectionId,
                        itemRepository: viewModel.itemRepository,
                        collectionRepository: viewModel.collectionRepository,
                        storageRepository: viewModel.storageRepository
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
                        viewModel.performAdvancedSearch(query: query, filters: filters)
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
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.headline)
                    Text("You have \(viewModel.collections.count) collections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingProfileModal = true
                } label: {
                    UserInitialsView(
                        displayName: authManager.currentUser?.displayName,
                        size: 40,
                        backgroundColor: .blue
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
                    
                    TextField("Search items...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            viewModel.performSearch()
                        }
                        .onChange(of: viewModel.searchText) { oldValue, newValue in
                            if newValue.isEmpty {
                                viewModel.clearSearch()
                            } else if newValue.count >= 2 {
                                viewModel.performSearch()
                            }
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: viewModel.clearSearch) {
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
                Button(action: { viewModel.showingAdvancedSearch = true }) {
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
                        Toggle("Favorites Only", isOn: $viewModel.showFavoritesOnly)
                            .onChange(of: viewModel.showFavoritesOnly) { _, _ in
                                if viewModel.isSearching {
                                    viewModel.performSearch()
                                }
                            }
                        
                        VStack {
                            Text("Minimum Rating: \(viewModel.minimumRating, specifier: "%.1f")")
                            Slider(value: $viewModel.minimumRating, in: 0...5, step: 0.5)
                                .onChange(of: viewModel.minimumRating) { _, _ in
                                    if viewModel.isSearching {
                                        viewModel.performSearch()
                                    }
                                }
                        }
                    }
                    
                    Section {
                        Button("Clear Filters") {
                            viewModel.showFavoritesOnly = false
                            viewModel.minimumRating = 0.0
                            if viewModel.isSearching {
                                viewModel.performSearch()
                            }
                        }
                    }
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(viewModel.hasActiveFilters ? .blue : .secondary)
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
            if viewModel.collections.isEmpty {
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
                    ForEach(viewModel.collections, id: \.id) { collection in
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
            let itemsToShow = viewModel.isSearching ? viewModel.searchResults : viewModel.items
            let emptyTitle = viewModel.isSearching ? "No Search Results" : "No Recent Items"
            let emptyMessage = viewModel.isSearching ? "Try different search terms or check your spelling." : "Items you add or view will appear here."
            let emptyIcon = viewModel.isSearching ? "magnifyingglass" : "clock"
            
            if itemsToShow.isEmpty {
                EmptyStateView(
                    title: emptyTitle,
                    message: emptyMessage,
                    systemImage: emptyIcon,
                    actionTitle: viewModel.isSearching ? "Clear Search" : "Browse Collections",
                    action: { 
                        if viewModel.isSearching {
                            viewModel.clearSearch()
                        } else {
                            viewModel.selectedTab = 0 
                        }
                    }
                )
                .frame(minHeight: 400)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Search results header
                    if viewModel.isSearching {
                        HStack {
                            Text("Search Results (\(viewModel.searchResults.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearSearch()
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
                            itemRepository: viewModel.itemRepository,
                            collectionRepository: viewModel.collectionRepository,
                            storageRepository: viewModel.storageRepository
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
}

/// Simple template card view for previews
struct TemplateCardView: View {
    let template: Template
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.gradient)
                .frame(height: 80)
                .overlay(
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundColor(.white)
                )
            
            Text(template.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(template.category)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("Home with Data") {
    HomeView()
}

#Preview("Empty State") {
    HomeView()
        .onAppear {
            // This would normally clear data, but PreviewSampleViewModel 
            // already has sample data, so this demonstrates the loaded state
        }
}

#Preview("Dark Mode") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    HomeView()
}

#Preview("Collections Tab") {
    HomeView()
        .onAppear {
            // Default shows collections tab
        }
}

#Preview("Recent Items Tab") {
    @Previewable @State var selectedTab = 1
    HomeView()
}

#Preview("Templates Tab") {
    @Previewable @State var selectedTab = 2
    HomeView()
}
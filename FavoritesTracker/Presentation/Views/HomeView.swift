import SwiftUI

/// Main home screen showing user's collections and recent items
struct HomeView: View {
    @StateObject private var viewModel = PreviewSampleViewModel()
    @State private var selectedTab = 0
    
    // Repository dependencies
    let itemRepository: ItemRepositoryProtocol
    let collectionRepository: CollectionRepositoryProtocol
    let storageRepository: StorageRepositoryProtocol
    
    init(
        itemRepository: ItemRepositoryProtocol = PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: CollectionRepositoryProtocol = PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: StorageRepositoryProtocol = PreviewRepositoryProvider.shared.storageRepository
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.storageRepository = storageRepository
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
                        // Add action
                    } label: {
                        Image(systemName: "plus")
                    }
                }
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
                    Text("You have \(viewModel.collections.count) collections")
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
        ScrollView {
            if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No Recent Items",
                    message: "Items you add or view will appear here.",
                    systemImage: "clock",
                    actionTitle: "Browse Collections",
                    action: { selectedTab = 0 }
                )
                .frame(minHeight: 400)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.items, id: \.id) { item in
                        ItemCardView(
                            item: item,
                            itemRepository: itemRepository,
                            collectionRepository: collectionRepository,
                            storageRepository: storageRepository
                        )
                    }
                }
                .padding()
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
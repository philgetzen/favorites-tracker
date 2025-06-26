import SwiftUI

/// SwiftUI view for displaying detailed information about a single item
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    init(
        itemId: String,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self._viewModel = StateObject(wrappedValue: ItemDetailViewModel(
            itemId: itemId,
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle(viewModel.item?.name ?? "Item")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolbarMenu
                    }
                }
                .task {
                    await viewModel.loadItem()
                }
                .refreshable {
                    await viewModel.refreshItem()
                }
                .alert("Delete Item", isPresented: $viewModel.showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            let success = await viewModel.confirmDelete()
                            if success {
                                dismiss()
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this item? This action cannot be undone.")
                }
                .sheet(isPresented: $viewModel.showingEditSheet) {
                    if let editViewModel = viewModel.getEditViewModel() {
                        ItemFormView(
                            userId: editViewModel.userId,
                            collectionId: editViewModel.collectionId,
                            editingItem: editViewModel.editingItem,
                            itemRepository: editViewModel.itemRepository,
                            collectionRepository: editViewModel.collectionRepository,
                            storageRepository: editViewModel.storageRepository
                        )
                    }
                }
                .fullScreenCover(isPresented: $viewModel.showingImageViewer) {
                    imageViewer
                }
        }
    }
    
    // MARK: - Content Views
    
    private var content: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let item = viewModel.item {
                itemDetailContent(item: item)
            } else {
                errorState
            }
        }
    }
    
    private func itemDetailContent(item: Item) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Images Section
                if viewModel.hasImages {
                    heroImagesSection(item: item)
                }
                
                VStack(spacing: 20) {
                    // Basic Information
                    basicInfoSection(item: item)
                    
                    // Description
                    if viewModel.hasDescription {
                        descriptionSection(item: item)
                    }
                    
                    // Rating
                    if viewModel.hasRating {
                        ratingSection(item: item)
                    }
                    
                    // Tags
                    if viewModel.hasTags {
                        tagsSection(item: item)
                    }
                    
                    // Custom Fields
                    if !item.customFields.isEmpty {
                        customFieldsSection(item: item)
                    }
                    
                    // Metadata
                    metadataSection(item: item)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
    }
    
    private func heroImagesSection(item: Item) -> some View {
        TabView {
            ForEach(Array(item.imageURLs.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 300)
                .clipped()
                .cornerRadius(12)
                .onTapGesture {
                    viewModel.showImage(at: index)
                }
            }
        }
        .tabViewStyle(.page)
        .frame(height: 320)
        .padding(.horizontal)
    }
    
    private func basicInfoSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let description = item.description, !description.isEmpty {
                        RichTextDisplayView(text: description, style: .detail, lineLimit: 2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite()
                    }
                }) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(item.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func descriptionSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes & Description")
                .font(.headline)
                .foregroundColor(.primary)
            
            RichTextDisplayView(text: item.description ?? "", style: .body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func ratingSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                StarRatingView(rating: item.rating ?? 0, maxRating: 5, starSize: 18)
                
                Text(String(format: "%.1f", item.rating ?? 0))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func tagsSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func customFieldsSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(Array(item.customFields.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(item.customFields[key]?.stringValue ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func metadataSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !Calendar.current.isDate(item.createdAt, inSameDayAs: item.updatedAt) {
                    HStack {
                        Text("Last Updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(viewModel.formattedUpdatedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Item Not Found")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("This item could not be loaded or may have been deleted.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button(action: viewModel.editItem) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: viewModel.deleteItem) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
            
            Button(action: {
                Task {
                    await viewModel.refreshItem()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private var imageViewer: some View {
        Group {
            if let item = viewModel.item, !item.imageURLs.isEmpty {
                ImageViewer(
                    imageURLs: item.imageURLs,
                    selectedIndex: $viewModel.selectedImageIndex,
                    isPresented: $viewModel.showingImageViewer
                )
            }
        }
    }
}

// MARK: - Image Viewer Component

private struct ImageViewer: View {
    let imageURLs: [URL]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .background(Color.black)
            .navigationTitle("Image \(selectedIndex + 1) of \(imageURLs.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Item with Full Data") {
    ItemDetailView(
        itemId: "preview-item",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
}

#Preview("Item Loading") {
    let viewModel = ItemDetailViewModel.preview()
    viewModel.isLoading = true
    
    return ItemDetailView(
        itemId: "preview-item",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
}

#Preview("Item Not Found") {
    ItemDetailView(
        itemId: "nonexistent-item",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
}

#Preview("Dark Mode") {
    ItemDetailView(
        itemId: "preview-item",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
    .preferredColorScheme(.dark)
}
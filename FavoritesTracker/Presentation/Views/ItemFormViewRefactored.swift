import SwiftUI
import PhotosUI

/// Refactored ItemFormView using decomposed ViewModels
struct ItemFormViewRefactored: View {
    @StateObject private var viewModel: ItemFormViewModelRefactored
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name
        case description
    }
    
    init(
        userId: String,
        collectionId: String,
        editingItem: Item? = nil,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        _viewModel = StateObject(wrappedValue: ItemFormViewModelRefactored(
            userId: userId,
            collectionId: collectionId,
            editingItem: editingItem,
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    nameField
                    descriptionField
                }
                
                // Rating Section
                Section("Rating") {
                    ratingField
                }
                
                // Photos Section
                Section("Photos") {
                    photosSection
                }
                
                // Tags Section
                Section("Tags") {
                    tagsSection
                }
                
                // Favorite Toggle
                Section {
                    favoriteToggle
                }
                
                // Validation Errors
                if !viewModel.validation.validationErrors.isEmpty {
                    Section {
                        ForEach(viewModel.validation.validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.formState.formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.formState.submitButtonTitle) {
                        Task {
                            await viewModel.submitForm()
                            if viewModel.validation.validationErrors.isEmpty {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
    
    // MARK: - Form Fields
    
    private var nameField: some View {
        TextField("Name", text: $viewModel.formState.name)
            .focused($focusedField, equals: .name)
            .onAppear {
                if viewModel.formState.name.isEmpty {
                    focusedField = .name
                }
            }
            .overlay(alignment: .trailing) {
                if let error = viewModel.validation.fieldErrors["name"] {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .help(error)
                }
            }
    }
    
    private var descriptionField: some View {
        TextField("Description (optional)", text: $viewModel.formState.description, axis: .vertical)
            .lineLimit(3...6)
            .focused($focusedField, equals: .description)
    }
    
    private var ratingField: some View {
        HStack {
            Text("Rating")
            Spacer()
            InteractiveStarRatingView(rating: $viewModel.formState.rating)
            if viewModel.formState.rating > 0 {
                Button("Clear") {
                    viewModel.formState.rating = 0
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private var photosSection: some View {
        Group {
            if !viewModel.photoUpload.uploadedImageURLs.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.photoUpload.uploadedImageURLs.enumerated()), id: \.offset) { index, url in
                            ImageThumbnail(url: url) {
                                viewModel.photoUpload.removeImage(at: index)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if viewModel.photoUpload.uploadedImageURLs.count < 5 {
                let remaining = max(0, 5 - viewModel.photoUpload.uploadedImageURLs.count)
                PhotosPicker(
                    selection: $viewModel.photoUpload.selectedPhotoItems,
                    maxSelectionCount: remaining,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Add Photos (\(remaining) remaining)")
                    }
                }
            }
            
            if viewModel.photoUpload.isUploadingImages {
                ProgressView("Uploading...", value: viewModel.photoUpload.uploadProgress)
                    .progressViewStyle(.linear)
            }
        }
    }
    
    private var tagsSection: some View {
        Group {
            if !viewModel.formState.tags.isEmpty {
                WrappingHStack(viewModel.formState.tags, id: \.self) { tag in
                    TagChip(tag: tag) {
                        viewModel.removeTag(tag)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.availableTags.filter { !viewModel.formState.tags.contains($0) }, id: \.self) { tag in
                        Button(tag) {
                            viewModel.selectTag(tag)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                }
            }
        }
    }
    
    private var favoriteToggle: some View {
        Toggle(isOn: $viewModel.formState.isFavorite) {
            Label("Mark as Favorite", systemImage: "star")
        }
    }
}

// MARK: - Supporting Views

struct ImageThumbnail: View {
    let url: URL
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        ProgressView()
                    }
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .offset(x: 4, y: -4)
        }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(15)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                Text("Please wait...")
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}

// MARK: - WrappingHStack

struct WrappingHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content
    
    init(_ data: Data, id: KeyPath<Data.Element, Data.Element> = \.self, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        // Use a simpler approach that's Swift 6 compliant
        // This creates a wrapping layout using VStack and HStack
        VStack(alignment: .leading, spacing: 4) {
            let chunks = createChunks(from: Array(data))
            ForEach(Array(chunks.enumerated()), id: \.offset) { _, chunk in
                HStack(spacing: 4) {
                    ForEach(chunk, id: \.self) { item in
                        content(item)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func createChunks(from items: [Data.Element]) -> [[Data.Element]] {
        // Simple chunking - in a real implementation you'd measure text width
        // For now, we'll use a reasonable default of 3-4 items per row
        let chunkSize = min(4, max(1, items.count / max(1, (items.count + 3) / 4)))
        return items.chunked(into: chunkSize)
    }
}

// Helper extension for chunking arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ItemFormViewRefactored_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // New Item Form
            ItemFormViewRefactored(
                userId: "preview-user",
                collectionId: "preview-collection",
                itemRepository: PreviewRepositoryProvider.shared.itemRepository,
                collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
                storageRepository: PreviewRepositoryProvider.shared.storageRepository
            )
            .previewDisplayName("New Item")
            
            // Edit Item Form
            ItemFormViewRefactored(
                userId: "preview-user",
                collectionId: "preview-collection",
                editingItem: Item(
                    id: "preview-item",
                    userId: "preview-user",
                    collectionId: "preview-collection",
                    name: "Sample Book",
                    description: "A great book",
                    imageURLs: [],
                    customFields: [:],
                    isFavorite: true,
                    tags: ["fiction", "sci-fi"],
                    location: nil,
                    rating: 4.5,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                itemRepository: PreviewRepositoryProvider.shared.itemRepository,
                collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
                storageRepository: PreviewRepositoryProvider.shared.storageRepository
            )
            .previewDisplayName("Edit Item")
        }
    }
}
#endif
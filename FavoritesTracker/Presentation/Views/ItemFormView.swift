import SwiftUI

/// SwiftUI view for creating and editing items
struct ItemFormView: View {
    @StateObject private var viewModel: ItemFormViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    init(
        userId: String,
        collectionId: String,
        editingItem: Item? = nil,
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        storageRepository: StorageRepositoryProtocol
    ) {
        self._viewModel = StateObject(wrappedValue: ItemFormViewModel(
            userId: userId,
            collectionId: collectionId,
            editingItem: editingItem,
            itemRepository: itemRepository,
            collectionRepository: collectionRepository,
            storageRepository: storageRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Main form content
                    formContent
                    
                    // Submit button
                    submitButton
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle(viewModel.formTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelForm()
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: .constant(!viewModel.validationErrors.isEmpty)) {
                Button("OK") {
                    viewModel.validationErrors = []
                }
            } message: {
                Text(viewModel.validationErrors.joined(separator: "\n"))
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack(spacing: 20) {
            // Basic Information Section
            basicInfoSection
            
            // Rating Section
            ratingSection
            
            // Images Section
            imagesSection
            
            // Tags Section
            tagsSection
            
            // Options Section
            optionsSection
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter item name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("Add a description...", text: $viewModel.description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Rating: \(viewModel.rating, specifier: "%.1f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Star display
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(viewModel.rating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                Slider(value: $viewModel.rating, in: 0...5, step: 0.5)
                    .accentColor(.blue)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: viewModel.selectImages) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Photo")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
            }
            
            if viewModel.selectedImageURLs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No photos added")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap 'Add Photo' to include images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedImageURLs.enumerated()), id: \.offset) { index, url in
                            ZStack(alignment: .topTrailing) {
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
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()
                                
                                Button(action: { viewModel.removeImage(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Add tag input
                HStack {
                    TextField("Add a tag...", text: $viewModel.newTag)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.addTag()
                        }
                    
                    Button("Add", action: viewModel.addTag)
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Display current tags
                if !viewModel.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Button(action: { viewModel.removeTag(tag) }) {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Toggle("Mark as Favorite", isOn: $viewModel.isFavorite)
                    .font(.subheadline)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitForm()
                if viewModel.validationErrors.isEmpty {
                    dismiss()
                }
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(viewModel.submitButtonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
}

// MARK: - Previews

#Preview("Create Item") {
    ItemFormView(
        userId: "preview-user",
        collectionId: "preview-collection",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
}

#Preview("Edit Item") {
    let sampleItem = Item(
        id: "sample-id",
        userId: "preview-user",
        collectionId: "preview-collection",
        name: "Sample Book",
        description: "A great book I'm reading",
        imageURLs: [],
        customFields: [:],
        isFavorite: true,
        tags: ["fiction", "sci-fi"],
        location: nil,
        rating: 4.5,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    ItemFormView(
        userId: "preview-user",
        collectionId: "preview-collection",
        editingItem: sampleItem,
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
}

#Preview("Dark Mode") {
    ItemFormView(
        userId: "preview-user",
        collectionId: "preview-collection",
        itemRepository: PreviewRepositoryProvider.shared.itemRepository,
        collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
        storageRepository: PreviewRepositoryProvider.shared.storageRepository
    )
    .preferredColorScheme(.dark)
}
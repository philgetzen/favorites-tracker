import SwiftUI
import PhotosUI

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
            
            // Data Tracking Section
            dataTrackingSection
            
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
                
                // Rich text description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes & Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    RichTextEditorView(
                        text: $viewModel.description,
                        placeholder: "Add notes, description, or any details about this item...",
                        minHeight: 140
                    )
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
            
            VStack(spacing: 16) {
                HStack {
                    Text("Rating: \(viewModel.rating, specifier: "%.1f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Enhanced star display with half-star support
                    StarRatingView(rating: viewModel.rating, maxRating: 5, starSize: 16)
                }
                
                // Interactive star rating (alternative to slider)
                VStack(spacing: 8) {
                    Text("Tap to rate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    InteractiveStarRatingView(
                        rating: $viewModel.rating,
                        maxRating: 5,
                        starSize: 24,
                        allowHalfStars: true
                    )
                }
                
                // Keep slider as alternative input method
                Text("Or use slider:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                
                PhotosPicker(selection: $viewModel.selectedPhotoItems, maxSelectionCount: 5, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Photo")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
            }
            
            if viewModel.selectedImageURLs.isEmpty && !viewModel.isUploadingImages {
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
            } else if viewModel.isUploadingImages && viewModel.selectedImageURLs.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Uploading photos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Show uploaded images
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
                        
                        // Show upload progress indicator if uploading
                        if viewModel.isUploadingImages {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    VStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Uploading...")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        TagManagerView(
            selectedTags: $viewModel.tags,
            availableTags: viewModel.availableTags,
            maxTags: 10,
            allowCustomTags: true
        )
    }
    
    private var dataTrackingSection: some View {
        DataTrackingView(
            customFields: $viewModel.customFields,
            title: "Data Tracking",
            showPriceTracking: true,
            showDateTracking: true,
            showAvailabilityTracking: true
        )
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
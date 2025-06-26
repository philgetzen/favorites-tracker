import SwiftUI
import PhotosUI

/// Image component for photo upload, display, and management
struct ImageComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var displayImages: [UIImage] = []
    @State private var imageURLs: [String] = []
    @State private var validationResult: ComponentValidationResult = .valid
    @State private var isLoadingImages = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageIndex: Int? = nil
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    private var maxImages: Int {
        if let validation = definition.validation,
           let maxValue = validation.maxValue {
            return Int(maxValue)
        }
        return allowsMultipleImages ? 10 : 1
    }
    
    private var allowsMultipleImages: Bool {
        let label = definition.label.lowercased()
        return label.contains("photos") || label.contains("images") || label.contains("gallery")
    }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize images from existing value
        if case .text(let urlsString) = value.wrappedValue, !urlsString.isEmpty {
            let urls = urlsString.components(separatedBy: ",").filter { !$0.isEmpty }
            self._imageURLs = State(initialValue: urls)
            // Note: In a real app, you'd load these images from URLs/storage
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label with required indicator
            HStack {
                Text(definition.label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if definition.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Spacer()
                
                // Image count indicator
                if !displayImages.isEmpty {
                    Text("\(displayImages.count)/\(maxImages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Image display and selection area
            VStack(spacing: 16) {
                if displayImages.isEmpty {
                    emptyStateView
                } else {
                    imageGridView
                }
                
                // Add image buttons
                imageControlsView
            }
            .overlay(
                // Loading indicator
                Group {
                    if isLoadingImages {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
            
            // Validation feedback
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
            
            // Helper text
            if let helperText = helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            validateInput()
        }
        .onChange(of: selectedImages) { oldImages, newImages in
            loadSelectedImages()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImages, maxSelectionCount: maxImages, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                addImage(image)
            }
        }
        .sheet(item: Binding<IdentifiableInt?>(
            get: { selectedImageIndex.map(IdentifiableInt.init) },
            set: { selectedImageIndex = $0?.value }
        )) { item in
            ImageDetailView(
                image: displayImages[item.value],
                imageIndex: item.value,
                totalImages: displayImages.count,
                onDelete: { deleteImage(at: item.value) },
                onReplace: { replaceImage(at: item.value) }
            )
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No images selected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(allowsMultipleImages ? "Add up to \(maxImages) images" : "Add an image")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
    }
    
    private var imageGridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(Array(displayImages.enumerated()), id: \.offset) { index, image in
                imageItemView(image: image, index: index)
            }
        }
    }
    
    private func imageItemView(image: UIImage, index: Int) -> some View {
        Button(action: {
            selectedImageIndex = index
        }) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageItemSize, height: imageItemSize)
                    .clipped()
                    .cornerRadius(8)
                
                // Delete button
                Button(action: {
                    deleteImage(at: index)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                        .font(.title3)
                }
                .offset(x: 8, y: -8)
                
                // Primary image indicator
                if index == 0 && allowsMultipleImages {
                    VStack {
                        Spacer()
                        HStack {
                            Text("Primary")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                            Spacer()
                        }
                    }
                    .padding(4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var imageControlsView: some View {
        HStack(spacing: 12) {
            // Photos picker button
            Button(action: {
                showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Photos")
                }
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(displayImages.count >= maxImages)
            
            // Camera button
            Button(action: {
                showingCamera = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .foregroundColor(.green)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(displayImages.count >= maxImages)
            
            Spacer()
            
            // Clear all button
            if !displayImages.isEmpty {
                Button(action: {
                    clearAllImages()
                }) {
                    Text("Clear All")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && displayImages.isEmpty {
            return .invalid("Please add at least one image")
        }
        
        // Check minimum count
        if let minValue = validationRule.minValue, displayImages.count < Int(minValue) {
            return .invalid("Please add at least \(Int(minValue)) image(s)")
        }
        
        // Check maximum count
        if let maxValue = validationRule.maxValue, displayImages.count > Int(maxValue) {
            return .invalid("Maximum \(Int(maxValue)) image(s) allowed")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var gridColumns: [GridItem] {
        let itemsPerRow = allowsMultipleImages ? 3 : 2
        return Array(repeating: GridItem(.flexible()), count: itemsPerRow)
    }
    
    private var imageItemSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 32 // Total horizontal padding
        let spacing: CGFloat = 12 * 2 // Grid spacing
        let itemsPerRow: CGFloat = allowsMultipleImages ? 3 : 2
        
        return (screenWidth - padding - spacing) / itemsPerRow
    }
    
    private var helperText: String? {
        let label = definition.label.lowercased()
        
        if label.contains("profile") {
            return "Add a profile photo"
        } else if label.contains("gallery") {
            return "Add multiple photos to showcase this item"
        } else if allowsMultipleImages {
            return "The first image will be used as the primary photo"
        }
        
        return "Tap to add an image"
    }
    
    private func loadSelectedImages() {
        guard !selectedImages.isEmpty else { return }
        
        isLoadingImages = true
        
        Task {
            var newImages: [UIImage] = []
            
            for item in selectedImages {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newImages.append(image)
                }
            }
            
            await MainActor.run {
                // Respect maximum image limit
                let availableSlots = maxImages - displayImages.count
                let imagesToAdd = Array(newImages.prefix(availableSlots))
                
                displayImages.append(contentsOf: imagesToAdd)
                updateValue()
                validateInput()
                isLoadingImages = false
                selectedImages.removeAll()
            }
        }
    }
    
    private func addImage(_ image: UIImage) {
        guard displayImages.count < maxImages else { return }
        
        displayImages.append(image)
        updateValue()
        validateInput()
    }
    
    private func deleteImage(at index: Int) {
        guard index < displayImages.count else { return }
        
        displayImages.remove(at: index)
        imageURLs.removeAll { _ in imageURLs.count > index }
        
        updateValue()
        validateInput()
    }
    
    private func replaceImage(at index: Int) {
        // This would typically open an image picker for replacement
        // For now, we'll just remove the image
        deleteImage(at: index)
    }
    
    private func clearAllImages() {
        displayImages.removeAll()
        imageURLs.removeAll()
        updateValue()
        validateInput()
    }
    
    private func updateValue() {
        if displayImages.isEmpty {
            value.wrappedValue = nil
        } else {
            // In a real app, you'd upload images and store URLs
            // For demo purposes, we'll create placeholder URLs
            let placeholderURLs = displayImages.enumerated().map { index, _ in
                "image_\(definition.id)_\(index).jpg"
            }
            value.wrappedValue = .text(placeholderURLs.joined(separator: ","))
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Supporting Views

private struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private struct ImageDetailView: View {
    let image: UIImage
    let imageIndex: Int
    let totalImages: Int
    let onDelete: () -> Void
    let onReplace: () -> Void
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZoomableImageView(image: image)
                .navigationTitle("Image \(imageIndex + 1) of \(totalImages)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Replace", action: onReplace)
                            Button("Delete", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}

private struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                
                                // Constrain scale
                                if scale < 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    withAnimation {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                } else if scale > 4.0 {
                                    scale = 4.0
                                    lastScale = 4.0
                                }
                            },
                        
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale == 1.0 {
                            scale = 2.0
                            lastScale = 2.0
                        } else {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
                }
        }
    }
}

// MARK: - Helper Types

private struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}

// MARK: - Preview Support

#if DEBUG
struct ImageComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Single image component
            ImageComponent(
                definition: ComponentDefinition(
                    id: "profile_photo",
                    type: .image,
                    label: "Profile Photo",
                    isRequired: true,
                    validation: ValidationRule(required: true)
                ),
                value: .constant(nil)
            )
            
            // Multiple images component
            ImageComponent(
                definition: ComponentDefinition(
                    id: "gallery",
                    type: .image,
                    label: "Photo Gallery",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                value: .constant(.text("image1.jpg,image2.jpg"))
            )
        }
        .padding()
    }
}
#endif
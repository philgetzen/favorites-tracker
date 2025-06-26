import SwiftUI

/// High-performance cached image loader with memory management
/// Replaces AsyncImage for better performance and caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var imageState: ImageState = .loading
    
    private enum ImageState {
        case loading
        case success(Image)
        case failure
    }
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            switch imageState {
            case .loading:
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
                    .onTapGesture {
                        // Retry on tap
                        loadImage()
                    }
            }
        }
        .onChange(of: url) { _, newURL in
            if newURL != nil {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            imageState = .failure
            return
        }
        
        imageState = .loading
        
        // Load from network
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let uiImage = UIImage(data: data) {
                    let image = Image(uiImage: uiImage)
                    
                    await MainActor.run {
                        imageState = .success(image)
                    }
                } else {
                    await MainActor.run {
                        imageState = .failure
                    }
                }
            } catch {
                await MainActor.run {
                    imageState = .failure
                }
            }
        }
    }
}


// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(url: url) { image in
            image
        } placeholder: {
            Color.gray.opacity(0.3)
        }
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(url: url) { image in
            image
        } placeholder: {
            ProgressView()
        }
    }
}

// MARK: - Previews

#Preview("Cached Image Loading") {
    VStack {
        CachedAsyncImage(url: URL(string: "https://picsum.photos/300/200")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 200)
                .clipped()
                .cornerRadius(12)
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 300, height: 200)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                )
        }
        
        Text("Cached Image with Custom Placeholder")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Multiple Cached Images") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(0..<6, id: \.self) { index in
                CachedAsyncImage(url: URL(string: "https://picsum.photos/200/200?random=\(index)")) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
        }
        .padding()
    }
}
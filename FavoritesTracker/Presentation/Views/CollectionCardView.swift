import SwiftUI

/// Card view for displaying collections
struct CollectionCardView: View {
    let collection: Collection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .overlay(
                    VStack {
                        Image(systemName: "folder.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("\(collection.itemCount)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                )
            
            // Collection details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(collection.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if collection.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let description = collection.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(collection.itemCount) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if collection.isPublic {
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if !collection.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(collection.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Previews

#Preview("Basic Collection") {
    CollectionCardView(collection: PreviewHelpers.sampleCollections[0])
        .frame(width: 200)
        .padding()
}

#Preview("Favorited Collection") {
    let favoriteCollection: Collection = {
        var collection = Collection(userId: "1", name: "Coffee Shops", templateId: "places-template")
        collection.isFavorite = true
        collection.tags = ["food", "drinks", "local"]
        return collection
    }()
    
    return CollectionCardView(collection: favoriteCollection)
        .frame(width: 200)
        .padding()
}

#Preview("Grid Layout") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
        ForEach(PreviewHelpers.sampleCollections, id: \.id) { collection in
            CollectionCardView(collection: collection)
        }
    }
    .padding()
}

#Preview("List Layout") {
    VStack(spacing: 12) {
        ForEach(PreviewHelpers.sampleCollections, id: \.id) { collection in
            CollectionCardView(collection: collection)
                .frame(maxWidth: .infinity)
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    CollectionCardView(collection: PreviewHelpers.sampleCollections[0])
        .frame(width: 200)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
        ForEach(PreviewHelpers.sampleCollections, id: \.id) { collection in
            CollectionCardView(collection: collection)
        }
    }
    .padding()
}
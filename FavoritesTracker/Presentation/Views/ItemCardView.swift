import SwiftUI

/// Card view for displaying individual items in collections
struct ItemCardView: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                )
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack {
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if !item.tags.isEmpty {
                        Text(item.tags.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let rating = item.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("Basic Item") {
    ItemCardView(item: PreviewHelpers.sampleItems[0])
        .frame(width: 180)
        .padding()
}

#Preview("Favorited Item") {
    let favoriteItem: Item = {
        var item = Item(userId: "1", collectionId: "1", name: "The Great Gatsby")
        item.isFavorite = true
        item.tags = ["fiction", "classic"]
        return item
    }()
    
    return ItemCardView(item: favoriteItem)
        .frame(width: 180)
        .padding()
}

#Preview("Grid Layout") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
        ForEach(PreviewHelpers.sampleItems, id: \.id) { item in
            ItemCardView(item: item)
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    ItemCardView(item: PreviewHelpers.sampleItems[0])
        .frame(width: 180)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("iPad Layout", traits: .landscapeLeft) {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
        ForEach(PreviewHelpers.sampleItems, id: \.id) { item in
            ItemCardView(item: item)
        }
    }
    .padding()
}
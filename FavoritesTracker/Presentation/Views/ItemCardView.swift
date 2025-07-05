import SwiftUI

/// Card view for displaying individual items in collections
struct ItemCardView: View {
    let item: Item
    let itemRepository: ItemRepositoryProtocol
    let collectionRepository: CollectionRepositoryProtocol
    let storageRepository: StorageRepositoryProtocol
    
    var body: some View {
        NavigationLink(destination: 
            ItemDetailViewRefactored(
                itemId: item.id,
                itemRepository: itemRepository,
                collectionRepository: collectionRepository,
                storageRepository: storageRepository
            )
        ) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item image
            imageSection
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
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
                                .foregroundColor(.secondary)
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
    
    private var imageSection: some View {
        Group {
            if let firstImageURL = item.imageURLs.first {
                AsyncImage(url: firstImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("Basic Item") {
    NavigationView {
        ItemCardView(
            item: PreviewHelpers.sampleItems[0],
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        .frame(width: 180)
        .padding()
    }
}

#Preview("Favorited Item") {
    let favoriteItem: Item = {
        var item = Item(userId: "1", collectionId: "1", name: "The Great Gatsby")
        item.isFavorite = true
        item.tags = ["fiction", "classic"]
        return item
    }()
    
    return NavigationView {
        ItemCardView(
            item: favoriteItem,
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        .frame(width: 180)
        .padding()
    }
}

#Preview("Grid Layout") {
    NavigationView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(PreviewHelpers.sampleItems, id: \.id) { item in
                ItemCardView(
                    item: item,
                    itemRepository: PreviewRepositoryProvider.shared.itemRepository,
                    collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
                    storageRepository: PreviewRepositoryProvider.shared.storageRepository
                )
            }
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    NavigationView {
        ItemCardView(
            item: PreviewHelpers.sampleItems[0],
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
            storageRepository: PreviewRepositoryProvider.shared.storageRepository
        )
        .frame(width: 180)
        .padding()
        .preferredColorScheme(.dark)
    }
}

#Preview("iPad Layout", traits: .landscapeLeft) {
    NavigationView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(PreviewHelpers.sampleItems, id: \.id) { item in
                ItemCardView(
                    item: item,
                    itemRepository: PreviewRepositoryProvider.shared.itemRepository,
                    collectionRepository: PreviewRepositoryProvider.shared.collectionRepository,
                    storageRepository: PreviewRepositoryProvider.shared.storageRepository
                )
            }
        }
        .padding()
    }
}
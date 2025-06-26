import Foundation

/// Concrete implementation of HomeServiceProtocol that handles business logic for the Home screen
final class HomeService: HomeServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let itemRepository: ItemRepositoryProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
    }
    
    // MARK: - HomeServiceProtocol Implementation
    
    func fetchData(for userId: String) async throws -> (collections: [Collection], items: [Item]) {
        // Fetch collections and items concurrently for better performance
        async let collectionsTask = collectionRepository.getCollections(for: userId)
        async let itemsTask = itemRepository.getItems(for: userId)
        
        let collections = try await collectionsTask
        let items = try await itemsTask
        
        return (collections: collections, items: items)
    }
    
    func fetchCollections(for userId: String) async throws -> [Collection] {
        return try await collectionRepository.getCollections(for: userId)
    }
    
    func fetchItems(for userId: String) async throws -> [Item] {
        return try await itemRepository.getItems(for: userId)
    }
    
    func searchItems(query: String, userId: String) async throws -> [Item] {
        return try await itemRepository.searchItems(query: query, userId: userId)
    }
    
    func advancedSearch(query: String, filters: SearchFilters, userId: String) async throws -> [Item] {
        // Get all items first (use "*" for empty query to get all items)
        let searchQuery = query.isEmpty ? "*" : query
        let allItems = try await itemRepository.searchItems(query: searchQuery, userId: userId)
        
        // Apply filters and sorting
        let filteredItems = applyFilters(to: allItems, with: filters)
        let sortedItems = sortItems(filteredItems, by: filters.sortBy)
        
        return sortedItems
    }
    
    func createDefaultCollection(for userId: String) async throws -> Collection {
        let defaultCollection = Collection(
            userId: userId,
            name: "My Collection"
        )
        
        return try await collectionRepository.createCollection(defaultCollection)
    }
    
    func applyFilters(to items: [Item], with filters: SearchFilters) -> [Item] {
        return items.filter { item in
            // Favorites filter
            if filters.favoritesOnly && !item.isFavorite {
                return false
            }
            
            // Recent items filter (last 30 days)
            if filters.recentItemsOnly {
                let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
                if item.createdAt < thirtyDaysAgo {
                    return false
                }
            }
            
            // Has images filter
            if filters.hasImagesOnly && item.imageURLs.isEmpty {
                return false
            }
            
            // Has notes filter
            if filters.hasNotesOnly && (item.description?.isEmpty ?? true) {
                return false
            }
            
            // Rating range filter
            let itemRating = item.rating ?? 0.0
            if itemRating < filters.minimumRating || itemRating > filters.maximumRating {
                return false
            }
            
            // Date range filter
            if let dateFrom = filters.dateFrom, item.createdAt < dateFrom {
                return false
            }
            if let dateTo = filters.dateTo, item.createdAt > dateTo {
                return false
            }
            
            // Tags filter (item must have ALL specified tags)
            if !filters.includeTags.isEmpty {
                let hasAllTags = filters.includeTags.allSatisfy { requiredTag in
                    item.tags.contains(requiredTag)
                }
                if !hasAllTags {
                    return false
                }
            }
            
            return true
        }
    }
    
    func sortItems(_ items: [Item], by sortOption: SortOption) -> [Item] {
        switch sortOption {
        case .newest:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return items.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .ratingHigh:
            return items.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .ratingLow:
            return items.sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }
        case .recentlyUpdated:
            return items.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeService {
    @MainActor
    static func preview() -> HomeService {
        return HomeService(
            itemRepository: PreviewRepositoryProvider.shared.itemRepository,
            collectionRepository: PreviewRepositoryProvider.shared.collectionRepository
        )
    }
}
#endif
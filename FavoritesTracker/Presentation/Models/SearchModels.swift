import Foundation

/// Filter criteria for search operations
struct SearchFilters {
    var favoritesOnly: Bool = false
    var recentItemsOnly: Bool = false
    var hasImagesOnly: Bool = false
    var hasNotesOnly: Bool = false
    var minimumRating: Double = 0.0
    var maximumRating: Double = 5.0
    var dateFrom: Date?
    var dateTo: Date?
    var includeTags: [String] = []
    var sortBy: SortOption = .newest
    
    /// Indicates whether any filters are active
    var isEmpty: Bool {
        !favoritesOnly &&
        !recentItemsOnly &&
        !hasImagesOnly &&
        !hasNotesOnly &&
        minimumRating == 0.0 &&
        maximumRating == 5.0 &&
        dateFrom == nil &&
        dateTo == nil &&
        includeTags.isEmpty &&
        sortBy == .newest
    }
    
    /// Cache key for memoization of filter operations
    var cacheKey: String {
        let dateFromString = dateFrom?.timeIntervalSince1970.description ?? "nil"
        let dateToString = dateTo?.timeIntervalSince1970.description ?? "nil"
        let tagsString = includeTags.sorted().joined(separator: ",")
        
        return "\(favoritesOnly)_\(recentItemsOnly)_\(hasImagesOnly)_\(hasNotesOnly)_\(minimumRating)_\(maximumRating)_\(dateFromString)_\(dateToString)_\(tagsString)_\(sortBy.rawValue)"
    }
}

/// Available sort options for search results
enum SortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case nameAZ = "name_az"
    case nameZA = "name_za"
    case ratingHigh = "rating_high"
    case ratingLow = "rating_low"
    case recentlyUpdated = "recently_updated"
    
    /// Display name for the sort option
    var displayName: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .nameAZ: return "Name A-Z"
        case .nameZA: return "Name Z-A"
        case .ratingHigh: return "Rating ↓"
        case .ratingLow: return "Rating ↑"
        case .recentlyUpdated: return "Updated"
        }
    }
}
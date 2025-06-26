import Foundation

/// Protocol defining the business logic interface for the Home screen
protocol HomeServiceProtocol: Sendable {
    /// Fetches collections and items for a user concurrently
    func fetchData(for userId: String) async throws -> (collections: [Collection], items: [Item])
    
    /// Fetches collections for a specific user
    func fetchCollections(for userId: String) async throws -> [Collection]
    
    /// Fetches items for a specific user
    func fetchItems(for userId: String) async throws -> [Item]
    
    /// Performs a basic search for items
    func searchItems(query: String, userId: String) async throws -> [Item]
    
    /// Performs an advanced search with filters
    func advancedSearch(query: String, filters: SearchFilters, userId: String) async throws -> [Item]
    
    /// Creates a default collection for a user if none exist
    func createDefaultCollection(for userId: String) async throws -> Collection
    
    /// Applies client-side filters to a list of items
    func applyFilters(to items: [Item], with filters: SearchFilters) -> [Item]
    
    /// Sorts items based on the specified sort option
    func sortItems(_ items: [Item], by sortOption: SortOption) -> [Item]
}
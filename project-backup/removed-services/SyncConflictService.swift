import Foundation

/// Service for handling sync conflicts and resolution strategies
@MainActor
final class SyncConflictService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var pendingConflicts: [SyncConflict] = []
    @Published var isResolving = false
    @Published var lastResolutionResult: ConflictResolutionResult?
    
    // MARK: - Dependencies
    
    private let itemRepository: ItemRepositoryProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    private let networkMonitor: NetworkMonitorService
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        networkMonitor: NetworkMonitorService
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - Conflict Detection
    
    /// Detects conflicts between local and remote versions of data
    /// - Parameters:
    ///   - localItems: Items from local storage
    ///   - remoteItems: Items from remote server
    /// - Returns: Array of detected conflicts
    func detectConflicts(
        localItems: [Item],
        remoteItems: [Item]
    ) -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        // Create lookup dictionaries for efficient comparison
        let localItemsDict = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
        let remoteItemsDict = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })
        
        // Check for conflicts in items that exist in both local and remote
        for (itemId, localItem) in localItemsDict {
            if let remoteItem = remoteItemsDict[itemId] {
                if let conflict = detectItemConflict(local: localItem, remote: remoteItem) {
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    /// Detects conflicts for collections
    /// - Parameters:
    ///   - localCollections: Collections from local storage
    ///   - remoteCollections: Collections from remote server
    /// - Returns: Array of detected collection conflicts
    func detectCollectionConflicts(
        localCollections: [Collection],
        remoteCollections: [Collection]
    ) -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        let localCollectionsDict = Dictionary(uniqueKeysWithValues: localCollections.map { ($0.id, $0) })
        let remoteCollectionsDict = Dictionary(uniqueKeysWithValues: remoteCollections.map { ($0.id, $0) })
        
        for (collectionId, localCollection) in localCollectionsDict {
            if let remoteCollection = remoteCollectionsDict[collectionId] {
                if let conflict = detectCollectionConflict(local: localCollection, remote: remoteCollection) {
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolves a sync conflict using the specified strategy
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - strategy: The resolution strategy to use
    /// - Returns: The resolution result
    func resolveConflict(
        _ conflict: SyncConflict,
        using strategy: ConflictResolutionStrategy
    ) async throws -> ConflictResolutionResult {
        isResolving = true
        
        do {
            let result: ConflictResolutionResult
            
            switch conflict.type {
            case .item:
                result = try await resolveItemConflict(conflict, using: strategy)
            case .collection:
                result = try await resolveCollectionConflict(conflict, using: strategy)
            }
            
            // Remove resolved conflict from pending list
            pendingConflicts.removeAll { $0.id == conflict.id }
            
            lastResolutionResult = result
            isResolving = false
            
            return result
            
        } catch {
            isResolving = false
            throw error
        }
    }
    
    /// Resolves multiple conflicts using automated strategies
    /// - Parameter conflicts: Array of conflicts to resolve
    /// - Returns: Array of resolution results
    func resolveConflictsAutomatically(_ conflicts: [SyncConflict]) async throws -> [ConflictResolutionResult] {
        var results: [ConflictResolutionResult] = []
        
        for conflict in conflicts {
            let strategy = determineOptimalStrategy(for: conflict)
            let result = try await resolveConflict(conflict, using: strategy)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func detectItemConflict(local: Item, remote: Item) -> SyncConflict? {
        // Check if both versions have been modified since last sync
        let localModified = local.updatedAt
        let remoteModified = remote.updatedAt
        
        // If timestamps are equal, no conflict
        if localModified == remoteModified {
            return nil
        }
        
        // Determine which version is newer
        let isLocalNewer = localModified > remoteModified
        
        // Check for specific field conflicts
        var conflictedFields: [ConflictField] = []
        
        if local.name != remote.name {
            conflictedFields.append(.name)
        }
        
        if local.description != remote.description {
            conflictedFields.append(.description)
        }
        
        if local.rating != remote.rating {
            conflictedFields.append(.rating)
        }
        
        if local.isFavorite != remote.isFavorite {
            conflictedFields.append(.isFavorite)
        }
        
        if local.tags != remote.tags {
            conflictedFields.append(.tags)
        }
        
        if !areCustomFieldsEqual(local.customFields, remote.customFields) {
            conflictedFields.append(.customFields)
        }
        
        // Only create conflict if there are actual field differences
        if conflictedFields.isEmpty {
            return nil
        }
        
        return SyncConflict(
            id: UUID().uuidString,
            entityId: local.id,
            type: .item,
            localVersion: .item(local),
            remoteVersion: .item(remote),
            conflictedFields: conflictedFields,
            detectedAt: Date(),
            isLocalNewer: isLocalNewer
        )
    }
    
    private func detectCollectionConflict(local: Collection, remote: Collection) -> SyncConflict? {
        let localModified = local.updatedAt
        let remoteModified = remote.updatedAt
        
        if localModified == remoteModified {
            return nil
        }
        
        let isLocalNewer = localModified > remoteModified
        var conflictedFields: [ConflictField] = []
        
        if local.name != remote.name {
            conflictedFields.append(.name)
        }
        
        if local.description != remote.description {
            conflictedFields.append(.description)
        }
        
        if local.isFavorite != remote.isFavorite {
            conflictedFields.append(.isFavorite)
        }
        
        if local.tags != remote.tags {
            conflictedFields.append(.tags)
        }
        
        if local.isPublic != remote.isPublic {
            conflictedFields.append(.isPublic)
        }
        
        if conflictedFields.isEmpty {
            return nil
        }
        
        return SyncConflict(
            id: UUID().uuidString,
            entityId: local.id,
            type: .collection,
            localVersion: .collection(local),
            remoteVersion: .collection(remote),
            conflictedFields: conflictedFields,
            detectedAt: Date(),
            isLocalNewer: isLocalNewer
        )
    }
    
    private func resolveItemConflict(
        _ conflict: SyncConflict,
        using strategy: ConflictResolutionStrategy
    ) async throws -> ConflictResolutionResult {
        guard case .item(let localItem) = conflict.localVersion,
              case .item(let remoteItem) = conflict.remoteVersion else {
            throw SyncConflictError.invalidConflictType
        }
        
        let resolvedItem: Item
        
        switch strategy {
        case .useLocal:
            resolvedItem = localItem
            
        case .useRemote:
            resolvedItem = remoteItem
            
        case .useNewer:
            resolvedItem = conflict.isLocalNewer ? localItem : remoteItem
            
        case .merge:
            resolvedItem = try mergeItems(local: localItem, remote: remoteItem, conflict: conflict)
            
        case .manual:
            throw SyncConflictError.manualResolutionRequired
        }
        
        // Save the resolved item
        let savedItem = try await itemRepository.updateItem(resolvedItem)
        
        return ConflictResolutionResult(
            conflictId: conflict.id,
            strategy: strategy,
            resolvedEntity: .item(savedItem),
            resolvedAt: Date()
        )
    }
    
    private func resolveCollectionConflict(
        _ conflict: SyncConflict,
        using strategy: ConflictResolutionStrategy
    ) async throws -> ConflictResolutionResult {
        guard case .collection(let localCollection) = conflict.localVersion,
              case .collection(let remoteCollection) = conflict.remoteVersion else {
            throw SyncConflictError.invalidConflictType
        }
        
        let resolvedCollection: Collection
        
        switch strategy {
        case .useLocal:
            resolvedCollection = localCollection
            
        case .useRemote:
            resolvedCollection = remoteCollection
            
        case .useNewer:
            resolvedCollection = conflict.isLocalNewer ? localCollection : remoteCollection
            
        case .merge:
            resolvedCollection = try mergeCollections(local: localCollection, remote: remoteCollection, conflict: conflict)
            
        case .manual:
            throw SyncConflictError.manualResolutionRequired
        }
        
        // Save the resolved collection
        let savedCollection = try await collectionRepository.updateCollection(resolvedCollection)
        
        return ConflictResolutionResult(
            conflictId: conflict.id,
            strategy: strategy,
            resolvedEntity: .collection(savedCollection),
            resolvedAt: Date()
        )
    }
    
    private func mergeItems(local: Item, remote: Item, conflict: SyncConflict) throws -> Item {
        // Smart merge strategy: prefer the newer value for each field
        let useLocalForField = conflict.isLocalNewer
        
        return Item(
            id: local.id,
            userId: local.userId,
            collectionId: local.collectionId,
            name: conflict.conflictedFields.contains(.name) 
                ? (useLocalForField ? local.name : remote.name) 
                : local.name,
            description: conflict.conflictedFields.contains(.description)
                ? (useLocalForField ? local.description : remote.description)
                : local.description,
            imageURLs: local.imageURLs, // Images are typically not conflicted
            customFields: conflict.conflictedFields.contains(.customFields)
                ? mergeCustomFields(local: local.customFields, remote: remote.customFields)
                : local.customFields,
            isFavorite: conflict.conflictedFields.contains(.isFavorite)
                ? (useLocalForField ? local.isFavorite : remote.isFavorite)
                : local.isFavorite,
            tags: conflict.conflictedFields.contains(.tags)
                ? mergeTags(local: local.tags, remote: remote.tags)
                : local.tags,
            location: local.location,
            rating: conflict.conflictedFields.contains(.rating)
                ? (useLocalForField ? local.rating : remote.rating)
                : local.rating,
            createdAt: min(local.createdAt, remote.createdAt), // Use earliest creation date
            updatedAt: max(local.updatedAt, remote.updatedAt)  // Use latest update date
        )
    }
    
    private func mergeCollections(local: Collection, remote: Collection, conflict: SyncConflict) throws -> Collection {
        let useLocalForField = conflict.isLocalNewer
        
        return Collection(
            id: local.id,
            userId: local.userId,
            name: conflict.conflictedFields.contains(.name)
                ? (useLocalForField ? local.name : remote.name)
                : local.name,
            description: conflict.conflictedFields.contains(.description)
                ? (useLocalForField ? local.description : remote.description)
                : local.description,
            templateId: local.templateId,
            itemCount: max(local.itemCount, remote.itemCount), // Use higher count
            coverImageURL: local.coverImageURL,
            isFavorite: conflict.conflictedFields.contains(.isFavorite)
                ? (useLocalForField ? local.isFavorite : remote.isFavorite)
                : local.isFavorite,
            tags: conflict.conflictedFields.contains(.tags)
                ? mergeTags(local: local.tags, remote: remote.tags)
                : local.tags,
            isPublic: conflict.conflictedFields.contains(.isPublic)
                ? (useLocalForField ? local.isPublic : remote.isPublic)
                : local.isPublic,
            createdAt: min(local.createdAt, remote.createdAt),
            updatedAt: max(local.updatedAt, remote.updatedAt)
        )
    }
    
    private func mergeCustomFields(
        local: [String: CustomFieldValue],
        remote: [String: CustomFieldValue]
    ) -> [String: CustomFieldValue] {
        var merged = local
        
        // Add fields that exist only in remote
        for (key, value) in remote {
            if merged[key] == nil {
                merged[key] = value
            }
        }
        
        return merged
    }
    
    private func mergeTags(local: [String], remote: [String]) -> [String] {
        // Merge tags by combining both arrays and removing duplicates
        return Array(Set(local + remote)).sorted()
    }
    
    private func areCustomFieldsEqual(
        _ fields1: [String: CustomFieldValue],
        _ fields2: [String: CustomFieldValue]
    ) -> Bool {
        guard fields1.count == fields2.count else { return false }
        
        for (key, value1) in fields1 {
            guard let value2 = fields2[key] else { return false }
            if value1.stringValue != value2.stringValue {
                return false
            }
        }
        
        return true
    }
    
    private func determineOptimalStrategy(for conflict: SyncConflict) -> ConflictResolutionStrategy {
        // Simple heuristic: if local is newer and has more fields, prefer local
        // Otherwise, try to merge
        if conflict.isLocalNewer && conflict.conflictedFields.count <= 2 {
            return .useLocal
        } else if !conflict.isLocalNewer && conflict.conflictedFields.count <= 2 {
            return .useRemote
        } else {
            return .merge
        }
    }
}

// MARK: - Supporting Types

/// Represents a sync conflict between local and remote versions
struct SyncConflict: Identifiable {
    let id: String
    let entityId: String
    let type: ConflictEntityType
    let localVersion: ConflictEntity
    let remoteVersion: ConflictEntity
    let conflictedFields: [ConflictField]
    let detectedAt: Date
    let isLocalNewer: Bool
}

/// Types of entities that can have conflicts
enum ConflictEntityType {
    case item
    case collection
}

/// Wrapper for conflicted entities
enum ConflictEntity {
    case item(Item)
    case collection(Collection)
}

/// Fields that can be in conflict
enum ConflictField {
    case name
    case description
    case rating
    case isFavorite
    case tags
    case customFields
    case isPublic
}

/// Strategies for resolving conflicts
enum ConflictResolutionStrategy {
    case useLocal      // Keep local version
    case useRemote     // Use remote version
    case useNewer      // Use version with later timestamp
    case merge         // Attempt intelligent merge
    case manual        // Require manual resolution
}

/// Result of conflict resolution
struct ConflictResolutionResult {
    let conflictId: String
    let strategy: ConflictResolutionStrategy
    let resolvedEntity: ConflictEntity
    let resolvedAt: Date
}

/// Errors that can occur during conflict resolution
enum SyncConflictError: LocalizedError {
    case invalidConflictType
    case manualResolutionRequired
    case mergeFailed
    case resolutionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConflictType:
            return "Invalid conflict type for resolution"
        case .manualResolutionRequired:
            return "Manual resolution required for this conflict"
        case .mergeFailed:
            return "Failed to merge conflicted versions"
        case .resolutionFailed(let reason):
            return "Conflict resolution failed: \(reason)"
        }
    }
}
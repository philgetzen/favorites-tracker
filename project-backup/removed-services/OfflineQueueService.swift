import Foundation
import Combine

/// Service for managing offline operations queue and sync
/// Handles operations performed while offline and replays them when connectivity is restored
@MainActor
final class OfflineQueueService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessingQueue = false
    @Published var queuedOperations: [OfflineOperation] = []
    @Published var lastSyncResult: OfflineSyncResult?
    @Published var hasPendingOperations: Bool = false
    
    // MARK: - Dependencies
    
    private let itemRepository: ItemRepositoryProtocol
    private let collectionRepository: CollectionRepositoryProtocol
    private let networkMonitor: NetworkMonitorService
    private let syncConflictService: SyncConflictService
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let queueStorageKey = "offline_operations_queue"
    private let maxRetryAttempts = 3
    
    // MARK: - Initialization
    
    init(
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        networkMonitor: NetworkMonitorService,
        syncConflictService: SyncConflictService
    ) {
        self.itemRepository = itemRepository
        self.collectionRepository = collectionRepository
        self.networkMonitor = networkMonitor
        self.syncConflictService = syncConflictService
        
        setupNetworkMonitoring()
        loadQueuedOperations()
    }
    
    // MARK: - Queue Management
    
    /// Adds an operation to the offline queue
    /// - Parameter operation: The operation to queue
    func queueOperation(_ operation: OfflineOperation) {
        queuedOperations.append(operation)
        hasPendingOperations = true
        saveQueuedOperations()
        
        // Try to process immediately if online
        if networkMonitor.isConnected {
            Task {
                await processQueuedOperations()
            }
        }
    }
    
    /// Processes all queued operations when connectivity is restored
    func processQueuedOperations() async {
        guard networkMonitor.isConnected && !isProcessingQueue else {
            return
        }
        
        isProcessingQueue = true
        
        var processedOperations: [OfflineOperation] = []
        var failedOperations: [OfflineOperation] = []
        var conflictingOperations: [OfflineOperation] = []
        
        for operation in queuedOperations {
            do {
                let result = try await processOperation(operation)
                
                switch result {
                case .success:
                    processedOperations.append(operation)
                case .conflict(let conflicts):
                    conflictingOperations.append(operation)
                    // Add conflicts to sync conflict service for resolution
                    syncConflictService.pendingConflicts.append(contentsOf: conflicts)
                case .failed:
                    if operation.retryCount < maxRetryAttempts {
                        // Increment retry count and keep in queue
                        var retryOperation = operation
                        retryOperation.retryCount += 1
                        retryOperation.lastAttemptAt = Date()
                        failedOperations.append(retryOperation)
                    } else {
                        // Max retries reached, remove from queue
                        processedOperations.append(operation)
                    }
                }
                
            } catch {
                if operation.retryCount < maxRetryAttempts {
                    var retryOperation = operation
                    retryOperation.retryCount += 1
                    retryOperation.lastAttemptAt = Date()
                    retryOperation.lastError = error.localizedDescription
                    failedOperations.append(retryOperation)
                } else {
                    processedOperations.append(operation)
                }
            }
        }
        
        // Update queued operations (remove processed, keep failed for retry)
        queuedOperations = failedOperations + conflictingOperations
        hasPendingOperations = !queuedOperations.isEmpty
        saveQueuedOperations()
        
        // Create sync result
        lastSyncResult = OfflineSyncResult(
            totalOperations: processedOperations.count + failedOperations.count + conflictingOperations.count,
            successfulOperations: processedOperations.count,
            failedOperations: failedOperations.count,
            conflictingOperations: conflictingOperations.count,
            syncedAt: Date()
        )
        
        isProcessingQueue = false
    }
    
    /// Removes all queued operations (use with caution)
    func clearQueue() {
        queuedOperations.removeAll()
        hasPendingOperations = false
        saveQueuedOperations()
    }
    
    /// Gets the count of pending operations by type
    func getPendingOperationCounts() -> [OfflineOperationType: Int] {
        var counts: [OfflineOperationType: Int] = [:]
        
        for operation in queuedOperations {
            counts[operation.type, default: 0] += 1
        }
        
        return counts
    }
    
    // MARK: - Convenience Methods for Common Operations
    
    /// Queues an item creation operation
    func queueItemCreation(_ item: Item) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .createItem,
            entityId: item.id,
            data: try? JSONEncoder().encode(item),
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    /// Queues an item update operation
    func queueItemUpdate(_ item: Item) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .updateItem,
            entityId: item.id,
            data: try? JSONEncoder().encode(item),
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    /// Queues an item deletion operation
    func queueItemDeletion(_ itemId: String) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .deleteItem,
            entityId: itemId,
            data: nil,
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    /// Queues a collection creation operation
    func queueCollectionCreation(_ collection: Collection) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .createCollection,
            entityId: collection.id,
            data: try? JSONEncoder().encode(collection),
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    /// Queues a collection update operation
    func queueCollectionUpdate(_ collection: Collection) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .updateCollection,
            entityId: collection.id,
            data: try? JSONEncoder().encode(collection),
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    /// Queues a collection deletion operation
    func queueCollectionDeletion(_ collectionId: String) {
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .deleteCollection,
            entityId: collectionId,
            data: nil,
            createdAt: Date()
        )
        queueOperation(operation)
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        await self?.processQueuedOperations()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func processOperation(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        switch operation.type {
        case .createItem:
            return try await processItemCreation(operation)
        case .updateItem:
            return try await processItemUpdate(operation)
        case .deleteItem:
            return try await processItemDeletion(operation)
        case .createCollection:
            return try await processCollectionCreation(operation)
        case .updateCollection:
            return try await processCollectionUpdate(operation)
        case .deleteCollection:
            return try await processCollectionDeletion(operation)
        }
    }
    
    private func processItemCreation(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        guard let data = operation.data,
              let item = try? JSONDecoder().decode(Item.self, from: data) else {
            throw OfflineQueueError.invalidOperationData
        }
        
        // Check if item already exists (might have been synced from another device)
        if let existingItem = try await itemRepository.getItem(id: item.id) {
            // Item already exists, check for conflicts
            let conflicts = syncConflictService.detectConflicts(
                localItems: [item],
                remoteItems: [existingItem]
            )
            
            if !conflicts.isEmpty {
                return .conflict(conflicts)
            } else {
                return .success
            }
        }
        
        // Create the item
        _ = try await itemRepository.createItem(item)
        return .success
    }
    
    private func processItemUpdate(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        guard let data = operation.data,
              let item = try? JSONDecoder().decode(Item.self, from: data) else {
            throw OfflineQueueError.invalidOperationData
        }
        
        // Check if item exists remotely
        if let remoteItem = try await itemRepository.getItem(id: item.id) {
            // Check for conflicts
            let conflicts = syncConflictService.detectConflicts(
                localItems: [item],
                remoteItems: [remoteItem]
            )
            
            if !conflicts.isEmpty {
                return .conflict(conflicts)
            }
        }
        
        // Update the item
        _ = try await itemRepository.updateItem(item)
        return .success
    }
    
    private func processItemDeletion(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        // Check if item still exists
        if let _ = try await itemRepository.getItem(id: operation.entityId) {
            try await itemRepository.deleteItem(id: operation.entityId)
        }
        // If item doesn't exist, consider it successful (already deleted)
        return .success
    }
    
    private func processCollectionCreation(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        guard let data = operation.data,
              let collection = try? JSONDecoder().decode(Collection.self, from: data) else {
            throw OfflineQueueError.invalidOperationData
        }
        
        // Check if collection already exists
        if let existingCollection = try await collectionRepository.getCollection(id: collection.id) {
            // Collection already exists, check for conflicts
            let conflicts = syncConflictService.detectCollectionConflicts(
                localCollections: [collection],
                remoteCollections: [existingCollection]
            )
            
            if !conflicts.isEmpty {
                return .conflict(conflicts)
            } else {
                return .success
            }
        }
        
        // Create the collection
        _ = try await collectionRepository.createCollection(collection)
        return .success
    }
    
    private func processCollectionUpdate(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        guard let data = operation.data,
              let collection = try? JSONDecoder().decode(Collection.self, from: data) else {
            throw OfflineQueueError.invalidOperationData
        }
        
        // Check if collection exists remotely
        if let remoteCollection = try await collectionRepository.getCollection(id: collection.id) {
            // Check for conflicts
            let conflicts = syncConflictService.detectCollectionConflicts(
                localCollections: [collection],
                remoteCollections: [remoteCollection]
            )
            
            if !conflicts.isEmpty {
                return .conflict(conflicts)
            }
        }
        
        // Update the collection
        _ = try await collectionRepository.updateCollection(collection)
        return .success
    }
    
    private func processCollectionDeletion(_ operation: OfflineOperation) async throws -> OfflineOperationResult {
        // Check if collection still exists
        if let _ = try await collectionRepository.getCollection(id: operation.entityId) {
            try await collectionRepository.deleteCollection(id: operation.entityId)
        }
        // If collection doesn't exist, consider it successful (already deleted)
        return .success
    }
    
    private func loadQueuedOperations() {
        if let data = UserDefaults.standard.data(forKey: queueStorageKey),
           let operations = try? JSONDecoder().decode([OfflineOperation].self, from: data) {
            queuedOperations = operations
            hasPendingOperations = !operations.isEmpty
        }
    }
    
    private func saveQueuedOperations() {
        if let data = try? JSONEncoder().encode(queuedOperations) {
            UserDefaults.standard.set(data, forKey: queueStorageKey)
        }
    }
}

// MARK: - Supporting Types

/// Represents an operation that was performed while offline
struct OfflineOperation: Codable {
    let id: String
    let type: OfflineOperationType
    let entityId: String
    let data: Data? // Encoded entity data
    let createdAt: Date
    var retryCount: Int = 0
    var lastAttemptAt: Date?
    var lastError: String?
}

/// Types of operations that can be queued while offline
enum OfflineOperationType: String, Codable, CaseIterable {
    case createItem
    case updateItem
    case deleteItem
    case createCollection
    case updateCollection
    case deleteCollection
}

/// Result of processing an offline operation
enum OfflineOperationResult {
    case success
    case conflict([SyncConflict])
    case failed
}

/// Result of a complete offline sync operation
struct OfflineSyncResult {
    let totalOperations: Int
    let successfulOperations: Int
    let failedOperations: Int
    let conflictingOperations: Int
    let syncedAt: Date
    
    var successRate: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(successfulOperations) / Double(totalOperations)
    }
    
    var hasConflicts: Bool {
        return conflictingOperations > 0
    }
    
    var hasFailures: Bool {
        return failedOperations > 0
    }
}

/// Errors that can occur in the offline queue service
enum OfflineQueueError: LocalizedError {
    case invalidOperationData
    case operationProcessingFailed(String)
    case queueStorageError
    
    var errorDescription: String? {
        switch self {
        case .invalidOperationData:
            return "Invalid data in offline operation"
        case .operationProcessingFailed(let reason):
            return "Failed to process offline operation: \(reason)"
        case .queueStorageError:
            return "Failed to store offline operations queue"
        }
    }
}
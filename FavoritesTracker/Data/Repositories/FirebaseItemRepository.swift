import Foundation
import FirebaseFirestore
import Combine

/// Firebase implementation of ItemRepositoryProtocol
/// Handles Firestore operations for items with real-time synchronization
final class FirebaseItemRepository: ItemRepositoryProtocol, @unchecked Sendable {
    
    private let firestore: Firestore
    private let collectionName = FirestoreCollection.Groups.items
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    // MARK: - ItemRepositoryProtocol Implementation
    
    func getItems(for userId: String) async throws -> [Item] {
        let query = firestore.collectionGroup(collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let itemDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: ItemDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(itemDTOs, using: ItemMapper.self)
    }
    
    func getItem(id: String) async throws -> Item? {
        // Since items are in subcollections, we need to search across all collections
        let query = firestore.collectionGroup(collectionName)
            .whereField("id", isEqualTo: id)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        let itemDTO = try document.data(as: ItemDTO.self)
        return ItemMapper.toDomain(itemDTO)
    }
    
    func createItem(_ item: Item) async throws -> Item {
        let itemDTO = ItemMapper.toFirestore(item)
        let itemPath = FirestoreCollection.Paths.collectionItem(
            item.userId,
            collectionId: item.collectionId,
            itemId: item.id
        )
        
        let documentRef = firestore.document(itemPath)
        
        _ = try await firestore.runTransaction { transaction, errorPointer in
            do {
                // Create the item
                try transaction.setData(itemDTO.asDictionary(), forDocument: documentRef)
                
                // Update collection item count
                let collectionPath = FirestoreCollection.Paths.userCollection(item.userId, collectionId: item.collectionId)
                let collectionRef = self.firestore.document(collectionPath)
                transaction.updateData([
                    "itemCount": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: collectionRef)
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        return item
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        let itemDTO = ItemMapper.toFirestore(item)
        let itemPath = FirestoreCollection.Paths.collectionItem(
            item.userId,
            collectionId: item.collectionId,
            itemId: item.id
        )
        
        var updateData = try itemDTO.asDictionary()
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await firestore.document(itemPath).updateData(updateData)
        return item
    }
    
    func deleteItem(id: String) async throws {
        // Find the item first to get its collection info
        guard let item = try await getItem(id: id) else {
            throw RepositoryError.itemNotFound
        }
        
        let itemPath = FirestoreCollection.Paths.collectionItem(
            item.userId,
            collectionId: item.collectionId,
            itemId: item.id
        )
        
        _ = try await firestore.runTransaction { transaction, errorPointer in
            // Delete the item
            transaction.deleteDocument(self.firestore.document(itemPath))
            
            // Update collection item count
            let collectionPath = FirestoreCollection.Paths.userCollection(item.userId, collectionId: item.collectionId)
            let collectionRef = self.firestore.document(collectionPath)
            transaction.updateData([
                "itemCount": FieldValue.increment(Int64(-1)),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: collectionRef)
            
            return nil
        }
    }
    
    func searchItems(query: String, userId: String) async throws -> [Item] {
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !searchTerms.isEmpty else {
            return try await getItems(for: userId)
        }
        
        // Firestore doesn't support full-text search, so we use array-contains-any
        // This is a simplified search - for production, consider using Algolia or similar
        let firestoreQuery = firestore.collectionGroup(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("searchTerms", arrayContainsAny: searchTerms)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)
        
        let snapshot = try await firestoreQuery.getDocuments()
        let itemDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: ItemDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(itemDTOs, using: ItemMapper.self)
    }
    
    // MARK: - Additional Methods
    
    /// Get items for a specific collection
    func getItems(for userId: String, collectionId: String) async throws -> [Item] {
        let collectionPath = FirestoreCollection.Paths.userCollection(userId, collectionId: collectionId)
        let query = firestore.collection("\(collectionPath)/\(FirestoreCollection.items)")
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let itemDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: ItemDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(itemDTOs, using: ItemMapper.self)
    }
    
    /// Get favorite items for a user
    func getFavoriteItems(for userId: String) async throws -> [Item] {
        let query = firestore.collectionGroup(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("isFavorite", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let itemDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: ItemDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(itemDTOs, using: ItemMapper.self)
    }
    
    /// Listen to real-time updates for items in a collection
    func listenToItems(for userId: String, collectionId: String) -> AnyPublisher<[Item], Error> {
        let collectionPath = FirestoreCollection.Paths.userCollection(userId, collectionId: collectionId)
        let query = firestore.collection("\(collectionPath)/\(FirestoreCollection.items)")
            .order(by: "createdAt", descending: true)
        
        return Publishers.FirestoreQuery(query: query)
            .map { snapshot in
                let itemDTOs = snapshot.documents.compactMap { document in
                    try? document.data(as: ItemDTO.self)
                }
                return FirestoreBatchMapper.toDomain(itemDTOs, using: ItemMapper.self)
            }
            .eraseToAnyPublisher()
    }
}

// RepositoryError is now defined in Data/Models/RepositoryError.swift

// MARK: - Extensions

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw RepositoryError.invalidData
        }
        return dictionary
    }
}

// MARK: - Firestore Publisher

extension Publishers {
    struct FirestoreQuery: Publisher {
        typealias Output = QuerySnapshot
        typealias Failure = Error
        
        let query: Query
        
        func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, QuerySnapshot == S.Input {
            let subscription = FirestoreQuerySubscription(subscriber: subscriber, query: query)
            subscriber.receive(subscription: subscription)
        }
    }
}

final class FirestoreQuerySubscription<S: Subscriber>: Subscription where S.Input == QuerySnapshot, S.Failure == Error {
    private var subscriber: S?
    private var listener: ListenerRegistration?
    
    init(subscriber: S, query: Query) {
        self.subscriber = subscriber
        
        listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                subscriber.receive(completion: .failure(error))
            } else if let snapshot = snapshot {
                _ = subscriber.receive(snapshot)
            }
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        // Firestore listeners don't use demand
    }
    
    func cancel() {
        listener?.remove()
        subscriber = nil
    }
}
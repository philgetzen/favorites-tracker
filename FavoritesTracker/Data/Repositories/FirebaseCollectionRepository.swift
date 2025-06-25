import Foundation
import FirebaseFirestore
import Combine

/// Firebase implementation of CollectionRepositoryProtocol
/// Handles Firestore operations for collections with real-time synchronization
final class FirebaseCollectionRepository: CollectionRepositoryProtocol, @unchecked Sendable {
    
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    // MARK: - CollectionRepositoryProtocol Implementation
    
    func getCollections(for userId: String) async throws -> [Collection] {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.collections)")
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let collectionDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: CollectionDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
    }
    
    func getCollection(id: String) async throws -> Collection? {
        // Since collections are in subcollections, we need to search across all users
        // In practice, you'd typically know the userId, but this handles the general case
        let query = firestore.collectionGroup(FirestoreCollection.collections)
            .whereField("id", isEqualTo: id)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        let collectionDTO = try document.data(as: CollectionDTO.self)
        return CollectionMapper.toDomain(collectionDTO)
    }
    
    func createCollection(_ collection: Collection) async throws -> Collection {
        let collectionDTO = CollectionMapper.toFirestore(collection)
        let collectionPath = FirestoreCollection.Paths.userCollection(collection.userId, collectionId: collection.id)
        
        let documentRef = firestore.document(collectionPath)
        try await documentRef.setData(try collectionDTO.asDictionary())
        
        return collection
    }
    
    func updateCollection(_ collection: Collection) async throws -> Collection {
        let collectionDTO = CollectionMapper.toFirestore(collection)
        let collectionPath = FirestoreCollection.Paths.userCollection(collection.userId, collectionId: collection.id)
        
        var updateData = try collectionDTO.asDictionary()
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await firestore.document(collectionPath).updateData(updateData)
        return collection
    }
    
    func deleteCollection(id: String) async throws {
        // Find the collection first to get user info
        guard let collection = try await getCollection(id: id) else {
            throw RepositoryError.collectionNotFound
        }
        
        let collectionPath = FirestoreCollection.Paths.userCollection(collection.userId, collectionId: collection.id)
        
        _ = try await firestore.runTransaction { transaction, errorPointer in
            let collectionRef = self.firestore.document(collectionPath)
            
            // Delete all items in the collection first
            let itemsPath = "\(collectionPath)/\(FirestoreCollection.items)"
            let itemsQuery = self.firestore.collection(itemsPath)
            
            // Note: In a production app, you'd want to batch delete items
            // For simplicity, we're just deleting the collection document
            // The items will be orphaned and should be cleaned up separately
            transaction.deleteDocument(collectionRef)
            
            return nil
        }
    }
    
    // MARK: - Additional Methods
    
    /// Get collections by template ID
    func getCollections(for userId: String, templateId: String) async throws -> [Collection] {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.collections)")
            .whereField("templateId", isEqualTo: templateId)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let collectionDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: CollectionDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
    }
    
    /// Get favorite collections for a user
    func getFavoriteCollections(for userId: String) async throws -> [Collection] {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.collections)")
            .whereField("isFavorite", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let collectionDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: CollectionDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
    }
    
    /// Get public collections (for discovery)
    func getPublicCollections(limit: Int = 20) async throws -> [Collection] {
        let query = firestore.collectionGroup(FirestoreCollection.collections)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let collectionDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: CollectionDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
    }
    
    /// Search collections by name and tags
    func searchCollections(query: String, userId: String) async throws -> [Collection] {
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !searchTerms.isEmpty else {
            return try await getCollections(for: userId)
        }
        
        let userPath = FirestoreCollection.Paths.user(userId)
        let firestoreQuery = firestore.collection("\(userPath)/\(FirestoreCollection.collections)")
            .whereField("searchTerms", arrayContainsAny: searchTerms)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)
        
        let snapshot = try await firestoreQuery.getDocuments()
        let collectionDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: CollectionDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
    }
    
    /// Listen to real-time updates for user collections
    func listenToCollections(for userId: String) -> AnyPublisher<[Collection], Error> {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.collections)")
            .order(by: "updatedAt", descending: true)
        
        return Publishers.FirestoreQuery(query: query)
            .map { snapshot in
                let collectionDTOs = snapshot.documents.compactMap { document in
                    try? document.data(as: CollectionDTO.self)
                }
                return FirestoreBatchMapper.toDomain(collectionDTOs, using: CollectionMapper.self)
            }
            .eraseToAnyPublisher()
    }
    
    /// Update collection item count
    func updateItemCount(collectionId: String, userId: String, increment: Int) async throws {
        let collectionPath = FirestoreCollection.Paths.userCollection(userId, collectionId: collectionId)
        let updateData: [String: Any] = [
            "itemCount": FieldValue.increment(Int64(increment)),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(collectionPath).updateData(updateData)
    }
    
    /// Get collection with specific user and collection ID
    func getCollection(userId: String, collectionId: String) async throws -> Collection? {
        let collectionPath = FirestoreCollection.Paths.userCollection(userId, collectionId: collectionId)
        let document = try await firestore.document(collectionPath).getDocument()
        
        guard document.exists, let collectionDTO = try? document.data(as: CollectionDTO.self) else {
            return nil
        }
        
        return CollectionMapper.toDomain(collectionDTO)
    }
}
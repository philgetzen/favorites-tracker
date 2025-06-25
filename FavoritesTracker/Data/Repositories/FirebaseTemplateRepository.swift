import Foundation
import FirebaseFirestore
import Combine

/// Firebase implementation of TemplateRepositoryProtocol
/// Handles Firestore operations for templates with marketplace functionality
final class FirebaseTemplateRepository: TemplateRepositoryProtocol, @unchecked Sendable {
    
    private let firestore: Firestore
    private let collectionName = FirestoreCollection.templates
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    // MARK: - TemplateRepositoryProtocol Implementation
    
    func getTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "downloadCount", descending: true)
            .limit(to: 100)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    func getTemplate(id: String) async throws -> Template? {
        let documentPath = FirestoreCollection.Paths.template(id)
        let document = try await firestore.document(documentPath).getDocument()
        
        guard document.exists, let templateDTO = try? document.data(as: TemplateDTO.self) else {
            return nil
        }
        
        return TemplateMapper.toDomain(templateDTO)
    }
    
    func createTemplate(_ template: Template) async throws -> Template {
        let templateDTO = TemplateMapper.toFirestore(template)
        let documentPath = FirestoreCollection.Paths.template(template.id)
        
        try await firestore.document(documentPath).setData(try templateDTO.asDictionary())
        return template
    }
    
    func updateTemplate(_ template: Template) async throws -> Template {
        let templateDTO = TemplateMapper.toFirestore(template)
        let documentPath = FirestoreCollection.Paths.template(template.id)
        
        var updateData = try templateDTO.asDictionary()
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await firestore.document(documentPath).updateData(updateData)
        return template
    }
    
    func deleteTemplate(id: String) async throws {
        let documentPath = FirestoreCollection.Paths.template(id)
        try await firestore.document(documentPath).delete()
    }
    
    func searchTemplates(query: String, category: String?) async throws -> [Template] {
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var firestoreQuery = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
        
        // Add category filter if provided
        if let category = category {
            firestoreQuery = firestoreQuery.whereField("category", isEqualTo: category)
        }
        
        // Add search terms filter if provided
        if !searchTerms.isEmpty {
            firestoreQuery = firestoreQuery.whereField("searchTerms", arrayContainsAny: searchTerms)
        }
        
        firestoreQuery = firestoreQuery
            .order(by: "downloadCount", descending: true)
            .limit(to: 50)
        
        let snapshot = try await firestoreQuery.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    func getFeaturedTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "downloadCount", descending: true)
            .limit(to: 10)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    // MARK: - Additional Template Methods
    
    /// Get templates by category
    func getTemplates(category: String) async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .whereField("category", isEqualTo: category)
            .order(by: "downloadCount", descending: true)
            .limit(to: 50)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Get templates created by a specific user
    func getTemplates(createdBy userId: String) async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Get premium templates
    func getPremiumTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .whereField("isPremium", isEqualTo: true)
            .order(by: "downloadCount", descending: true)
            .limit(to: 50)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Get free templates
    func getFreeTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .whereField("isPremium", isEqualTo: false)
            .order(by: "downloadCount", descending: true)
            .limit(to: 50)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Increment template download count
    func incrementDownloadCount(templateId: String) async throws {
        let documentPath = FirestoreCollection.Paths.template(templateId)
        let updateData: [String: Any] = [
            "downloadCount": FieldValue.increment(Int64(1)),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(documentPath).updateData(updateData)
    }
    
    /// Update template rating
    func updateTemplateRating(templateId: String, newRating: Double) async throws {
        let documentPath = FirestoreCollection.Paths.template(templateId)
        let updateData: [String: Any] = [
            "rating": newRating,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(documentPath).updateData(updateData)
    }
    
    /// Get templates sorted by newest
    func getNewestTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Get templates sorted by highest rated
    func getTopRatedTemplates() async throws -> [Template] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .whereField("rating", isGreaterThan: 0)
            .order(by: "rating", descending: true)
            .limit(to: 20)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
    }
    
    /// Get all categories with template counts
    func getTemplateCategories() async throws -> [String: Int] {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
        
        let snapshot = try await query.getDocuments()
        let templateDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: TemplateDTO.self)
        }
        
        var categoryCounts: [String: Int] = [:]
        for template in templateDTOs {
            categoryCounts[template.category, default: 0] += 1
        }
        
        return categoryCounts
    }
    
    /// Listen to real-time updates for featured templates
    func listenToFeaturedTemplates() -> AnyPublisher<[Template], Error> {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "downloadCount", descending: true)
            .limit(to: 10)
        
        return Publishers.FirestoreQuery(query: query)
            .map { snapshot in
                let templateDTOs = snapshot.documents.compactMap { document in
                    try? document.data(as: TemplateDTO.self)
                }
                return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
            }
            .eraseToAnyPublisher()
    }
    
    /// Listen to real-time updates for templates by category
    func listenToTemplates(category: String) -> AnyPublisher<[Template], Error> {
        let query = firestore.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .whereField("category", isEqualTo: category)
            .order(by: "downloadCount", descending: true)
            .limit(to: 50)
        
        return Publishers.FirestoreQuery(query: query)
            .map { snapshot in
                let templateDTOs = snapshot.documents.compactMap { document in
                    try? document.data(as: TemplateDTO.self)
                }
                return FirestoreBatchMapper.toDomain(templateDTOs, using: TemplateMapper.self)
            }
            .eraseToAnyPublisher()
    }
}
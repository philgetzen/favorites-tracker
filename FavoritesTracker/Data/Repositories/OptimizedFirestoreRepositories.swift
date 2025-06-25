import Foundation
import FirebaseFirestore
import Combine

// MARK: - Optimized Firestore Repository Implementations

/// High-performance implementation of CollectionRepositoryProtocol
class OptimizedCollectionRepository: CollectionRepositoryProtocol, @unchecked Sendable {
    private let performanceManager: FirestorePerformanceManager
    private let performanceMonitor: FirestorePerformanceMonitor
    
    init(performanceManager: FirestorePerformanceManager = FirestorePerformanceManager()) {
        self.performanceManager = performanceManager
        self.performanceMonitor = FirestorePerformanceMonitor()
    }
    
    func getCollections(for userId: String) async throws -> [Collection] {
        let startTime = Date()
        
        let query = performanceManager.queries.optimizedCollectionQuery(
            userId: userId,
            filters: CollectionFilters(),
            pagination: PaginationOptions(limit: 50)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: CollectionDTO.self,
            cacheKey: "user_collections_\(userId)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getCollections",
            duration: duration,
            documentCount: results.count,
            fromCache: false // TODO: Detect cache usage
        )
        
        return results.map { $0.toDomain() }
    }
    
    func getCollection(id: String) async throws -> Collection? {
        let startTime = Date()
        
        // Use batch read for efficient single document retrieval
        let docRef = performanceManager.queries.db.collectionGroup("collections")
            .whereField("id", isEqualTo: id)
            .limit(to: 1)
        
        let snapshot = try await docRef.getDocuments()
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getCollection",
            duration: duration,
            documentCount: snapshot.documents.count,
            fromCache: snapshot.metadata.isFromCache
        )
        
        guard let document = snapshot.documents.first else { return nil }
        let dto = try CollectionDTO.fromFirestore(document)
        return dto.toDomain()
    }
    
    func createCollection(_ collection: Collection) async throws -> Collection {
        let startTime = Date()
        let dto = CollectionDTO.fromDomain(collection)
        
        let operation = BatchWriteOperation<CollectionDTO>.create(
            performanceManager.queries.db.collection("users")
                .document(collection.userId)
                .collection("collections")
                .document(collection.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "createCollection",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return collection
    }
    
    func updateCollection(_ collection: Collection) async throws -> Collection {
        let startTime = Date()
        let dto = CollectionDTO.fromDomain(collection)
        
        let operation = BatchWriteOperation<CollectionDTO>.update(
            performanceManager.queries.db.collection("users")
                .document(collection.userId)
                .collection("collections")
                .document(collection.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "updateCollection",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return collection
    }
    
    func deleteCollection(id: String) async throws {
        let startTime = Date()
        
        // First, get the collection to find the document path
        guard let collection = try await getCollection(id: id) else {
            throw RepositoryError.notFound("Collection not found")
        }
        
        let operation = BatchWriteOperation<CollectionDTO>.delete(
            performanceManager.queries.db.collection("users")
                .document(collection.userId)
                .collection("collections")
                .document(id)
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "deleteCollection",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
    }
    
    func searchCollections(query: String, userId: String) async throws -> [Collection] {
        let startTime = Date()
        
        let filters = CollectionFilters(searchTerm: query)
        let firestoreQuery = performanceManager.queries.optimizedCollectionQuery(
            userId: userId,
            filters: filters,
            pagination: PaginationOptions(limit: 20)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: firestoreQuery,
            type: CollectionDTO.self,
            cacheKey: "search_collections_\(userId)_\(query.hashValue)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "searchCollections",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
}

/// High-performance implementation of ItemRepositoryProtocol
class OptimizedItemRepository: ItemRepositoryProtocol, @unchecked Sendable {
    private let performanceManager: FirestorePerformanceManager
    private let performanceMonitor: FirestorePerformanceMonitor
    
    init(performanceManager: FirestorePerformanceManager = FirestorePerformanceManager()) {
        self.performanceManager = performanceManager
        self.performanceMonitor = FirestorePerformanceMonitor()
    }
    
    func getItems(for userId: String) async throws -> [Item] {
        let startTime = Date()
        
        let filters = ItemFilters(crossCollection: true)
        let query = performanceManager.queries.optimizedItemsQuery(
            userId: userId,
            filters: filters,
            pagination: PaginationOptions(limit: 100)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: ItemDTO.self,
            cacheKey: "user_items_\(userId)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getItems",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    func getItem(id: String) async throws -> Item? {
        let startTime = Date()
        
        let query = performanceManager.queries.db.collectionGroup("items")
            .whereField("id", isEqualTo: id)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getItem",
            duration: duration,
            documentCount: snapshot.documents.count,
            fromCache: snapshot.metadata.isFromCache
        )
        
        guard let document = snapshot.documents.first else { return nil }
        let dto = try ItemDTO.fromFirestore(document)
        return dto.toDomain()
    }
    
    func createItem(_ item: Item) async throws -> Item {
        let startTime = Date()
        let dto = ItemDTO.fromDomain(item)
        
        let operation = BatchWriteOperation<ItemDTO>.create(
            performanceManager.queries.db.collection("users")
                .document(item.userId)
                .collection("collections")
                .document(item.collectionId)
                .collection("items")
                .document(item.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "createItem",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return item
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        let startTime = Date()
        let dto = ItemDTO.fromDomain(item)
        
        let operation = BatchWriteOperation<ItemDTO>.update(
            performanceManager.queries.db.collection("users")
                .document(item.userId)
                .collection("collections")
                .document(item.collectionId)
                .collection("items")
                .document(item.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "updateItem",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return item
    }
    
    func deleteItem(id: String) async throws {
        let startTime = Date()
        
        guard let item = try await getItem(id: id) else {
            throw RepositoryError.notFound("Item not found")
        }
        
        let operation = BatchWriteOperation<ItemDTO>.delete(
            performanceManager.queries.db.collection("users")
                .document(item.userId)
                .collection("collections")
                .document(item.collectionId)
                .collection("items")
                .document(id)
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "deleteItem",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
    }
    
    func searchItems(query: String, userId: String) async throws -> [Item] {
        let startTime = Date()
        
        let filters = ItemFilters(crossCollection: true, searchTerm: query)
        let firestoreQuery = performanceManager.queries.optimizedItemsQuery(
            userId: userId,
            filters: filters,
            pagination: PaginationOptions(limit: 50)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: firestoreQuery,
            type: ItemDTO.self,
            cacheKey: "search_items_\(userId)_\(query.hashValue)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "searchItems",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    // MARK: - Bulk Operations
    
    /// Efficiently create multiple items using batch operations
    func createItems(_ items: [Item]) async throws -> [Item] {
        let startTime = Date()
        
        let operations = items.map { item in
            let dto = ItemDTO.fromDomain(item)
            return BatchWriteOperation<ItemDTO>.create(
                performanceManager.queries.db.collection("users")
                    .document(item.userId)
                    .collection("collections")
                    .document(item.collectionId)
                    .collection("items")
                    .document(item.id),
                dto
            )
        }
        
        try await performanceManager.batching.batchWrite(operations: operations) { completed, total in
            print("Creating items: \(completed)/\(total) batches completed")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "createItems",
            duration: duration,
            documentCount: items.count,
            fromCache: false
        )
        
        return items
    }
    
    /// Efficiently update multiple items using batch operations
    func updateItems(_ items: [Item]) async throws -> [Item] {
        let startTime = Date()
        
        let operations = items.map { item in
            let dto = ItemDTO.fromDomain(item)
            return BatchWriteOperation<ItemDTO>.update(
                performanceManager.queries.db.collection("users")
                    .document(item.userId)
                    .collection("collections")
                    .document(item.collectionId)
                    .collection("items")
                    .document(item.id),
                dto
            )
        }
        
        try await performanceManager.batching.batchWrite(operations: operations) { completed, total in
            print("Updating items: \(completed)/\(total) batches completed")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "updateItems",
            duration: duration,
            documentCount: items.count,
            fromCache: false
        )
        
        return items
    }
}

/// High-performance implementation of TemplateRepositoryProtocol
class OptimizedTemplateRepository: TemplateRepositoryProtocol, @unchecked Sendable {
    private let performanceManager: FirestorePerformanceManager
    private let performanceMonitor: FirestorePerformanceMonitor
    
    init(performanceManager: FirestorePerformanceManager = FirestorePerformanceManager()) {
        self.performanceManager = performanceManager
        self.performanceMonitor = FirestorePerformanceMonitor()
    }
    
    func getTemplates() async throws -> [Template] {
        let startTime = Date()
        
        let query = performanceManager.queries.optimizedTemplateQuery(
            filters: TemplateFilters(),
            pagination: PaginationOptions(limit: 50)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: TemplateDTO.self,
            cacheKey: "public_templates"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getTemplates",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    func getTemplate(id: String) async throws -> Template? {
        let startTime = Date()
        
        let docRef = performanceManager.queries.db.collection("templates").document(id)
        let snapshot = try await docRef.getDocument()
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getTemplate",
            duration: duration,
            documentCount: snapshot.exists ? 1 : 0,
            fromCache: snapshot.metadata.isFromCache
        )
        
        guard snapshot.exists else { return nil }
        let dto = try TemplateDTO.fromFirestore(snapshot)
        return dto.toDomain()
    }
    
    func createTemplate(_ template: Template) async throws -> Template {
        let startTime = Date()
        let dto = TemplateDTO.fromDomain(template)
        
        let operation = BatchWriteOperation<TemplateDTO>.create(
            performanceManager.queries.db.collection("templates").document(template.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "createTemplate",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return template
    }
    
    func updateTemplate(_ template: Template) async throws -> Template {
        let startTime = Date()
        let dto = TemplateDTO.fromDomain(template)
        
        let operation = BatchWriteOperation<TemplateDTO>.update(
            performanceManager.queries.db.collection("templates").document(template.id),
            dto
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "updateTemplate",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
        
        return template
    }
    
    func deleteTemplate(id: String) async throws {
        let startTime = Date()
        
        let operation = BatchWriteOperation<TemplateDTO>.delete(
            performanceManager.queries.db.collection("templates").document(id)
        )
        
        try await performanceManager.batching.batchWrite(operations: [operation])
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "deleteTemplate",
            duration: duration,
            documentCount: 1,
            fromCache: false
        )
    }
    
    func searchTemplates(query: String, category: String? = nil) async throws -> [Template] {
        let startTime = Date()
        
        let filters = TemplateFilters(category: category, searchTerm: query)
        let firestoreQuery = performanceManager.queries.optimizedTemplateQuery(
            filters: filters,
            pagination: PaginationOptions(limit: 20)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: firestoreQuery,
            type: TemplateDTO.self,
            cacheKey: "search_templates_\(query.hashValue)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "searchTemplates",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    // MARK: - Advanced Template Queries
    
    func getTemplatesByCategory(_ category: String) async throws -> [Template] {
        let startTime = Date()
        
        let filters = TemplateFilters(category: category)
        let query = performanceManager.queries.optimizedTemplateQuery(
            filters: filters,
            pagination: PaginationOptions(limit: 30)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: TemplateDTO.self,
            cacheKey: "templates_category_\(category)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getTemplatesByCategory",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    func getPopularTemplates(limit: Int = 10) async throws -> [Template] {
        let startTime = Date()
        
        let filters = TemplateFilters(sortBy: .popularity)
        let query = performanceManager.queries.optimizedTemplateQuery(
            filters: filters,
            pagination: PaginationOptions(limit: limit)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: TemplateDTO.self,
            cacheKey: "popular_templates_\(limit)"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getPopularTemplates",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
    
    func getFeaturedTemplates() async throws -> [Template] {
        let startTime = Date()
        
        // Featured templates are those that are popular and highly rated
        var filters = TemplateFilters()
        filters.sortBy = .popularity
        let query = performanceManager.queries.optimizedTemplateQuery(
            filters: filters,
            pagination: PaginationOptions(limit: 10)
        )
        
        let results = try await performanceManager.queries.executeWithCache(
            query: query,
            type: TemplateDTO.self,
            cacheKey: "featured_templates"
        )
        
        let duration = Date().timeIntervalSince(startTime)
        performanceMonitor.recordQuery(
            operation: "getFeaturedTemplates",
            duration: duration,
            documentCount: results.count,
            fromCache: false
        )
        
        return results.map { $0.toDomain() }
    }
}

// MARK: - Repository Protocol Extensions

// MARK: - Error Types

// RepositoryError is now defined in Data/Models/RepositoryError.swift

// MARK: - DTO to Domain Conversions

extension CollectionDTO {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> CollectionDTO {
        guard let data = document.data() else {
            throw RepositoryError.dataCorruption("Document has no data")
        }
        return try Firestore.Decoder().decode(CollectionDTO.self, from: data)
    }
    
    func toDomain() -> Collection {
        let collection = Collection(userId: userId, name: name, templateId: templateId)
        // Copy over all the properties that can't be set in the initializer
        // Note: This would need proper Collection initializer or property setters
        return collection
    }
    
    static func fromDomain(_ collection: Collection) -> CollectionDTO {
        return CollectionDTO(
            id: collection.id,
            userId: collection.userId,
            name: collection.name,
            description: collection.description,
            templateId: collection.templateId,
            itemCount: collection.itemCount,
            coverImageURL: collection.coverImageURL?.absoluteString,
            isFavorite: collection.isFavorite,
            tags: collection.tags,
            isPublic: collection.isPublic,
            createdAt: Timestamp(date: collection.createdAt),
            updatedAt: Timestamp(date: collection.updatedAt),
            searchTerms: generateSearchTerms(collection)
        )
    }
    
    private static func generateSearchTerms(_ collection: Collection) -> [String] {
        var terms = [collection.name.lowercased()]
        terms.append(contentsOf: collection.tags.map { $0.lowercased() })
        if let description = collection.description {
            terms.append(contentsOf: description.lowercased().components(separatedBy: .whitespacesAndNewlines))
        }
        return Array(Set(terms)).filter { !$0.isEmpty }
    }
}

extension ItemDTO {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> ItemDTO {
        guard let data = document.data() else {
            throw RepositoryError.dataCorruption("Document has no data")
        }
        return try Firestore.Decoder().decode(ItemDTO.self, from: data)
    }
    
    func toDomain() -> Item {
        let item = Item(userId: userId, collectionId: collectionId, name: name)
        // Copy over additional properties
        // Note: This would need proper Item initializer or property setters
        return item
    }
    
    static func fromDomain(_ item: Item) -> ItemDTO {
        return ItemDTO(
            id: item.id,
            userId: item.userId,
            collectionId: item.collectionId,
            name: item.name,
            description: item.description,
            imageURLs: item.imageURLs.map { $0.absoluteString },
            customFields: item.customFields.mapValues { CustomFieldValueDTO.fromDomain($0) },
            isFavorite: item.isFavorite,
            tags: item.tags,
            location: item.location.map { LocationDTO.fromDomain($0) },
            rating: item.rating,
            createdAt: Timestamp(date: item.createdAt),
            updatedAt: Timestamp(date: item.updatedAt),
            searchTerms: generateSearchTerms(item)
        )
    }
    
    private static func generateSearchTerms(_ item: Item) -> [String] {
        var terms = [item.name.lowercased()]
        terms.append(contentsOf: item.tags.map { $0.lowercased() })
        if let description = item.description {
            terms.append(contentsOf: description.lowercased().components(separatedBy: .whitespacesAndNewlines))
        }
        return Array(Set(terms)).filter { !$0.isEmpty }
    }
}

extension TemplateDTO {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> TemplateDTO {
        guard let data = document.data() else {
            throw RepositoryError.dataCorruption("Document has no data")
        }
        return try Firestore.Decoder().decode(TemplateDTO.self, from: data)
    }
    
    func toDomain() -> Template {
        let template = Template(creatorId: creatorId, name: name, description: description, category: category)
        // Copy over additional properties
        // Note: This would need proper Template initializer or property setters
        return template
    }
    
    static func fromDomain(_ template: Template) -> TemplateDTO {
        return TemplateDTO(
            id: template.id,
            creatorId: template.creatorId,
            name: template.name,
            description: template.description,
            category: template.category,
            components: template.components.map { ComponentDefinitionDTO.fromDomain($0) },
            previewImageURL: template.previewImageURL?.absoluteString,
            isFavorite: template.isFavorite,
            tags: template.tags,
            isPublic: template.isPublic,
            isPremium: template.isPremium,
            downloadCount: template.downloadCount,
            rating: template.rating,
            createdAt: Timestamp(date: template.createdAt),
            updatedAt: Timestamp(date: template.updatedAt),
            searchTerms: generateSearchTerms(template),
            creatorDisplayName: nil // Would be populated from user data
        )
    }
    
    private static func generateSearchTerms(_ template: Template) -> [String] {
        var terms = [template.name.lowercased(), template.category.lowercased()]
        terms.append(contentsOf: template.tags.map { $0.lowercased() })
        terms.append(contentsOf: template.description.lowercased().components(separatedBy: .whitespacesAndNewlines))
        return Array(Set(terms)).filter { !$0.isEmpty }
    }
}

// MARK: - Additional DTO Conversion Extensions

extension CustomFieldValueDTO {
    func toDomain() -> CustomFieldValue {
        switch type {
        case "text":
            return .text(stringValue ?? "")
        case "number":
            return .number(numberValue ?? 0.0)
        case "date":
            return .date(dateValue?.dateValue() ?? Date())
        case "boolean":
            return .boolean(booleanValue ?? false)
        case "url":
            return .url(URL(string: stringValue ?? "") ?? URL(string: "https://example.com")!)
        default:
            return .text(stringValue ?? "")
        }
    }
    
    static func fromDomain(_ value: CustomFieldValue) -> CustomFieldValueDTO {
        switch value {
        case .text(let text):
            return CustomFieldValueDTO(type: "text", stringValue: text, numberValue: nil, dateValue: nil, booleanValue: nil)
        case .number(let number):
            return CustomFieldValueDTO(type: "number", stringValue: nil, numberValue: number, dateValue: nil, booleanValue: nil)
        case .date(let date):
            return CustomFieldValueDTO(type: "date", stringValue: nil, numberValue: nil, dateValue: Timestamp(date: date), booleanValue: nil)
        case .boolean(let bool):
            return CustomFieldValueDTO(type: "boolean", stringValue: nil, numberValue: nil, dateValue: nil, booleanValue: bool)
        case .url(let url):
            return CustomFieldValueDTO(type: "url", stringValue: url.absoluteString, numberValue: nil, dateValue: nil, booleanValue: nil)
        case .image(let url):
            return CustomFieldValueDTO(type: "url", stringValue: url.absoluteString, numberValue: nil, dateValue: nil, booleanValue: nil)
        }
    }
}

extension LocationDTO {
    func toDomain() -> Location {
        return Location(
            latitude: latitude,
            longitude: longitude,
            address: address,
            name: name
        )
    }
    
    static func fromDomain(_ location: Location) -> LocationDTO {
        return LocationDTO(
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.address,
            name: location.name
        )
    }
}

extension ComponentDefinitionDTO {
    func toDomain() -> ComponentDefinition {
        let componentType = ComponentDefinition.ComponentType(rawValue: type) ?? .textField
        
        return ComponentDefinition(
            id: id,
            type: componentType,
            label: label,
            isRequired: isRequired,
            defaultValue: defaultValue?.toDomain(),
            options: options,
            validation: validation?.toDomain()
        )
    }
    
    static func fromDomain(_ component: ComponentDefinition) -> ComponentDefinitionDTO {
        return ComponentDefinitionDTO(
            id: component.id,
            type: component.type.rawValue,
            label: component.label,
            isRequired: component.isRequired,
            defaultValue: component.defaultValue.map { CustomFieldValueDTO.fromDomain($0) },
            options: component.options,
            validation: component.validation.map { ValidationRuleDTO.fromDomain($0) }
        )
    }
}

extension ValidationRuleDTO {
    func toDomain() -> ValidationRule {
        return ValidationRule(
            minLength: minLength,
            maxLength: maxLength,
            minValue: nil, // Not available in DTO
            maxValue: nil, // Not available in DTO
            pattern: pattern,
            required: true // Default assumption
        )
    }
    
    static func fromDomain(_ rule: ValidationRule) -> ValidationRuleDTO {
        return ValidationRuleDTO(
            minLength: rule.minLength,
            maxLength: rule.maxLength,
            pattern: rule.pattern
        )
    }
}
import Foundation
import FirebaseFirestore

// MARK: - Data Migration Strategy for Schema Evolution

/// Central coordinator for managing database schema evolution and data migrations
class DataMigrationManager: @unchecked Sendable {
    private let db: Firestore
    private let migrationHistory: MigrationHistoryRepository
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
        self.migrationHistory = MigrationHistoryRepository(firestore: firestore)
    }
    
    /// Execute all pending migrations
    func runMigrations() async throws {
        let currentVersion = await getCurrentSchemaVersion()
        let targetVersion = SchemaVersion.current
        
        if currentVersion < targetVersion {
            let migrations = getMigrationsToRun(from: currentVersion, to: targetVersion)
            
            for migration in migrations {
                try await executeMigration(migration)
                await recordMigrationCompletion(migration)
            }
        }
    }
    
    /// Check if migrations are needed
    func needsMigration() async -> Bool {
        let currentVersion = await getCurrentSchemaVersion()
        return currentVersion < SchemaVersion.current
    }
    
    private func getCurrentSchemaVersion() async -> SchemaVersion {
        // Implementation to check current schema version from metadata collection
        return await migrationHistory.getCurrentVersion()
    }
    
    private func getMigrationsToRun(from: SchemaVersion, to: SchemaVersion) -> [Migration] {
        return MigrationRegistry.migrations.filter { migration in
            migration.version > from && migration.version <= to
        }.sorted { $0.version < $1.version }
    }
    
    private func executeMigration(_ migration: Migration) async throws {
        print("Executing migration: \(migration.name) (v\(migration.version.rawValue))")
        try await migration.execute(firestore: db)
        print("Migration completed: \(migration.name)")
    }
    
    private func recordMigrationCompletion(_ migration: Migration) async {
        await migrationHistory.recordMigration(migration)
    }
}

// MARK: - Schema Version Management

/// Enum representing schema versions for migration tracking
enum SchemaVersion: Int, CaseIterable, Comparable {
    case v1_0 = 100  // Initial version
    case v1_1 = 101  // Added search terms
    case v1_2 = 102  // Added location fields
    case v1_3 = 103  // Added subscription info
    case v1_4 = 104  // Added template versioning
    case v2_0 = 200  // Major version with breaking changes
    
    static let current: SchemaVersion = .v2_0
    
    static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Migration Protocol and Base Classes

/// Protocol defining a database migration
protocol Migration {
    var version: SchemaVersion { get }
    var name: String { get }
    var description: String { get }
    var isReversible: Bool { get }
    
    func execute(firestore: Firestore) async throws
    func rollback(firestore: Firestore) async throws
}

/// Base class for migrations providing common functionality
class BaseMigration: Migration, @unchecked Sendable {
    let version: SchemaVersion
    let name: String
    let description: String
    let isReversible: Bool
    
    init(version: SchemaVersion, name: String, description: String, isReversible: Bool = false) {
        self.version = version
        self.name = name
        self.description = description
        self.isReversible = isReversible
    }
    
    func execute(firestore: Firestore) async throws {
        fatalError("Subclasses must implement execute(firestore:)")
    }
    
    func rollback(firestore: Firestore) async throws {
        if !isReversible {
            throw MigrationError.notReversible(name)
        }
        fatalError("Subclasses must implement rollback(firestore:)")
    }
    
    /// Helper method for batch operations with progress tracking
    func batchOperation<T>(
        items: [T],
        batchSize: Int = 500,
        operation: @escaping ([T], WriteBatch) async throws -> Void,
        firestore: Firestore
    ) async throws {
        let batches = items.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            let writeBatch = firestore.batch()
            try await operation(batch, writeBatch)
            try await writeBatch.commit()
            
            print("Processed batch \(index + 1)/\(batches.count)")
        }
    }
}

// MARK: - Migration Registry

/// Registry of all available migrations
struct MigrationRegistry {
    nonisolated(unsafe) static let migrations: [Migration] = [
        AddSearchTermsMigration(),
        AddLocationFieldsMigration(),
        AddSubscriptionInfoMigration(),
        AddTemplateVersioningMigration(),
        MajorSchemaRestructureMigration()
    ]
}

// MARK: - Specific Migrations

/// Migration to add search terms to existing documents
class AddSearchTermsMigration: BaseMigration, @unchecked Sendable {
    init() {
        super.init(
            version: .v1_1,
            name: "AddSearchTerms",
            description: "Add searchTerms field to Collections and Templates for text search",
            isReversible: true
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        // Migrate Collections
        try await migrateCollectionSearchTerms(firestore: firestore)
        
        // Migrate Templates
        try await migrateTemplateSearchTerms(firestore: firestore)
    }
    
    override func rollback(firestore: Firestore) async throws {
        // Remove searchTerms field from Collections and Templates
        try await removeSearchTermsField(firestore: firestore)
    }
    
    private func migrateCollectionSearchTerms(firestore: Firestore) async throws {
        let collectionsRef = firestore.collectionGroup("collections")
        let snapshot = try await collectionsRef.getDocuments()
        
        let collections = try snapshot.documents.compactMap { doc -> CollectionDTO? in
            try doc.data(as: CollectionDTO.self)
        }
        
        try await batchOperation(items: collections, batchSize: 500, operation: { batch, writeBatch in
            for collection in batch {
                let searchTerms = self.generateSearchTerms(name: collection.name, tags: collection.tags)
                let docRef = firestore.document("users/\(collection.userId)/collections/\(collection.id)")
                writeBatch.updateData(["searchTerms": searchTerms], forDocument: docRef)
            }
        }, firestore: firestore)
    }
    
    private func migrateTemplateSearchTerms(firestore: Firestore) async throws {
        let templatesRef = firestore.collection("templates")
        let snapshot = try await templatesRef.getDocuments()
        
        let templates = try snapshot.documents.compactMap { doc -> TemplateDTO? in
            try doc.data(as: TemplateDTO.self)
        }
        
        try await batchOperation(items: templates, batchSize: 500, operation: { batch, writeBatch in
            for template in batch {
                let searchTerms = self.generateSearchTerms(
                    name: template.name,
                    tags: template.tags,
                    category: template.category
                )
                let docRef = firestore.document("templates/\(template.id)")
                writeBatch.updateData(["searchTerms": searchTerms], forDocument: docRef)
            }
        }, firestore: firestore)
    }
    
    private func removeSearchTermsField(firestore: Firestore) async throws {
        // Implementation to remove searchTerms field
        // Note: Firestore doesn't support removing fields directly, would need to recreate documents
    }
    
    private func generateSearchTerms(name: String, tags: [String], category: String? = nil) -> [String] {
        var terms = [name.lowercased()]
        terms.append(contentsOf: tags.map { $0.lowercased() })
        if let category = category {
            terms.append(category.lowercased())
        }
        return Array(Set(terms)) // Remove duplicates
    }
}

/// Migration to add location fields to Items
class AddLocationFieldsMigration: BaseMigration, @unchecked Sendable {
    init() {
        super.init(
            version: .v1_2,
            name: "AddLocationFields",
            description: "Add location field to existing Items for geo-tagging",
            isReversible: true
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        let itemsRef = firestore.collectionGroup("items")
        let snapshot = try await itemsRef.getDocuments()
        
        let items = try snapshot.documents.compactMap { doc -> ItemDTO? in
            try doc.data(as: ItemDTO.self)
        }
        
        try await batchOperation(items: items, batchSize: 500, operation: { batch, writeBatch in
            for item in batch {
                let docRef = firestore.document("users/\(item.userId)/collections/\(item.collectionId)/items/\(item.id)")
                writeBatch.updateData(["location": NSNull()], forDocument: docRef)
            }
        }, firestore: firestore)
    }
    
    override func rollback(firestore: Firestore) async throws {
        // Remove location field (would need document recreation)
    }
}

/// Migration to add subscription information to UserProfile
class AddSubscriptionInfoMigration: BaseMigration, @unchecked Sendable {
    init() {
        super.init(
            version: .v1_3,
            name: "AddSubscriptionInfo",
            description: "Add subscription field to UserProfile for premium features",
            isReversible: true
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        let profilesRef = firestore.collectionGroup("profile")
        let snapshot = try await profilesRef.getDocuments()
        
        let profiles = try snapshot.documents.compactMap { doc -> UserProfileDTO? in
            try doc.data(as: UserProfileDTO.self)
        }
        
        try await batchOperation(items: profiles, batchSize: 500, operation: { batch, writeBatch in
            for profile in batch {
                let docRef = firestore.document("users/\(profile.userId)/profile/\(profile.id)")
                writeBatch.updateData(["subscription": NSNull()], forDocument: docRef)
            }
        }, firestore: firestore)
    }
    
    override func rollback(firestore: Firestore) async throws {
        // Remove subscription field
    }
}

/// Migration to add versioning to Templates
class AddTemplateVersioningMigration: BaseMigration, @unchecked Sendable {
    init() {
        super.init(
            version: .v1_4,
            name: "AddTemplateVersioning",
            description: "Add version and dependency tracking to Templates",
            isReversible: false
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        let templatesRef = firestore.collection("templates")
        let snapshot = try await templatesRef.getDocuments()
        
        let templates = try snapshot.documents.compactMap { doc -> TemplateDTO? in
            try doc.data(as: TemplateDTO.self)
        }
        
        try await batchOperation(items: templates, batchSize: 500, operation: { batch, writeBatch in
            for template in batch {
                let docRef = firestore.document("templates/\(template.id)")
                let updates: [String: Any] = [
                    "version": "1.0.0",
                    "dependencies": [],
                    "changelog": ["1.0.0": "Initial version"]
                ]
                writeBatch.updateData(updates, forDocument: docRef)
            }
        }, firestore: firestore)
    }
}

/// Major schema restructure migration (example of breaking changes)
class MajorSchemaRestructureMigration: BaseMigration, @unchecked Sendable {
    init() {
        super.init(
            version: .v2_0,
            name: "MajorSchemaRestructure",
            description: "Restructure schema for performance and new features",
            isReversible: false
        )
    }
    
    override func execute(firestore: Firestore) async throws {
        // Example: Move user settings to separate collection
        try await restructureUserSettings(firestore: firestore)
        
        // Example: Denormalize frequently accessed data
        try await denormalizeItemCounts(firestore: firestore)
    }
    
    private func restructureUserSettings(firestore: Firestore) async throws {
        // Migration logic for major restructuring
        print("Restructuring user settings...")
    }
    
    private func denormalizeItemCounts(firestore: Firestore) async throws {
        // Add item counts to collections for performance
        print("Denormalizing item counts...")
    }
}

// MARK: - Migration History Tracking

/// Repository for tracking migration history
class MigrationHistoryRepository: @unchecked Sendable {
    private let firestore: Firestore
    private let collectionName = "schema_migrations"
    
    init(firestore: Firestore) {
        self.firestore = firestore
    }
    
    func getCurrentVersion() async -> SchemaVersion {
        do {
            let snapshot = try await firestore.collection(collectionName)
                .order(by: "version", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first,
               let versionRaw = document.data()["version"] as? Int,
               let version = SchemaVersion(rawValue: versionRaw) {
                return version
            }
        } catch {
            print("Error getting current schema version: \(error)")
        }
        
        return .v1_0 // Default to initial version
    }
    
    func recordMigration(_ migration: Migration) async {
        let migrationRecord: [String: Any] = [
            "name": migration.name,
            "description": migration.description,
            "version": migration.version.rawValue,
            "executedAt": Timestamp(),
            "isReversible": migration.isReversible
        ]
        
        do {
            try await firestore.collection(collectionName).addDocument(data: migrationRecord)
        } catch {
            print("Error recording migration: \(error)")
        }
    }
    
    func getMigrationHistory() async -> [MigrationRecord] {
        do {
            let snapshot = try await firestore.collection(collectionName)
                .order(by: "executedAt", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: MigrationRecord.self)
            }
        } catch {
            print("Error getting migration history: \(error)")
            return []
        }
    }
}

/// Record of executed migration
struct MigrationRecord: Codable {
    let name: String
    let description: String
    let version: Int
    let executedAt: Timestamp
    let isReversible: Bool
}

// MARK: - Error Types

enum MigrationError: Error, LocalizedError {
    case notReversible(String)
    case executionFailed(String, Error)
    case incompatibleVersion(SchemaVersion, SchemaVersion)
    
    var errorDescription: String? {
        switch self {
        case .notReversible(let migrationName):
            return "Migration '\(migrationName)' is not reversible"
        case .executionFailed(let migrationName, let error):
            return "Migration '\(migrationName)' failed: \(error.localizedDescription)"
        case .incompatibleVersion(let current, let target):
            return "Incompatible schema version: current \(current), target \(target)"
        }
    }
}

// MARK: - Utility Extensions

// Array.chunked(into:) extension is defined in Data/Performance/FirestoreOptimizations.swift

// MARK: - Migration Strategies Documentation

/*
 MIGRATION STRATEGIES:
 
 1. ADDITIVE CHANGES (Non-breaking):
    - Adding new optional fields
    - Adding new collections
    - Adding new indexes
    - Strategy: Add fields with default values, use optional types
 
 2. FIELD MODIFICATIONS (Semi-breaking):
    - Changing field types
    - Renaming fields
    - Strategy: Create new field, migrate data, deprecate old field
 
 3. STRUCTURAL CHANGES (Breaking):
    - Changing collection structure
    - Splitting/merging collections
    - Strategy: Create new structure, migrate all data, remove old structure
 
 4. DATA TRANSFORMATIONS:
    - Normalizing/denormalizing data
    - Changing data relationships
    - Strategy: Batch process with careful transaction management
 
 5. PERFORMANCE OPTIMIZATIONS:
    - Adding composite indexes
    - Restructuring for query efficiency
    - Strategy: Add new indexes, verify performance, remove old ones
 
 BEST PRACTICES:
 - Always backup data before migrations
 - Test migrations on development environment first
 - Use batched operations for large datasets
 - Track migration execution and allow rollbacks where possible
 - Monitor performance impact during migrations
 - Use feature flags for gradual rollouts of schema changes
 */
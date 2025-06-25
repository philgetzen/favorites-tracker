import Foundation
import FirebaseFirestore

// MARK: - Migration Utilities and Helpers

/// Utility class providing common migration operations and safety checks
class MigrationUtilities: @unchecked Sendable {
    
    // MARK: - Data Validation
    
    /// Validate data integrity before and after migration
    static func validateDataIntegrity(
        firestore: Firestore,
        validationRules: [DataValidationRule]
    ) async throws -> MigrationValidationResult {
        var results: [ValidationRuleResult] = []
        
        for rule in validationRules {
            let result = try await rule.validate(firestore: firestore)
            results.append(result)
        }
        
        return MigrationValidationResult(rules: results)
    }
    
    /// Count documents in collection for before/after comparison
    static func countDocuments(
        firestore: Firestore,
        collection: String,
        subcollection: String? = nil
    ) async throws -> Int {
        let ref: Query
        
        if let subcollection = subcollection {
            ref = firestore.collectionGroup(subcollection)
        } else {
            ref = firestore.collection(collection)
        }
        
        let snapshot = try await ref.count.getAggregation(source: .server)
        return Int(snapshot.count.intValue)
    }
    
    // MARK: - Backup and Restore
    
    /// Create backup of collection before migration
    static func createBackup(
        firestore: Firestore,
        collection: String,
        backupSuffix: String = "_backup"
    ) async throws {
        let sourceRef = firestore.collection(collection)
        let backupRef = firestore.collection("\(collection)\(backupSuffix)")
        
        let snapshot = try await sourceRef.getDocuments()
        
        for document in snapshot.documents {
            try await backupRef.document(document.documentID).setData(document.data())
        }
        
        print("Backup created for collection: \(collection)")
    }
    
    /// Restore collection from backup
    static func restoreFromBackup(
        firestore: Firestore,
        collection: String,
        backupSuffix: String = "_backup"
    ) async throws {
        let backupRef = firestore.collection("\(collection)\(backupSuffix)")
        let targetRef = firestore.collection(collection)
        
        // Clear target collection first
        try await clearCollection(firestore: firestore, collection: collection)
        
        let snapshot = try await backupRef.getDocuments()
        
        for document in snapshot.documents {
            try await targetRef.document(document.documentID).setData(document.data())
        }
        
        print("Restored collection from backup: \(collection)")
    }
    
    /// Clear all documents in collection
    static func clearCollection(
        firestore: Firestore,
        collection: String
    ) async throws {
        let ref = firestore.collection(collection)
        let snapshot = try await ref.getDocuments()
        
        let batches = snapshot.documents.chunked(into: 500)
        
        for batch in batches {
            let writeBatch = firestore.batch()
            for document in batch {
                writeBatch.deleteDocument(document.reference)
            }
            try await writeBatch.commit()
        }
    }
    
    // MARK: - Progress Tracking
    
    /// Track migration progress with callbacks
    static func trackProgress<T>(
        items: [T],
        batchSize: Int = 100,
        operation: @escaping ([T]) async throws -> Void,
        progressCallback: @escaping (Int, Int) -> Void
    ) async throws {
        let batches = items.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            try await operation(batch)
            progressCallback(index + 1, batches.count)
        }
    }
    
    // MARK: - Safe Field Updates
    
    /// Safely add field with default value if not exists
    static func addFieldSafely(
        firestore: Firestore,
        documentRef: DocumentReference,
        fieldName: String,
        defaultValue: Any,
        onlyIfMissing: Bool = true
    ) async throws {
        if onlyIfMissing {
            let document = try await documentRef.getDocument()
            if document.exists && document.data()?[fieldName] != nil {
                return // Field already exists
            }
        }
        
        try await documentRef.updateData([fieldName: defaultValue])
    }
    
    /// Safely rename field (copy to new field, then remove old)
    static func renameField(
        firestore: Firestore,
        documentRef: DocumentReference,
        oldFieldName: String,
        newFieldName: String
    ) async throws {
        let document = try await documentRef.getDocument()
        
        guard let data = document.data(),
              let value = data[oldFieldName] else {
            return // Old field doesn't exist
        }
        
        // Add new field with old value
        try await documentRef.updateData([newFieldName: value])
        
        // Remove old field
        try await documentRef.updateData([oldFieldName: FieldValue.delete()])
    }
    
    // MARK: - Type Conversion Helpers
    
    /// Convert string to URL safely
    static func convertStringToURL(_ string: String) -> URL? {
        return URL(string: string)
    }
    
    /// Convert URL to string safely  
    static func convertURLToString(_ url: URL) -> String {
        return url.absoluteString
    }
    
    /// Convert Timestamp to Date
    static func convertTimestampToDate(_ timestamp: Timestamp) -> Date {
        return timestamp.dateValue()
    }
    
    /// Convert Date to Timestamp
    static func convertDateToTimestamp(_ date: Date) -> Timestamp {
        return Timestamp(date: date)
    }
}

// MARK: - Data Validation Framework

/// Protocol for data validation rules
protocol DataValidationRule {
    var name: String { get }
    var description: String { get }
    
    func validate(firestore: Firestore) async throws -> ValidationRuleResult
}

/// Result of a validation rule
struct ValidationRuleResult: Sendable {
    let ruleName: String
    let passed: Bool
    let message: String
    let details: [String: String]?
    
    init(ruleName: String, passed: Bool, message: String, details: [String: String]? = nil) {
        self.ruleName = ruleName
        self.passed = passed
        self.message = message
        self.details = details
    }
}

/// Overall migration validation result
struct MigrationValidationResult: Sendable {
    let rules: [ValidationRuleResult]
    let overallPassed: Bool
    let summary: String
    
    init(rules: [ValidationRuleResult]) {
        self.rules = rules
        self.overallPassed = rules.allSatisfy { $0.passed }
        
        let passedCount = rules.filter { $0.passed }.count
        let totalCount = rules.count
        self.summary = "\(passedCount)/\(totalCount) validation rules passed"
    }
}

// MARK: - Specific Validation Rules

/// Validate that required fields exist in all documents
struct RequiredFieldsValidation: DataValidationRule {
    let name = "RequiredFieldsValidation"
    let description = "Validates that all required fields exist in documents"
    
    let collection: String
    let requiredFields: [String]
    
    func validate(firestore: Firestore) async throws -> ValidationRuleResult {
        let snapshot = try await firestore.collection(collection).getDocuments()
        var missingFields: [String: [String]] = [:]
        
        for document in snapshot.documents {
            let data = document.data()
            let missing = requiredFields.filter { data[$0] == nil }
            
            if !missing.isEmpty {
                missingFields[document.documentID] = missing
            }
        }
        
        let passed = missingFields.isEmpty
        let message = passed ? 
            "All documents have required fields" : 
            "Found \(missingFields.count) documents with missing fields"
        
        return ValidationRuleResult(
            ruleName: name,
            passed: passed,
            message: message,
            details: ["missingFields": String(describing: missingFields)]
        )
    }
}

/// Validate data type consistency
struct DataTypeValidation: DataValidationRule {
    let name = "DataTypeValidation"
    let description = "Validates data type consistency across documents"
    
    let collection: String
    let fieldTypeRules: [String: Any.Type]
    
    func validate(firestore: Firestore) async throws -> ValidationRuleResult {
        let snapshot = try await firestore.collection(collection).getDocuments()
        var typeViolations: [String: [String]] = [:]
        
        for document in snapshot.documents {
            let data = document.data()
            
            for (field, expectedType) in fieldTypeRules {
                if let value = data[field] {
                    let actualType = type(of: value)
                    if actualType != expectedType {
                        if typeViolations[document.documentID] == nil {
                            typeViolations[document.documentID] = []
                        }
                        typeViolations[document.documentID]?.append(
                            "\(field): expected \(expectedType), got \(actualType)"
                        )
                    }
                }
            }
        }
        
        let passed = typeViolations.isEmpty
        let message = passed ?
            "All fields have correct data types" :
            "Found \(typeViolations.count) documents with type violations"
        
        return ValidationRuleResult(
            ruleName: name,
            passed: passed,
            message: message,
            details: ["typeViolations": String(describing: typeViolations)]
        )
    }
}

/// Validate referential integrity
struct ReferentialIntegrityValidation: DataValidationRule {
    let name = "ReferentialIntegrityValidation"
    let description = "Validates referential integrity between collections"
    
    let sourceCollection: String
    let referenceField: String
    let targetCollection: String
    
    func validate(firestore: Firestore) async throws -> ValidationRuleResult {
        // Get all referenced IDs
        let sourceSnapshot = try await firestore.collection(sourceCollection).getDocuments()
        let referencedIds = Set(sourceSnapshot.documents.compactMap { doc in
            doc.data()[referenceField] as? String
        })
        
        // Get all existing target IDs
        let targetSnapshot = try await firestore.collection(targetCollection).getDocuments()
        let existingIds = Set(targetSnapshot.documents.map { $0.documentID })
        
        // Find orphaned references
        let orphanedIds = referencedIds.subtracting(existingIds)
        
        let passed = orphanedIds.isEmpty
        let message = passed ?
            "All references are valid" :
            "Found \(orphanedIds.count) orphaned references"
        
        return ValidationRuleResult(
            ruleName: name,
            passed: passed,
            message: message,
            details: ["orphanedReferences": String(describing: Array(orphanedIds))]
        )
    }
}

// MARK: - Migration Safety Checks

/// Pre-migration safety checks
struct PreMigrationChecks {
    let firestore: Firestore
    
    /// Check if Firestore is available and responsive
    func checkFirestoreHealth() async throws -> Bool {
        do {
            // Try to read from a minimal collection or create a test document
            let testRef = firestore.collection("health_check").document("test")
            try await testRef.setData(["timestamp": FieldValue.serverTimestamp()])
            try await testRef.delete()
            return true
        } catch {
            print("Firestore health check failed: \(error)")
            return false
        }
    }
    
    /// Check available storage quota (if possible)
    func checkStorageQuota() async -> StorageStatus {
        // This would need implementation based on Firebase quotas
        // For now, return a placeholder
        return StorageStatus(used: 0, available: 1_000_000_000, percentage: 0.0)
    }
    
    /// Verify backup exists before destructive migration
    func verifyBackupExists(collection: String, backupSuffix: String = "_backup") async throws -> Bool {
        let backupRef = firestore.collection("\(collection)\(backupSuffix)")
        let snapshot = try await backupRef.limit(to: 1).getDocuments()
        return !snapshot.isEmpty
    }
}

/// Storage status information
struct StorageStatus {
    let used: Int
    let available: Int
    let percentage: Double
    
    var hasEnoughSpace: Bool {
        return percentage < 0.8 // Less than 80% used
    }
}

// MARK: - Post-Migration Verification

/// Post-migration verification checks
struct PostMigrationVerification {
    let firestore: Firestore
    
    /// Verify document counts match expectations
    func verifyDocumentCounts(
        collection: String,
        expectedCount: Int,
        tolerance: Int = 0
    ) async throws -> Bool {
        let actualCount = try await MigrationUtilities.countDocuments(
            firestore: firestore,
            collection: collection
        )
        
        let difference = abs(actualCount - expectedCount)
        return difference <= tolerance
    }
    
    /// Verify data integrity post-migration
    func verifyDataIntegrity(
        validationRules: [DataValidationRule]
    ) async throws -> MigrationValidationResult {
        return try await MigrationUtilities.validateDataIntegrity(
            firestore: firestore,
            validationRules: validationRules
        )
    }
    
    /// Sample and verify random documents
    func sampleAndVerify<T: Codable>(
        collection: String,
        type: T.Type,
        sampleSize: Int = 10
    ) async throws -> SampleVerificationResult {
        let snapshot = try await firestore.collection(collection)
            .limit(to: sampleSize)
            .getDocuments()
        
        var successCount = 0
        var errors: [String] = []
        
        for document in snapshot.documents {
            do {
                _ = try document.data(as: type)
                successCount += 1
            } catch {
                errors.append("Document \(document.documentID): \(error.localizedDescription)")
            }
        }
        
        return SampleVerificationResult(
            totalSampled: snapshot.documents.count,
            successCount: successCount,
            errors: errors
        )
    }
}

/// Result of sample verification
struct SampleVerificationResult {
    let totalSampled: Int
    let successCount: Int
    let errors: [String]
    
    var successRate: Double {
        guard totalSampled > 0 else { return 0.0 }
        return Double(successCount) / Double(totalSampled)
    }
    
    var isPassing: Bool {
        return successRate >= 0.95 // 95% success rate required
    }
}
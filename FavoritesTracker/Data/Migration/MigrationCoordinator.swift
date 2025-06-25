import Foundation
import FirebaseFirestore
import Combine

// MARK: - Migration Coordinator

/// Coordinates migration execution with app lifecycle and user experience
@MainActor
class MigrationCoordinator: ObservableObject {
    @Published var migrationState: MigrationState = .idle
    @Published var progress: MigrationProgress = .init()
    @Published var lastError: MigrationError?
    
    nonisolated(unsafe) private let migrationManager: DataMigrationManager
    nonisolated(unsafe) private let userNotificationService: UserNotificationService
    private var migrationTask: Task<Void, Never>?
    
    init(migrationManager: DataMigrationManager = DataMigrationManager()) {
        self.migrationManager = migrationManager
        self.userNotificationService = UserNotificationService()
    }
    
    /// Check and run migrations on app startup
    func checkAndRunMigrations() async {
        guard migrationState == .idle else { return }
        
        do {
            let needsMigration = await migrationManager.needsMigration()
            
            if needsMigration {
                await runMigrations()
            } else {
                migrationState = .completed
            }
        } catch {
            await handleMigrationError(error)
        }
    }
    
    /// Run migrations with progress tracking
    func runMigrations() async {
        guard migrationState != .running else { return }
        
        migrationState = .running
        progress = MigrationProgress()
        
        migrationTask = Task {
            do {
                // Pre-migration checks
                await updateProgress(phase: .preparation, message: "Preparing migration...")
                try await performPreMigrationChecks()
                
                // Run migrations
                await updateProgress(phase: .execution, message: "Executing migrations...")
                try await migrationManager.runMigrations()
                
                // Post-migration verification
                await updateProgress(phase: .verification, message: "Verifying migration...")
                try await performPostMigrationVerification()
                
                // Complete
                await updateProgress(phase: .completed, message: "Migration completed successfully")
                migrationState = .completed
                
            } catch {
                await handleMigrationError(error)
            }
        }
        
        await migrationTask?.value
    }
    
    /// Cancel running migration (if possible)
    func cancelMigration() {
        migrationTask?.cancel()
        migrationState = .cancelled
        progress.phase = .cancelled
    }
    
    // MARK: - Private Methods
    
    private func performPreMigrationChecks() async throws {
        let checks = PreMigrationChecks(firestore: Firestore.firestore())
        
        // Check Firestore health
        let isHealthy = try await checks.checkFirestoreHealth()
        guard isHealthy else {
            throw MigrationError.executionFailed("PreMigrationChecks", 
                NSError(domain: "Migration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Firestore health check failed"]))
        }
        
        // Check storage quota
        let storageStatus = await checks.checkStorageQuota()
        guard storageStatus.hasEnoughSpace else {
            throw MigrationError.executionFailed("PreMigrationChecks",
                NSError(domain: "Migration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Insufficient storage space"]))
        }
    }
    
    private func performPostMigrationVerification() async throws {
        let verification = PostMigrationVerification(firestore: Firestore.firestore())
        
        // Define validation rules for verification
        let validationRules: [DataValidationRule] = [
            RequiredFieldsValidation(
                collection: "collections",
                requiredFields: ["id", "userId", "name", "createdAt", "updatedAt"]
            ),
            RequiredFieldsValidation(
                collection: "templates", 
                requiredFields: ["id", "creatorId", "name", "createdAt", "updatedAt"]
            ),
            ReferentialIntegrityValidation(
                sourceCollection: "collections",
                referenceField: "templateId",
                targetCollection: "templates"
            )
        ]
        
        let result = try await verification.verifyDataIntegrity(validationRules: validationRules)
        
        guard result.overallPassed else {
            let errorMessage = "Post-migration verification failed: \(result.summary)"
            throw MigrationError.executionFailed("PostMigrationVerification",
                NSError(domain: "Migration", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
    }
    
    private func updateProgress(phase: MigrationPhase, message: String, percentage: Double = 0.0) async {
        progress.phase = phase
        progress.message = message
        progress.percentage = percentage
        
        // Notify user service for UI updates
        await userNotificationService.notifyMigrationProgress(progress)
    }
    
    private func handleMigrationError(_ error: Error) async {
        let migrationError = error as? MigrationError ?? 
            MigrationError.executionFailed("Unknown", error)
        
        lastError = migrationError
        migrationState = .failed
        progress.phase = .failed
        progress.message = migrationError.localizedDescription
        
        await userNotificationService.notifyMigrationError(migrationError)
    }
}

// MARK: - Migration State Management

/// Current state of migration process
enum MigrationState: Equatable {
    case idle
    case running
    case completed
    case failed
    case cancelled
}

/// Detailed progress tracking for migrations
struct MigrationProgress {
    var phase: MigrationPhase = .idle
    var message: String = ""
    var percentage: Double = 0.0
    var startTime: Date?
    var estimatedTimeRemaining: TimeInterval?
    
    init() {
        self.startTime = Date()
    }
}

/// Phases of migration process
enum MigrationPhase: String, CaseIterable {
    case idle = "Idle"
    case preparation = "Preparation"
    case execution = "Execution" 
    case verification = "Verification"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var description: String {
        switch self {
        case .idle:
            return "Ready to start migration"
        case .preparation:
            return "Preparing for migration"
        case .execution:
            return "Running migration scripts"
        case .verification:
            return "Verifying migration results"
        case .completed:
            return "Migration completed successfully"
        case .failed:
            return "Migration failed"
        case .cancelled:
            return "Migration cancelled"
        }
    }
}

// MARK: - User Notification Service

/// Service for notifying users about migration progress
class UserNotificationService {
    
    func notifyMigrationProgress(_ progress: MigrationProgress) async {
        // Implementation would depend on UI framework
        // Could post notifications, update UI, etc.
        print("Migration Progress: \(progress.phase) - \(progress.message)")
    }
    
    func notifyMigrationError(_ error: MigrationError) async {
        // Handle error notifications to user
        print("Migration Error: \(error.localizedDescription)")
    }
    
    func shouldShowMigrationUI() -> Bool {
        // Determine if migration UI should be shown to user
        // Based on migration duration, criticality, etc.
        return true
    }
}

// MARK: - Migration Strategy Selection

/// Selects appropriate migration strategy based on data size and complexity
struct MigrationStrategySelector {
    
    enum Strategy {
        case immediate    // Run immediately on app start
        case background   // Run in background
        case scheduled    // Schedule for later
        case interactive  // Require user interaction
    }
    
    static func selectStrategy(
        migrationSize: MigrationSize,
        userContext: UserContext,
        systemResources: SystemResources
    ) -> Strategy {
        
        switch (migrationSize, userContext.connectionType, systemResources.batteryLevel) {
        case (.small, _, _):
            return .immediate
            
        case (.medium, .wifi, .high), (.medium, .wifi, .medium):
            return .immediate
            
        case (.medium, .cellular, _), (.medium, .wifi, .low), (.medium, .none, _):
            return .background
            
        case (.large, .wifi, .high):
            return .interactive
            
        case (.large, _, _):
            return .scheduled
        }
    }
}

/// Size classification for migrations
enum MigrationSize {
    case small    // < 1000 documents
    case medium   // 1000-10000 documents  
    case large    // > 10000 documents
    
    static func classify(documentCount: Int) -> MigrationSize {
        switch documentCount {
        case 0..<1000:
            return .small
        case 1000..<10000:
            return .medium
        default:
            return .large
        }
    }
}

/// User context for migration decisions
struct UserContext {
    let connectionType: ConnectionType
    let isAppInForeground: Bool
    let lastMigrationDate: Date?
    
    enum ConnectionType {
        case wifi, cellular, none
    }
}

/// System resources for migration decisions
struct SystemResources {
    let batteryLevel: BatteryLevel
    let availableMemory: Int
    let storageSpace: Int
    
    enum BatteryLevel {
        case low, medium, high
    }
}

// MARK: - Migration Recovery

/// Handles migration failure recovery
class MigrationRecoveryManager {
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    /// Attempt to recover from failed migration
    func attemptRecovery(
        failedMigration: Migration,
        error: Error
    ) async throws -> RecoveryResult {
        
        // Analyze the failure
        let failureAnalysis = analyzeFailure(migration: failedMigration, error: error)
        
        switch failureAnalysis.type {
        case .transient:
            // Retry the migration
            return try await retryMigration(failedMigration)
            
        case .dataCorruption:
            // Restore from backup if available
            return try await restoreFromBackup(failedMigration)
            
        case .schemaConflict:
            // Manual intervention required
            return .manualInterventionRequired(failureAnalysis.details)
            
        case .systemResource:
            // Schedule for retry when resources available
            return .retryLater(failureAnalysis.suggestedRetryTime)
        }
    }
    
    private func analyzeFailure(migration: Migration, error: Error) -> FailureAnalysis {
        // Implementation would analyze error type and context
        return FailureAnalysis(
            type: .transient,
            details: error.localizedDescription,
            suggestedRetryTime: Date().addingTimeInterval(3600) // 1 hour
        )
    }
    
    private func retryMigration(_ migration: Migration) async throws -> RecoveryResult {
        try await migration.execute(firestore: firestore)
        return .recovered
    }
    
    private func restoreFromBackup(_ migration: Migration) async throws -> RecoveryResult {
        // Implementation would restore from backup
        return .recovered
    }
}

/// Result of recovery attempt
enum RecoveryResult {
    case recovered
    case manualInterventionRequired(String)
    case retryLater(Date)
}

/// Analysis of migration failure
struct FailureAnalysis {
    let type: FailureType
    let details: String
    let suggestedRetryTime: Date
    
    enum FailureType {
        case transient       // Network issues, temporary failures
        case dataCorruption  // Data integrity issues
        case schemaConflict  // Schema version conflicts
        case systemResource  // Insufficient resources
    }
}

// MARK: - Migration Monitoring

/// Monitors migration performance and health
class MigrationMonitor {
    private var metrics: [MigrationMetric] = []
    
    func recordMetric(_ metric: MigrationMetric) {
        metrics.append(metric)
    }
    
    func getPerformanceReport() -> MigrationPerformanceReport {
        return MigrationPerformanceReport(metrics: metrics)
    }
    
    func shouldAlertOnPerformance() -> Bool {
        // Check if performance is degrading
        let recentMetrics = metrics.suffix(10)
        let averageDuration = recentMetrics.map(\.duration).reduce(0, +) / Double(recentMetrics.count)
        
        return averageDuration > 60.0 // Alert if taking more than 60 seconds
    }
}

/// Individual migration metric
struct MigrationMetric {
    let migrationName: String
    let version: SchemaVersion
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let documentsProcessed: Int
    let success: Bool
    let error: String?
    
    init(migrationName: String, version: SchemaVersion, startTime: Date, endTime: Date, documentsProcessed: Int, success: Bool, error: String? = nil) {
        self.migrationName = migrationName
        self.version = version
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.documentsProcessed = documentsProcessed
        self.success = success
        self.error = error
    }
}

/// Performance report for migrations
struct MigrationPerformanceReport {
    let metrics: [MigrationMetric]
    let totalMigrations: Int
    let successfulMigrations: Int
    let averageDuration: TimeInterval
    let totalDocumentsProcessed: Int
    
    init(metrics: [MigrationMetric]) {
        self.metrics = metrics
        self.totalMigrations = metrics.count
        self.successfulMigrations = metrics.filter(\.success).count
        self.averageDuration = metrics.map(\.duration).reduce(0, +) / Double(max(metrics.count, 1))
        self.totalDocumentsProcessed = metrics.map(\.documentsProcessed).reduce(0, +)
    }
    
    var successRate: Double {
        guard totalMigrations > 0 else { return 0.0 }
        return Double(successfulMigrations) / Double(totalMigrations)
    }
}
import Foundation
import FirebaseFirestore

// MARK: - Firestore Indexing Strategy

/// Manages Firestore index configuration and optimization
class FirestoreIndexManager: @unchecked Sendable {
    private let db: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }
    
    /// Generate index configuration for deployment
    func generateIndexConfiguration() -> FirestoreIndexConfiguration {
        return FirestoreIndexConfiguration(
            compositeIndexes: getRequiredCompositeIndexes(),
            singleFieldIndexes: getRequiredSingleFieldIndexes(),
            fieldOverrides: getFieldOverrides()
        )
    }
    
    /// Validate that required indexes exist
    func validateIndexes() async -> IndexValidationResult {
        // Note: In production, this would query Firestore's index API
        // For now, we'll return validation rules and recommendations
        
        let missingIndexes = identifyMissingIndexes()
        let recommendations = generateIndexRecommendations()
        
        return IndexValidationResult(
            missingIndexes: missingIndexes,
            recommendations: recommendations,
            allIndexesPresent: missingIndexes.isEmpty
        )
    }
    
    // MARK: - Composite Indexes
    
    private func getRequiredCompositeIndexes() -> [CompositeIndexDefinition] {
        return [
            // User collections with filtering and sorting
            CompositeIndexDefinition(
                collection: "collections",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "isFavorite", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collection,
                description: "User favorite collections ordered by update time"
            ),
            
            CompositeIndexDefinition(
                collection: "collections",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "templateId", order: .ascending),
                    IndexField(name: "createdAt", order: .descending)
                ],
                scope: .collection,
                description: "Collections by template, ordered by creation"
            ),
            
            CompositeIndexDefinition(
                collection: "collections",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "tags", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collection,
                description: "Collections filtered by tags with recency"
            ),
            
            CompositeIndexDefinition(
                collection: "collections",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "searchTerms", order: .ascending),
                    IndexField(name: "itemCount", order: .descending)
                ],
                scope: .collection,
                description: "Search collections by popularity (item count)"
            ),
            
            // Cross-collection item queries (collection group)
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "isFavorite", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collectionGroup,
                description: "User favorite items across all collections"
            ),
            
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "rating", order: .descending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collectionGroup,
                description: "Highly rated items by recency"
            ),
            
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "tags", order: .ascending),
                    IndexField(name: "createdAt", order: .descending)
                ],
                scope: .collectionGroup,
                description: "Items by tags across collections"
            ),
            
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "collectionId", order: .ascending),
                    IndexField(name: "isFavorite", order: .ascending),
                    IndexField(name: "rating", order: .descending)
                ],
                scope: .collection,
                description: "Collection items by rating and favorite status"
            ),
            
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "collectionId", order: .ascending),
                    IndexField(name: "searchTerms", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collection,
                description: "Search items within collection by recency"
            ),
            
            // Template marketplace queries
            CompositeIndexDefinition(
                collection: "templates",
                fields: [
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "category", order: .ascending),
                    IndexField(name: "downloadCount", order: .descending)
                ],
                scope: .collection,
                description: "Public templates by category popularity"
            ),
            
            CompositeIndexDefinition(
                collection: "templates",
                fields: [
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "isPremium", order: .ascending),
                    IndexField(name: "rating", order: .descending)
                ],
                scope: .collection,
                description: "Public templates by premium status and rating"
            ),
            
            CompositeIndexDefinition(
                collection: "templates",
                fields: [
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "searchTerms", order: .ascending),
                    IndexField(name: "downloadCount", order: .descending)
                ],
                scope: .collection,
                description: "Template search by popularity"
            ),
            
            CompositeIndexDefinition(
                collection: "templates",
                fields: [
                    IndexField(name: "creatorId", order: .ascending),
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collection,
                description: "Creator's templates by visibility and recency"
            ),
            
            // Advanced search and filtering
            CompositeIndexDefinition(
                collection: "collections",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "isFavorite", order: .ascending),
                    IndexField(name: "updatedAt", order: .descending)
                ],
                scope: .collection,
                description: "Collections by visibility, favorites, and recency"
            ),
            
            CompositeIndexDefinition(
                collection: "templates",
                fields: [
                    IndexField(name: "isPublic", order: .ascending),
                    IndexField(name: "category", order: .ascending),
                    IndexField(name: "isPremium", order: .ascending),
                    IndexField(name: "createdAt", order: .descending)
                ],
                scope: .collection,
                description: "Templates by category, premium status, and recency"
            ),
            
            // Location-based queries (when location is added)
            CompositeIndexDefinition(
                collection: "items",
                fields: [
                    IndexField(name: "userId", order: .ascending),
                    IndexField(name: "location", order: .ascending),
                    IndexField(name: "createdAt", order: .descending)
                ],
                scope: .collectionGroup,
                description: "Items with location by recency"
            )
        ]
    }
    
    // MARK: - Single Field Indexes
    
    private func getRequiredSingleFieldIndexes() -> [SingleFieldIndexDefinition] {
        return [
            // Essential fields for all collections
            SingleFieldIndexDefinition(
                field: "userId",
                mode: .ascending,
                description: "User-based filtering across all collections"
            ),
            SingleFieldIndexDefinition(
                field: "createdAt",
                mode: .both,
                description: "Sorting by creation date"
            ),
            SingleFieldIndexDefinition(
                field: "updatedAt",
                mode: .both,
                description: "Sorting by update date"
            ),
            
            // Collection-specific indexes
            SingleFieldIndexDefinition(
                field: "templateId",
                mode: .ascending,
                description: "Filter collections by template"
            ),
            SingleFieldIndexDefinition(
                field: "itemCount",
                mode: .both,
                description: "Sort collections by item count"
            ),
            SingleFieldIndexDefinition(
                field: "isFavorite",
                mode: .ascending,
                description: "Filter favorite items/collections"
            ),
            SingleFieldIndexDefinition(
                field: "isPublic",
                mode: .ascending,
                description: "Filter public content"
            ),
            
            // Item-specific indexes
            SingleFieldIndexDefinition(
                field: "collectionId",
                mode: .ascending,
                description: "Items within specific collection"
            ),
            SingleFieldIndexDefinition(
                field: "rating",
                mode: .both,
                description: "Sort items by rating"
            ),
            
            // Template-specific indexes
            SingleFieldIndexDefinition(
                field: "category",
                mode: .ascending,
                description: "Filter templates by category"
            ),
            SingleFieldIndexDefinition(
                field: "creatorId",
                mode: .ascending,
                description: "Templates by creator"
            ),
            SingleFieldIndexDefinition(
                field: "downloadCount",
                mode: .both,
                description: "Sort templates by popularity"
            ),
            SingleFieldIndexDefinition(
                field: "isPremium",
                mode: .ascending,
                description: "Filter premium templates"
            ),
            
            // Array fields (automatic indexing)
            SingleFieldIndexDefinition(
                field: "tags",
                mode: .arrayContains,
                description: "Search by tags"
            ),
            SingleFieldIndexDefinition(
                field: "searchTerms",
                mode: .arrayContains,
                description: "Full-text search functionality"
            )
        ]
    }
    
    // MARK: - Field Overrides
    
    private func getFieldOverrides() -> [FieldOverride] {
        return [
            // Disable indexing for large text fields to save storage
            FieldOverride(
                field: "description",
                indexMode: .none,
                reason: "Large text field, indexed via searchTerms instead"
            ),
            FieldOverride(
                field: "bio",
                indexMode: .none,
                reason: "User bio, not used for queries"
            ),
            
            // Optimize array field indexing
            FieldOverride(
                field: "imageURLs",
                indexMode: .none,
                reason: "URLs not used for filtering, only display"
            ),
            FieldOverride(
                field: "customFields",
                indexMode: .none,
                reason: "Dynamic fields, indexed individually if needed"
            ),
            
            // Location fields (GeoPoint optimization)
            FieldOverride(
                field: "location.geoPoint",
                indexMode: .ascending,
                reason: "Enable geo queries when implemented"
            )
        ]
    }
    
    // MARK: - Index Validation
    
    private func identifyMissingIndexes() -> [String] {
        // In production, this would check against actual Firestore indexes
        // For now, return common missing index scenarios
        return [
            "collections: userId + isFavorite + updatedAt",
            "items (collection group): userId + rating + updatedAt",
            "templates: isPublic + category + downloadCount"
        ]
    }
    
    private func generateIndexRecommendations() -> [IndexRecommendation] {
        return [
            IndexRecommendation(
                type: .composite,
                collection: "collections",
                fields: ["userId", "searchTerms", "itemCount"],
                reason: "Optimize search queries with popularity sorting",
                priority: .high
            ),
            IndexRecommendation(
                type: .composite,
                collection: "items",
                fields: ["collectionId", "tags", "updatedAt"],
                reason: "Enable tag filtering within collections",
                priority: .medium
            ),
            IndexRecommendation(
                type: .singleField,
                collection: "templates",
                fields: ["rating"],
                reason: "Enable rating-based sorting",
                priority: .low
            )
        ]
    }
}

// MARK: - Index Definitions

struct CompositeIndexDefinition {
    let collection: String
    let fields: [IndexField]
    let scope: IndexScope
    let description: String
    
    enum IndexScope {
        case collection
        case collectionGroup
    }
}

struct IndexField {
    let name: String
    let order: FieldOrder
    
    enum FieldOrder {
        case ascending
        case descending
    }
}

struct SingleFieldIndexDefinition {
    let field: String
    let mode: IndexMode
    let description: String
    
    enum IndexMode {
        case ascending
        case descending
        case both
        case arrayContains
        case none
    }
}

struct FieldOverride {
    let field: String
    let indexMode: SingleFieldIndexDefinition.IndexMode
    let reason: String
}

// MARK: - Index Configuration Export

struct FirestoreIndexConfiguration {
    let compositeIndexes: [CompositeIndexDefinition]
    let singleFieldIndexes: [SingleFieldIndexDefinition]
    let fieldOverrides: [FieldOverride]
    
    /// Generate Firebase CLI index configuration
    func generateFirebaseIndexes() -> String {
        var config = """
        {
          "indexes": [
        """
        
        // Add composite indexes
        let compositeConfigs = compositeIndexes.map { index in
            generateCompositeIndexConfig(index)
        }
        
        config += compositeConfigs.joined(separator: ",\n")
        
        config += """
          ],
          "fieldOverrides": [
        """
        
        // Add field overrides
        let overrideConfigs = fieldOverrides.map { override in
            generateFieldOverrideConfig(override)
        }
        
        config += overrideConfigs.joined(separator: ",\n")
        
        config += """
          ]
        }
        """
        
        return config
    }
    
    private func generateCompositeIndexConfig(_ index: CompositeIndexDefinition) -> String {
        let fieldsConfig = index.fields.map { field in
            """
                  {
                    "fieldPath": "\(field.name)",
                    "order": "\(field.order == .ascending ? "ASCENDING" : "DESCENDING")"
                  }
            """
        }.joined(separator: ",\n")
        
        let queryScope = index.scope == .collectionGroup ? "COLLECTION_GROUP" : "COLLECTION"
        
        return """
            {
              "collectionGroup": "\(index.collection)",
              "queryScope": "\(queryScope)",
              "fields": [
        \(fieldsConfig)
              ]
            }
        """
    }
    
    private func generateFieldOverrideConfig(_ override: FieldOverride) -> String {
        let indexMode: String
        switch override.indexMode {
        case .ascending:
            indexMode = "ASCENDING"
        case .descending:
            indexMode = "DESCENDING"
        case .arrayContains:
            indexMode = "ARRAY_CONTAINS"
        case .none:
            indexMode = "EXEMPT"
        case .both:
            indexMode = "ASCENDING" // Default, will need separate entry for descending
        }
        
        return """
            {
              "fieldPath": "\(override.field)",
              "indexes": [
                {
                  "order": "\(indexMode)",
                  "queryScope": "COLLECTION"
                }
              ]
            }
        """
    }
}

// MARK: - Index Validation

struct IndexValidationResult {
    let missingIndexes: [String]
    let recommendations: [IndexRecommendation]
    let allIndexesPresent: Bool
}

struct IndexRecommendation {
    let type: RecommendationType
    let collection: String
    let fields: [String]
    let reason: String
    let priority: Priority
    
    enum RecommendationType {
        case composite
        case singleField
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
}

// MARK: - Query Pattern Analysis

/// Analyzes query patterns to suggest index optimizations
class QueryPatternAnalyzer: @unchecked Sendable {
    private var queryPatterns: [QueryPattern] = []
    
    /// Record a query pattern for analysis
    func recordQueryPattern(
        collection: String,
        filters: [String],
        orderBy: [String],
        executionTime: TimeInterval,
        fromCache: Bool
    ) {
        let pattern = QueryPattern(
            collection: collection,
            filters: filters,
            orderBy: orderBy,
            executionTime: executionTime,
            fromCache: fromCache,
            timestamp: Date()
        )
        
        queryPatterns.append(pattern)
        
        // Analyze for optimization opportunities
        if executionTime > 1.0 && !fromCache {
            analyzeSlowQuery(pattern)
        }
    }
    
    /// Analyze patterns and suggest index optimizations
    func generateIndexSuggestions() -> [IndexSuggestion] {
        var suggestions: [IndexSuggestion] = []
        
        // Group patterns by collection and filter combinations
        let groupedPatterns = Dictionary(grouping: queryPatterns) { pattern in
            "\(pattern.collection):\(pattern.filters.joined(separator: ","))"
        }
        
        for (key, patterns) in groupedPatterns {
            let averageTime = patterns.map(\.executionTime).reduce(0, +) / Double(patterns.count)
            let cacheHitRate = Double(patterns.filter(\.fromCache).count) / Double(patterns.count)
            
            if averageTime > 0.5 || cacheHitRate < 0.7 {
                let suggestion = IndexSuggestion(
                    collection: patterns.first?.collection ?? "",
                    recommendedFields: patterns.first?.filters ?? [],
                    orderFields: patterns.first?.orderBy ?? [],
                    impact: calculateImpact(patterns),
                    reason: "Frequently used query pattern with poor performance"
                )
                suggestions.append(suggestion)
            }
        }
        
        return suggestions.sorted { $0.impact > $1.impact }
    }
    
    private func analyzeSlowQuery(_ pattern: QueryPattern) {
        print("🐌 Slow query detected:")
        print("  Collection: \(pattern.collection)")
        print("  Filters: \(pattern.filters)")
        print("  Order: \(pattern.orderBy)")
        print("  Time: \(pattern.executionTime)s")
        print("  Suggestion: Consider adding composite index for this query pattern")
    }
    
    private func calculateImpact(_ patterns: [QueryPattern]) -> Double {
        let frequency = Double(patterns.count)
        let averageTime = patterns.map(\.executionTime).reduce(0, +) / Double(patterns.count)
        return frequency * averageTime // Simple impact calculation
    }
}

struct QueryPattern {
    let collection: String
    let filters: [String]
    let orderBy: [String]
    let executionTime: TimeInterval
    let fromCache: Bool
    let timestamp: Date
}

struct IndexSuggestion {
    let collection: String
    let recommendedFields: [String]
    let orderFields: [String]
    let impact: Double
    let reason: String
}
import SwiftUI
import Combine

/// ViewModel responsible for managing form state and field values
@MainActor
public final class ItemFormStateViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var rating: Double = 0.0
    @Published var isFavorite: Bool = false
    @Published var tags: [String] = []
    @Published var customFields: [String: CustomFieldValue] = [:]
    
    // MARK: - Properties
    
    let isEditing: Bool
    private let editingItem: Item?
    
    // MARK: - Computed Properties
    
    var formTitle: String {
        isEditing ? "Edit Item" : "Add New Item"
    }
    
    var submitButtonTitle: String {
        isEditing ? "Update Item" : "Create Item"
    }
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var hasValidName: Bool {
        !trimmedName.isEmpty
    }
    
    // MARK: - Initialization
    
    init(editingItem: Item? = nil) {
        self.editingItem = editingItem
        self.isEditing = editingItem != nil
        
        if let item = editingItem {
            populateForm(with: item)
        }
    }
    
    // MARK: - Public Methods
    
    func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func updateCustomField(key: String, value: CustomFieldValue) {
        customFields[key] = value
    }
    
    func removeCustomField(key: String) {
        customFields.removeValue(forKey: key)
    }
    
    func buildItem(userId: String, collectionId: String, imageURLs: [URL]) -> Item {
        if let existingItem = editingItem {
            // Update existing item
            return Item(
                id: existingItem.id,
                userId: existingItem.userId,
                collectionId: existingItem.collectionId,
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                imageURLs: imageURLs,
                customFields: customFields,
                isFavorite: isFavorite,
                tags: tags,
                location: existingItem.location,
                rating: rating > 0 ? rating : nil,
                createdAt: existingItem.createdAt,
                updatedAt: Date()
            )
        } else {
            // Create new item
            return Item(
                id: UUID().uuidString,
                userId: userId,
                collectionId: collectionId,
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                imageURLs: imageURLs,
                customFields: customFields,
                isFavorite: isFavorite,
                tags: tags,
                location: nil,
                rating: rating > 0 ? rating : nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    func reset() {
        name = ""
        description = ""
        rating = 0.0
        isFavorite = false
        tags = []
        customFields = [:]
    }
    
    // MARK: - Private Methods
    
    private func populateForm(with item: Item) {
        name = item.name
        description = item.description ?? ""
        rating = item.rating ?? 0.0
        isFavorite = item.isFavorite
        tags = item.tags
        customFields = item.customFields
    }
}
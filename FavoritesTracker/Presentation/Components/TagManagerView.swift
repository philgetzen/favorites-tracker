import SwiftUI

/// Advanced tag management component with suggestions, categories, and validation
struct TagManagerView: View {
    @Binding var selectedTags: [String]
    @State private var searchText: String = ""
    @State private var showingSuggestedTags: Bool = false
    @State private var selectedCategory: TagCategory = .all
    
    let availableTags: [String]
    let maxTags: Int
    let allowCustomTags: Bool
    
    init(
        selectedTags: Binding<[String]>,
        availableTags: [String] = [],
        maxTags: Int = 10,
        allowCustomTags: Bool = true
    ) {
        self._selectedTags = selectedTags
        self.availableTags = availableTags
        self.maxTags = maxTags
        self.allowCustomTags = allowCustomTags
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            
            // Search and add new tags
            tagInputSection
            
            // Category filter
            categoryFilterSection
            
            // Selected tags display
            selectedTagsSection
            
            // Suggested tags
            if showingSuggestedTags && !filteredSuggestedTags.isEmpty {
                suggestedTagsSection
            }
            
            // Popular/Recent tags
            if !filteredPopularTags.isEmpty {
                popularTagsSection
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Tags & Categories")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(selectedTags.count)/\(maxTags)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var tagInputSection: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Search or add tags...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .onSubmit {
                        addCustomTag()
                    }
                    .onChange(of: searchText) { _, newValue in
                        showingSuggestedTags = !newValue.isEmpty
                    }
                
                Button(action: addCustomTag) {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAddTag)
            }
            
            if !searchText.isEmpty && allowCustomTags {
                Text("Press Enter or + to add '\(searchText)' as a new tag")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TagCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private var selectedTagsSection: some View {
        Group {
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Tags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(selectedTags, id: \.self) { tag in
                            selectedTagChip(tag: tag)
                        }
                    }
                }
            }
        }
    }
    
    private var suggestedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(filteredSuggestedTags, id: \.self) { tag in
                    suggestedTagChip(tag: tag)
                }
            }
        }
    }
    
    private var popularTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular Tags")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(filteredPopularTags.prefix(12), id: \.self) { tag in
                    suggestedTagChip(tag: tag)
                }
            }
        }
    }
    
    @ViewBuilder
    private func selectedTagChip(tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: { removeTag(tag) }) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func suggestedTagChip(tag: String) -> some View {
        Button(action: { addTag(tag) }) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(selectedTags.contains(tag) || selectedTags.count >= maxTags)
    }
    
    // MARK: - Computed Properties
    
    private var canAddTag: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && 
               !selectedTags.contains(trimmed) && 
               selectedTags.count < maxTags &&
               allowCustomTags
    }
    
    private var filteredSuggestedTags: [String] {
        let query = searchText.lowercased()
        return availableTags.filter { tag in
            tag.lowercased().contains(query) && 
            !selectedTags.contains(tag) &&
            (selectedCategory == .all || tagMatchesCategory(tag, category: selectedCategory))
        }
    }
    
    private var filteredPopularTags: [String] {
        let popularTags = getPopularTagsForCategory(selectedCategory)
        return popularTags.filter { !selectedTags.contains($0) }
    }
    
    // MARK: - Actions
    
    private func addTag(_ tag: String) {
        guard !selectedTags.contains(tag) && selectedTags.count < maxTags else { return }
        selectedTags.append(tag)
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
    
    private func addCustomTag() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canAddTag else { return }
        
        addTag(trimmed)
        searchText = ""
        showingSuggestedTags = false
    }
    
    // MARK: - Helper Functions
    
    private func tagMatchesCategory(_ tag: String, category: TagCategory) -> Bool {
        let categoryTags = getPopularTagsForCategory(category)
        return categoryTags.contains(tag)
    }
    
    private func getPopularTagsForCategory(_ category: TagCategory) -> [String] {
        switch category {
        case .all:
            // Return all tags from all non-.all categories to avoid infinite recursion
            return TagCategory.allCases.filter { $0 != .all }.flatMap { getPopularTagsForCategory($0) }
        case .general:
            return ["favorite", "wishlist", "recommended", "new", "vintage", "rare", "classic", "modern"]
        case .quality:
            return ["excellent", "good", "fair", "poor", "mint", "used", "damaged", "restored"]
        case .location:
            return ["home", "work", "travel", "store", "online", "local", "imported", "handmade"]
        case .price:
            return ["expensive", "cheap", "bargain", "overpriced", "worth-it", "investment", "budget", "premium"]
        case .status:
            return ["owned", "wanted", "sold", "given-away", "broken", "missing", "loaned", "returned"]
        case .category:
            return ["electronics", "books", "clothing", "food", "toys", "tools", "art", "music", "sports", "hobby"]
        }
    }
}

// MARK: - Supporting Types

enum TagCategory: String, CaseIterable {
    case all = "all"
    case general = "general"
    case quality = "quality"
    case location = "location"
    case price = "price"
    case status = "status"
    case category = "category"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .general: return "General"
        case .quality: return "Quality"
        case .location: return "Location"
        case .price: return "Price"
        case .status: return "Status"
        case .category: return "Category"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tag"
        case .general: return "star"
        case .quality: return "checkmark.seal"
        case .location: return "location"
        case .price: return "dollarsign.circle"
        case .status: return "flag"
        case .category: return "folder"
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        @State private var selectedTags: [String] = ["favorite", "electronics"]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Tag Manager Demo")
                        .font(.title2)
                        .padding()
                    
                    TagManagerView(
                        selectedTags: $selectedTags,
                        availableTags: ["smartphone", "laptop", "tablet", "headphones", "camera", "watch", "favorite", "electronics", "expensive", "new"],
                        maxTags: 8,
                        allowCustomTags: true
                    )
                    .padding()
                    
                    Text("Selected: \(selectedTags.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    return PreviewContainer()
}
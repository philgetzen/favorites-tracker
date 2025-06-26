import SwiftUI

/// View for duplicating items with modification options
struct ItemDuplicationView: View {
    
    // MARK: - Properties
    
    let item: Item
    let collections: [Collection]
    @StateObject private var duplicationService: ItemDuplicationService
    @State private var modifications = ItemDuplicationModifications()
    @State private var selectedCollectionId: String
    @State private var useSmartSuggestions = true
    @State private var showingAdvancedOptions = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    // Callbacks
    let onDuplicationComplete: (Item) -> Void
    
    // MARK: - Initialization
    
    init(
        item: Item,
        collections: [Collection],
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        onDuplicationComplete: @escaping (Item) -> Void
    ) {
        self.item = item
        self.collections = collections
        self.onDuplicationComplete = onDuplicationComplete
        self._selectedCollectionId = State(initialValue: item.collectionId)
        self._duplicationService = StateObject(wrappedValue: ItemDuplicationService(
            itemRepository: itemRepository,
            collectionRepository: collectionRepository
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                originalItemSection
                targetCollectionSection
                modificationsSection
                if showingAdvancedOptions {
                    advancedOptionsSection
                }
                actionSection
            }
            .navigationTitle("Duplicate Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Duplicate") {
                        Task {
                            await duplicateItem()
                        }
                    }
                    .disabled(duplicationService.isProcessing)
                }
            }
            .disabled(duplicationService.isProcessing)
        }
        .task {
            if useSmartSuggestions {
                modifications = duplicationService.generateSmartDuplicationSuggestions(for: item)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var originalItemSection: some View {
        Section("Original Item") {
            HStack {
                AsyncImage(url: item.imageURLs.first) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let description = item.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let rating = item.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var targetCollectionSection: some View {
        Section("Target Collection") {
            Picker("Collection", selection: $selectedCollectionId) {
                ForEach(collections, id: \.id) { collection in
                    HStack {
                        Text(collection.name)
                        Spacer()
                        if collection.id == item.collectionId {
                            Text("(Current)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .tag(collection.id)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var modificationsSection: some View {
        Section("Modifications") {
            Toggle("Use Smart Suggestions", isOn: $useSmartSuggestions)
                .onChange(of: useSmartSuggestions) { oldValue, newValue in
                    if newValue {
                        modifications = duplicationService.generateSmartDuplicationSuggestions(for: item)
                    } else {
                        modifications = ItemDuplicationModifications()
                    }
                }
            
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Name") {
                    TextField("Item name", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Description") {
                    TextField("Description", text: descriptionBinding, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                HStack {
                    LabeledContent("Favorite") {
                        Toggle("", isOn: favoriteBinding)
                    }
                    
                    Spacer()
                    
                    LabeledContent("Rating") {
                        HStack {
                            Button("Clear") {
                                modifications.rating = nil
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            InteractiveStarRatingView(rating: ratingBinding)
                        }
                    }
                }
            }
            
            Button("Advanced Options") {
                showingAdvancedOptions.toggle()
            }
            .foregroundColor(.blue)
        }
    }
    
    private var advancedOptionsSection: some View {
        Section("Advanced Options") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tags")
                    .font(.headline)
                
                TagEditor(
                    tags: Binding(
                        get: { modifications.tags ?? item.tags },
                        set: { modifications.tags = $0 }
                    )
                )
                
                Text("Custom Fields")
                    .font(.headline)
                    .padding(.top)
                
                let customFields = modifications.customFields ?? item.customFields
                if !customFields.isEmpty {
                    ForEach(Array(customFields.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Remove") {
                                var fields = modifications.customFields ?? item.customFields
                                fields.removeValue(forKey: key)
                                modifications.customFields = fields
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                } else {
                    Text("No custom fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            if duplicationService.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Duplicating item...")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                        Text("Create duplicate with modifications")
                        Spacer()
                    }
                    
                    Text("The duplicate will be created in the selected collection with your modifications applied.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func duplicateItem() async {
        let targetCollectionId = selectedCollectionId != item.collectionId ? selectedCollectionId : nil
        
        do {
            let duplicatedItem = try await duplicationService.duplicateItem(
                item,
                with: modifications,
                to: targetCollectionId
            )
            
            await MainActor.run {
                onDuplicationComplete(duplicatedItem)
                dismiss()
            }
        } catch {
            // Error handling would be implemented here
            // For now, we'll just print the error
            print("Duplication failed: \(error)")
        }
    }
    
    // MARK: - Computed Bindings
    
    private var nameBinding: Binding<String> {
        Binding(
            get: { modifications.name ?? item.name },
            set: { modifications.name = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var descriptionBinding: Binding<String> {
        Binding(
            get: { modifications.description ?? item.description ?? "" },
            set: { modifications.description = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var favoriteBinding: Binding<Bool> {
        Binding(
            get: { modifications.isFavorite ?? item.isFavorite },
            set: { modifications.isFavorite = $0 }
        )
    }
    
    private var ratingBinding: Binding<Double> {
        Binding(
            get: { modifications.rating ?? item.rating ?? 0 },
            set: { modifications.rating = $0 > 0 ? $0 : nil }
        )
    }
}

// MARK: - Tag Editor

private struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(text: tag) {
                        tags.removeAll { $0 == tag }
                    }
                }
                
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit {
                        addTag()
                    }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

private struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
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
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > width && currentRowWidth > 0 {
                height += currentRowHeight + spacing
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + (currentRowWidth > 0 ? spacing : 0)
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentPosition = bounds.origin
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + subviewSize.width > bounds.maxX && currentPosition.x > bounds.minX {
                currentPosition.x = bounds.minX
                currentPosition.y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(at: currentPosition, proposal: ProposedViewSize(subviewSize))
            
            currentPosition.x += subviewSize.width + spacing
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
}
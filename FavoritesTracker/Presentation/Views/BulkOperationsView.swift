import SwiftUI

/// View for performing bulk operations on selected items
struct BulkOperationsView: View {
    
    // MARK: - Properties
    
    let selectedItems: [Item]
    let collections: [Collection]
    @StateObject private var bulkService: BulkOperationsService
    @State private var selectedOperation: BulkOperationType = .edit
    @State private var showingConfirmation = false
    @State private var operationResult: BulkOperationResult?
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    // Edit operations state
    @State private var editRating: Double?
    @State private var editIsFavorite: Bool?
    @State private var editTags: [String] = []
    @State private var tagMode: BulkTagMode = .add
    
    // Move operation state
    @State private var targetCollectionId: String = ""
    
    // Callbacks
    let onOperationComplete: (BulkOperationResult) -> Void
    
    // MARK: - Initialization
    
    init(
        selectedItems: [Item],
        collections: [Collection],
        itemRepository: ItemRepositoryProtocol,
        collectionRepository: CollectionRepositoryProtocol,
        onOperationComplete: @escaping (BulkOperationResult) -> Void
    ) {
        self.selectedItems = selectedItems
        self.collections = collections
        self.onOperationComplete = onOperationComplete
        self._bulkService = StateObject(wrappedValue: BulkOperationsService(
            itemRepository: itemRepository,
            collectionRepository: collectionRepository
        ))
        
        // Initialize target collection to first available collection
        if let firstCollection = collections.first {
            self._targetCollectionId = State(initialValue: firstCollection.id)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                selectedItemsSection
                operationSelectionSection
                
                switch selectedOperation {
                case .edit:
                    bulkEditSection
                case .delete:
                    bulkDeleteSection
                case .move:
                    bulkMoveSection
                case .tag:
                    bulkTagSection
                case .duplicate:
                    bulkDuplicateSection
                }
                
                if bulkService.isProcessing {
                    progressSection
                } else {
                    actionSection
                }
                
                if let result = operationResult {
                    resultSection(result)
                }
            }
            .navigationTitle("Bulk Operations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Execute") {
                        showingConfirmation = true
                    }
                    .disabled(bulkService.isProcessing || !canExecuteOperation)
                }
            }
            .confirmationDialog(
                "Confirm Bulk Operation",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Execute", role: .destructive) {
                    Task {
                        await executeOperation()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(confirmationMessage)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var selectedItemsSection: some View {
        Section("Selected Items (\(selectedItems.count))") {
            if selectedItems.count <= 3 {
                ForEach(selectedItems, id: \.id) { item in
                    ItemRowView(item: item)
                }
            } else {
                ForEach(selectedItems.prefix(2), id: \.id) { item in
                    ItemRowView(item: item)
                }
                
                Text("And \(selectedItems.count - 2) more items...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var operationSelectionSection: some View {
        Section("Operation") {
            Picker("Operation Type", selection: $selectedOperation) {
                Text("Edit Items").tag(BulkOperationType.edit)
                Text("Delete Items").tag(BulkOperationType.delete)
                Text("Move Items").tag(BulkOperationType.move)
                Text("Apply Tags").tag(BulkOperationType.tag)
                Text("Duplicate Items").tag(BulkOperationType.duplicate)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var bulkEditSection: some View {
        Section("Edit Options") {
            VStack(alignment: .leading, spacing: 16) {
                LabeledContent("Rating") {
                    HStack {
                        Button("Clear") {
                            editRating = nil
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        InteractiveStarRatingView(
                            rating: Binding(
                                get: { editRating ?? 0 },
                                set: { editRating = $0 > 0 ? $0 : nil }
                            )
                        )
                    }
                }
                
                LabeledContent("Favorite Status") {
                    Picker("Favorite", selection: Binding(
                        get: { editIsFavorite },
                        set: { editIsFavorite = $0 }
                    )) {
                        Text("Don't Change").tag(nil as Bool?)
                        Text("Set as Favorite").tag(true as Bool?)
                        Text("Remove from Favorites").tag(false as Bool?)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    private var bulkDeleteSection: some View {
        Section("Delete Confirmation") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Permanently delete \(selectedItems.count) items")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Text("This action cannot be undone. All selected items will be removed from their collections.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var bulkMoveSection: some View {
        Section("Move to Collection") {
            Picker("Target Collection", selection: $targetCollectionId) {
                ForEach(collections, id: \.id) { collection in
                    Text(collection.name).tag(collection.id)
                }
            }
            .pickerStyle(.menu)
            
            Text("All selected items will be moved to the chosen collection.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var bulkTagSection: some View {
        Section("Tag Operations") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Tag Mode", selection: $tagMode) {
                    Text("Add Tags").tag(BulkTagMode.add)
                    Text("Replace Tags").tag(BulkTagMode.replace)
                    Text("Remove Tags").tag(BulkTagMode.remove)
                }
                .pickerStyle(.segmented)
                
                TagEditor(tags: $editTags)
                
                switch tagMode {
                case .add:
                    Text("Tags will be added to existing tags on each item.")
                case .replace:
                    Text("All existing tags will be replaced with the specified tags.")
                case .remove:
                    Text("Specified tags will be removed from each item.")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var bulkDuplicateSection: some View {
        Section("Duplicate Options") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                    Text("Create duplicates of \(selectedItems.count) items")
                        .font(.headline)
                }
                
                Text("Smart suggestions will be applied to each duplicate (names will have 'Copy' appended, ratings cleared, etc.).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressSection: some View {
        Section("Progress") {
            VStack(spacing: 12) {
                ProgressView(value: bulkService.operationProgress)
                
                HStack {
                    Text("Processing...")
                    Spacer()
                    Text("\(Int(bulkService.operationProgress * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            Button(action: {
                showingConfirmation = true
            }) {
                HStack {
                    Image(systemName: operationIcon)
                    Text(operationButtonText)
                    Spacer()
                }
                .foregroundColor(operationColor)
            }
            .disabled(!canExecuteOperation)
        }
    }
    
    private func resultSection(_ result: BulkOperationResult) -> some View {
        Section("Operation Result") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: result.hasFailures ? "exclamationmark.triangle" : "checkmark.circle")
                        .foregroundColor(result.hasFailures ? .orange : .green)
                    
                    Text("\(result.successCount) of \(result.totalItems) items processed successfully")
                        .font(.headline)
                }
                
                if result.hasFailures {
                    Text("\(result.failedCount) items failed to process")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Text("Success Rate: \(Int(result.successRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var confirmationMessage: String {
        switch selectedOperation {
        case .edit:
            return "Apply bulk edits to \(selectedItems.count) items?"
        case .delete:
            return "Permanently delete \(selectedItems.count) items? This cannot be undone."
        case .move:
            return "Move \(selectedItems.count) items to the selected collection?"
        case .tag:
            return "Apply tag changes to \(selectedItems.count) items?"
        case .duplicate:
            return "Create duplicates of \(selectedItems.count) items?"
        }
    }
    
    private var operationButtonText: String {
        switch selectedOperation {
        case .edit: return "Apply Edits"
        case .delete: return "Delete Items"
        case .move: return "Move Items"
        case .tag: return "Apply Tags"
        case .duplicate: return "Duplicate Items"
        }
    }
    
    private var operationIcon: String {
        switch selectedOperation {
        case .edit: return "pencil"
        case .delete: return "trash"
        case .move: return "folder"
        case .tag: return "tag"
        case .duplicate: return "doc.on.doc"
        }
    }
    
    private var operationColor: Color {
        switch selectedOperation {
        case .edit: return .blue
        case .delete: return .red
        case .move: return .green
        case .tag: return .purple
        case .duplicate: return .orange
        }
    }
    
    private var canExecuteOperation: Bool {
        switch selectedOperation {
        case .edit:
            return editRating != nil || editIsFavorite != nil
        case .delete:
            return true
        case .move:
            return !targetCollectionId.isEmpty
        case .tag:
            return !editTags.isEmpty
        case .duplicate:
            return true
        }
    }
    
    // MARK: - Actions
    
    private func executeOperation() async {
        do {
            let result: BulkOperationResult
            
            switch selectedOperation {
            case .edit:
                let edits = BulkEditOperations(
                    rating: editRating,
                    isFavorite: editIsFavorite,
                    customFieldUpdates: nil
                )
                result = try await bulkService.bulkEditItems(selectedItems, with: edits)
                
            case .delete:
                result = try await bulkService.bulkDeleteItems(selectedItems)
                
            case .move:
                result = try await bulkService.bulkMoveItems(selectedItems, to: targetCollectionId)
                
            case .tag:
                result = try await bulkService.bulkApplyTags(to: selectedItems, tags: editTags, mode: tagMode)
                
            case .duplicate:
                // For now, we'll use the duplication service for individual items
                // A more efficient bulk duplicate could be implemented later
                result = BulkOperationResult(
                    operation: .duplicate,
                    totalItems: selectedItems.count,
                    successCount: 0,
                    failedCount: 0,
                    failedItems: []
                )
            }
            
            await MainActor.run {
                operationResult = result
                onOperationComplete(result)
                
                // Auto-dismiss after successful operations
                if !result.hasFailures {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
            
        } catch {
            print("Bulk operation failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

private struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            AsyncImage(url: item.imageURLs.first) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipped()
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Tag Editor (Reused from ItemDuplicationView)

private struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
            
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
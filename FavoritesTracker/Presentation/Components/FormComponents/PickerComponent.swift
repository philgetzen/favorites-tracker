import SwiftUI

/// Picker component for single or multiple selection from predefined options
struct PickerComponent: FormComponentProtocol, OptionBasedFormComponent {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var selectedOption: String = ""
    @State private var selectedOptions: Set<String> = []
    @State private var validationResult: ComponentValidationResult = .valid
    @State private var showingOptions = false
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    var options: [String] {
        definition.options ?? []
    }
    
    var allowsMultipleSelection: Bool {
        // Determine from label or type - could be enhanced with a specific property
        let label = definition.label.lowercased()
        return label.contains("tags") || label.contains("categories") || label.contains("features")
    }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize selected values from binding
        if case .text(let text) = value.wrappedValue {
            if allowsMultipleSelection {
                self._selectedOptions = State(initialValue: Set(text.components(separatedBy: ",")))
            } else {
                self._selectedOption = State(initialValue: text)
            }
        } else if let defaultValue = definition.defaultValue,
                  case .text(let defaultText) = defaultValue {
            if allowsMultipleSelection {
                self._selectedOptions = State(initialValue: Set(defaultText.components(separatedBy: ",")))
            } else {
                self._selectedOption = State(initialValue: defaultText)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with required indicator
            HStack {
                Text(definition.label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if definition.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Spacer()
                
                // Selection count for multiple selection
                if allowsMultipleSelection && !selectedOptions.isEmpty {
                    Text("\(selectedOptions.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Picker button or inline options
            if shouldShowInlineOptions {
                inlineOptionsView
            } else {
                pickerButtonView
            }
            
            // Selected items display for multiple selection
            if allowsMultipleSelection && !selectedOptions.isEmpty {
                selectedItemsView
            }
            
            // Validation feedback
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
            
            // Helper text
            if let helperText = helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Set initial value if none exists
            if value.wrappedValue == nil, let defaultValue = definition.defaultValue {
                value.wrappedValue = defaultValue
                if case .text(let text) = defaultValue {
                    if allowsMultipleSelection {
                        selectedOptions = Set(text.components(separatedBy: ","))
                    } else {
                        selectedOption = text
                    }
                }
            }
            validateInput()
        }
    }
    
    // MARK: - View Components
    
    private var pickerButtonView: some View {
        Button(action: {
            showingOptions.toggle()
        }) {
            HStack {
                Image(systemName: pickerIcon)
                    .foregroundColor(.blue)
                
                Text(buttonDisplayText)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingOptions) {
            OptionsSelectionSheet(
                title: definition.label,
                options: options,
                allowsMultipleSelection: allowsMultipleSelection,
                selectedOption: $selectedOption,
                selectedOptions: $selectedOptions,
                onSelectionChanged: handleSelectionChanged
            )
        }
    }
    
    private var inlineOptionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    toggleOption(option)
                }) {
                    HStack {
                        Image(systemName: isOptionSelected(option) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isOptionSelected(option) ? .blue : .secondary)
                        
                        Text(option)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(isOptionSelected(option) ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOptionSelected(option) ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var selectedItemsView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80))
        ], spacing: 8) {
            ForEach(Array(selectedOptions), id: \.self) { option in
                HStack(spacing: 4) {
                    Text(option)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        selectedOptions.remove(option)
                        updateMultipleSelectionValue()
                    }) {
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
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required {
            if allowsMultipleSelection {
                if selectedOptions.isEmpty {
                    return .invalid("Please select at least one option")
                }
            } else {
                if selectedOption.isEmpty {
                    return .invalid("Please select an option")
                }
            }
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var shouldShowInlineOptions: Bool {
        // Show inline for small option sets or specific types
        return options.count <= 4 || definition.label.lowercased().contains("priority")
    }
    
    private var pickerIcon: String {
        let label = definition.label.lowercased()
        
        if label.contains("category") {
            return "folder"
        } else if label.contains("priority") {
            return "exclamationmark.triangle"
        } else if label.contains("tag") {
            return "tag"
        } else if label.contains("status") {
            return "checkmark.circle"
        }
        
        return "list.bullet"
    }
    
    private var buttonDisplayText: String {
        if allowsMultipleSelection {
            if selectedOptions.isEmpty {
                return "Select options"
            } else if selectedOptions.count == 1 {
                return selectedOptions.first ?? "Select options"
            } else {
                return "\(selectedOptions.count) options selected"
            }
        } else {
            return selectedOption.isEmpty ? "Select option" : selectedOption
        }
    }
    
    private var helperText: String? {
        if allowsMultipleSelection {
            return "You can select multiple options"
        }
        return nil
    }
    
    private func isOptionSelected(_ option: String) -> Bool {
        if allowsMultipleSelection {
            return selectedOptions.contains(option)
        } else {
            return selectedOption == option
        }
    }
    
    private func toggleOption(_ option: String) {
        if allowsMultipleSelection {
            if selectedOptions.contains(option) {
                selectedOptions.remove(option)
            } else {
                selectedOptions.insert(option)
            }
            updateMultipleSelectionValue()
        } else {
            selectedOption = option
            value.wrappedValue = .text(option)
        }
        validateInput()
    }
    
    private func updateMultipleSelectionValue() {
        if selectedOptions.isEmpty {
            value.wrappedValue = nil
        } else {
            value.wrappedValue = .text(Array(selectedOptions).joined(separator: ","))
        }
    }
    
    private func handleSelectionChanged() {
        if allowsMultipleSelection {
            updateMultipleSelectionValue()
        } else {
            value.wrappedValue = selectedOption.isEmpty ? nil : .text(selectedOption)
        }
        validateInput()
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Options Selection Sheet

private struct OptionsSelectionSheet: View {
    let title: String
    let options: [String]
    let allowsMultipleSelection: Bool
    @Binding var selectedOption: String
    @Binding var selectedOptions: Set<String>
    let onSelectionChanged: () -> Void
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredOptions: [String] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                if options.count > 10 {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                }
                
                // Options list
                List(filteredOptions, id: \.self) { option in
                    Button(action: {
                        selectOption(option)
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isSelected(option) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelectionChanged()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func isSelected(_ option: String) -> Bool {
        if allowsMultipleSelection {
            return selectedOptions.contains(option)
        } else {
            return selectedOption == option
        }
    }
    
    private func selectOption(_ option: String) {
        if allowsMultipleSelection {
            if selectedOptions.contains(option) {
                selectedOptions.remove(option)
            } else {
                selectedOptions.insert(option)
            }
        } else {
            selectedOption = option
            onSelectionChanged()
            dismiss()
        }
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search options", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview Support

#if DEBUG
struct PickerComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Single selection picker
            PickerComponent(
                definition: ComponentDefinition(
                    id: "category",
                    type: .picker,
                    label: "Category",
                    isRequired: true,
                    options: ["Books", "Electronics", "Clothing", "Home & Garden"],
                    validation: ValidationRule(required: true)
                ),
                value: .constant(.text("Books"))
            )
            
            // Multiple selection picker
            PickerComponent(
                definition: ComponentDefinition(
                    id: "tags",
                    type: .picker,
                    label: "Tags",
                    isRequired: false,
                    options: ["Favorite", "Gift", "Vintage", "Rare", "Collection"]
                ),
                value: .constant(.text("Favorite,Vintage"))
            )
            
            // Priority picker with inline display
            PickerComponent(
                definition: ComponentDefinition(
                    id: "priority",
                    type: .picker,
                    label: "Priority",
                    isRequired: false,
                    options: ["Low", "Medium", "High", "Urgent"]
                ),
                value: .constant(.text("Medium"))
            )
        }
        .padding()
    }
}
#endif
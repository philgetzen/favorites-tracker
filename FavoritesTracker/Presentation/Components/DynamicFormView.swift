import SwiftUI

/// Dynamic form view that renders forms from component definitions
/// This is the main interface for creating template-driven forms
struct DynamicFormView: View {
    let definitions: [ComponentDefinition]
    @Binding var values: [String: CustomFieldValue]
    
    @StateObject private var factory = ComponentFactory()
    @State private var validationResults: [String: ComponentValidationResult] = [:]
    @State private var isFormValid = false
    
    // Customization options
    let showValidationErrors: Bool
    let groupBySection: Bool
    let onValidationChange: ((Bool) -> Void)?
    let onValuesChange: (([String: CustomFieldValue]) -> Void)?
    
    init(
        definitions: [ComponentDefinition],
        values: Binding<[String: CustomFieldValue]>,
        showValidationErrors: Bool = true,
        groupBySection: Bool = true,
        onValidationChange: ((Bool) -> Void)? = nil,
        onValuesChange: (([String: CustomFieldValue]) -> Void)? = nil
    ) {
        self.definitions = definitions
        self._values = values
        self.showValidationErrors = showValidationErrors
        self.groupBySection = groupBySection
        self.onValidationChange = onValidationChange
        self.onValuesChange = onValuesChange
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if groupBySection {
                    groupedFormView
                } else {
                    linearFormView
                }
                
                // Form summary
                if showFormSummary {
                    formSummaryView
                }
            }
            .padding()
        }
        .onChange(of: values) { oldValues, newValues in
            validateForm()
            onValuesChange?(newValues)
        }
        .onAppear {
            // Initialize missing values with defaults
            initializeDefaultValues()
            validateForm()
        }
    }
    
    // MARK: - Form Layout Options
    
    private var linearFormView: some View {
        ForEach(definitions, id: \.id) { definition in
            createComponentView(for: definition)
        }
    }
    
    private var groupedFormView: some View {
        ForEach(componentGroups, id: \.title) { group in
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Text(group.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Section progress indicator
                    if group.definitions.count > 1 {
                        Text("\(completedCount(in: group))/\(group.definitions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section components
                VStack(spacing: 16) {
                    ForEach(group.definitions, id: \.id) { definition in
                        createComponentView(for: definition)
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
        }
    }
    
    private var formSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Form Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(completedFieldsCount)/\(totalFieldsCount) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            ProgressView(value: formCompletionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            // Validation status
            HStack {
                Image(systemName: isFormValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isFormValid ? .green : .orange)
                
                Text(isFormValid ? "Form is valid" : "Some fields need attention")
                    .font(.caption)
                    .foregroundColor(isFormValid ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Component Creation
    
    private func createComponentView(for definition: ComponentDefinition) -> some View {
        let valueBinding = Binding<CustomFieldValue?>(
            get: { values[definition.id] },
            set: { newValue in
                if let newValue = newValue {
                    values[definition.id] = newValue
                } else {
                    values.removeValue(forKey: definition.id)
                }
            }
        )
        
        return VStack(alignment: .leading, spacing: 8) {
            factory.createComponent(definition: definition, value: valueBinding)
            
            // Show validation errors if enabled
            if showValidationErrors,
               let validationResult = validationResults[definition.id],
               !validationResult.isValid,
               let errorMessage = validationResult.errorMessage {
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
        }
    }
    
    // MARK: - Form Organization
    
    private var componentGroups: [ComponentGroup] {
        // Group components by logical sections
        var groups: [ComponentGroup] = []
        var currentGroup: ComponentGroup?
        
        for definition in definitions {
            let section = determineSection(for: definition)
            
            if currentGroup?.title != section {
                if let group = currentGroup {
                    groups.append(group)
                }
                currentGroup = ComponentGroup(title: section, definitions: [])
            }
            
            currentGroup?.definitions.append(definition)
        }
        
        if let group = currentGroup {
            groups.append(group)
        }
        
        return groups
    }
    
    private func determineSection(for definition: ComponentDefinition) -> String {
        let label = definition.label.lowercased()
        
        if label.contains("name") || label.contains("title") || label.contains("description") {
            return "Basic Information"
        } else if label.contains("price") || label.contains("cost") || label.contains("value") {
            return "Pricing & Value"
        } else if label.contains("date") || label.contains("time") || label.contains("when") {
            return "Dates & Timeline"
        } else if label.contains("rating") || label.contains("score") || label.contains("quality") {
            return "Ratings & Reviews"
        } else if label.contains("tag") || label.contains("category") || label.contains("type") {
            return "Classification"
        } else if label.contains("location") || label.contains("address") || label.contains("where") {
            return "Location & Contact"
        } else if label.contains("note") || label.contains("comment") || label.contains("additional") {
            return "Additional Details"
        }
        
        return "General"
    }
    
    // MARK: - Form State Management
    
    private func initializeDefaultValues() {
        for definition in definitions {
            // Only set default if no value exists
            if values[definition.id] == nil, let defaultValue = definition.defaultValue {
                values[definition.id] = defaultValue
            }
        }
    }
    
    private func validateForm() {
        validationResults = factory.validateForm(definitions: definitions, values: values)
        isFormValid = validationResults.values.allSatisfy { $0.isValid }
        onValidationChange?(isFormValid)
    }
    
    // MARK: - Progress Calculation
    
    private var totalFieldsCount: Int {
        definitions.count
    }
    
    private var completedFieldsCount: Int {
        definitions.count { definition in
            let value = values[definition.id]
            return value != nil && !value!.stringValue.isEmpty
        }
    }
    
    private var formCompletionPercentage: Double {
        guard totalFieldsCount > 0 else { return 0 }
        return Double(completedFieldsCount) / Double(totalFieldsCount)
    }
    
    private var showFormSummary: Bool {
        totalFieldsCount > 3
    }
    
    private func completedCount(in group: ComponentGroup) -> Int {
        group.definitions.count { definition in
            let value = values[definition.id]
            return value != nil && !value!.stringValue.isEmpty
        }
    }
}

// MARK: - Supporting Types

private struct ComponentGroup {
    let title: String
    var definitions: [ComponentDefinition]
}

// MARK: - Preview Support

#if DEBUG
struct DynamicFormView_Previews: PreviewProvider {
    @State private static var formValues: [String: CustomFieldValue] = [:]
    
    static var previews: some View {
        NavigationView {
            DynamicFormView(
                definitions: sampleDefinitions,
                values: $formValues,
                onValidationChange: { isValid in
                    print("Form is valid: \(isValid)")
                },
                onValuesChange: { values in
                    print("Form values changed: \(values)")
                }
            )
            .navigationTitle("Dynamic Form")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private static var sampleDefinitions: [ComponentDefinition] {
        [
            ComponentDefinition(
                id: "name",
                type: .textField,
                label: "Item Name",
                isRequired: true,
                validation: ValidationRule(minLength: 2, maxLength: 100, required: true)
            ),
            ComponentDefinition(
                id: "description",
                type: .textArea,
                label: "Description",
                isRequired: false,
                validation: ValidationRule(maxLength: 500)
            ),
            ComponentDefinition(
                id: "price",
                type: .numberField,
                label: "Price ($)",
                isRequired: false,
                validation: ValidationRule(minValue: 0, maxValue: 10000)
            ),
            ComponentDefinition(
                id: "purchase_date",
                type: .dateField,
                label: "Purchase Date",
                isRequired: false
            ),
            ComponentDefinition(
                id: "category",
                type: .picker,
                label: "Category",
                isRequired: true,
                options: ["Electronics", "Books", "Clothing", "Home & Garden", "Sports"],
                validation: ValidationRule(required: true)
            ),
            ComponentDefinition(
                id: "is_favorite",
                type: .toggle,
                label: "Favorite",
                isRequired: false
            ),
            ComponentDefinition(
                id: "overall_rating",
                type: .rating,
                label: "Overall Rating",
                isRequired: false,
                validation: ValidationRule(minValue: 1, maxValue: 5)
            )
        ]
    }
}
#endif
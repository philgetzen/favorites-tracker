import SwiftUI

/// Factory class for creating form components dynamically
/// Provides high-level interface for component instantiation and form generation
@MainActor
final class ComponentFactory: ObservableObject {
    
    /// Component registry for type mapping
    private let registry: ComponentRegistry
    
    /// Initialize with a specific registry (useful for testing)
    init(registry: ComponentRegistry = .shared) {
        self.registry = registry
    }
    
    // MARK: - Single Component Creation
    
    /// Create a single form component from its definition
    func createComponent(
        definition: ComponentDefinition,
        value: Binding<CustomFieldValue?>
    ) -> AnyView {
        return registry.createComponent(for: definition, value: value)
    }
    
    /// Create a component with an initial value and change handler
    func createComponent(
        definition: ComponentDefinition,
        initialValue: CustomFieldValue? = nil,
        onChange: @escaping (CustomFieldValue?) -> Void = { _ in }
    ) -> AnyView {
        return registry.createComponent(
            for: definition,
            initialValue: initialValue,
            onChange: onChange
        )
    }
    
    // MARK: - Form Creation
    
    /// Create a complete form from component definitions
    func createForm(
        definitions: [ComponentDefinition],
        values: Binding<[String: CustomFieldValue]>
    ) -> some View {
        FormContainer(
            definitions: definitions,
            values: values,
            factory: self
        )
    }
    
    /// Create a form with initial values and validation
    func createValidatedForm(
        definitions: [ComponentDefinition],
        initialValues: [String: CustomFieldValue] = [:],
        onValidationChange: @escaping (Bool) -> Void = { _ in },
        onValuesChange: @escaping ([String: CustomFieldValue]) -> Void = { _ in }
    ) -> some View {
        ValidatedFormContainer(
            definitions: definitions,
            initialValues: initialValues,
            factory: self,
            onValidationChange: onValidationChange,
            onValuesChange: onValuesChange
        )
    }
    
    // MARK: - Utility Methods
    
    /// Check if all required fields in definitions have values
    func validateRequiredFields(
        definitions: [ComponentDefinition],
        values: [String: CustomFieldValue]
    ) -> ComponentValidationResult {
        let requiredFields = definitions.filter { $0.isRequired }
        
        for definition in requiredFields {
            let value = values[definition.id]
            
            if value == nil || value?.stringValue.isEmpty == true {
                return .invalid("'\(definition.label)' is required")
            }
        }
        
        return .valid
    }
    
    /// Validate all components in a form
    func validateForm(
        definitions: [ComponentDefinition],
        values: [String: CustomFieldValue]
    ) -> [String: ComponentValidationResult] {
        var results: [String: ComponentValidationResult] = [:]
        
        for definition in definitions {
            let value = values[definition.id]
            let result = validateComponent(definition: definition, value: value)
            results[definition.id] = result
        }
        
        return results
    }
    
    /// Validate a single component
    func validateComponent(
        definition: ComponentDefinition,
        value: CustomFieldValue?
    ) -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required
        if validationRule.required && (value == nil || value?.stringValue.isEmpty == true) {
            return .invalid("This field is required")
        }
        
        guard let fieldValue = value else {
            return .valid
        }
        
        // Type-specific validation
        switch fieldValue {
        case .text(let text):
            return validateText(text, rule: validationRule)
        case .number(let number):
            return validateNumber(number, rule: validationRule)
        case .date, .boolean, .url, .image:
            return .valid
        }
    }
    
    // MARK: - Private Validation Helpers
    
    private func validateText(_ text: String, rule: ValidationRule) -> ComponentValidationResult {
        if let minLength = rule.minLength, text.count < minLength {
            return .invalid("Must be at least \(minLength) characters")
        }
        
        if let maxLength = rule.maxLength, text.count > maxLength {
            return .invalid("Must be no more than \(maxLength) characters")
        }
        
        if let pattern = rule.pattern {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex?.firstMatch(in: text, options: [], range: range)
            
            if matches == nil {
                return .invalid("Invalid format")
            }
        }
        
        return .valid
    }
    
    private func validateNumber(_ number: Double, rule: ValidationRule) -> ComponentValidationResult {
        if let minValue = rule.minValue, number < minValue {
            return .invalid("Must be at least \(minValue)")
        }
        
        if let maxValue = rule.maxValue, number > maxValue {
            return .invalid("Must be no more than \(maxValue)")
        }
        
        return .valid
    }
}

// MARK: - Form Container Views

/// Internal container for basic form rendering
private struct FormContainer: View {
    let definitions: [ComponentDefinition]
    @Binding var values: [String: CustomFieldValue]
    let factory: ComponentFactory
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(definitions, id: \.id) { definition in
                createComponentView(for: definition)
            }
        }
    }
    
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
        
        return factory.createComponent(definition: definition, value: valueBinding)
    }
}

/// Internal container for validated form rendering
private struct ValidatedFormContainer: View {
    let definitions: [ComponentDefinition]
    let factory: ComponentFactory
    let onValidationChange: (Bool) -> Void
    let onValuesChange: ([String: CustomFieldValue]) -> Void
    
    @State private var values: [String: CustomFieldValue]
    @State private var validationResults: [String: ComponentValidationResult] = [:]
    
    init(
        definitions: [ComponentDefinition],
        initialValues: [String: CustomFieldValue],
        factory: ComponentFactory,
        onValidationChange: @escaping (Bool) -> Void,
        onValuesChange: @escaping ([String: CustomFieldValue]) -> Void
    ) {
        self.definitions = definitions
        self.factory = factory
        self.onValidationChange = onValidationChange
        self.onValuesChange = onValuesChange
        self._values = State(initialValue: initialValues)
    }
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(definitions, id: \.id) { definition in
                VStack(alignment: .leading, spacing: 4) {
                    createComponentView(for: definition)
                    
                    // Show validation error if present
                    if let validationResult = validationResults[definition.id],
                       !validationResult.isValid,
                       let errorMessage = validationResult.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .onChange(of: values) { oldValues, newValues in
            validateAndNotify()
            onValuesChange(newValues)
        }
        .onAppear {
            validateAndNotify()
        }
    }
    
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
        
        return factory.createComponent(definition: definition, value: valueBinding)
    }
    
    private func validateAndNotify() {
        validationResults = factory.validateForm(definitions: definitions, values: values)
        let isValid = validationResults.values.allSatisfy { $0.isValid }
        onValidationChange(isValid)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ComponentFactory {
    
    /// Create a preview-safe factory
    static func previewFactory() -> ComponentFactory {
        return ComponentFactory(registry: .previewRegistry())
    }
    
    /// Create sample component definitions for previews
    static func sampleDefinitions() -> [ComponentDefinition] {
        return [
            ComponentDefinition(
                id: "name",
                type: .textField,
                label: "Name",
                isRequired: true,
                validation: ValidationRule(minLength: 2, maxLength: 50, required: true)
            ),
            ComponentDefinition(
                id: "description",
                type: .textArea,
                label: "Description",
                isRequired: false
            ),
            ComponentDefinition(
                id: "rating",
                type: .rating,
                label: "Rating",
                isRequired: false
            )
        ]
    }
}
#endif
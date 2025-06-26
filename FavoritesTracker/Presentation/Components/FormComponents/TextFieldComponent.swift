import SwiftUI

/// Text field component for single-line text input with validation
struct TextFieldComponent: FormComponentProtocol, FocusableFormComponent {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var textValue: String = ""
    @State private var validationResult: ComponentValidationResult = .valid
    @FocusState var isFocused: Bool
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize text value from binding
        if case .text(let text) = value.wrappedValue {
            self._textValue = State(initialValue: text)
        } else if let defaultValue = definition.defaultValue,
                  case .text(let defaultText) = defaultValue {
            self._textValue = State(initialValue: defaultText)
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
            }
            
            // Text field
            TextField(placeholderText, text: $textValue)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onChange(of: textValue) { oldValue, newValue in
                    updateValue(newValue)
                    validateInput()
                }
                .onSubmit {
                    validateInput()
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
            if let validation = definition.validation, !validation.required {
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
                    textValue = text
                }
            }
            validateInput()
        }
    }
    
    // MARK: - FocusableFormComponent
    
    func focus() {
        isFocused = true
    }
    
    func unfocus() {
        isFocused = false
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("\(definition.label) is required")
        }
        
        let trimmedText = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Length validation
        if let minLength = validationRule.minLength, trimmedText.count < minLength {
            return .invalid("Must be at least \(minLength) characters")
        }
        
        if let maxLength = validationRule.maxLength, trimmedText.count > maxLength {
            return .invalid("Must be no more than \(maxLength) characters")
        }
        
        // Pattern validation
        if let pattern = validationRule.pattern {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: trimmedText.utf16.count)
                let matches = regex.firstMatch(in: trimmedText, options: [], range: range)
                
                if matches == nil {
                    return .invalid("Invalid format")
                }
            } catch {
                return .invalid("Invalid pattern validation")
            }
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var placeholderText: String {
        if let validation = definition.validation {
            var parts: [String] = []
            
            if let minLength = validation.minLength, let maxLength = validation.maxLength {
                parts.append("\(minLength)-\(maxLength) characters")
            } else if let minLength = validation.minLength {
                parts.append("At least \(minLength) characters")
            } else if let maxLength = validation.maxLength {
                parts.append("Up to \(maxLength) characters")
            }
            
            if parts.isEmpty {
                return "Enter \(definition.label.lowercased())"
            } else {
                return parts.joined(separator: ", ")
            }
        }
        
        return "Enter \(definition.label.lowercased())"
    }
    
    private var helperText: String {
        guard let validation = definition.validation else {
            return ""
        }
        
        var parts: [String] = []
        
        if let minLength = validation.minLength, let maxLength = validation.maxLength {
            parts.append("Length: \(minLength)-\(maxLength) characters")
        } else if let minLength = validation.minLength {
            parts.append("Minimum: \(minLength) characters")
        } else if let maxLength = validation.maxLength {
            parts.append("Maximum: \(maxLength) characters")
        }
        
        if validation.pattern != nil {
            parts.append("Must match required format")
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func updateValue(_ newText: String) {
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            value.wrappedValue = nil
        } else {
            value.wrappedValue = .text(trimmedText)
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Text Area Component

/// Multi-line text area component for longer text input
struct TextAreaComponent: FormComponentProtocol, FocusableFormComponent {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var textValue: String = ""
    @State private var validationResult: ComponentValidationResult = .valid
    @FocusState var isFocused: Bool
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize text value from binding
        if case .text(let text) = value.wrappedValue {
            self._textValue = State(initialValue: text)
        } else if let defaultValue = definition.defaultValue,
                  case .text(let defaultText) = defaultValue {
            self._textValue = State(initialValue: defaultText)
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
                
                // Character count
                if let maxLength = definition.validation?.maxLength {
                    Text("\(textValue.count)/\(maxLength)")
                        .font(.caption2)
                        .foregroundColor(textValue.count > maxLength ? .red : .secondary)
                }
            }
            
            // Text editor
            TextEditor(text: $textValue)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isFocused)
                .onChange(of: textValue) { oldValue, newValue in
                    updateValue(newValue)
                    validateInput()
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
        }
        .onAppear {
            // Set initial value if none exists
            if value.wrappedValue == nil, let defaultValue = definition.defaultValue {
                value.wrappedValue = defaultValue
                if case .text(let text) = defaultValue {
                    textValue = text
                }
            }
            validateInput()
        }
    }
    
    // MARK: - FocusableFormComponent
    
    func focus() {
        isFocused = true
    }
    
    func unfocus() {
        isFocused = false
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("\(definition.label) is required")
        }
        
        let trimmedText = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Length validation
        if let minLength = validationRule.minLength, trimmedText.count < minLength {
            return .invalid("Must be at least \(minLength) characters")
        }
        
        if let maxLength = validationRule.maxLength, trimmedText.count > maxLength {
            return .invalid("Must be no more than \(maxLength) characters")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private func updateValue(_ newText: String) {
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            value.wrappedValue = nil
        } else {
            value.wrappedValue = .text(trimmedText)
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Preview Support

#if DEBUG
struct TextFieldComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Required text field
            TextFieldComponent(
                definition: ComponentDefinition(
                    id: "name",
                    type: .textField,
                    label: "Name",
                    isRequired: true,
                    validation: ValidationRule(minLength: 2, maxLength: 50, required: true)
                ),
                value: .constant(.text("Sample Text"))
            )
            
            // Optional text area
            TextAreaComponent(
                definition: ComponentDefinition(
                    id: "description",
                    type: .textArea,
                    label: "Description",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 200)
                ),
                value: .constant(nil)
            )
        }
        .padding()
    }
}
#endif
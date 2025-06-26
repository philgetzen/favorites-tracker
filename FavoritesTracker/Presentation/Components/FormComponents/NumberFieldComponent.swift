import SwiftUI

/// Number field component for numeric input with validation
struct NumberFieldComponent: FormComponentProtocol, FocusableFormComponent {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var textValue: String = ""
    @State private var numericValue: Double = 0.0
    @State private var validationResult: ComponentValidationResult = .valid
    @FocusState var isFocused: Bool
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    // Number formatting options
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize numeric value from binding
        if case .number(let number) = value.wrappedValue {
            self._numericValue = State(initialValue: number)
            self._textValue = State(initialValue: String(number))
        } else if let defaultValue = definition.defaultValue,
                  case .number(let defaultNumber) = defaultValue {
            self._numericValue = State(initialValue: defaultNumber)
            self._textValue = State(initialValue: String(defaultNumber))
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
                
                // Range indicator
                if let validation = definition.validation,
                   let minValue = validation.minValue,
                   let maxValue = validation.maxValue {
                    Text("(\(formatNumber(minValue)) - \(formatNumber(maxValue)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Number input field
            HStack {
                TextField(placeholderText, text: $textValue)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onChange(of: textValue) { oldValue, newValue in
                        processTextInput(newValue)
                    }
                    .onSubmit {
                        validateInput()
                    }
                
                // Unit label (if any)
                if let unitSymbol = unitSymbol {
                    Text(unitSymbol)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            }
            
            // Stepper controls for fine adjustment
            if shouldShowStepper {
                HStack {
                    Button(action: decrementValue) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.blue)
                    }
                    .disabled(!canDecrement)
                    
                    Spacer()
                    
                    Text(formatNumber(numericValue))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: incrementValue) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                    .disabled(!canIncrement)
                }
                .padding(.horizontal)
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
                if case .number(let number) = defaultValue {
                    numericValue = number
                    textValue = String(number)
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
        
        // Check if text can be converted to number
        let trimmedText = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return .valid // Empty optional field is valid
        }
        
        guard let number = Double(trimmedText) else {
            return .invalid("Must be a valid number")
        }
        
        // Range validation
        if let minValue = validationRule.minValue, number < minValue {
            return .invalid("Must be at least \(formatNumber(minValue))")
        }
        
        if let maxValue = validationRule.maxValue, number > maxValue {
            return .invalid("Must be no more than \(formatNumber(maxValue))")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var placeholderText: String {
        if let validation = definition.validation {
            if let minValue = validation.minValue, let maxValue = validation.maxValue {
                return "\(formatNumber(minValue)) - \(formatNumber(maxValue))"
            } else if let minValue = validation.minValue {
                return "Min: \(formatNumber(minValue))"
            } else if let maxValue = validation.maxValue {
                return "Max: \(formatNumber(maxValue))"
            }
        }
        
        return "Enter number"
    }
    
    private var helperText: String? {
        guard let validation = definition.validation else {
            return nil
        }
        
        var parts: [String] = []
        
        if let minValue = validation.minValue, let maxValue = validation.maxValue {
            parts.append("Range: \(formatNumber(minValue)) to \(formatNumber(maxValue))")
        } else if let minValue = validation.minValue {
            parts.append("Minimum: \(formatNumber(minValue))")
        } else if let maxValue = validation.maxValue {
            parts.append("Maximum: \(formatNumber(maxValue))")
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
    
    private var unitSymbol: String? {
        // Extract unit from label or validation pattern
        let label = definition.label.lowercased()
        
        if label.contains("price") || label.contains("cost") || label.contains("$") {
            return "$"
        } else if label.contains("weight") && label.contains("kg") {
            return "kg"
        } else if label.contains("weight") && label.contains("lb") {
            return "lbs"
        } else if label.contains("percent") || label.contains("%") {
            return "%"
        }
        
        return nil
    }
    
    private var shouldShowStepper: Bool {
        // Show stepper for small ranges or when min/max are defined
        guard let validation = definition.validation,
              let minValue = validation.minValue,
              let maxValue = validation.maxValue else {
            return false
        }
        
        let range = maxValue - minValue
        return range <= 100 // Show stepper for ranges of 100 or less
    }
    
    private var canIncrement: Bool {
        guard let validation = definition.validation,
              let maxValue = validation.maxValue else {
            return true
        }
        
        return numericValue < maxValue
    }
    
    private var canDecrement: Bool {
        guard let validation = definition.validation,
              let minValue = validation.minValue else {
            return true
        }
        
        return numericValue > minValue
    }
    
    private func formatNumber(_ number: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? String(number)
    }
    
    private func processTextInput(_ newText: String) {
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            value.wrappedValue = nil
            numericValue = 0.0
        } else if let number = Double(trimmedText) {
            numericValue = number
            value.wrappedValue = .number(number)
        }
        
        validateInput()
    }
    
    private func incrementValue() {
        let stepValue = getStepValue()
        let newValue = numericValue + stepValue
        
        if let validation = definition.validation,
           let maxValue = validation.maxValue,
           newValue > maxValue {
            numericValue = maxValue
        } else {
            numericValue = newValue
        }
        
        textValue = formatNumber(numericValue)
        value.wrappedValue = .number(numericValue)
        validateInput()
    }
    
    private func decrementValue() {
        let stepValue = getStepValue()
        let newValue = numericValue - stepValue
        
        if let validation = definition.validation,
           let minValue = validation.minValue,
           newValue < minValue {
            numericValue = minValue
        } else {
            numericValue = newValue
        }
        
        textValue = formatNumber(numericValue)
        value.wrappedValue = .number(numericValue)
        validateInput()
    }
    
    private func getStepValue() -> Double {
        guard let validation = definition.validation,
              let minValue = validation.minValue,
              let maxValue = validation.maxValue else {
            return 1.0
        }
        
        let range = maxValue - minValue
        
        if range <= 10 {
            return 0.1
        } else if range <= 100 {
            return 1.0
        } else {
            return 10.0
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Preview Support

#if DEBUG
struct NumberFieldComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Required number field with range
            NumberFieldComponent(
                definition: ComponentDefinition(
                    id: "price",
                    type: .numberField,
                    label: "Price ($)",
                    isRequired: true,
                    validation: ValidationRule(minValue: 0, maxValue: 1000, required: true)
                ),
                value: .constant(.number(25.50))
            )
            
            // Rating field with stepper
            NumberFieldComponent(
                definition: ComponentDefinition(
                    id: "rating",
                    type: .numberField,
                    label: "Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 10)
                ),
                value: .constant(.number(7))
            )
            
            // Weight field
            NumberFieldComponent(
                definition: ComponentDefinition(
                    id: "weight",
                    type: .numberField,
                    label: "Weight (kg)",
                    isRequired: false,
                    validation: ValidationRule(minValue: 0)
                ),
                value: .constant(nil)
            )
        }
        .padding()
    }
}
#endif
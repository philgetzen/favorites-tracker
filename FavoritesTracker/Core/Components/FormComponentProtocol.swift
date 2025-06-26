import SwiftUI

/// Protocol that all dynamic form components must conform to
/// Enables consistent interface for component rendering and value management
protocol FormComponentProtocol: View {
    /// The component definition that describes this component's configuration
    var definition: ComponentDefinition { get }
    
    /// Binding to the current value of this component
    var value: Binding<CustomFieldValue?> { get }
    
    /// Whether this component is currently in an error state
    var isValid: Bool { get }
    
    /// Current validation error message, if any
    var errorMessage: String? { get }
    
    /// Validates the current value against the component's validation rules
    func validate() -> ComponentValidationResult
}

/// Result of component validation
struct ComponentValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ComponentValidationResult(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> ComponentValidationResult {
        ComponentValidationResult(isValid: false, errorMessage: message)
    }
}

/// Base implementation for common validation logic
extension FormComponentProtocol {
    
    /// Default validation implementation using the component's validation rules
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && (value.wrappedValue == nil || value.wrappedValue?.stringValue.isEmpty == true) {
            return .invalid("This field is required")
        }
        
        guard let fieldValue = value.wrappedValue else {
            return .valid // Optional field with no value is valid
        }
        
        // Validate based on field type
        switch fieldValue {
        case .text(let text):
            return validateText(text, rule: validationRule)
        case .number(let number):
            return validateNumber(number, rule: validationRule)
        case .boolean, .date, .url, .image:
            return .valid // These types don't need additional validation
        }
    }
    
    /// Default error message based on validation state
    var errorMessage: String? {
        validate().errorMessage
    }
    
    /// Default validation state
    var isValid: Bool {
        validate().isValid
    }
    
    // MARK: - Private Validation Helpers
    
    private func validateText(_ text: String, rule: ValidationRule) -> ComponentValidationResult {
        // Length validation
        if let minLength = rule.minLength, text.count < minLength {
            return .invalid("Must be at least \(minLength) characters")
        }
        
        if let maxLength = rule.maxLength, text.count > maxLength {
            return .invalid("Must be no more than \(maxLength) characters")
        }
        
        // Pattern validation
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
        // Range validation
        if let minValue = rule.minValue, number < minValue {
            return .invalid("Must be at least \(minValue)")
        }
        
        if let maxValue = rule.maxValue, number > maxValue {
            return .invalid("Must be no more than \(maxValue)")
        }
        
        return .valid
    }
}

/// Protocol for components that support focus management
protocol FocusableFormComponent: FormComponentProtocol {
    /// Whether this component is currently focused
    var isFocused: Bool { get set }
    
    /// Focus the component programmatically
    func focus()
    
    /// Remove focus from the component
    func unfocus()
}

/// Protocol for components that support options/choices
protocol OptionBasedFormComponent: FormComponentProtocol {
    /// Available options for this component
    var options: [String] { get }
    
    /// Whether multiple selection is allowed
    var allowsMultipleSelection: Bool { get }
}

/// Protocol for components that support rich input (like images, files)
protocol MediaFormComponent: FormComponentProtocol {
    /// Whether this component is currently loading/uploading media
    var isLoading: Bool { get }
    
    /// Progress of current media operation (0.0 to 1.0)
    var progress: Double { get }
}
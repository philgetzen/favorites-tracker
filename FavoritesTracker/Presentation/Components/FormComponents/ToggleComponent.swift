import SwiftUI

/// Toggle component for boolean values with customizable appearance
struct ToggleComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var boolValue: Bool = false
    @State private var validationResult: ComponentValidationResult = .valid
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize boolean value from binding
        if case .boolean(let bool) = value.wrappedValue {
            self._boolValue = State(initialValue: bool)
        } else if let defaultValue = definition.defaultValue,
                  case .boolean(let defaultBool) = defaultValue {
            self._boolValue = State(initialValue: defaultBool)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Toggle with label
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(definition.label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if definition.isRequired {
                            Text("*")
                                .foregroundColor(.red)
                                .font(.headline)
                        }
                    }
                    
                    // Description or helper text
                    if let description = toggleDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $boolValue)
                    .onChange(of: boolValue) { oldValue, newValue in
                        value.wrappedValue = .boolean(newValue)
                        validateInput()
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Alternative style for certain types
            if shouldShowAlternativeStyle {
                HStack {
                    Button(action: {
                        boolValue = false
                        value.wrappedValue = .boolean(false)
                        validateInput()
                    }) {
                        HStack {
                            Image(systemName: boolValue ? "circle" : "checkmark.circle.fill")
                                .foregroundColor(boolValue ? .secondary : .green)
                            Text(negativeLabel)
                                .foregroundColor(boolValue ? .secondary : .primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(boolValue ? Color.clear : Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(boolValue ? Color.secondary : Color.green, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        boolValue = true
                        value.wrappedValue = .boolean(true)
                        validateInput()
                    }) {
                        HStack {
                            Image(systemName: boolValue ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(boolValue ? .blue : .secondary)
                            Text(positiveLabel)
                                .foregroundColor(boolValue ? .primary : .secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(boolValue ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(boolValue ? Color.blue : Color.secondary, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Status indicator
            if showStatusIndicator {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.caption)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
                .padding(.top, 4)
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
                if case .boolean(let bool) = defaultValue {
                    boolValue = bool
                }
            } else if value.wrappedValue == nil {
                // Default to false for optional boolean fields
                value.wrappedValue = .boolean(false)
            }
            validateInput()
        }
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // For boolean fields, "required" typically means "must be true"
        if validationRule.required && !boolValue {
            return .invalid("This option must be selected")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var toggleDescription: String? {
        let label = definition.label.lowercased()
        
        if label.contains("favorite") {
            return "Mark as favorite item"
        } else if label.contains("public") {
            return "Make visible to other users"
        } else if label.contains("notification") {
            return "Receive notifications"
        } else if label.contains("available") {
            return "Currently available for use"
        } else if label.contains("verified") {
            return "Item has been verified"
        }
        
        return nil
    }
    
    private var shouldShowAlternativeStyle: Bool {
        let label = definition.label.lowercased()
        return label.contains("condition") || label.contains("status") || label.contains("available")
    }
    
    private var positiveLabel: String {
        let label = definition.label.lowercased()
        
        if label.contains("condition") {
            return "Good"
        } else if label.contains("available") {
            return "Available"
        } else if label.contains("new") {
            return "New"
        }
        
        return "Yes"
    }
    
    private var negativeLabel: String {
        let label = definition.label.lowercased()
        
        if label.contains("condition") {
            return "Poor"
        } else if label.contains("available") {
            return "Unavailable"
        } else if label.contains("new") {
            return "Used"
        }
        
        return "No"
    }
    
    private var showStatusIndicator: Bool {
        let label = definition.label.lowercased()
        return label.contains("favorite") || label.contains("verified") || label.contains("public")
    }
    
    private var statusIcon: String {
        if boolValue {
            let label = definition.label.lowercased()
            if label.contains("favorite") {
                return "heart.fill"
            } else if label.contains("verified") {
                return "checkmark.shield.fill"
            } else if label.contains("public") {
                return "globe"
            }
            return "checkmark.circle.fill"
        }
        return "circle"
    }
    
    private var statusColor: Color {
        if boolValue {
            let label = definition.label.lowercased()
            if label.contains("favorite") {
                return .red
            } else if label.contains("verified") {
                return .green
            } else if label.contains("public") {
                return .blue
            }
            return .green
        }
        return .secondary
    }
    
    private var statusText: String {
        if boolValue {
            let label = definition.label.lowercased()
            if label.contains("favorite") {
                return "Added to favorites"
            } else if label.contains("verified") {
                return "Verified"
            } else if label.contains("public") {
                return "Public"
            }
            return "Enabled"
        }
        return "Disabled"
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Preview Support

#if DEBUG
struct ToggleComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Favorite toggle
            ToggleComponent(
                definition: ComponentDefinition(
                    id: "is_favorite",
                    type: .toggle,
                    label: "Favorite",
                    isRequired: false
                ),
                value: .constant(.boolean(true))
            )
            
            // Required agreement toggle
            ToggleComponent(
                definition: ComponentDefinition(
                    id: "agreement",
                    type: .toggle,
                    label: "I agree to the terms",
                    isRequired: true,
                    validation: ValidationRule(required: true)
                ),
                value: .constant(.boolean(false))
            )
            
            // Condition toggle with alternative style
            ToggleComponent(
                definition: ComponentDefinition(
                    id: "condition",
                    type: .toggle,
                    label: "Condition",
                    isRequired: false
                ),
                value: .constant(.boolean(true))
            )
            
            // Public visibility toggle
            ToggleComponent(
                definition: ComponentDefinition(
                    id: "is_public",
                    type: .toggle,
                    label: "Public",
                    isRequired: false
                ),
                value: .constant(.boolean(false))
            )
        }
        .padding()
    }
}
#endif
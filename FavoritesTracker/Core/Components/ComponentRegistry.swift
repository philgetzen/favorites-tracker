import SwiftUI

/// Registry that maps ComponentTypes to their corresponding SwiftUI view builders
/// Enables dynamic component instantiation based on ComponentDefinition
@MainActor
final class ComponentRegistry: ObservableObject {
    
    /// Shared instance of the component registry
    static let shared = ComponentRegistry()
    
    /// Type alias for component builder functions
    typealias ComponentBuilder = (ComponentDefinition, Binding<CustomFieldValue?>) -> AnyView
    
    /// Internal registry mapping component types to their builders
    private var builders: [ComponentDefinition.ComponentType: ComponentBuilder] = [:]
    
    private init() {
        registerDefaultComponents()
    }
    
    /// Register a component builder for a specific component type
    func register<T: FormComponentProtocol>(
        _ componentType: ComponentDefinition.ComponentType,
        builder: @escaping (ComponentDefinition, Binding<CustomFieldValue?>) -> T
    ) {
        builders[componentType] = { definition, value in
            AnyView(builder(definition, value))
        }
    }
    
    /// Create a SwiftUI view for the given component definition and value binding
    func createComponent(
        for definition: ComponentDefinition,
        value: Binding<CustomFieldValue?>
    ) -> AnyView {
        guard let builder = builders[definition.type] else {
            // Fallback to error view if component type is not registered
            return AnyView(
                Text("Unknown component type: \(definition.type.rawValue)")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            )
        }
        
        return builder(definition, value)
    }
    
    /// Check if a component type is registered
    func isRegistered(_ componentType: ComponentDefinition.ComponentType) -> Bool {
        return builders[componentType] != nil
    }
    
    /// Get all registered component types
    var registeredTypes: [ComponentDefinition.ComponentType] {
        return Array(builders.keys).sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Clear all registered components (useful for testing)
    func clearRegistry() {
        builders.removeAll()
    }
    
    // MARK: - Default Component Registration
    
    /// Register all default form components
    private func registerDefaultComponents() {
        // Text-based components
        register(.textField) { definition, value in
            TextFieldComponent(definition: definition, value: value)
        }
        
        register(.textArea) { definition, value in
            TextAreaComponent(definition: definition, value: value)
        }
        
        // Numeric components
        register(.numberField) { definition, value in
            NumberFieldComponent(definition: definition, value: value)
        }
        
        // Date components
        register(.dateField) { definition, value in
            DateFieldComponent(definition: definition, value: value)
        }
        
        // Boolean components
        register(.toggle) { definition, value in
            ToggleComponent(definition: definition, value: value)
        }
        
        // Selection components
        register(.picker) { definition, value in
            PickerComponent(definition: definition, value: value)
        }
        
        // Rating components
        register(.rating) { definition, value in
            RatingComponent(definition: definition, value: value)
        }
        
        // Media components
        register(.image) { definition, value in
            ImageComponent(definition: definition, value: value)
        }
        
        // Location components
        register(.location) { definition, value in
            LocationComponent(definition: definition, value: value)
        }
    }
}

/// Extension to provide convenient access to component creation
extension ComponentRegistry {
    
    /// Create multiple components from an array of definitions
    @MainActor
    func createComponents(
        for definitions: [ComponentDefinition],
        values: Binding<[String: CustomFieldValue]>
    ) -> [AnyView] {
        return definitions.map { definition in
            let valueBinding = Binding<CustomFieldValue?>(
                get: { values.wrappedValue[definition.id] },
                set: { newValue in
                    if let newValue = newValue {
                        values.wrappedValue[definition.id] = newValue
                    } else {
                        values.wrappedValue.removeValue(forKey: definition.id)
                    }
                }
            )
            
            return createComponent(for: definition, value: valueBinding)
        }
    }
    
    /// Create a component with initial value
    func createComponent(
        for definition: ComponentDefinition,
        initialValue: CustomFieldValue? = nil,
        onChange: @escaping (CustomFieldValue?) -> Void
    ) -> AnyView {
        @State var currentValue = initialValue
        
        let valueBinding = Binding<CustomFieldValue?>(
            get: { currentValue },
            set: { newValue in
                currentValue = newValue
                onChange(newValue)
            }
        )
        
        return createComponent(for: definition, value: valueBinding)
    }
}

/// Preview support for component registry
#if DEBUG
extension ComponentRegistry {
    
    /// Create a preview-safe component registry with mock components
    static func previewRegistry() -> ComponentRegistry {
        let registry = ComponentRegistry()
        
        // Register mock components for previews
        registry.register(.textField) { definition, value in
            MockFormComponent(definition: definition, value: value)
        }
        
        return registry
    }
}

/// Mock component for previews that conforms to FormComponentProtocol
private struct MockFormComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(definition.label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Enter text", text: .constant("Preview"))
                .textFieldStyle(.roundedBorder)
        }
    }
    
    func validate() -> ComponentValidationResult {
        .valid
    }
    
    var isValid: Bool { true }
    var errorMessage: String? { nil }
}
#endif
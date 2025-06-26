import SwiftUI

/// Date field component for date selection with formatting options
struct DateFieldComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var dateValue: Date = Date()
    @State private var validationResult: ComponentValidationResult = .valid
    @State private var showingDatePicker = false
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize date value from binding
        if case .date(let date) = value.wrappedValue {
            self._dateValue = State(initialValue: date)
        } else if let defaultValue = definition.defaultValue,
                  case .date(let defaultDate) = defaultValue {
            self._dateValue = State(initialValue: defaultDate)
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
            
            // Date picker button
            Button(action: {
                showingDatePicker.toggle()
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text(formattedDate)
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
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: $dateValue,
                    label: definition.label,
                    onDateChanged: { newDate in
                        dateValue = newDate
                        value.wrappedValue = .date(newDate)
                        validateInput()
                    }
                )
            }
            
            // Quick date buttons
            if shouldShowQuickButtons {
                HStack {
                    ForEach(quickDateOptions, id: \.title) { option in
                        Button(option.title) {
                            dateValue = option.date
                            value.wrappedValue = .date(option.date)
                            validateInput()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                }
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
                if case .date(let date) = defaultValue {
                    dateValue = date
                }
            } else if value.wrappedValue == nil && definition.isRequired {
                // Set to current date for required fields
                value.wrappedValue = .date(dateValue)
            }
            validateInput()
        }
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && value.wrappedValue == nil {
            return .invalid("\(definition.label) is required")
        }
        
        // Additional date-specific validation could be added here
        // For example, date range validation, business days only, etc.
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var formattedDate: String {
        if let dateValue = value.wrappedValue, case .date(let date) = dateValue {
            return dateFormatter.string(from: date)
        } else {
            return "Select date"
        }
    }
    
    private var helperText: String? {
        let label = definition.label.lowercased()
        
        if label.contains("birth") || label.contains("birthday") {
            return "Select your date of birth"
        } else if label.contains("purchase") || label.contains("bought") {
            return "When did you purchase this item?"
        } else if label.contains("expir") || label.contains("expiry") {
            return "When does this expire?"
        }
        
        return nil
    }
    
    private var shouldShowQuickButtons: Bool {
        let label = definition.label.lowercased()
        return label.contains("purchase") || label.contains("bought") || label.contains("created")
    }
    
    private var quickDateOptions: [(title: String, date: Date)] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            ("Today", now),
            ("Yesterday", calendar.date(byAdding: .day, value: -1, to: now) ?? now),
            ("1 Week Ago", calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now),
            ("1 Month Ago", calendar.date(byAdding: .month, value: -1, to: now) ?? now)
        ]
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let label: String
    let onDateChanged: (Date) -> Void
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select \(label)",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select \(label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDateChanged(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct DateFieldComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Required date field
            DateFieldComponent(
                definition: ComponentDefinition(
                    id: "purchase_date",
                    type: .dateField,
                    label: "Purchase Date",
                    isRequired: true,
                    validation: ValidationRule(required: true)
                ),
                value: .constant(.date(Date()))
            )
            
            // Optional birthday field
            DateFieldComponent(
                definition: ComponentDefinition(
                    id: "birthday",
                    type: .dateField,
                    label: "Birthday",
                    isRequired: false
                ),
                value: .constant(nil)
            )
            
            // Expiry date field
            DateFieldComponent(
                definition: ComponentDefinition(
                    id: "expiry",
                    type: .dateField,
                    label: "Expiry Date",
                    isRequired: false
                ),
                value: .constant(nil)
            )
        }
        .padding()
    }
}
#endif
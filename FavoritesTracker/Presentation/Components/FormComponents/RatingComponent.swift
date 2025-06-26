import SwiftUI

/// Rating component using star ratings with customizable scale and appearance
struct RatingComponent: FormComponentProtocol {
    let definition: ComponentDefinition
    var value: Binding<CustomFieldValue?>
    
    @State private var ratingValue: Double = 0.0
    @State private var validationResult: ComponentValidationResult = .valid
    
    var isValid: Bool { validationResult.isValid }
    var errorMessage: String? { validationResult.errorMessage }
    
    // Rating configuration
    private var maxRating: Int {
        if let validation = definition.validation,
           let maxValue = validation.maxValue {
            return Int(maxValue)
        }
        return 5 // Default to 5-star rating
    }
    
    private var minRating: Int {
        if let validation = definition.validation,
           let minValue = validation.minValue {
            return Int(minValue)
        }
        return 0 // Default minimum is 0 (no rating)
    }
    
    private var allowsHalfStars: Bool {
        // Allow half stars unless the label suggests whole numbers only
        let label = definition.label.lowercased()
        return !label.contains("score") && !label.contains("level")
    }
    
    init(definition: ComponentDefinition, value: Binding<CustomFieldValue?>) {
        self.definition = definition
        self.value = value
        
        // Initialize rating value from binding
        if case .number(let number) = value.wrappedValue {
            self._ratingValue = State(initialValue: number)
        } else if let defaultValue = definition.defaultValue,
                  case .number(let defaultNumber) = defaultValue {
            self._ratingValue = State(initialValue: defaultNumber)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                
                // Current rating display
                if ratingValue > 0 {
                    Text(formattedRating)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Star rating component
            VStack(spacing: 8) {
                InteractiveStarRatingView(
                    rating: $ratingValue,
                    maxRating: maxRating,
                    starSize: 28,
                    color: starColor,
                    allowHalfStars: allowsHalfStars
                )
                .onChange(of: ratingValue) { oldValue, newValue in
                    updateValue(newValue)
                    validateInput()
                }
                
                // Rating scale labels
                if shouldShowScaleLabels {
                    HStack {
                        Text(scaleLabels.low)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(scaleLabels.high)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // Alternative rating styles for specific types
            if shouldShowAlternativeStyle {
                alternativeRatingView
            }
            
            // Clear rating button
            if ratingValue > 0 {
                HStack {
                    Spacer()
                    
                    Button("Clear Rating") {
                        ratingValue = 0.0
                        value.wrappedValue = nil
                        validateInput()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                if case .number(let number) = defaultValue {
                    ratingValue = number
                }
            }
            validateInput()
        }
    }
    
    // MARK: - Alternative Rating Views
    
    private var alternativeRatingView: some View {
        VStack(spacing: 8) {
            if definition.label.lowercased().contains("mood") {
                moodRatingView
            } else if definition.label.lowercased().contains("difficulty") {
                difficultyRatingView
            } else if definition.label.lowercased().contains("satisfaction") {
                satisfactionRatingView
            }
        }
    }
    
    private var moodRatingView: some View {
        HStack {
            ForEach(1...5, id: \.self) { index in
                Button(action: {
                    ratingValue = Double(index)
                    updateValue(ratingValue)
                    validateInput()
                }) {
                    Text(moodEmoji(for: index))
                        .font(.title2)
                        .opacity(ratingValue >= Double(index) ? 1.0 : 0.3)
                        .scaleEffect(ratingValue == Double(index) ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: ratingValue)
                }
            }
        }
    }
    
    private var difficultyRatingView: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Button(action: {
                    ratingValue = Double(index)
                    updateValue(ratingValue)
                    validateInput()
                }) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(ratingValue >= Double(index) ? .orange : .gray.opacity(0.3))
                        .font(.title3)
                        .scaleEffect(ratingValue == Double(index) ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: ratingValue)
                }
            }
        }
    }
    
    private var satisfactionRatingView: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(1...maxRating, id: \.self) { index in
                    Button(action: {
                        ratingValue = Double(index)
                        updateValue(ratingValue)
                        validateInput()
                    }) {
                        Circle()
                            .fill(satisfactionColor(for: index))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(index)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(ratingValue == Double(index) ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: ratingValue)
                    }
                }
            }
            
            if ratingValue > 0 {
                Text(satisfactionLabel(for: Int(ratingValue)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - FormComponentProtocol
    
    func validate() -> ComponentValidationResult {
        guard let validationRule = definition.validation else {
            return .valid
        }
        
        // Check required field
        if validationRule.required && ratingValue <= 0 {
            return .invalid("Please provide a rating")
        }
        
        // Range validation
        if let minValue = validationRule.minValue, ratingValue < minValue {
            return .invalid("Rating must be at least \(Int(minValue))")
        }
        
        if let maxValue = validationRule.maxValue, ratingValue > maxValue {
            return .invalid("Rating must be no more than \(Int(maxValue))")
        }
        
        return .valid
    }
    
    // MARK: - Private Helpers
    
    private var starColor: Color {
        let label = definition.label.lowercased()
        
        if label.contains("quality") {
            return .green
        } else if label.contains("difficulty") {
            return .orange
        } else if label.contains("importance") {
            return .red
        }
        
        return .yellow
    }
    
    private var formattedRating: String {
        if allowsHalfStars {
            return String(format: "%.1f/\(maxRating)", ratingValue)
        } else {
            return "\(Int(ratingValue))/\(maxRating)"
        }
    }
    
    private var shouldShowScaleLabels: Bool {
        return maxRating >= 5
    }
    
    private var shouldShowAlternativeStyle: Bool {
        let label = definition.label.lowercased()
        return label.contains("mood") || label.contains("difficulty") || label.contains("satisfaction")
    }
    
    private var scaleLabels: (low: String, high: String) {
        let label = definition.label.lowercased()
        
        if label.contains("quality") {
            return ("Poor", "Excellent")
        } else if label.contains("difficulty") {
            return ("Easy", "Very Hard")
        } else if label.contains("importance") {
            return ("Low", "Critical")
        } else if label.contains("satisfaction") {
            return ("Dissatisfied", "Very Satisfied")
        }
        
        return ("Lowest", "Highest")
    }
    
    private var helperText: String? {
        let label = definition.label.lowercased()
        
        if label.contains("overall") {
            return "Rate your overall experience"
        } else if label.contains("quality") {
            return "Rate the quality of this item"
        } else if label.contains("value") {
            return "Rate the value for money"
        }
        
        return "Tap to rate"
    }
    
    private func moodEmoji(for index: Int) -> String {
        switch index {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😐"
        }
    }
    
    private func satisfactionColor(for index: Int) -> Color {
        switch index {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .blue
        case 5: return .green
        default: return .gray
        }
    }
    
    private func satisfactionLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Very Dissatisfied"
        case 2: return "Dissatisfied"
        case 3: return "Neutral"
        case 4: return "Satisfied"
        case 5: return "Very Satisfied"
        default: return ""
        }
    }
    
    private func updateValue(_ newRating: Double) {
        if newRating > 0 {
            value.wrappedValue = .number(newRating)
        } else {
            value.wrappedValue = nil
        }
    }
    
    private func validateInput() {
        validationResult = validate()
    }
}

// MARK: - Preview Support

#if DEBUG
struct RatingComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard 5-star rating
            RatingComponent(
                definition: ComponentDefinition(
                    id: "overall_rating",
                    type: .rating,
                    label: "Overall Rating",
                    isRequired: true,
                    validation: ValidationRule(minValue: 1, maxValue: 5, required: true)
                ),
                value: .constant(.number(4.5))
            )
            
            // Quality rating with green stars
            RatingComponent(
                definition: ComponentDefinition(
                    id: "quality",
                    type: .rating,
                    label: "Quality Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                value: .constant(.number(3.0))
            )
            
            // Mood rating with emojis
            RatingComponent(
                definition: ComponentDefinition(
                    id: "mood",
                    type: .rating,
                    label: "Mood Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                value: .constant(.number(4.0))
            )
            
            // Satisfaction rating with colors
            RatingComponent(
                definition: ComponentDefinition(
                    id: "satisfaction",
                    type: .rating,
                    label: "Satisfaction Level",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                value: .constant(.number(5.0))
            )
        }
        .padding()
    }
}
#endif
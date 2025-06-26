import SwiftUI

/// Comprehensive data tracking component for prices, dates, and availability
struct DataTrackingView: View {
    @Binding var customFields: [String: CustomFieldValue]
    
    let title: String
    let showPriceTracking: Bool
    let showDateTracking: Bool
    let showAvailabilityTracking: Bool
    
    init(
        customFields: Binding<[String: CustomFieldValue]>,
        title: String = "Data Tracking",
        showPriceTracking: Bool = true,
        showDateTracking: Bool = true,
        showAvailabilityTracking: Bool = true
    ) {
        self._customFields = customFields
        self.title = title
        self.showPriceTracking = showPriceTracking
        self.showDateTracking = showDateTracking
        self.showAvailabilityTracking = showAvailabilityTracking
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 20) {
                if showPriceTracking {
                    priceTrackingSection
                }
                
                if showDateTracking {
                    dateTrackingSection
                }
                
                if showAvailabilityTracking {
                    availabilityTrackingSection
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Price Tracking Section
    
    private var priceTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Price Tracking", systemImage: "dollarsign.circle")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Purchase Price
                PriceFieldView(
                    title: "Purchase Price",
                    value: binding(for: "purchase_price"),
                    placeholder: "0.00"
                )
                
                // Current Value
                PriceFieldView(
                    title: "Current Value",
                    value: binding(for: "current_value"),
                    placeholder: "0.00"
                )
                
                // Retail Price
                PriceFieldView(
                    title: "Retail Price",
                    value: binding(for: "retail_price"),
                    placeholder: "0.00"
                )
                
                // Sale Price
                PriceFieldView(
                    title: "Sale Price",
                    value: binding(for: "sale_price"),
                    placeholder: "0.00"
                )
            }
            
            // Value change indicator
            if let purchasePrice = getNumberValue("purchase_price"),
               let currentValue = getNumberValue("current_value"),
               purchasePrice > 0 {
                let change = currentValue - purchasePrice
                let changePercent = (change / purchasePrice) * 100
                
                HStack {
                    Text("Value Change:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text("$\(abs(change), specifier: "%.2f") (\(abs(changePercent), specifier: "%.1f")%)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Date Tracking Section
    
    private var dateTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Date Tracking", systemImage: "calendar")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Purchase Date
                DateFieldView(
                    title: "Purchase Date",
                    value: binding(for: "purchase_date")
                )
                
                // Expiry Date
                DateFieldView(
                    title: "Expiry Date",
                    value: binding(for: "expiry_date")
                )
                
                // Warranty Until
                DateFieldView(
                    title: "Warranty Until",
                    value: binding(for: "warranty_date")
                )
                
                // Last Used
                DateFieldView(
                    title: "Last Used",
                    value: binding(for: "last_used_date")
                )
            }
            
            // Days until expiry indicator
            if let expiryDate = getDateValue("expiry_date") {
                let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                
                HStack {
                    Text("Days until expiry:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(daysUntilExpiry)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(daysUntilExpiry < 30 ? .red : (daysUntilExpiry < 90 ? .orange : .green))
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Availability Tracking Section
    
    private var availabilityTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Availability & Status", systemImage: "flag")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Ownership Status
                StatusPickerView(
                    title: "Ownership Status",
                    value: binding(for: "ownership_status"),
                    options: OwnershipStatus.allCases.map { $0.rawValue }
                )
                
                // Condition
                StatusPickerView(
                    title: "Condition",
                    value: binding(for: "condition"),
                    options: ItemCondition.allCases.map { $0.rawValue }
                )
                
                // Availability
                StatusPickerView(
                    title: "Availability",
                    value: binding(for: "availability"),
                    options: AvailabilityStatus.allCases.map { $0.rawValue }
                )
                
                // Location
                TextFieldView(
                    title: "Current Location",
                    value: binding(for: "current_location"),
                    placeholder: "Where is this item?"
                )
                
                // Quantity
                QuantityFieldView(
                    title: "Quantity",
                    value: binding(for: "quantity")
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: {
                switch customFields[key] {
                case .text(let value): return value
                case .number(let value): return String(value)
                case .date(let value): return ISO8601DateFormatter().string(from: value)
                case .boolean(let value): return String(value)
                case .url(let value): return value.absoluteString
                case .image(let value): return value.absoluteString
                case .none: return ""
                }
            },
            set: { newValue in
                if newValue.isEmpty {
                    customFields.removeValue(forKey: key)
                } else {
                    // Determine the appropriate type based on the key
                    if key.contains("price") || key.contains("value") || key == "quantity" {
                        if let doubleValue = Double(newValue) {
                            customFields[key] = .number(doubleValue)
                        }
                    } else if key.contains("date") {
                        if let date = ISO8601DateFormatter().date(from: newValue) {
                            customFields[key] = .date(date)
                        }
                    } else {
                        customFields[key] = .text(newValue)
                    }
                }
            }
        )
    }
    
    private func getNumberValue(_ key: String) -> Double? {
        if case .number(let value) = customFields[key] {
            return value
        }
        return nil
    }
    
    private func getDateValue(_ key: String) -> Date? {
        if case .date(let value) = customFields[key] {
            return value
        }
        return nil
    }
}

// MARK: - Supporting Views

struct PriceFieldView: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                TextField(placeholder, text: $value)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct DateFieldView: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            DatePicker("", selection: Binding(
                get: {
                    ISO8601DateFormatter().date(from: value) ?? Date()
                },
                set: { newDate in
                    value = ISO8601DateFormatter().string(from: newDate)
                }
            ), displayedComponents: .date)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StatusPickerView: View {
    let title: String
    @Binding var value: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker(title, selection: $value) {
                Text("Not Set").tag("")
                ForEach(options, id: \.self) { option in
                    Text(option.capitalized).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TextFieldView: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct QuantityFieldView: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: decrementQuantity) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.blue)
                }
                
                TextField("0", text: $value)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 80)
                
                Button(action: incrementQuantity) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func incrementQuantity() {
        let current = Int(value) ?? 0
        value = String(current + 1)
    }
    
    private func decrementQuantity() {
        let current = Int(value) ?? 0
        if current > 0 {
            value = String(current - 1)
        }
    }
}

// MARK: - Enums

enum OwnershipStatus: String, CaseIterable {
    case owned = "owned"
    case wanted = "wanted"
    case wishlist = "wishlist"
    case sold = "sold"
    case given = "given"
    case borrowed = "borrowed"
    case lent = "lent"
    
    var displayName: String {
        switch self {
        case .owned: return "Owned"
        case .wanted: return "Wanted"
        case .wishlist: return "Wishlist"
        case .sold: return "Sold"
        case .given: return "Given Away"
        case .borrowed: return "Borrowed"
        case .lent: return "Lent Out"
        }
    }
}

enum ItemCondition: String, CaseIterable {
    case mint = "mint"
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case damaged = "damaged"
    case broken = "broken"
    case restored = "restored"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum AvailabilityStatus: String, CaseIterable {
    case inStock = "in_stock"
    case outOfStock = "out_of_stock"
    case discontinued = "discontinued"
    case limitedEdition = "limited_edition"
    case preOrder = "pre_order"
    case backOrder = "back_order"
    case seasonal = "seasonal"
    
    var displayName: String {
        switch self {
        case .inStock: return "In Stock"
        case .outOfStock: return "Out of Stock"
        case .discontinued: return "Discontinued"
        case .limitedEdition: return "Limited Edition"
        case .preOrder: return "Pre-Order"
        case .backOrder: return "Back Order"
        case .seasonal: return "Seasonal"
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        @State private var customFields: [String: CustomFieldValue] = [
            "purchase_price": .number(25.99),
            "current_value": .number(35.00),
            "purchase_date": .date(Date().addingTimeInterval(-30*24*60*60)),
            "ownership_status": .text("owned"),
            "condition": .text("excellent")
        ]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Data Tracking Demo")
                        .font(.title2)
                        .padding()
                    
                    DataTrackingView(customFields: $customFields)
                        .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    return PreviewContainer()
}
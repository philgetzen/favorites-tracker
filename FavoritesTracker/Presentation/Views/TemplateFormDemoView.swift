import SwiftUI

/// Demo view showcasing the new dynamic form component system
/// This demonstrates how templates can drive form generation
struct TemplateFormDemoView: View {
    @State private var formValues: [String: CustomFieldValue] = [:]
    @State private var isFormValid = false
    @State private var selectedTemplate: DemoTemplate = .bookCollection
    
    var body: some View {
        NavigationView {
            VStack {
                // Template selector
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(DemoTemplate.allCases, id: \.self) { template in
                        Text(template.name).tag(template)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Dynamic form based on selected template
                DynamicFormView(
                    definitions: selectedTemplate.componentDefinitions,
                    values: $formValues,
                    onValidationChange: { valid in
                        isFormValid = valid
                    },
                    onValuesChange: { values in
                        print("Form values: \(values)")
                    }
                )
                
                Spacer()
                
                // Action buttons
                HStack {
                    Button("Clear Form") {
                        formValues.removeAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Item") {
                        saveItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid)
                }
                .padding()
            }
            .navigationTitle("Template Form Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        formValues.removeAll()
                        selectedTemplate = .bookCollection
                    }
                }
            }
        }
        .onChange(of: selectedTemplate) { oldTemplate, newTemplate in
            // Clear form when template changes
            formValues.removeAll()
        }
    }
    
    private func saveItem() {
        print("Saving item with values: \(formValues)")
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // In a real app, this would save to the repository
        // For demo purposes, we'll just clear the form
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            formValues.removeAll()
        }
    }
}

// MARK: - Demo Templates

enum DemoTemplate: CaseIterable {
    case bookCollection
    case wineCollection
    case gadgetCollection
    case artCollection
    case photographyCollection
    case realEstateCollection
    
    var name: String {
        switch self {
        case .bookCollection: return "Books"
        case .wineCollection: return "Wine"
        case .gadgetCollection: return "Gadgets"
        case .artCollection: return "Art"
        case .photographyCollection: return "Photography"
        case .realEstateCollection: return "Real Estate"
        }
    }
    
    var componentDefinitions: [ComponentDefinition] {
        switch self {
        case .bookCollection:
            return [
                ComponentDefinition(
                    id: "title",
                    type: .textField,
                    label: "Book Title",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 200, required: true)
                ),
                ComponentDefinition(
                    id: "author",
                    type: .textField,
                    label: "Author",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 100, required: true)
                ),
                ComponentDefinition(
                    id: "isbn",
                    type: .textField,
                    label: "ISBN",
                    isRequired: false,
                    validation: ValidationRule(pattern: "^[0-9-]{10,17}$")
                ),
                ComponentDefinition(
                    id: "genre",
                    type: .picker,
                    label: "Genre",
                    isRequired: false,
                    options: ["Fiction", "Non-Fiction", "Mystery", "Romance", "Sci-Fi", "Biography", "History"]
                ),
                ComponentDefinition(
                    id: "pages",
                    type: .numberField,
                    label: "Pages",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 2000)
                ),
                ComponentDefinition(
                    id: "read_date",
                    type: .dateField,
                    label: "Date Read",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "rating",
                    type: .rating,
                    label: "Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "is_favorite",
                    type: .toggle,
                    label: "Favorite",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "notes",
                    type: .textArea,
                    label: "Reading Notes",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 1000)
                )
            ]
            
        case .wineCollection:
            return [
                ComponentDefinition(
                    id: "name",
                    type: .textField,
                    label: "Wine Name",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 150, required: true)
                ),
                ComponentDefinition(
                    id: "winery",
                    type: .textField,
                    label: "Winery",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 100, required: true)
                ),
                ComponentDefinition(
                    id: "variety",
                    type: .picker,
                    label: "Variety",
                    isRequired: false,
                    options: ["Cabernet Sauvignon", "Merlot", "Pinot Noir", "Chardonnay", "Sauvignon Blanc", "Riesling", "Malbec", "Syrah"]
                ),
                ComponentDefinition(
                    id: "vintage",
                    type: .numberField,
                    label: "Vintage Year",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1900, maxValue: 2025)
                ),
                ComponentDefinition(
                    id: "price",
                    type: .numberField,
                    label: "Price ($)",
                    isRequired: false,
                    validation: ValidationRule(minValue: 0, maxValue: 1000)
                ),
                ComponentDefinition(
                    id: "tasted_date",
                    type: .dateField,
                    label: "Date Tasted",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "rating",
                    type: .rating,
                    label: "Overall Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "would_buy_again",
                    type: .toggle,
                    label: "Would Buy Again",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "tasting_notes",
                    type: .textArea,
                    label: "Tasting Notes",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 800)
                )
            ]
            
        case .gadgetCollection:
            return [
                ComponentDefinition(
                    id: "name",
                    type: .textField,
                    label: "Gadget Name",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 100, required: true)
                ),
                ComponentDefinition(
                    id: "brand",
                    type: .textField,
                    label: "Brand",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 50, required: true)
                ),
                ComponentDefinition(
                    id: "model",
                    type: .textField,
                    label: "Model",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 50)
                ),
                ComponentDefinition(
                    id: "category",
                    type: .picker,
                    label: "Category",
                    isRequired: false,
                    options: ["Smartphone", "Laptop", "Tablet", "Smart Watch", "Headphones", "Speaker", "Camera", "Gaming"]
                ),
                ComponentDefinition(
                    id: "purchase_price",
                    type: .numberField,
                    label: "Purchase Price ($)",
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
                    id: "condition",
                    type: .toggle,
                    label: "Good Condition",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "performance_rating",
                    type: .rating,
                    label: "Performance Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "value_rating",
                    type: .rating,
                    label: "Value for Money",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                )
            ]
            
        case .artCollection:
            return [
                ComponentDefinition(
                    id: "title",
                    type: .textField,
                    label: "Artwork Title",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 150, required: true)
                ),
                ComponentDefinition(
                    id: "artist",
                    type: .textField,
                    label: "Artist",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 100, required: true)
                ),
                ComponentDefinition(
                    id: "medium",
                    type: .picker,
                    label: "Medium",
                    isRequired: false,
                    options: ["Oil on Canvas", "Watercolor", "Acrylic", "Digital", "Photography", "Sculpture", "Mixed Media", "Print"]
                ),
                ComponentDefinition(
                    id: "year_created",
                    type: .numberField,
                    label: "Year Created",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1400, maxValue: 2025)
                ),
                ComponentDefinition(
                    id: "acquisition_date",
                    type: .dateField,
                    label: "Acquisition Date",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "estimated_value",
                    type: .numberField,
                    label: "Estimated Value ($)",
                    isRequired: false,
                    validation: ValidationRule(minValue: 0, maxValue: 1000000)
                ),
                ComponentDefinition(
                    id: "is_authenticated",
                    type: .toggle,
                    label: "Authenticated",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "condition_rating",
                    type: .rating,
                    label: "Condition",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "personal_rating",
                    type: .rating,
                    label: "Personal Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "description",
                    type: .textArea,
                    label: "Description & Provenance",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 1500)
                )
            ]
            
        case .photographyCollection:
            return [
                ComponentDefinition(
                    id: "photo_title",
                    type: .textField,
                    label: "Photo Title",
                    isRequired: true,
                    validation: ValidationRule(minLength: 1, maxLength: 100, required: true)
                ),
                ComponentDefinition(
                    id: "photographer",
                    type: .textField,
                    label: "Photographer",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 100)
                ),
                ComponentDefinition(
                    id: "camera_model",
                    type: .textField,
                    label: "Camera Model",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 50)
                ),
                ComponentDefinition(
                    id: "image_files",
                    type: .image,
                    label: "Photo Gallery",
                    isRequired: true,
                    validation: ValidationRule(minValue: 1, maxValue: 10, required: true)
                ),
                ComponentDefinition(
                    id: "shoot_location",
                    type: .location,
                    label: "Shoot Location",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "shoot_date",
                    type: .dateField,
                    label: "Date Taken",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "iso_setting",
                    type: .numberField,
                    label: "ISO Setting",
                    isRequired: false,
                    validation: ValidationRule(minValue: 50, maxValue: 25600)
                ),
                ComponentDefinition(
                    id: "aperture",
                    type: .textField,
                    label: "Aperture (f-stop)",
                    isRequired: false,
                    validation: ValidationRule(pattern: "^f/[0-9.]+$")
                ),
                ComponentDefinition(
                    id: "is_portfolio_worthy",
                    type: .toggle,
                    label: "Portfolio Worthy",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "technical_rating",
                    type: .rating,
                    label: "Technical Quality",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "artistic_rating",
                    type: .rating,
                    label: "Artistic Merit",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "photo_notes",
                    type: .textArea,
                    label: "Photography Notes",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 800)
                )
            ]
            
        case .realEstateCollection:
            return [
                ComponentDefinition(
                    id: "property_address",
                    type: .location,
                    label: "Property Address",
                    isRequired: true,
                    validation: ValidationRule(minLength: 10, required: true)
                ),
                ComponentDefinition(
                    id: "property_type",
                    type: .picker,
                    label: "Property Type",
                    isRequired: true,
                    options: ["Single Family", "Condo", "Townhouse", "Multi-Family", "Commercial", "Land"],
                    validation: ValidationRule(required: true)
                ),
                ComponentDefinition(
                    id: "listing_price",
                    type: .numberField,
                    label: "Listing Price ($)",
                    isRequired: true,
                    validation: ValidationRule(minValue: 1000, maxValue: 50000000, required: true)
                ),
                ComponentDefinition(
                    id: "square_footage",
                    type: .numberField,
                    label: "Square Footage",
                    isRequired: false,
                    validation: ValidationRule(minValue: 100, maxValue: 50000)
                ),
                ComponentDefinition(
                    id: "bedrooms",
                    type: .numberField,
                    label: "Bedrooms",
                    isRequired: false,
                    validation: ValidationRule(minValue: 0, maxValue: 20)
                ),
                ComponentDefinition(
                    id: "bathrooms",
                    type: .numberField,
                    label: "Bathrooms",
                    isRequired: false,
                    validation: ValidationRule(minValue: 0, maxValue: 20)
                ),
                ComponentDefinition(
                    id: "year_built",
                    type: .numberField,
                    label: "Year Built",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1800, maxValue: 2025)
                ),
                ComponentDefinition(
                    id: "property_photos",
                    type: .image,
                    label: "Property Photos",
                    isRequired: false,
                    validation: ValidationRule(maxValue: 20)
                ),
                ComponentDefinition(
                    id: "viewing_date",
                    type: .dateField,
                    label: "Viewing Date",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "is_favorite",
                    type: .toggle,
                    label: "Favorite Property",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "has_garage",
                    type: .toggle,
                    label: "Has Garage",
                    isRequired: false
                ),
                ComponentDefinition(
                    id: "overall_rating",
                    type: .rating,
                    label: "Overall Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "location_rating",
                    type: .rating,
                    label: "Location Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "condition_rating",
                    type: .rating,
                    label: "Condition Rating",
                    isRequired: false,
                    validation: ValidationRule(minValue: 1, maxValue: 5)
                ),
                ComponentDefinition(
                    id: "property_notes",
                    type: .textArea,
                    label: "Property Notes",
                    isRequired: false,
                    validation: ValidationRule(maxLength: 1000)
                )
            ]
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct TemplateFormDemoView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateFormDemoView()
    }
}
#endif
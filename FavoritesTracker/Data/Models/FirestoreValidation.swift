import Foundation
import FirebaseFirestore

// MARK: - Validation Errors

/// Errors that can occur during Firestore data validation
enum FirestoreValidationError: LocalizedError {
    case invalidEmail(String)
    case invalidUserID(String)
    case invalidCollectionName(String)
    case invalidItemName(String)
    case invalidTemplateName(String)
    case invalidRating(Double)
    case tooManyPhotos(Int, limit: Int)
    case documentTooLarge(Int, limit: Int)
    case invalidURL(String)
    case invalidCoordinates(latitude: Double, longitude: Double)
    case invalidFieldName(String)
    case invalidFieldValue(String)
    case requiredFieldMissing(String)
    case textTooLong(String, length: Int, limit: Int)
    case invalidSubscriptionDates(start: Date, end: Date)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail(let email):
            return "Invalid email format: \(email)"
        case .invalidUserID(let id):
            return "Invalid user ID: \(id)"
        case .invalidCollectionName(let name):
            return "Invalid collection name: \(name)"
        case .invalidItemName(let name):
            return "Invalid item name: \(name)"
        case .invalidTemplateName(let name):
            return "Invalid template name: \(name)"
        case .invalidRating(let rating):
            return "Invalid rating: \(rating). Must be between 0.0 and 5.0"
        case .tooManyPhotos(let count, let limit):
            return "Too many photos: \(count). Limit is \(limit)"
        case .documentTooLarge(let size, let limit):
            return "Document too large: \(size) bytes. Limit is \(limit) bytes"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidCoordinates(let latitude, let longitude):
            return "Invalid coordinates: lat=\(latitude), lng=\(longitude)"
        case .invalidFieldName(let name):
            return "Invalid field name: \(name)"
        case .invalidFieldValue(let value):
            return "Invalid field value: \(value)"
        case .requiredFieldMissing(let field):
            return "Required field missing: \(field)"
        case .textTooLong(let field, let length, let limit):
            return "Text too long for field '\(field)': \(length) characters. Limit is \(limit)"
        case .invalidSubscriptionDates(let start, let end):
            return "Invalid subscription dates: start=\(start), end=\(end)"
        }
    }
}

// MARK: - Validation Result

/// Result of validation operation
enum ValidationResult {
    case valid
    case invalid([FirestoreValidationError])
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errors: [FirestoreValidationError] {
        switch self {
        case .valid:
            return []
        case .invalid(let errors):
            return errors
        }
    }
}

// MARK: - Validation Protocol

/// Protocol for validating Firestore DTOs
protocol FirestoreValidatable {
    func validate() -> ValidationResult
}

// MARK: - Common Validation Utilities

struct FirestoreValidator {
    
    // MARK: - String Validations
    
    static func validateEmail(_ email: String) -> ValidationResult {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if emailPredicate.evaluate(with: email) {
            return .valid
        } else {
            return .invalid([.invalidEmail(email)])
        }
    }
    
    static func validateRequiredString(_ value: String?, fieldName: String, maxLength: Int? = nil) -> ValidationResult {
        guard let value = value, !value.isEmpty else {
            return .invalid([.requiredFieldMissing(fieldName)])
        }
        
        if let maxLength = maxLength, value.count > maxLength {
            return .invalid([.textTooLong(fieldName, length: value.count, limit: maxLength)])
        }
        
        return .valid
    }
    
    static func validateOptionalString(_ value: String?, fieldName: String, maxLength: Int) -> ValidationResult {
        guard let value = value else { return .valid }
        
        if value.count > maxLength {
            return .invalid([.textTooLong(fieldName, length: value.count, limit: maxLength)])
        }
        
        return .valid
    }
    
    static func validateUserID(_ userID: String) -> ValidationResult {
        if userID.isEmpty {
            return .invalid([.invalidUserID("User ID cannot be empty")])
        }
        
        if userID.count > 1024 { // Firestore limit
            return .invalid([.invalidUserID("User ID too long")])
        }
        
        return .valid
    }
    
    // MARK: - Numeric Validations
    
    static func validateRating(_ rating: Double?) -> ValidationResult {
        guard let rating = rating else { return .valid }
        
        if rating < 0.0 || rating > 5.0 {
            return .invalid([.invalidRating(rating)])
        }
        
        return .valid
    }
    
    static func validateCoordinates(latitude: Double, longitude: Double) -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        if latitude < -90.0 || latitude > 90.0 {
            errors.append(.invalidCoordinates(latitude: latitude, longitude: longitude))
        }
        
        if longitude < -180.0 || longitude > 180.0 {
            errors.append(.invalidCoordinates(latitude: latitude, longitude: longitude))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Array Validations
    
    static func validatePhotoCount(_ photos: [String], isFreemium: Bool) -> ValidationResult {
        let limit = isFreemium ? FirestoreConstraints.PhotoLimits.freeUser : FirestoreConstraints.PhotoLimits.premiumUser
        
        if photos.count > limit {
            return .invalid([.tooManyPhotos(photos.count, limit: limit)])
        }
        
        return .valid
    }
    
    static func validateURLs(_ urls: [String]) -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        for urlString in urls {
            if URL(string: urlString) == nil {
                errors.append(.invalidURL(urlString))
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Date Validations
    
    static func validateSubscriptionDates(start: Date, end: Date) -> ValidationResult {
        if start >= end {
            return .invalid([.invalidSubscriptionDates(start: start, end: end)])
        }
        
        return .valid
    }
    
    // MARK: - Document Size Validation
    
    static func validateDocumentSize<T: Codable>(_ document: T) -> ValidationResult {
        do {
            let data = try JSONEncoder().encode(document)
            if data.count > FirestoreConstraints.maxDocumentSize {
                return .invalid([.documentTooLarge(data.count, limit: FirestoreConstraints.maxDocumentSize)])
            }
            return .valid
        } catch {
            return .invalid([.invalidFieldValue("Failed to encode document")])
        }
    }
    
    // MARK: - Custom Field Validations
    
    static func validateCustomFields(_ fields: [String: CustomFieldValueDTO]) -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        for (key, value) in fields {
            // Validate field name
            if key.isEmpty || key.count > 255 {
                errors.append(.invalidFieldName(key))
            }
            
            // Validate field value based on type
            switch value.type {
            case "text":
                if let stringValue = value.stringValue, stringValue.count > FirestoreConstraints.TextLimits.customFieldValue {
                    errors.append(.textTooLong(key, length: stringValue.count, limit: FirestoreConstraints.TextLimits.customFieldValue))
                }
            case "url":
                if let urlString = value.stringValue, URL(string: urlString) == nil {
                    errors.append(.invalidURL(urlString))
                }
            default:
                break
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - DTO Validations

extension UserDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        let emailValidation = FirestoreValidator.validateEmail(email)
        errors.append(contentsOf: emailValidation.errors)
        
        let userIdValidation = FirestoreValidator.validateUserID(id)
        errors.append(contentsOf: userIdValidation.errors)
        
        // Validate optional fields
        if let photoURL = photoURL, URL(string: photoURL) == nil {
            errors.append(.invalidURL(photoURL))
        }
        
        let displayNameValidation = FirestoreValidator.validateOptionalString(displayName, fieldName: "displayName", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: displayNameValidation.errors)
        
        // Validate document size
        let sizeValidation = FirestoreValidator.validateDocumentSize(self)
        errors.append(contentsOf: sizeValidation.errors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

extension UserProfileDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        let userIdValidation = FirestoreValidator.validateUserID(userId)
        errors.append(contentsOf: userIdValidation.errors)
        
        let displayNameValidation = FirestoreValidator.validateRequiredString(displayName, fieldName: "displayName", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: displayNameValidation.errors)
        
        // Validate optional fields
        let bioValidation = FirestoreValidator.validateOptionalString(bio, fieldName: "bio", maxLength: FirestoreConstraints.TextLimits.bio)
        errors.append(contentsOf: bioValidation.errors)
        
        if let profileImageURL = profileImageURL, URL(string: profileImageURL) == nil {
            errors.append(.invalidURL(profileImageURL))
        }
        
        // Validate subscription dates if present
        if let subscription = subscription {
            let subscriptionValidation = subscription.validate()
            errors.append(contentsOf: subscriptionValidation.errors)
        }
        
        // Validate document size
        let sizeValidation = FirestoreValidator.validateDocumentSize(self)
        errors.append(contentsOf: sizeValidation.errors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

extension SubscriptionInfoDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        let dateValidation = FirestoreValidator.validateSubscriptionDates(
            start: startDate.dateValue(),
            end: expiryDate.dateValue()
        )
        return dateValidation
    }
}

extension CollectionDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        let userIdValidation = FirestoreValidator.validateUserID(userId)
        errors.append(contentsOf: userIdValidation.errors)
        
        let nameValidation = FirestoreValidator.validateRequiredString(name, fieldName: "name", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: nameValidation.errors)
        
        // Validate optional fields
        let descriptionValidation = FirestoreValidator.validateOptionalString(description, fieldName: "description", maxLength: FirestoreConstraints.TextLimits.description)
        errors.append(contentsOf: descriptionValidation.errors)
        
        if let coverImageURL = coverImageURL, URL(string: coverImageURL) == nil {
            errors.append(.invalidURL(coverImageURL))
        }
        
        // Validate item count is non-negative
        if itemCount < 0 {
            errors.append(.invalidFieldValue("Item count cannot be negative"))
        }
        
        // Validate document size
        let sizeValidation = FirestoreValidator.validateDocumentSize(self)
        errors.append(contentsOf: sizeValidation.errors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

extension ItemDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        let userIdValidation = FirestoreValidator.validateUserID(userId)
        errors.append(contentsOf: userIdValidation.errors)
        
        let nameValidation = FirestoreValidator.validateRequiredString(name, fieldName: "name", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: nameValidation.errors)
        
        // Validate optional fields
        let descriptionValidation = FirestoreValidator.validateOptionalString(description, fieldName: "description", maxLength: FirestoreConstraints.TextLimits.description)
        errors.append(contentsOf: descriptionValidation.errors)
        
        // Validate image URLs
        let urlValidation = FirestoreValidator.validateURLs(imageURLs)
        errors.append(contentsOf: urlValidation.errors)
        
        // Validate photo count (assume free user for now - this would be checked at repository level)
        let photoValidation = FirestoreValidator.validatePhotoCount(imageURLs, isFreemium: true)
        errors.append(contentsOf: photoValidation.errors)
        
        // Validate rating
        let ratingValidation = FirestoreValidator.validateRating(rating)
        errors.append(contentsOf: ratingValidation.errors)
        
        // Validate custom fields
        let customFieldsValidation = FirestoreValidator.validateCustomFields(customFields)
        errors.append(contentsOf: customFieldsValidation.errors)
        
        // Validate location if present
        if let location = location {
            let locationValidation = FirestoreValidator.validateCoordinates(
                latitude: location.latitude,
                longitude: location.longitude
            )
            errors.append(contentsOf: locationValidation.errors)
        }
        
        // Validate document size
        let sizeValidation = FirestoreValidator.validateDocumentSize(self)
        errors.append(contentsOf: sizeValidation.errors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

extension TemplateDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        let creatorIdValidation = FirestoreValidator.validateUserID(creatorId)
        errors.append(contentsOf: creatorIdValidation.errors)
        
        let nameValidation = FirestoreValidator.validateRequiredString(name, fieldName: "name", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: nameValidation.errors)
        
        let descriptionValidation = FirestoreValidator.validateRequiredString(description, fieldName: "description", maxLength: FirestoreConstraints.TextLimits.description)
        errors.append(contentsOf: descriptionValidation.errors)
        
        let categoryValidation = FirestoreValidator.validateRequiredString(category, fieldName: "category", maxLength: FirestoreConstraints.TextLimits.name)
        errors.append(contentsOf: categoryValidation.errors)
        
        // Validate optional fields
        if let previewImageURL = previewImageURL, URL(string: previewImageURL) == nil {
            errors.append(.invalidURL(previewImageURL))
        }
        
        // Validate rating
        let ratingValidation = FirestoreValidator.validateRating(rating)
        errors.append(contentsOf: ratingValidation.errors)
        
        // Validate download count is non-negative
        if downloadCount < 0 {
            errors.append(.invalidFieldValue("Download count cannot be negative"))
        }
        
        // Validate components
        for component in components {
            let componentValidation = component.validate()
            errors.append(contentsOf: componentValidation.errors)
        }
        
        // Validate document size
        let sizeValidation = FirestoreValidator.validateDocumentSize(self)
        errors.append(contentsOf: sizeValidation.errors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

extension ComponentDefinitionDTO: FirestoreValidatable {
    func validate() -> ValidationResult {
        var errors: [FirestoreValidationError] = []
        
        // Validate required fields
        if id.isEmpty {
            errors.append(.requiredFieldMissing("id"))
        }
        
        if label.isEmpty {
            errors.append(.requiredFieldMissing("label"))
        }
        
        // Validate component type
        let validTypes = ["textField", "textArea", "numberField", "dropdown", "checkbox", "datePicker", "imageUpload", "ratingPicker"]
        if !validTypes.contains(type) {
            errors.append(.invalidFieldValue("Invalid component type: \(type)"))
        }
        
        // Validate options for dropdown
        if type == "dropdown" && (options?.isEmpty ?? true) {
            errors.append(.invalidFieldValue("Dropdown component must have options"))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Validation Helper Extensions

extension Collection {
    /// Validate domain entity before converting to Firestore
    func validateForFirestore() -> ValidationResult {
        let dto = CollectionMapper.toFirestore(self)
        return dto.validate()
    }
}

extension Item {
    /// Validate domain entity before converting to Firestore
    func validateForFirestore() -> ValidationResult {
        let dto = ItemMapper.toFirestore(self)
        return dto.validate()
    }
}

extension Template {
    /// Validate domain entity before converting to Firestore
    func validateForFirestore() -> ValidationResult {
        let dto = TemplateMapper.toFirestore(self)
        return dto.validate()
    }
}

extension User {
    /// Validate domain entity before converting to Firestore
    func validateForFirestore() -> ValidationResult {
        let dto = UserMapper.toFirestore(self)
        return dto.validate()
    }
}
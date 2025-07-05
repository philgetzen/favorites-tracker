import Foundation

// MARK: - Validation Result Types

/// Result of a validation operation
struct ValidationServiceResult: Sendable {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationServiceResult(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> ValidationServiceResult {
        ValidationServiceResult(isValid: false, errorMessage: message)
    }
}

/// Comprehensive form validation result
struct ValidationFormResult: Sendable {
    let isValid: Bool
    let fieldErrors: [String: String] // field name -> error message
    let generalError: String?
    
    static let valid = ValidationFormResult(isValid: true, fieldErrors: [:], generalError: nil)
    
    static func invalid(fieldErrors: [String: String] = [:], generalError: String? = nil) -> ValidationFormResult {
        ValidationFormResult(
            isValid: false,
            fieldErrors: fieldErrors,
            generalError: generalError
        )
    }
    
    var hasFieldErrors: Bool {
        !fieldErrors.isEmpty
    }
    
    var allErrors: [String] {
        var errors = Array(fieldErrors.values)
        if let generalError = generalError {
            errors.append(generalError)
        }
        return errors
    }
}

/// Password strength levels
enum PasswordStrength: String, CaseIterable, Sendable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case fair = "Fair"
    case good = "Good"
    case strong = "Strong"
    case veryStrong = "Very Strong"
    
    var color: String {
        switch self {
        case .veryWeak, .weak:
            return "red"
        case .fair:
            return "orange"
        case .good:
            return "yellow"
        case .strong, .veryStrong:
            return "green"
        }
    }
    
    var score: Int {
        switch self {
        case .veryWeak: return 1
        case .weak: return 2
        case .fair: return 3
        case .good: return 4
        case .strong: return 5
        case .veryStrong: return 6
        }
    }
}

/// Detailed password validation result
struct ValidationPasswordResult: Sendable {
    let isValid: Bool
    let errors: [ValidationPasswordError]
    let strength: PasswordStrength
    
    var errorMessages: [String] {
        errors.map { $0.rawValue }
    }
    
    var strengthDescription: String {
        strength.rawValue
    }
    
    var strengthColor: String {
        strength.color
    }
}

/// Specific password validation errors
enum ValidationPasswordError: String, CaseIterable, Sendable {
    case tooShort = "Password must be at least 8 characters"
    case missingLetter = "Password must contain at least one letter"
    case missingNumber = "Password must contain at least one number"
    case missingSpecialChar = "Password must contain at least one special character"
    case tooWeak = "Password is too weak. Please choose a stronger password."
}

/// Email validation configuration
struct EmailValidationConfig: Sendable {
    let allowEmptyDomain: Bool
    let requireTopLevelDomain: Bool
    let minLength: Int
    let maxLength: Int
    
    static let `default` = EmailValidationConfig(
        allowEmptyDomain: false,
        requireTopLevelDomain: true,
        minLength: 5,
        maxLength: 254
    )
}

/// Display name validation configuration
struct DisplayNameValidationConfig: Sendable {
    let minLength: Int
    let maxLength: Int
    let allowSpecialCharacters: Bool
    let trimWhitespace: Bool
    
    static let `default` = DisplayNameValidationConfig(
        minLength: 2,
        maxLength: 30,
        allowSpecialCharacters: false,
        trimWhitespace: true
    )
}

/// Password validation configuration
struct PasswordValidationConfig: Sendable {
    let minLength: Int
    let requireLetters: Bool
    let requireNumbers: Bool
    let requireSpecialCharacters: Bool
    let requireUppercase: Bool
    let requireLowercase: Bool
    let minimumStrength: PasswordStrength
    
    static let `default` = PasswordValidationConfig(
        minLength: 8,
        requireLetters: true,
        requireNumbers: true,
        requireSpecialCharacters: false,
        requireUppercase: false,
        requireLowercase: false,
        minimumStrength: .fair
    )
    
    static let enhanced = PasswordValidationConfig(
        minLength: 8,
        requireLetters: true,
        requireNumbers: true,
        requireSpecialCharacters: true,
        requireUppercase: true,
        requireLowercase: true,
        minimumStrength: .good
    )
}

// MARK: - Validation Service Protocol

/// Protocol defining comprehensive validation capabilities
protocol ValidationServiceProtocol: Sendable {
    
    // MARK: - Configuration
    
    var emailConfig: EmailValidationConfig { get }
    var passwordConfig: PasswordValidationConfig { get }
    var displayNameConfig: DisplayNameValidationConfig { get }
    
    // MARK: - Email Validation
    
    /// Validate email format and structure
    /// - Parameter email: Email address to validate
    /// - Returns: ValidationServiceResult with success/failure and error message
    func validateEmail(_ email: String) -> ValidationServiceResult
    
    /// Quick email format check
    /// - Parameter email: Email address to check
    /// - Returns: Boolean indicating if email format is valid
    func isValidEmail(_ email: String) -> Bool
    
    /// Validate email for account updates (checks against current email)
    /// - Parameters:
    ///   - newEmail: New email address
    ///   - currentEmail: Current email address (optional)
    /// - Returns: ValidationServiceResult considering current email context
    func validateEmailForUpdate(_ newEmail: String, currentEmail: String?) -> ValidationServiceResult
    
    // MARK: - Password Validation
    
    /// Comprehensive password validation with strength assessment
    /// - Parameter password: Password to validate
    /// - Returns: ValidationPasswordResult with errors and strength assessment
    func validatePassword(_ password: String) -> ValidationPasswordResult
    
    /// Calculate password strength score
    /// - Parameter password: Password to assess
    /// - Returns: PasswordStrength enum with strength level
    func calculatePasswordStrength(_ password: String) -> PasswordStrength
    
    /// Validate password confirmation match
    /// - Parameters:
    ///   - password: Original password
    ///   - confirmation: Confirmation password
    /// - Returns: ValidationServiceResult indicating if passwords match
    func validatePasswordMatch(_ password: String, confirmation: String) -> ValidationServiceResult
    
    /// Quick password format check
    /// - Parameter password: Password to check
    /// - Returns: Boolean indicating if password meets basic requirements
    func isValidPassword(_ password: String) -> Bool
    
    // MARK: - Display Name Validation
    
    /// Validate display name format and length
    /// - Parameter displayName: Display name to validate
    /// - Returns: ValidationServiceResult with success/failure and error message
    func validateDisplayName(_ displayName: String) -> ValidationServiceResult
    
    /// Quick display name format check
    /// - Parameter displayName: Display name to check
    /// - Returns: Boolean indicating if display name is valid
    func isValidDisplayName(_ displayName: String) -> Bool
    
    // MARK: - Form Validation
    
    /// Validate complete sign-up form
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Password
    ///   - confirmPassword: Password confirmation
    ///   - displayName: Display name
    /// - Returns: ValidationFormResult with field-specific errors
    func validateSignUpForm(
        email: String,
        password: String,
        confirmPassword: String,
        displayName: String
    ) -> ValidationFormResult
    
    /// Validate sign-in form
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Password
    /// - Returns: ValidationFormResult with validation errors
    func validateSignInForm(email: String, password: String) -> ValidationFormResult
    
    /// Validate email change form
    /// - Parameters:
    ///   - newEmail: New email address
    ///   - currentEmail: Current email address
    /// - Returns: ValidationFormResult with validation errors
    func validateEmailChangeForm(newEmail: String, currentEmail: String) -> ValidationFormResult
    
    /// Validate password change form
    /// - Parameters:
    ///   - currentPassword: Current password
    ///   - newPassword: New password
    ///   - confirmPassword: New password confirmation
    /// - Returns: ValidationFormResult with validation errors
    func validatePasswordChangeForm(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String
    ) -> ValidationFormResult
    
    // MARK: - Utility Methods
    
    /// Clean and prepare input for validation
    /// - Parameter input: Raw input string
    /// - Returns: Cleaned input string
    func cleanInput(_ input: String) -> String
    
    /// Validate multiple fields at once
    /// - Parameter fields: Dictionary of field names to values
    /// - Returns: ValidationFormResult with all field validations
    func validateFields(_ fields: [String: String]) -> ValidationFormResult
}

// MARK: - Default Implementation Extensions

extension ValidationServiceProtocol {
    
    /// Default input cleaning (trim whitespace)
    func cleanInput(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Quick email check using validateEmail
    func isValidEmail(_ email: String) -> Bool {
        validateEmail(email).isValid
    }
    
    /// Quick password check using validatePassword
    func isValidPassword(_ password: String) -> Bool {
        validatePassword(password).isValid
    }
    
    /// Quick display name check using validateDisplayName
    func isValidDisplayName(_ displayName: String) -> Bool {
        validateDisplayName(displayName).isValid
    }
}
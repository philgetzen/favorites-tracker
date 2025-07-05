import Foundation
import RegexBuilder

/// Production implementation of ValidationServiceProtocol
final class ValidationService: ValidationServiceProtocol {
    
    // MARK: - Configuration
    
    let emailConfig: EmailValidationConfig
    let passwordConfig: PasswordValidationConfig
    let displayNameConfig: DisplayNameValidationConfig
    
    // MARK: - Private Constants
    
    private let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    private let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    
    // MARK: - Initialization
    
    init(
        emailConfig: EmailValidationConfig = .default,
        passwordConfig: PasswordValidationConfig = .default,
        displayNameConfig: DisplayNameValidationConfig = .default
    ) {
        self.emailConfig = emailConfig
        self.passwordConfig = passwordConfig
        self.displayNameConfig = displayNameConfig
    }
    
    // MARK: - Email Validation
    
    func validateEmail(_ email: String) -> ValidationServiceResult {
        let cleanEmail = cleanInput(email)
        
        // Check if empty
        guard !cleanEmail.isEmpty else {
            return .invalid("Please enter an email address")
        }
        
        // Check length constraints
        guard cleanEmail.count >= emailConfig.minLength else {
            return .invalid("Email address is too short")
        }
        
        guard cleanEmail.count <= emailConfig.maxLength else {
            return .invalid("Email address is too long")
        }
        
        // Check format using regex
        guard isValidEmailFormat(cleanEmail) else {
            return .invalid("Please enter a valid email address")
        }
        
        return .valid
    }
    
    func validateEmailForUpdate(_ newEmail: String, currentEmail: String?) -> ValidationServiceResult {
        let cleanNewEmail = cleanInput(newEmail)
        let cleanCurrentEmail = currentEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if same as current email
        if let currentEmail = cleanCurrentEmail, cleanNewEmail == currentEmail {
            return .invalid("This is your current email address")
        }
        
        // Use standard email validation
        return validateEmail(cleanNewEmail)
    }
    
    // MARK: - Password Validation
    
    func validatePassword(_ password: String) -> ValidationPasswordResult {
        var errors: [ValidationPasswordError] = []
        
        // Check minimum length
        if password.count < passwordConfig.minLength {
            errors.append(.tooShort)
        }
        
        // Check for letters
        if passwordConfig.requireLetters {
            let hasLetter = password.rangeOfCharacter(from: .letters) != nil
            if !hasLetter {
                errors.append(.missingLetter)
            }
        }
        
        // Check for numbers
        if passwordConfig.requireNumbers {
            let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
            if !hasNumber {
                errors.append(.missingNumber)
            }
        }
        
        // Check for special characters
        if passwordConfig.requireSpecialCharacters {
            let specialCharSet = CharacterSet(charactersIn: specialCharacters)
            let hasSpecialChar = password.rangeOfCharacter(from: specialCharSet) != nil
            if !hasSpecialChar {
                errors.append(.missingSpecialChar)
            }
        }
        
        // Check for uppercase (if required)
        if passwordConfig.requireUppercase {
            let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
            if !hasUppercase {
                errors.append(.missingLetter) // Reuse general letter error
            }
        }
        
        // Check for lowercase (if required)
        if passwordConfig.requireLowercase {
            let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
            if !hasLowercase {
                errors.append(.missingLetter) // Reuse general letter error
            }
        }
        
        // Calculate strength
        let strength = calculatePasswordStrength(password)
        
        // Check minimum strength requirement
        if strength.score < passwordConfig.minimumStrength.score {
            errors.append(.tooWeak)
        }
        
        return ValidationPasswordResult(
            isValid: errors.isEmpty,
            errors: errors,
            strength: strength
        )
    }
    
    func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length scoring
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character type scoring
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        
        // Special characters
        let specialCharSet = CharacterSet(charactersIn: specialCharacters)
        if password.rangeOfCharacter(from: specialCharSet) != nil { score += 1 }
        
        // Map score to strength
        switch score {
        case 0...1:
            return .veryWeak
        case 2:
            return .weak
        case 3:
            return .fair
        case 4:
            return .good
        case 5:
            return .strong
        case 6...:
            return .veryStrong
        default:
            return .veryWeak
        }
    }
    
    func validatePasswordMatch(_ password: String, confirmation: String) -> ValidationServiceResult {
        guard !password.isEmpty else {
            return .invalid("Please enter a password")
        }
        
        guard !confirmation.isEmpty else {
            return .invalid("Please confirm your password")
        }
        
        guard password == confirmation else {
            return .invalid("Passwords do not match")
        }
        
        return .valid
    }
    
    // MARK: - Display Name Validation
    
    func validateDisplayName(_ displayName: String) -> ValidationServiceResult {
        let cleanName = displayNameConfig.trimWhitespace ? 
            cleanInput(displayName) : 
            displayName
        
        // Check if empty
        guard !cleanName.isEmpty else {
            return .invalid("Please enter a display name")
        }
        
        // Check minimum length
        guard cleanName.count >= displayNameConfig.minLength else {
            return .invalid("Display name must be at least \(displayNameConfig.minLength) characters")
        }
        
        // Check maximum length
        guard cleanName.count <= displayNameConfig.maxLength else {
            return .invalid("Display name must be less than \(displayNameConfig.maxLength) characters")
        }
        
        // Check for special characters (if not allowed)
        if !displayNameConfig.allowSpecialCharacters {
            let allowedCharSet = CharacterSet.alphanumerics.union(.whitespaces)
            let hasInvalidChar = cleanName.rangeOfCharacter(from: allowedCharSet.inverted) != nil
            if hasInvalidChar {
                return .invalid("Display name can only contain letters, numbers, and spaces")
            }
        }
        
        return .valid
    }
    
    // MARK: - Form Validation
    
    func validateSignUpForm(
        email: String,
        password: String,
        confirmPassword: String,
        displayName: String
    ) -> ValidationFormResult {
        var fieldErrors: [String: String] = [:]
        
        // Validate email
        let emailResult = validateEmail(email)
        if !emailResult.isValid, let error = emailResult.errorMessage {
            fieldErrors["email"] = error
        }
        
        // Validate password
        let passwordResult = validatePassword(password)
        if !passwordResult.isValid && !passwordResult.errors.isEmpty {
            fieldErrors["password"] = passwordResult.errors.first?.rawValue
        }
        
        // Validate password confirmation
        let confirmResult = validatePasswordMatch(password, confirmation: confirmPassword)
        if !confirmResult.isValid, let error = confirmResult.errorMessage {
            fieldErrors["confirmPassword"] = error
        }
        
        // Validate display name
        let nameResult = validateDisplayName(displayName)
        if !nameResult.isValid, let error = nameResult.errorMessage {
            fieldErrors["displayName"] = error
        }
        
        return ValidationFormResult(
            isValid: fieldErrors.isEmpty,
            fieldErrors: fieldErrors,
            generalError: nil
        )
    }
    
    func validateSignInForm(email: String, password: String) -> ValidationFormResult {
        var fieldErrors: [String: String] = [:]
        
        // Basic email format check
        let emailResult = validateEmail(email)
        if !emailResult.isValid, let error = emailResult.errorMessage {
            fieldErrors["email"] = error
        }
        
        // Basic password presence check
        if password.isEmpty {
            fieldErrors["password"] = "Please enter your password"
        }
        
        return ValidationFormResult(
            isValid: fieldErrors.isEmpty,
            fieldErrors: fieldErrors,
            generalError: nil
        )
    }
    
    func validateEmailChangeForm(newEmail: String, currentEmail: String) -> ValidationFormResult {
        var fieldErrors: [String: String] = [:]
        
        let emailResult = validateEmailForUpdate(newEmail, currentEmail: currentEmail)
        if !emailResult.isValid, let error = emailResult.errorMessage {
            fieldErrors["newEmail"] = error
        }
        
        return ValidationFormResult(
            isValid: fieldErrors.isEmpty,
            fieldErrors: fieldErrors,
            generalError: nil
        )
    }
    
    func validatePasswordChangeForm(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String
    ) -> ValidationFormResult {
        var fieldErrors: [String: String] = [:]
        
        // Check current password is provided
        if currentPassword.isEmpty {
            fieldErrors["currentPassword"] = "Please enter your current password"
        }
        
        // Validate new password
        let passwordResult = validatePassword(newPassword)
        if !passwordResult.isValid && !passwordResult.errors.isEmpty {
            fieldErrors["newPassword"] = passwordResult.errors.first?.rawValue
        }
        
        // Validate confirmation
        let confirmResult = validatePasswordMatch(newPassword, confirmation: confirmPassword)
        if !confirmResult.isValid, let error = confirmResult.errorMessage {
            fieldErrors["confirmPassword"] = error
        }
        
        // Check that new password is different from current
        if !currentPassword.isEmpty && !newPassword.isEmpty && currentPassword == newPassword {
            fieldErrors["newPassword"] = "New password must be different from current password"
        }
        
        return ValidationFormResult(
            isValid: fieldErrors.isEmpty,
            fieldErrors: fieldErrors,
            generalError: nil
        )
    }
    
    func validateFields(_ fields: [String: String]) -> ValidationFormResult {
        var fieldErrors: [String: String] = [:]
        
        for (fieldName, value) in fields {
            switch fieldName.lowercased() {
            case "email":
                let result = validateEmail(value)
                if !result.isValid, let error = result.errorMessage {
                    fieldErrors[fieldName] = error
                }
            case "password":
                let result = validatePassword(value)
                if !result.isValid && !result.errors.isEmpty {
                    fieldErrors[fieldName] = result.errors.first?.rawValue
                }
            case "displayname", "display_name":
                let result = validateDisplayName(value)
                if !result.isValid, let error = result.errorMessage {
                    fieldErrors[fieldName] = error
                }
            default:
                // Generic non-empty validation
                if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors[fieldName] = "\(fieldName.capitalized) is required"
                }
            }
        }
        
        return ValidationFormResult(
            isValid: fieldErrors.isEmpty,
            fieldErrors: fieldErrors,
            generalError: nil
        )
    }
    
    // MARK: - Private Methods
    
    private func isValidEmailFormat(_ email: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: emailRegex, options: []) else {
            return false
        }
        
        let range = NSRange(location: 0, length: email.utf16.count)
        return regex.firstMatch(in: email, options: [], range: range) != nil
    }
}

// MARK: - Configuration Presets

extension ValidationService {
    
    /// Standard validation service for general use
    static let standard = ValidationService()
    
    /// Enhanced validation service with stricter requirements
    static let enhanced = ValidationService(
        passwordConfig: .enhanced
    )
    
    /// Lenient validation service for testing or onboarding
    static let lenient = ValidationService(
        passwordConfig: PasswordValidationConfig(
            minLength: 6,
            requireLetters: true,
            requireNumbers: false,
            requireSpecialCharacters: false,
            requireUppercase: false,
            requireLowercase: false,
            minimumStrength: .weak
        )
    )
}

// MARK: - Preview Support

#if DEBUG
extension ValidationService {
    static func preview() -> ValidationService {
        return .standard
    }
}
#endif
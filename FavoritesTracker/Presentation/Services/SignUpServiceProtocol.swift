import Foundation

/// Protocol defining the business logic interface for user registration functionality
@MainActor
protocol SignUpServiceProtocol: Sendable {
    /// Validates email format and returns error message if invalid
    func validateEmail(_ email: String) -> String?
    
    /// Validates password strength and returns error message if invalid
    func validatePassword(_ password: String) -> String?
    
    /// Validates display name length and format
    func validateDisplayName(_ displayName: String) -> String?
    
    /// Calculates password strength based on various criteria
    func calculatePasswordStrength(_ password: String) -> PasswordStrength
    
    /// Determines if email format is valid
    func isValidEmail(_ email: String) -> Bool
    
    /// Determines if password has required character types
    func hasValidPasswordCharacters(_ password: String) -> Bool
}
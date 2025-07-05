import Foundation

/// Service implementation for user registration business logic
@MainActor
final class SignUpService: SignUpServiceProtocol {
    
    // MARK: - Email Validation
    
    func validateEmail(_ email: String) -> String? {
        guard !email.isEmpty else { return nil }
        
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    
    func validatePassword(_ password: String) -> String? {
        guard !password.isEmpty else { return nil }
        
        if password.count < 8 {
            return "Password must be at least 8 characters"
        } else if !hasValidPasswordCharacters(password) {
            return "Password must contain letters and numbers"
        }
        return nil
    }
    
    func hasValidPasswordCharacters(_ password: String) -> Bool {
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }
    
    func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length scoring
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character type scoring
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
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
    
    // MARK: - Display Name Validation
    
    func validateDisplayName(_ displayName: String) -> String? {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return nil }
        
        if trimmed.count < 2 {
            return "Display name must be at least 2 characters"
        } else if trimmed.count > 30 {
            return "Display name must be less than 30 characters"
        }
        return nil
    }
}
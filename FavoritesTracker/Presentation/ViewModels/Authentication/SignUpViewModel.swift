import Foundation
import Combine

/// ViewModel for sign-up functionality with validation and terms acceptance
@MainActor
final class SignUpViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    @Published var acceptedTerms: Bool = false
    @Published var acceptedPrivacy: Bool = false
    @Published var isSigningUp: Bool = false
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Validation Properties
    
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var displayNameError: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        isEmailValid && isPasswordValid && isConfirmPasswordValid && 
        isDisplayNameValid && acceptedTerms && acceptedPrivacy
    }
    
    var isEmailValid: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var isPasswordValid: Bool {
        password.count >= 8 && hasValidPasswordCharacters(password)
    }
    
    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var isDisplayNameValid: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    var canSignUp: Bool {
        isFormValid && !isSigningUp
    }
    
    var passwordStrength: PasswordStrength {
        return calculatePasswordStrength(password)
    }
    
    // MARK: - Initialization
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthenticationManager = AuthenticationManager.shared) {
        self.authManager = authManager
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
            .store(in: &cancellables)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.validatePassword(password)
                self?.validateConfirmPassword() // Re-validate confirm password
            }
            .store(in: &cancellables)
        
        // Confirm password validation
        $confirmPassword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateConfirmPassword()
            }
            .store(in: &cancellables)
        
        // Display name validation
        $displayName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] displayName in
                self?.validateDisplayName(displayName)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateEmail(_ email: String) {
        guard !email.isEmpty else {
            emailError = nil
            return
        }
        
        if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }
    
    private func validatePassword(_ password: String) {
        guard !password.isEmpty else {
            passwordError = nil
            return
        }
        
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else if !hasValidPasswordCharacters(password) {
            passwordError = "Password must contain letters and numbers"
        } else {
            passwordError = nil
        }
    }
    
    private func validateConfirmPassword() {
        guard !confirmPassword.isEmpty else {
            confirmPasswordError = nil
            return
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }
    
    private func validateDisplayName(_ displayName: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            displayNameError = nil
            return
        }
        
        if trimmed.count < 2 {
            displayNameError = "Display name must be at least 2 characters"
        } else if trimmed.count > 30 {
            displayNameError = "Display name must be less than 30 characters"
        } else {
            displayNameError = nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hasValidPasswordCharacters(_ password: String) -> Bool {
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }
    
    private func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character types
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        case 5...6:
            return .strong
        default:
            return .strong
        }
    }
    
    // MARK: - Actions
    
    func signUp() async {
        guard canSignUp else { return }
        
        isSigningUp = true
        clearError()
        
        do {
            try await authManager.signUp(email: email, password: password)
            
            // Update display name if provided
            if !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try await authManager.updateDisplayName(displayName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            // Success - state will be managed by AuthenticationManager
        } catch {
            handleError(error)
        }
        
        isSigningUp = false
    }
    
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        acceptedTerms = false
        acceptedPrivacy = false
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        displayNameError = nil
        clearError()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func setError(_ message: String) {
        errorMessage = message
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .emailAlreadyInUse:
                setError("An account with this email already exists. Please sign in instead.")
            case .weakPassword:
                setError("Password is too weak. Please choose a stronger password.")
            case .networkError:
                setError("Network error. Please check your connection and try again.")
            default:
                setError(authError.localizedDescription)
            }
        } else {
            setError("An unexpected error occurred. Please try again.")
        }
    }
}

// MARK: - Password Strength

enum PasswordStrength: CaseIterable {
    case weak
    case medium
    case strong
    
    var color: String {
        switch self {
        case .weak:
            return "red"
        case .medium:
            return "orange"
        case .strong:
            return "green"
        }
    }
    
    var description: String {
        switch self {
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension SignUpViewModel {
    static func preview() -> SignUpViewModel {
        let viewModel = SignUpViewModel()
        viewModel.email = "user@example.com"
        viewModel.displayName = "John Doe"
        return viewModel
    }
}
#endif
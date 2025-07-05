import Foundation
import Combine

/// ViewModel focused on password validation, strength calculation, and confirmation
@MainActor
final class PasswordValidationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    
    // MARK: - Private Properties
    
    private let signUpService: SignUpServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isPasswordValid: Bool {
        password.count >= 8 && signUpService.hasValidPasswordCharacters(password)
    }
    
    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var passwordStrength: PasswordStrength {
        signUpService.calculatePasswordStrength(password)
    }
    
    // MARK: - Initialization
    
    init(signUpService: SignUpServiceProtocol = SignUpService()) {
        self.signUpService = signUpService
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.validatePassword(password)
                self?.validateConfirmPassword() // Re-validate confirm password when password changes
            }
            .store(in: &cancellables)
        
        // Confirm password validation
        $confirmPassword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateConfirmPassword()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validatePassword(_ password: String) {
        passwordError = signUpService.validatePassword(password)
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
    
    // MARK: - Actions
    
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
    }
    
    func clearPasswords() {
        password = ""
        confirmPassword = ""
        passwordError = nil
        confirmPasswordError = nil
        showPassword = false
        showConfirmPassword = false
    }
}
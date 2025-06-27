import Foundation
import Combine

/// ViewModel for sign-in functionality with validation and error handling
@MainActor
final class SignInViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSigningIn: Bool = false
    @Published var showPassword: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Validation Properties
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var isEmailValid: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".")
    }
    
    var isPasswordValid: Bool {
        password.count >= 6
    }
    
    var canSignIn: Bool {
        isFormValid && !isSigningIn
    }
    
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
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateEmail(_ email: String) {
        guard !email.isEmpty else {
            emailError = nil
            return
        }
        
        if !email.contains("@") {
            emailError = "Please enter a valid email address"
        } else if !email.contains(".") {
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
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
    }
    
    // MARK: - Actions
    
    func signIn() async {
        guard canSignIn else { return }
        
        isSigningIn = true
        clearError()
        
        do {
            try await authManager.signIn(email: email, password: password)
            // Success - state will be managed by AuthenticationManager
        } catch {
            handleError(error)
        }
        
        isSigningIn = false
    }
    
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    func clearForm() {
        email = ""
        password = ""
        emailError = nil
        passwordError = nil
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
            case .invalidCredentials:
                setError("Invalid email or password. Please try again.")
            case .userNotSignedIn:
                setError("Please sign in to continue.")
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

// MARK: - Preview Support

#if DEBUG
extension SignInViewModel {
    static func preview() -> SignInViewModel {
        let viewModel = SignInViewModel()
        viewModel.email = "user@example.com"
        return viewModel
    }
}
#endif
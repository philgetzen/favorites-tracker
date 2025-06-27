import Foundation
import Combine

/// ViewModel for password reset functionality
@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var isSendingReset: Bool = false
    @Published var resetEmailSent: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Validation Properties
    
    @Published var emailError: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isEmailValid: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var canSendReset: Bool {
        isEmailValid && !isSendingReset
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
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Actions
    
    func sendPasswordReset() async {
        guard canSendReset else { return }
        
        isSendingReset = true
        clearError()
        
        do {
            try await authManager.sendPasswordReset(email: email)
            resetEmailSent = true
        } catch {
            handleError(error)
        }
        
        isSendingReset = false
    }
    
    func resendPasswordReset() async {
        resetEmailSent = false
        await sendPasswordReset()
    }
    
    func clearForm() {
        email = ""
        emailError = nil
        resetEmailSent = false
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
            case .networkError:
                setError("Network error. Please check your connection and try again.")
            default:
                setError("If an account with this email exists, you will receive a password reset email.")
            }
        } else {
            setError("If an account with this email exists, you will receive a password reset email.")
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension ForgotPasswordViewModel {
    static func preview() -> ForgotPasswordViewModel {
        let viewModel = ForgotPasswordViewModel()
        viewModel.email = "user@example.com"
        return viewModel
    }
}
#endif
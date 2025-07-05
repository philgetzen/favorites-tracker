import Foundation
import Combine

/// Coordinator ViewModel that orchestrates the sign-up flow using focused sub-ViewModels
@MainActor
final class SignUpViewModelRefactored: ObservableObject {
    
    // MARK: - Child ViewModels
    
    @Published var emailViewModel: EmailValidationViewModel
    @Published var passwordViewModel: PasswordValidationViewModel
    @Published var displayNameViewModel: DisplayNameViewModel
    @Published var termsViewModel: TermsAcceptanceViewModel
    
    // MARK: - Published Properties
    
    @Published var isSigningUp: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        emailViewModel.isEmailValid &&
        passwordViewModel.isPasswordValid &&
        passwordViewModel.isConfirmPasswordValid &&
        displayNameViewModel.isDisplayNameValid &&
        termsViewModel.hasAcceptedBoth
    }
    
    var canSignUp: Bool {
        isFormValid && !isSigningUp
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthenticationManager = AuthenticationManager.shared,
         signUpService: SignUpServiceProtocol = SignUpService()) {
        self.authManager = authManager
        self.emailViewModel = EmailValidationViewModel(signUpService: signUpService)
        self.passwordViewModel = PasswordValidationViewModel(signUpService: signUpService)
        self.displayNameViewModel = DisplayNameViewModel(signUpService: signUpService)
        self.termsViewModel = TermsAcceptanceViewModel()
    }
    
    // MARK: - Actions
    
    func signUp() async {
        guard canSignUp else { return }
        
        isSigningUp = true
        clearError()
        
        do {
            try await authManager.signUp(
                email: emailViewModel.email,
                password: passwordViewModel.password
            )
            
            // Update display name if provided
            if displayNameViewModel.hasDisplayName {
                try await authManager.updateDisplayName(displayNameViewModel.trimmedDisplayName)
            }
            
            // Success - state will be managed by AuthenticationManager
        } catch {
            handleError(error)
        }
        
        isSigningUp = false
    }
    
    func clearForm() {
        emailViewModel.clearEmail()
        passwordViewModel.clearPasswords()
        displayNameViewModel.clearDisplayName()
        termsViewModel.clearAcceptance()
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

// MARK: - Preview Support

#if DEBUG
extension SignUpViewModelRefactored {
    static func preview() -> SignUpViewModelRefactored {
        let viewModel = SignUpViewModelRefactored()
        viewModel.emailViewModel.email = "user@example.com"
        viewModel.displayNameViewModel.displayName = "John Doe"
        return viewModel
    }
}
#endif
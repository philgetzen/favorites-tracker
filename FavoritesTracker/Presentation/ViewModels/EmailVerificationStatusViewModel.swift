import Foundation

/// ViewModel focused on email verification status and sending verification emails
@MainActor
final class EmailVerificationStatusViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentEmail: String = ""
    @Published var isEmailVerified: Bool = false
    @Published var isSendingVerification: Bool = false
    @Published var verificationError: String?
    @Published var verificationSuccessMessage: String?
    
    // MARK: - Private Properties
    
    private let emailService: EmailServiceProtocol
    
    // MARK: - Computed Properties
    
    var canSendVerification: Bool {
        !isEmailVerified && !isSendingVerification
    }
    
    var hasVerificationError: Bool {
        verificationError != nil
    }
    
    var hasVerificationSuccess: Bool {
        verificationSuccessMessage != nil
    }
    
    // MARK: - Initialization
    
    init(emailService: EmailServiceProtocol = EmailService()) {
        self.emailService = emailService
        loadUserData()
    }
    
    // MARK: - Data Loading
    
    func loadUserData() {
        if let user = emailService.getCurrentUser() {
            updateUserData(user)
        }
    }
    
    func updateUserData(_ user: User) {
        currentEmail = user.email
        isEmailVerified = user.isEmailVerified
    }
    
    // MARK: - Actions
    
    func sendEmailVerification() async {
        guard canSendVerification else { return }
        
        isSendingVerification = true
        clearVerificationMessages()
        
        do {
            try await emailService.sendEmailVerification()
            verificationSuccessMessage = "Verification email sent! Check your inbox."
        } catch {
            handleVerificationError(error)
        }
        
        isSendingVerification = false
    }
    
    func reloadUserData() async {
        clearVerificationMessages()
        
        do {
            try await emailService.reloadUser()
            loadUserData()
        } catch {
            handleVerificationError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    func clearVerificationMessages() {
        verificationError = nil
        verificationSuccessMessage = nil
    }
    
    // MARK: - Error Handling
    
    private func handleVerificationError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .userNotSignedIn:
                verificationError = "Please sign in to continue."
            case .networkError:
                verificationError = "Network error. Please check your connection and try again."
            default:
                verificationError = authError.localizedDescription
            }
        } else {
            verificationError = "An unexpected error occurred. Please try again."
        }
    }
}
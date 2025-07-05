import Foundation

/// Coordinator ViewModel that orchestrates email verification and email change using focused sub-ViewModels
@MainActor
final class EmailVerificationViewModelRefactored: ObservableObject {
    
    // MARK: - Child ViewModels
    
    @Published var verificationStatusViewModel: EmailVerificationStatusViewModel
    @Published var emailChangeViewModel: EmailChangeViewModel
    
    // MARK: - Private Properties
    
    private let emailService: EmailServiceProtocol
    
    // MARK: - Computed Properties
    
    var currentEmail: String {
        verificationStatusViewModel.currentEmail
    }
    
    var isEmailVerified: Bool {
        verificationStatusViewModel.isEmailVerified
    }
    
    var hasAnyError: Bool {
        verificationStatusViewModel.hasVerificationError || 
        emailChangeViewModel.hasUpdateEmailError ||
        emailChangeViewModel.hasNewEmailError
    }
    
    var hasAnySuccess: Bool {
        verificationStatusViewModel.hasVerificationSuccess || 
        emailChangeViewModel.hasUpdateEmailSuccess
    }
    
    var isPerformingAnyAction: Bool {
        verificationStatusViewModel.isSendingVerification || 
        emailChangeViewModel.isUpdatingEmail
    }
    
    // MARK: - Initialization
    
    init(emailService: EmailServiceProtocol = EmailService()) {
        self.emailService = emailService
        self.verificationStatusViewModel = EmailVerificationStatusViewModel(emailService: emailService)
        self.emailChangeViewModel = EmailChangeViewModel(emailService: emailService)
    }
    
    // MARK: - Actions
    
    func updateUserData(_ user: User) {
        verificationStatusViewModel.updateUserData(user)
        emailChangeViewModel.updateUserData(user)
    }
    
    func reloadUserData() async {
        await verificationStatusViewModel.reloadUserData()
        if let currentUser = emailService.getCurrentUser() {
            emailChangeViewModel.updateUserData(currentUser)
        }
    }
    
    func clearAllMessages() {
        verificationStatusViewModel.clearVerificationMessages()
        emailChangeViewModel.clearUpdateEmailMessages()
    }
    
    func clearEmailForm() {
        emailChangeViewModel.clearEmailForm()
    }
}
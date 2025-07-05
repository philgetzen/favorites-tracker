import Foundation
import Combine

/// ViewModel focused on changing email address with validation
@MainActor
final class EmailChangeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentEmail: String = ""
    @Published var newEmail: String = ""
    @Published var newEmailError: String?
    @Published var isUpdatingEmail: Bool = false
    @Published var updateEmailError: String?
    @Published var updateEmailSuccessMessage: String?
    
    // MARK: - Private Properties
    
    private let emailService: EmailServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canUpdateEmail: Bool {
        emailService.isValidEmail(newEmail) && 
        newEmail != currentEmail && 
        !isUpdatingEmail &&
        newEmailError == nil
    }
    
    var hasUpdateEmailError: Bool {
        updateEmailError != nil
    }
    
    var hasUpdateEmailSuccess: Bool {
        updateEmailSuccessMessage != nil
    }
    
    var hasNewEmailError: Bool {
        newEmailError != nil
    }
    
    // MARK: - Initialization
    
    init(emailService: EmailServiceProtocol = EmailService()) {
        self.emailService = emailService
        setupValidation()
        loadUserData()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        $newEmail
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateNewEmail(email)
            }
            .store(in: &cancellables)
    }
    
    private func loadUserData() {
        if let user = emailService.getCurrentUser() {
            updateUserData(user)
        }
    }
    
    func updateUserData(_ user: User) {
        currentEmail = user.email
    }
    
    // MARK: - Validation
    
    private func validateNewEmail(_ email: String) {
        guard !email.isEmpty else {
            newEmailError = nil
            return
        }
        
        if !emailService.isValidEmail(email) {
            newEmailError = "Please enter a valid email address"
        } else if email == currentEmail {
            newEmailError = "This is your current email address"
        } else {
            newEmailError = nil
        }
    }
    
    // MARK: - Actions
    
    func updateEmail() async {
        guard canUpdateEmail else { return }
        
        isUpdatingEmail = true
        clearUpdateEmailMessages()
        
        do {
            try await emailService.updateEmail(newEmail)
            updateEmailSuccessMessage = "Email updated successfully! Please verify your new email address."
            newEmail = ""
            
            // Reload user data to reflect changes
            try await emailService.reloadUser()
            loadUserData()
        } catch {
            handleUpdateEmailError(error)
        }
        
        isUpdatingEmail = false
    }
    
    // MARK: - Helper Methods
    
    func clearEmailForm() {
        newEmail = ""
        newEmailError = nil
        clearUpdateEmailMessages()
    }
    
    func clearUpdateEmailMessages() {
        updateEmailError = nil
        updateEmailSuccessMessage = nil
    }
    
    // MARK: - Error Handling
    
    private func handleUpdateEmailError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .userNotSignedIn:
                updateEmailError = "Please sign in to continue."
            case .networkError:
                updateEmailError = "Network error. Please check your connection and try again."
            case .emailAlreadyInUse:
                updateEmailError = "This email address is already in use."
            default:
                updateEmailError = authError.localizedDescription
            }
        } else {
            updateEmailError = "An unexpected error occurred. Please try again."
        }
    }
}
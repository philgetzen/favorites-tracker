import Foundation
import Combine

/// Refactored AccountSettingsViewModel that coordinates focused sub-ViewModels
@MainActor
final class AccountSettingsViewModelRefactored: ObservableObject {
    
    // MARK: - Child ViewModels
    
    @Published var profileManagement: ProfileManagementViewModel
    @Published var passwordChange: PasswordChangeViewModel
    @Published var emailVerification: EmailVerificationViewModelRefactored
    @Published var accountActions: AccountActionsViewModel
    
    // MARK: - Published Properties
    
    @Published var showChangePassword: Bool = false
    @Published var showChangeEmail: Bool = false
    
    // MARK: - Properties
    
    private let service: AccountManagementServiceProtocol
    private let validationService: ValidationServiceProtocol
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasAnyError: Bool {
        profileManagement.hasProfileError ||
        passwordChange.hasAnyError ||
        emailVerification.hasAnyError ||
        accountActions.hasActionError
    }
    
    var hasAnySuccess: Bool {
        profileManagement.hasProfileSuccess ||
        passwordChange.hasSuccess ||
        emailVerification.hasAnySuccess ||
        accountActions.hasActionSuccess
    }
    
    var isPerformingAnyAction: Bool {
        profileManagement.isUpdatingProfile ||
        passwordChange.isChangingPassword ||
        emailVerification.isPerformingAnyAction ||
        accountActions.isPerformingAction
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthenticationManager = AuthenticationManager.shared) {
        self.authManager = authManager
        
        // Initialize services
        self.service = AccountManagementService(authManager: authManager)
        self.validationService = ValidationService()
        
        // Initialize child ViewModels
        self.profileManagement = ProfileManagementViewModel(service: service)
        self.passwordChange = PasswordChangeViewModel(
            service: service,
            validationService: validationService,
            userEmail: authManager.currentUser?.email ?? ""
        )
        self.emailVerification = EmailVerificationViewModelRefactored()
        self.accountActions = AccountActionsViewModel(service: service)
        
        setupUserObserver()
        setupChildViewModelObservers()
    }
    
    // MARK: - Setup
    
    private func setupUserObserver() {
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.updateAllViewModelsWithUser(user)
            }
            .store(in: &cancellables)
    }
    
    private func setupChildViewModelObservers() {
        // Close password change sheet on success
        passwordChange.$successMessage
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showChangePassword = false
            }
            .store(in: &cancellables)
        
        // Close email change sheet on success
        emailVerification.emailChangeViewModel.$updateEmailSuccessMessage
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showChangeEmail = false
            }
            .store(in: &cancellables)
    }
    
    private func updateAllViewModelsWithUser(_ user: User?) {
        guard let user = user else { return }
        
        profileManagement.updateUserData(user)
        emailVerification.updateUserData(user)
        
        // Update password ViewModel's email if it changed
        passwordChange = PasswordChangeViewModel(
            service: service,
            validationService: validationService,
            userEmail: user.email
        )
    }
    
    // MARK: - Navigation Actions
    
    func showPasswordChangeSheet() {
        showChangePassword = true
        passwordChange.clearForm()
    }
    
    func hidePasswordChangeSheet() {
        showChangePassword = false
        passwordChange.clearForm()
    }
    
    func showEmailChangeSheet() {
        showChangeEmail = true
        emailVerification.clearEmailForm()
    }
    
    func hideEmailChangeSheet() {
        showChangeEmail = false
        emailVerification.clearEmailForm()
    }
    
    // MARK: - Convenience Actions
    
    func reloadAllUserData() async {
        await profileManagement.reloadUserData()
        await emailVerification.reloadUserData()
    }
    
    func clearAllMessages() {
        profileManagement.clearMessages()
        passwordChange.clearMessages()
        emailVerification.clearAllMessages()
        accountActions.clearMessages()
    }
}

// MARK: - Preview Support

#if DEBUG
extension AccountSettingsViewModelRefactored {
    static func preview() -> AccountSettingsViewModelRefactored {
        let viewModel = AccountSettingsViewModelRefactored()
        
        // Pre-populate with sample data for previews
        viewModel.profileManagement.displayName = "John Doe"
        viewModel.profileManagement.email = "john@example.com"
        viewModel.profileManagement.isEmailVerified = true
        
        return viewModel
    }
}
#endif
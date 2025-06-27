import Foundation
import Combine

/// ViewModel for account management and profile updates
@MainActor
final class AccountSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isEmailVerified: Bool = false
    @Published var isUpdatingProfile: Bool = false
    @Published var isUpdatingEmail: Bool = false
    @Published var isSendingVerification: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var showChangePassword: Bool = false
    @Published var showChangeEmail: Bool = false
    
    // Email change properties
    @Published var newEmail: String = ""
    @Published var newEmailError: String?
    
    // Password change properties  
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    @Published var currentPasswordError: String?
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var isChangingPassword: Bool = false
    @Published var showCurrentPassword: Bool = false
    @Published var showNewPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canUpdateProfile: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !isUpdatingProfile
    }
    
    var canUpdateEmail: Bool {
        isValidEmail(newEmail) && newEmail != email && !isUpdatingEmail
    }
    
    var canSendVerification: Bool {
        !isEmailVerified && !isSendingVerification
    }
    
    var canChangePassword: Bool {
        isValidPasswordChange && !isChangingPassword
    }
    
    private var isValidPasswordChange: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmNewPassword &&
        hasValidPasswordCharacters(newPassword)
    }
    
    // MARK: - Initialization
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthenticationManager = AuthenticationManager.shared) {
        self.authManager = authManager
        setupUserObserver()
        setupValidation()
        loadUserData()
    }
    
    // MARK: - Setup
    
    private func setupUserObserver() {
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.updateUserData(user)
            }
            .store(in: &cancellables)
    }
    
    private func setupValidation() {
        // New email validation
        $newEmail
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateNewEmail(email)
            }
            .store(in: &cancellables)
        
        // Password validation
        $newPassword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.validateNewPassword(password)
                self?.validateConfirmPassword() // Re-validate confirm password
            }
            .store(in: &cancellables)
        
        $confirmNewPassword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateConfirmPassword()
            }
            .store(in: &cancellables)
    }
    
    private func loadUserData() {
        if let user = authManager.currentUser {
            updateUserData(user)
        }
    }
    
    private func updateUserData(_ user: User?) {
        guard let user = user else { return }
        
        displayName = user.displayName ?? ""
        email = user.email
        isEmailVerified = user.isEmailVerified
    }
    
    // MARK: - Validation Methods
    
    private func validateNewEmail(_ email: String) {
        guard !email.isEmpty else {
            newEmailError = nil
            return
        }
        
        if !isValidEmail(email) {
            newEmailError = "Please enter a valid email address"
        } else if email == self.email {
            newEmailError = "This is your current email address"
        } else {
            newEmailError = nil
        }
    }
    
    private func validateNewPassword(_ password: String) {
        guard !password.isEmpty else {
            newPasswordError = nil
            return
        }
        
        if password.count < 8 {
            newPasswordError = "Password must be at least 8 characters"
        } else if !hasValidPasswordCharacters(password) {
            newPasswordError = "Password must contain letters and numbers"
        } else {
            newPasswordError = nil
        }
    }
    
    private func validateConfirmPassword() {
        guard !confirmNewPassword.isEmpty else {
            confirmPasswordError = nil
            return
        }
        
        if newPassword != confirmNewPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }
    
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
    
    // MARK: - Actions
    
    func updateDisplayName() async {
        guard canUpdateProfile else { return }
        
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isUpdatingProfile = true
        clearError()
        
        do {
            try await authManager.updateDisplayName(trimmedName)
            // Success - user data will be updated automatically via observer
        } catch {
            handleError(error)
        }
        
        isUpdatingProfile = false
    }
    
    func updateEmail() async {
        guard canUpdateEmail else { return }
        
        isUpdatingEmail = true
        clearError()
        
        do {
            try await authManager.updateEmail(newEmail)
            newEmail = ""
            showChangeEmail = false
            // Success - user data will be updated automatically via observer
        } catch {
            handleError(error)
        }
        
        isUpdatingEmail = false
    }
    
    func sendEmailVerification() async {
        guard canSendVerification else { return }
        
        isSendingVerification = true
        clearError()
        
        do {
            try await authManager.sendEmailVerification()
            setSuccessMessage("Verification email sent! Check your inbox.")
        } catch {
            handleError(error)
        }
        
        isSendingVerification = false
    }
    
    func changePassword() async {
        guard canChangePassword else { return }
        
        isChangingPassword = true
        clearError()
        
        do {
            // First reauthenticate with current password
            try await authManager.reauthenticate(email: email, password: currentPassword)
            
            // Then update to new password
            try await authManager.updatePassword(newPassword)
            
            // Clear form and close
            clearPasswordForm()
            showChangePassword = false
            setSuccessMessage("Password updated successfully!")
            
        } catch {
            handlePasswordError(error)
        }
        
        isChangingPassword = false
    }
    
    func reloadUser() async {
        clearError()
        
        do {
            try await authManager.reloadUser()
            // User data will be updated automatically via observer
        } catch {
            handleError(error)
        }
    }
    
    func signOut() async {
        clearError()
        
        do {
            try await authManager.signOut()
        } catch {
            handleError(error)
        }
    }
    
    func deleteAccount() async {
        clearError()
        
        do {
            try await authManager.deleteAccount()
        } catch {
            handleError(error)
        }
        
        showDeleteConfirmation = false
    }
    
    // MARK: - Form Management
    
    func clearPasswordForm() {
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        currentPasswordError = nil
        newPasswordError = nil
        confirmPasswordError = nil
    }
    
    func clearEmailForm() {
        newEmail = ""
        newEmailError = nil
    }
    
    // MARK: - UI Actions
    
    func toggleCurrentPasswordVisibility() {
        showCurrentPassword.toggle()
    }
    
    func toggleNewPasswordVisibility() {
        showNewPassword.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func setError(_ message: String) {
        errorMessage = message
    }
    
    // MARK: - Error Handling
    
    private func handlePasswordError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                currentPasswordError = "Current password is incorrect"
            default:
                handleError(error)
            }
        } else {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
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
    
    private func setSuccessMessage(_ message: String) {
        // For now, we'll use the error system for success messages
        // In a real app, you might want a separate success message system
        setError(message) // This will show as an alert, you might want to style it differently
    }
}

// MARK: - Preview Support

#if DEBUG
extension AccountSettingsViewModel {
    static func preview() -> AccountSettingsViewModel {
        let viewModel = AccountSettingsViewModel()
        viewModel.displayName = "John Doe"
        viewModel.email = "john@example.com"
        viewModel.isEmailVerified = true
        return viewModel
    }
}
#endif
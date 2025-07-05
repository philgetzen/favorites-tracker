import Foundation
import Combine

/// ViewModel dedicated to password change functionality
@MainActor
final class PasswordChangeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    @Published var isChangingPassword: Bool = false
    
    // Validation errors
    @Published var currentPasswordError: String?
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var generalError: String?
    @Published var successMessage: String?
    
    // UI state
    @Published var showCurrentPassword: Bool = false
    @Published var showNewPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    
    // MARK: - Properties
    
    private let service: AccountManagementServiceProtocol
    private let validationService: ValidationServiceProtocol
    private let userEmail: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canChangePassword: Bool {
        isValidPasswordChange && !isChangingPassword
    }
    
    private var isValidPasswordChange: Bool {
        !currentPassword.isEmpty &&
        newPasswordError == nil &&
        confirmPasswordError == nil &&
        !newPassword.isEmpty &&
        newPassword == confirmNewPassword
    }
    
    var hasAnyError: Bool {
        currentPasswordError != nil || 
        newPasswordError != nil || 
        confirmPasswordError != nil || 
        generalError != nil
    }
    
    var hasSuccess: Bool {
        successMessage != nil
    }
    
    // MARK: - Initialization
    
    init(service: AccountManagementServiceProtocol, validationService: ValidationServiceProtocol, userEmail: String) {
        self.service = service
        self.validationService = validationService
        self.userEmail = userEmail
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        // New password validation
        $newPassword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.validateNewPassword(password)
            }
            .store(in: &cancellables)
        
        // Confirm password validation
        Publishers.CombineLatest($newPassword, $confirmNewPassword)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] newPassword, confirmPassword in
                self?.validateConfirmPassword(newPassword: newPassword, confirmPassword: confirmPassword)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    private func validateNewPassword(_ password: String) {
        guard !password.isEmpty else {
            newPasswordError = nil
            return
        }
        
        let validation = validationService.validatePassword(password)
        if validation.isValid {
            newPasswordError = nil
        } else {
            newPasswordError = validation.errorMessages.first
        }
    }
    
    private func validateConfirmPassword(newPassword: String, confirmPassword: String) {
        guard !confirmPassword.isEmpty else {
            confirmPasswordError = nil
            return
        }
        
        if newPassword != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }
    
    // MARK: - Actions
    
    func changePassword() async {
        guard canChangePassword else { return }
        
        isChangingPassword = true
        clearMessages()
        
        do {
            try await service.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                email: userEmail
            )
            
            successMessage = "Password updated successfully!"
            clearForm()
            
        } catch {
            handlePasswordError(error)
        }
        
        isChangingPassword = false
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
    
    func clearForm() {
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        clearValidationErrors()
    }
    
    func clearMessages() {
        generalError = nil
        successMessage = nil
        currentPasswordError = nil
    }
    
    private func clearValidationErrors() {
        currentPasswordError = nil
        newPasswordError = nil
        confirmPasswordError = nil
    }
    
    // MARK: - Error Handling
    
    private func handlePasswordError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                currentPasswordError = "Current password is incorrect"
            case .userNotSignedIn:
                generalError = "Please sign in to continue."
            case .networkError:
                generalError = "Network error. Please check your connection and try again."
            default:
                generalError = authError.localizedDescription
            }
        } else {
            generalError = "An unexpected error occurred. Please try again."
        }
    }
}
import Foundation

/// Service implementation for email verification and management business logic
@MainActor
final class EmailService: EmailServiceProtocol {
    
    // MARK: - Private Properties
    
    private let accountService: AccountManagementServiceProtocol
    private let validationService: ValidationServiceProtocol
    
    // MARK: - Initialization
    
    init(
        accountService: AccountManagementServiceProtocol = AccountManagementService(authManager: AuthenticationManager.shared),
        validationService: ValidationServiceProtocol = ValidationService()
    ) {
        self.accountService = accountService
        self.validationService = validationService
    }
    
    // MARK: - User Management
    
    func getCurrentUser() -> User? {
        return accountService.getCurrentUser()
    }
    
    func reloadUser() async throws {
        try await accountService.reloadUser()
    }
    
    // MARK: - Email Validation
    
    func isValidEmail(_ email: String) -> Bool {
        return validationService.isValidEmail(email)
    }
    
    // MARK: - Email Verification
    
    func sendEmailVerification() async throws {
        try await accountService.sendEmailVerification()
    }
    
    // MARK: - Email Update
    
    func updateEmail(_ newEmail: String) async throws {
        try await accountService.updateEmail(newEmail)
    }
}
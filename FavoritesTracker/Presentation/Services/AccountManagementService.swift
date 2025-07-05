import Foundation

/// Service implementation for account management business logic
final class AccountManagementService: AccountManagementServiceProtocol, @unchecked Sendable {
    private nonisolated let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    func updateDisplayName(_ name: String) async throws {
        try await authManager.updateDisplayName(name)
    }
    
    func updateEmail(_ email: String) async throws {
        try await authManager.updateEmail(email)
    }
    
    func sendEmailVerification() async throws {
        try await authManager.sendEmailVerification()
    }
    
    func changePassword(currentPassword: String, newPassword: String, email: String) async throws {
        // First reauthenticate with current password
        try await authManager.reauthenticate(email: email, password: currentPassword)
        
        // Then update to new password
        try await authManager.updatePassword(newPassword)
    }
    
    func reloadUser() async throws {
        try await authManager.reloadUser()
    }
    
    func signOut() async throws {
        try await authManager.signOut()
    }
    
    func deleteAccount() async throws {
        try await authManager.deleteAccount()
    }
    
    
    @MainActor
    func getCurrentUser() -> User? {
        return authManager.currentUser
    }
}
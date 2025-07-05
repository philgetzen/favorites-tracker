import Foundation

/// Protocol defining the business logic for account management operations
protocol AccountManagementServiceProtocol: Sendable {
    /// Update user's display name
    func updateDisplayName(_ name: String) async throws
    
    /// Update user's email address
    func updateEmail(_ email: String) async throws
    
    /// Send email verification
    func sendEmailVerification() async throws
    
    /// Change user's password
    func changePassword(currentPassword: String, newPassword: String, email: String) async throws
    
    /// Reload current user data
    func reloadUser() async throws
    
    /// Sign out the current user
    func signOut() async throws
    
    /// Delete the user's account
    func deleteAccount() async throws
    
    /// Get current user information
    @MainActor func getCurrentUser() -> User?
}
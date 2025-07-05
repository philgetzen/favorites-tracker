import Foundation

/// Protocol defining the business logic interface for email verification and management functionality
@MainActor
protocol EmailServiceProtocol: Sendable {
    /// Gets the current authenticated user
    func getCurrentUser() -> User?
    
    /// Validates email format
    func isValidEmail(_ email: String) -> Bool
    
    /// Sends email verification to current user
    func sendEmailVerification() async throws
    
    /// Updates user's email address
    func updateEmail(_ newEmail: String) async throws
    
    /// Reloads user data from server
    func reloadUser() async throws
}
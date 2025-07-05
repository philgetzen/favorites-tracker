import Foundation
import Combine

/// ViewModel dedicated to account-level actions (sign out, delete account)
@MainActor
final class AccountActionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var showDeleteConfirmation: Bool = false
    @Published var isDeletingAccount: Bool = false
    @Published var isSigningOut: Bool = false
    @Published var actionError: String?
    @Published var actionSuccessMessage: String?
    
    // Delete confirmation
    @Published var deleteConfirmationText: String = ""
    private let deleteConfirmationPhrase = "DELETE MY ACCOUNT"
    
    // MARK: - Properties
    
    private let service: AccountManagementServiceProtocol
    
    // MARK: - Computed Properties
    
    var canSignOut: Bool {
        !isSigningOut && !isDeletingAccount
    }
    
    var canDeleteAccount: Bool {
        deleteConfirmationText == deleteConfirmationPhrase && 
        !isDeletingAccount && 
        !isSigningOut
    }
    
    var hasActionError: Bool {
        actionError != nil
    }
    
    var hasActionSuccess: Bool {
        actionSuccessMessage != nil
    }
    
    var isPerformingAction: Bool {
        isSigningOut || isDeletingAccount
    }
    
    // MARK: - Initialization
    
    init(service: AccountManagementServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Sign Out Actions
    
    func signOut() async {
        guard canSignOut else { return }
        
        isSigningOut = true
        clearMessages()
        
        do {
            try await service.signOut()
            actionSuccessMessage = "Successfully signed out."
        } catch {
            handleError(error)
        }
        
        isSigningOut = false
    }
    
    // MARK: - Delete Account Actions
    
    func showDeleteAccountConfirmation() {
        showDeleteConfirmation = true
        clearMessages()
    }
    
    func cancelDeleteAccount() {
        showDeleteConfirmation = false
        deleteConfirmationText = ""
        clearMessages()
    }
    
    func deleteAccount() async {
        guard canDeleteAccount else { return }
        
        isDeletingAccount = true
        clearMessages()
        
        do {
            try await service.deleteAccount()
            // Note: If deletion is successful, the user will be signed out
            // and the app should handle navigation accordingly
            actionSuccessMessage = "Account deleted successfully."
        } catch {
            handleError(error)
        }
        
        isDeletingAccount = false
        showDeleteConfirmation = false
        deleteConfirmationText = ""
    }
    
    // MARK: - Helper Methods
    
    func clearMessages() {
        actionError = nil
        actionSuccessMessage = nil
    }
    
    // MARK: - Validation Helpers
    
    func validateDeleteConfirmation(_ text: String) -> Bool {
        return text == deleteConfirmationPhrase
    }
    
    var deleteConfirmationPrompt: String {
        "To confirm account deletion, please type: \(deleteConfirmationPhrase)"
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .userNotSignedIn:
                actionError = "Please sign in to continue."
            case .networkError:
                actionError = "Network error. Please check your connection and try again."
            case .invalidCredentials:
                actionError = "For security reasons, please sign in again before deleting your account."
            default:
                actionError = authError.localizedDescription
            }
        } else {
            actionError = "An unexpected error occurred. Please try again."
        }
    }
}
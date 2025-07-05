import Foundation
import Combine

/// ViewModel dedicated to profile management (display name, basic user info)
@MainActor
final class ProfileManagementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isEmailVerified: Bool = false
    @Published var isUpdatingProfile: Bool = false
    @Published var profileError: String?
    @Published var profileSuccessMessage: String?
    
    // MARK: - Properties
    
    private let service: AccountManagementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canUpdateProfile: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !isUpdatingProfile
    }
    
    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var hasProfileError: Bool {
        profileError != nil
    }
    
    var hasProfileSuccess: Bool {
        profileSuccessMessage != nil
    }
    
    // MARK: - Initialization
    
    init(service: AccountManagementServiceProtocol) {
        self.service = service
        loadUserData()
    }
    
    // MARK: - Data Loading
    
    func loadUserData() {
        if let user = service.getCurrentUser() {
            updateUserData(user)
        }
    }
    
    func updateUserData(_ user: User) {
        displayName = user.displayName ?? ""
        email = user.email
        isEmailVerified = user.isEmailVerified
    }
    
    // MARK: - Actions
    
    func updateDisplayName() async {
        guard canUpdateProfile else { return }
        
        let trimmed = trimmedDisplayName
        guard !trimmed.isEmpty else { return }
        
        isUpdatingProfile = true
        clearMessages()
        
        do {
            try await service.updateDisplayName(trimmed)
            profileSuccessMessage = "Display name updated successfully!"
            
            // Reload user data to reflect changes
            try await service.reloadUser()
            loadUserData()
        } catch {
            handleError(error)
        }
        
        isUpdatingProfile = false
    }
    
    func reloadUserData() async {
        clearMessages()
        
        do {
            try await service.reloadUser()
            loadUserData()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    func clearMessages() {
        profileError = nil
        profileSuccessMessage = nil
    }
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .userNotSignedIn:
                profileError = "Please sign in to continue."
            case .networkError:
                profileError = "Network error. Please check your connection and try again."
            default:
                profileError = authError.localizedDescription
            }
        } else {
            profileError = "An unexpected error occurred. Please try again."
        }
    }
}
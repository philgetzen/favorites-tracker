import Foundation
import FirebaseAuth
import Combine

/// Global authentication state manager
/// Manages authentication state and provides reactive updates throughout the app
@MainActor
final class AuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authenticationState: AuthenticationState = .loading
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isEmailVerified: Bool = false
    
    // MARK: - Private Properties
    
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Singleton
    
    static let shared = AuthenticationManager()
    
    private init(authRepository: AuthRepositoryProtocol = DIContainer.shared.resolve(AuthRepositoryProtocol.self)) {
        self.authRepository = authRepository
        setupAuthStateListener()
        // Check for existing authenticated user on initialization
        checkCurrentUser()
    }
    
    // MARK: - Authentication State Listener
    
    private func setupAuthStateListener() {
        authRepository.authStateChanges()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.handleAuthStateChange(user: user)
            }
            .store(in: &cancellables)
    }
    
    private func checkCurrentUser() {
        // Check if there's already an authenticated user
        if let currentUser = authRepository.getCurrentUser() {
            handleAuthStateChange(user: currentUser)
        } else {
            authenticationState = .unauthenticated
        }
    }
    
    private func handleAuthStateChange(user: User?) {
        currentUser = user
        isAuthenticated = user != nil
        isEmailVerified = user?.isEmailVerified ?? false
        
        if user != nil {
            authenticationState = .authenticated
        } else {
            authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        authenticationState = .loading
        
        do {
            _ = try await authRepository.signIn(email: email, password: password)
            // State will be updated automatically via the listener
        } catch {
            authenticationState = .unauthenticated
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        authenticationState = .loading
        
        do {
            _ = try await authRepository.signUp(email: email, password: password)
            // State will be updated automatically via the listener
        } catch {
            authenticationState = .unauthenticated
            throw error
        }
    }
    
    func signOut() async throws {
        authenticationState = .loading
        
        do {
            try await authRepository.signOut()
            // State will be updated automatically via the listener
        } catch {
            // If sign out fails, we should still update state
            authenticationState = .unauthenticated
            throw error
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        try await authRepository.sendPasswordReset(email: email)
    }
    
    func sendEmailVerification() async throws {
        try await authRepository.sendEmailVerification()
    }
    
    func reloadUser() async throws {
        if authenticationState == .authenticated {
            _ = try await authRepository.reloadUser()
            // State will be updated automatically via the listener
        }
    }
    
    func updateDisplayName(_ displayName: String) async throws {
        guard authenticationState == .authenticated else {
            throw AuthError.userNotSignedIn
        }
        
        let updatedUser = try await authRepository.updateDisplayName(displayName)
        // Force immediate state update since Firebase auth listener might be delayed
        await MainActor.run {
            self.currentUser = updatedUser
        }
    }
    
    func updateEmail(_ email: String) async throws {
        guard authenticationState == .authenticated else {
            throw AuthError.userNotSignedIn
        }
        
        _ = try await authRepository.updateEmail(email)
        // State will be updated automatically via the listener
    }
    
    func updatePassword(_ password: String) async throws {
        guard authenticationState == .authenticated else {
            throw AuthError.userNotSignedIn
        }
        
        try await authRepository.updatePassword(password)
    }
    
    func reauthenticate(email: String, password: String) async throws {
        guard authenticationState == .authenticated else {
            throw AuthError.userNotSignedIn
        }
        
        try await authRepository.reauthenticate(email: email, password: password)
    }
    
    func deleteAccount() async throws {
        guard authenticationState == .authenticated else {
            throw AuthError.userNotSignedIn
        }
        
        authenticationState = .loading
        
        do {
            try await authRepository.deleteAccount()
            // State will be updated automatically via the listener
        } catch {
            authenticationState = .authenticated
            throw error
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Note: In a singleton pattern, deinit is typically never called
        // But if it were, we'd clean up the auth listener here
        // The handle cleanup is handled by Firebase internally when the app terminates
    }
}

// MARK: - Authentication State

enum AuthenticationState: Equatable {
    case loading
    case authenticated
    case unauthenticated
    
    var isAuthenticated: Bool {
        switch self {
        case .authenticated:
            return true
        case .loading, .unauthenticated:
            return false
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .authenticated, .unauthenticated:
            return false
        }
    }
}
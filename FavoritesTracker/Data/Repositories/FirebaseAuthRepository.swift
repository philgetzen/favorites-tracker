import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Firebase implementation of AuthRepositoryProtocol
/// Handles Firebase Authentication operations and user management
final class FirebaseAuthRepository: AuthRepositoryProtocol {
    
    private let auth: Auth
    private let firestore: Firestore
    
    init(auth: Auth = Auth.auth(), firestore: Firestore = Firestore.firestore()) {
        self.auth = auth
        self.firestore = firestore
    }
    
    // MARK: - AuthRepositoryProtocol Implementation
    
    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        let firebaseUser = authResult.user
        
        // Create or update user document in Firestore
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
        
        try await createOrUpdateUserDocument(user)
        return user
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let firebaseUser = authResult.user
        
        // Create user document and profile in Firestore
        let user = User(
            id: firebaseUser.uid,
            email: email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
        
        try await createOrUpdateUserDocument(user)
        
        // Create initial user profile
        let userProfile = UserProfile(userId: user.id, displayName: user.displayName ?? "User")
        try await createInitialUserProfile(userProfile)
        
        // Send email verification
        try await firebaseUser.sendEmailVerification()
        
        return user
    }
    
    func signOut() async throws {
        try auth.signOut()
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        let userId = firebaseUser.uid
        
        _ = try await firestore.runTransaction { transaction, errorPointer in
            // Delete user profile
            let userPath = FirestoreCollection.Paths.user(userId)
            let profileQuery = self.firestore.collection("\(userPath)/\(FirestoreCollection.profiles)")
            
            // Note: In a production app, you'd want to delete all user data
            // including collections, items, etc. This is a simplified version
            
            // Delete the main user document
            let userRef = self.firestore.document(userPath)
            transaction.deleteDocument(userRef)
            
            return nil
        }
        
        // Delete the Firebase Auth user account
        try await firebaseUser.delete()
    }
    
    // MARK: - Additional Authentication Methods
    
    /// Send password reset email
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    /// Update email address
    func updateEmail(_ newEmail: String) async throws -> User {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        try await firebaseUser.updateEmail(to: newEmail)
        
        let user = User(
            id: firebaseUser.uid,
            email: newEmail,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: false // Email verification is reset when changing email
        )
        
        try await createOrUpdateUserDocument(user)
        return user
    }
    
    /// Update password
    func updatePassword(_ newPassword: String) async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        try await firebaseUser.updatePassword(to: newPassword)
    }
    
    /// Send email verification
    func sendEmailVerification() async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        try await firebaseUser.sendEmailVerification()
    }
    
    /// Reload user to get updated verification status
    func reloadUser() async throws -> User {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        try await firebaseUser.reload()
        
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
        
        try await createOrUpdateUserDocument(user)
        return user
    }
    
    /// Listen to authentication state changes
    func authStateChanges() -> AnyPublisher<User?, Never> {
        Publishers.AuthStateDidChange(auth: auth)
            .map { firebaseUser in
                guard let firebaseUser = firebaseUser else { return nil }
                
                return User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName,
                    photoURL: firebaseUser.photoURL,
                    isEmailVerified: firebaseUser.isEmailVerified
                )
            }
            .eraseToAnyPublisher()
    }
    
    /// Reauthenticate user (required for sensitive operations)
    func reauthenticate(email: String, password: String) async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await firebaseUser.reauthenticate(with: credential)
    }
    
    /// Update display name
    func updateDisplayName(_ displayName: String) async throws -> User {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
        
        try await createOrUpdateUserDocument(user)
        return user
    }
    
    /// Update photo URL
    func updatePhotoURL(_ photoURL: URL) async throws -> User {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }
        
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.photoURL = photoURL
        try await changeRequest.commitChanges()
        
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
        
        try await createOrUpdateUserDocument(user)
        return user
    }
    
    // MARK: - Private Helper Methods
    
    private func createOrUpdateUserDocument(_ user: User) async throws {
        let userDTO = UserMapper.toFirestore(user)
        let userPath = FirestoreCollection.Paths.user(user.id)
        
        var userData = try userDTO.asDictionary()
        userData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await firestore.document(userPath).setData(userData, merge: true)
    }
    
    private func createInitialUserProfile(_ profile: UserProfile) async throws {
        let profileDTO = UserProfileMapper.toFirestore(profile)
        let profilePath = FirestoreCollection.Paths.userProfile(profile.userId, profileId: profile.id)
        
        try await firestore.document(profilePath).setData(try profileDTO.asDictionary())
    }
}

// MARK: - Authentication Errors

enum AuthError: LocalizedError {
    case userNotSignedIn
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "User is not signed in"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "Email address is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Authentication error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Firebase Auth Publisher

extension Publishers {
    struct AuthStateDidChange: Publisher {
        typealias Output = FirebaseAuth.User?
        typealias Failure = Never
        
        let auth: Auth
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, FirebaseAuth.User? == S.Input {
            let subscription = AuthStateDidChangeSubscription(subscriber: subscriber, auth: auth)
            subscriber.receive(subscription: subscription)
        }
    }
}

final class AuthStateDidChangeSubscription<S: Subscriber>: Subscription where S.Input == FirebaseAuth.User?, S.Failure == Never {
    private var subscriber: S?
    private var handle: AuthStateDidChangeListenerHandle?
    
    init(subscriber: S, auth: Auth) {
        self.subscriber = subscriber
        
        handle = auth.addStateDidChangeListener { _, user in
            _ = subscriber.receive(user)
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        // Firebase auth state changes don't use demand
    }
    
    func cancel() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        subscriber = nil
    }
}
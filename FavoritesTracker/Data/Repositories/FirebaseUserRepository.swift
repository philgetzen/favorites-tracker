import Foundation
import FirebaseFirestore
import Combine

/// Firebase implementation of UserRepositoryProtocol
/// Handles Firestore operations for user profiles and settings
final class FirebaseUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    // MARK: - UserRepositoryProtocol Implementation
    
    func getUserProfile(id: String) async throws -> UserProfile? {
        // User profiles are stored in a subcollection under the user document
        // We need to query the profile subcollection
        let userPath = FirestoreCollection.Paths.user(id)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.profiles)")
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        let profileDTO = try document.data(as: UserProfileDTO.self)
        return UserProfileMapper.toDomain(profileDTO)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let profileDTO = UserProfileMapper.toFirestore(profile)
        let profilePath = FirestoreCollection.Paths.userProfile(profile.userId, profileId: profile.id)
        
        var updateData = try profileDTO.asDictionary()
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await firestore.document(profilePath).setData(updateData, merge: true)
        return profile
    }
    
    func deleteUserProfile(id: String) async throws {
        // Find the profile first to get the user ID
        guard let profile = try await getUserProfile(id: id) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(profile.userId, profileId: profile.id)
        try await firestore.document(profilePath).delete()
    }
    
    // MARK: - Additional User Methods
    
    /// Create a new user profile
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let profileDTO = UserProfileMapper.toFirestore(profile)
        let profilePath = FirestoreCollection.Paths.userProfile(profile.userId, profileId: profile.id)
        
        try await firestore.document(profilePath).setData(try profileDTO.asDictionary())
        return profile
    }
    
    /// Get user profile by user ID (most common use case)
    func getUserProfileByUserId(_ userId: String) async throws -> UserProfile? {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.profiles)")
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        let profileDTO = try document.data(as: UserProfileDTO.self)
        return UserProfileMapper.toDomain(profileDTO)
    }
    
    /// Update user preferences only
    func updateUserPreferences(userId: String, preferences: UserPreferences) async throws {
        guard let profile = try await getUserProfileByUserId(userId) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(userId, profileId: profile.id)
        let preferencesDTO = UserPreferencesMapper.toFirestore(preferences)
        
        let updateData: [String: Any] = [
            "preferences": try preferencesDTO.asDictionary(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(profilePath).updateData(updateData)
    }
    
    /// Update subscription info
    func updateSubscription(userId: String, subscription: SubscriptionInfo?) async throws {
        guard let profile = try await getUserProfileByUserId(userId) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(userId, profileId: profile.id)
        
        var updateData: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let subscription = subscription {
            let subscriptionDTO = SubscriptionInfoMapper.toFirestore(subscription)
            updateData["subscription"] = try subscriptionDTO.asDictionary()
        } else {
            updateData["subscription"] = FieldValue.delete()
        }
        
        try await firestore.document(profilePath).updateData(updateData)
    }
    
    /// Update profile image URL
    func updateProfileImage(userId: String, imageURL: URL?) async throws {
        guard let profile = try await getUserProfileByUserId(userId) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(userId, profileId: profile.id)
        
        let updateData: [String: Any] = [
            "profileImageURL": imageURL?.absoluteString ?? FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(profilePath).updateData(updateData)
    }
    
    /// Update display name
    func updateDisplayName(userId: String, displayName: String) async throws {
        guard let profile = try await getUserProfileByUserId(userId) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(userId, profileId: profile.id)
        
        let updateData: [String: Any] = [
            "displayName": displayName,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(profilePath).updateData(updateData)
    }
    
    /// Update bio
    func updateBio(userId: String, bio: String?) async throws {
        guard let profile = try await getUserProfileByUserId(userId) else {
            throw RepositoryError.userNotFound
        }
        
        let profilePath = FirestoreCollection.Paths.userProfile(userId, profileId: profile.id)
        
        let updateData: [String: Any] = [
            "bio": bio ?? FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.document(profilePath).updateData(updateData)
    }
    
    /// Get public profiles (for discovery/social features)
    func getPublicProfiles(limit: Int = 20) async throws -> [UserProfile] {
        let query = firestore.collectionGroup(FirestoreCollection.profiles)
            .whereField("preferences.privacy.profilePublic", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let profileDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: UserProfileDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(profileDTOs, using: UserProfileMapper.self)
    }
    
    /// Search public profiles by display name
    func searchPublicProfiles(query: String) async throws -> [UserProfile] {
        let searchTerm = query.lowercased()
        
        let firestoreQuery = firestore.collectionGroup(FirestoreCollection.profiles)
            .whereField("preferences.privacy.profilePublic", isEqualTo: true)
            .order(by: "displayName")
            .start(at: [searchTerm])
            .end(at: [searchTerm + "\u{f8ff}"])
            .limit(to: 20)
        
        let snapshot = try await firestoreQuery.getDocuments()
        let profileDTOs = try snapshot.documents.compactMap { document in
            try document.data(as: UserProfileDTO.self)
        }
        
        return FirestoreBatchMapper.toDomain(profileDTOs, using: UserProfileMapper.self)
    }
    
    /// Listen to real-time updates for a user profile
    func listenToUserProfile(userId: String) -> AnyPublisher<UserProfile?, Error> {
        let userPath = FirestoreCollection.Paths.user(userId)
        let query = firestore.collection("\(userPath)/\(FirestoreCollection.profiles)")
            .limit(to: 1)
        
        return Publishers.FirestoreQuery(query: query)
            .map { snapshot in
                guard let document = snapshot.documents.first else { return nil }
                
                guard let profileDTO = try? document.data(as: UserProfileDTO.self) else {
                    return nil
                }
                
                return UserProfileMapper.toDomain(profileDTO)
            }
            .eraseToAnyPublisher()
    }
    
    /// Check if user has premium subscription
    func hasActiveSubscription(userId: String) async throws -> Bool {
        guard let profile = try await getUserProfileByUserId(userId),
              let subscription = profile.subscription else {
            return false
        }
        
        return subscription.status == .active && 
               (subscription.endDate ?? Date()) > Date()
    }
    
    /// Get subscription status
    func getSubscriptionStatus(userId: String) async throws -> SubscriptionInfo.SubscriptionStatus {
        guard let profile = try await getUserProfileByUserId(userId),
              let subscription = profile.subscription else {
            return .expired
        }
        
        if subscription.status == .active && (subscription.endDate ?? Date()) > Date() {
            return .active
        } else {
            return .expired
        }
    }
}
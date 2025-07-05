import Foundation
import Combine
import UIKit

/// Service that manages user subscription state in conjunction with authentication
@MainActor
final class UserSubscriptionService: ObservableObject {
    static let shared = UserSubscriptionService()
    
    // MARK: - Published Properties
    
    @Published var hasActiveSubscription: Bool = false
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionExpiration: Date?
    @Published var isTrialActive: Bool = false
    @Published var trialExpiration: Date?
    
    // MARK: - Properties
    
    private let subscriptionManager = SubscriptionManager.shared
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Check if user can access premium features
    func canAccessPremiumFeatures() -> Bool {
        return hasActiveSubscription || isTrialActive
    }
    
    /// Check if user can access specific feature
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedTemplates, .advancedAnalytics, .dataExport, .prioritySupport:
            return canAccessPremiumFeatures()
        case .cloudSync:
            return hasActiveSubscription // Trial doesn't include cloud sync
        }
    }
    
    /// Get remaining trial days
    func remainingTrialDays() -> Int? {
        guard isTrialActive, let expiration = trialExpiration else { return nil }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
        return max(0, remaining ?? 0)
    }
    
    /// Start a trial subscription
    func startTrial() async throws {
        guard let user = authManager.currentUser else {
            throw SubscriptionError.networkError
        }
        
        // Set trial for 7 days
        let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        trialExpiration = trialEnd
        isTrialActive = true
        
        // Save trial info to user preferences or backend
        await saveTrialStatus(userId: user.id)
    }
    
    /// Cancel current subscription
    func cancelSubscription() async throws {
        // This will guide user to App Store settings
        // The actual cancellation happens in App Store
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Listen to subscription manager changes
        subscriptionManager.$subscriptionState
            .combineLatest(subscriptionManager.$currentEntitlements)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, entitlements in
                self?.updateSubscriptionStatus(state: state, entitlements: entitlements)
            }
            .store(in: &cancellables)
        
        // Listen to authentication changes
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                Task {
                    await self?.loadUserSubscriptionStatus(user: user)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateSubscriptionStatus(state: SubscriptionState, entitlements: Set<String>) {
        hasActiveSubscription = state == .subscribed && !entitlements.isEmpty
        
        if hasActiveSubscription {
            // Determine subscription tier based on product ID
            if entitlements.contains("com.favoritestracker.premium.yearly") {
                subscriptionTier = .premiumYearly
            } else if entitlements.contains("com.favoritestracker.premium.monthly") {
                subscriptionTier = .premiumMonthly
            }
        } else {
            subscriptionTier = .free
        }
        
        // If user has active subscription, trial is no longer relevant
        if hasActiveSubscription {
            isTrialActive = false
            trialExpiration = nil
        }
    }
    
    private func loadUserSubscriptionStatus(user: User?) async {
        guard let user = user else {
            resetSubscriptionStatus()
            return
        }
        
        // Load trial status from user preferences or backend
        await loadTrialStatus(userId: user.id)
    }
    
    private func resetSubscriptionStatus() {
        hasActiveSubscription = false
        subscriptionTier = .free
        subscriptionExpiration = nil
        isTrialActive = false
        trialExpiration = nil
    }
    
    private func saveTrialStatus(userId: String) async {
        // Save to UserDefaults for now, could be backend in future
        let trialData = TrialData(
            userId: userId,
            isActive: isTrialActive,
            expiration: trialExpiration
        )
        
        if let encoded = try? JSONEncoder().encode(trialData) {
            UserDefaults.standard.set(encoded, forKey: "trial_\(userId)")
        }
    }
    
    private func loadTrialStatus(userId: String) async {
        guard let data = UserDefaults.standard.data(forKey: "trial_\(userId)"),
              let trialData = try? JSONDecoder().decode(TrialData.self, from: data) else {
            return
        }
        
        // Check if trial is still valid
        if let expiration = trialData.expiration, expiration > Date() {
            isTrialActive = trialData.isActive
            trialExpiration = trialData.expiration
        } else {
            // Trial expired, clean up
            isTrialActive = false
            trialExpiration = nil
        }
    }
}

// MARK: - Supporting Types

enum SubscriptionTier {
    case free
    case premiumMonthly
    case premiumYearly
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premiumMonthly:
            return "Premium (Monthly)"
        case .premiumYearly:
            return "Premium (Yearly)"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .free:
            return false
        case .premiumMonthly, .premiumYearly:
            return true
        }
    }
}

enum PremiumFeature {
    case unlimitedTemplates
    case advancedAnalytics
    case cloudSync
    case dataExport
    case prioritySupport
    
    var displayName: String {
        switch self {
        case .unlimitedTemplates:
            return "Unlimited Templates"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .cloudSync:
            return "Cloud Sync"
        case .dataExport:
            return "Data Export"
        case .prioritySupport:
            return "Priority Support"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedTemplates:
            return "Access to all premium templates in the marketplace"
        case .advancedAnalytics:
            return "Detailed insights and usage pattern tracking"
        case .cloudSync:
            return "Sync your data across all your devices"
        case .dataExport:
            return "Export your collections in multiple formats"
        case .prioritySupport:
            return "Get priority customer support"
        }
    }
}

private struct TrialData: Codable {
    let userId: String
    let isActive: Bool
    let expiration: Date?
}
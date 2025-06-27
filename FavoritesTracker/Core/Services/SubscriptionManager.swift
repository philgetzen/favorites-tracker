import Foundation
import StoreKit
import Combine

/// Manages App Store subscriptions using StoreKit 2
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    @Published var subscriptionState: SubscriptionState = .unknown
    @Published var availableProducts: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var currentEntitlements: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // Product identifiers for our subscription tiers
    private let productIdentifiers: Set<String> = [
        "com.favoritestracker.premium.monthly",
        "com.favoritestracker.premium.yearly"
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load available products from the App Store
    func requestProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            availableProducts = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
            print("SubscriptionManager: Failed to request products: \(error)")
        }
        
        isLoading = false
    }
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            isLoading = false
            return transaction
            
        case .userCancelled:
            isLoading = false
            return nil
            
        case .pending:
            isLoading = false
            return nil
            
        @unknown default:
            isLoading = false
            return nil
        }
    }
    
    /// Restore previous purchases
    func restore() async throws {
        isLoading = true
        errorMessage = nil
        
        try await AppStore.sync()
        await updateCustomerProductStatus()
        
        isLoading = false
    }
    
    /// Check if user has active premium subscription
    func isPremiumSubscriber() -> Bool {
        return subscriptionState == .subscribed && !currentEntitlements.isEmpty
    }
    
    /// Get the active subscription product
    func getActiveSubscription() -> Product? {
        return purchasedSubscriptions.first
    }
    
    // MARK: - Private Methods
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await transaction.finish()
                    
                    // Update status on main actor
                    _ = await MainActor.run {
                        Task { @MainActor in
                            await SubscriptionManager.shared.updateCustomerProductStatus()
                        }
                    }
                } catch {
                    print("SubscriptionManager: Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Verify transaction authenticity
    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    /// Update subscription status based on current transactions
    private func updateCustomerProductStatus() async {
        var purchasedCourses: [Product] = []
        var entitlements: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                
                // Check if transaction is valid and not expired
                if transaction.revocationDate == nil {
                    if let subscription = availableProducts.first(where: { $0.id == transaction.productID }) {
                        purchasedCourses.append(subscription)
                        entitlements.insert(transaction.productID)
                    }
                }
            } catch {
                print("SubscriptionManager: Failed to verify transaction: \(error)")
            }
        }
        
        purchasedSubscriptions = purchasedCourses
        currentEntitlements = entitlements
        
        // Update subscription state
        if !entitlements.isEmpty {
            subscriptionState = .subscribed
        } else {
            subscriptionState = .notSubscribed
        }
    }
}

// MARK: - Supporting Types

enum SubscriptionState {
    case unknown
    case subscribed
    case notSubscribed
}

enum SubscriptionError: Error, LocalizedError {
    case failedVerification
    case networkError
    case invalidProduct
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase authenticity"
        case .networkError:
            return "Network connection error"
        case .invalidProduct:
            return "Invalid subscription product"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Format price for display
    var formattedPrice: String {
        return priceFormatStyle.format(price)
    }
    
    /// Check if this is a monthly subscription
    var isMonthly: Bool {
        return id.contains("monthly")
    }
    
    /// Check if this is a yearly subscription
    var isYearly: Bool {
        return id.contains("yearly")
    }
    
    /// Get subscription period description
    var subscriptionPeriodDescription: String {
        guard let subscription = subscription else { return "" }
        
        let period = subscription.subscriptionPeriod
        let unit = period.unit
        let value = period.value
        
        switch unit {
        case .day:
            return value == 1 ? "Daily" : "\(value) days"
        case .week:
            return value == 1 ? "Weekly" : "\(value) weeks"
        case .month:
            return value == 1 ? "Monthly" : "\(value) months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) years"
        @unknown default:
            return "Unknown period"
        }
    }
    
    /// Get introductory offer description
    var introductoryOfferDescription: String? {
        guard let introOffer = subscription?.introductoryOffer else { return nil }
        
        let period = introOffer.period
        return "Special offer: \(period.value) \(period.unit.description)"
    }
}

// MARK: - Subscription Period Unit Extension

extension Product.SubscriptionPeriod.Unit {
    var description: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "unknown"
        }
    }
}
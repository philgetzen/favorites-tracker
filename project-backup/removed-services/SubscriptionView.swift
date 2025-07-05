import SwiftUI
import StoreKit

/// Main subscription management view
struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var showingPurchaseConfirmation = false
    @State private var showingManageSubscriptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if subscriptionManager.isLoading {
                        loadingSection
                    } else {
                        featuresSection
                        subscriptionOptionsSection
                        currentSubscriptionSection
                    }
                    
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("FavoritesTracker Premium")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if subscriptionManager.isPremiumSubscriber() {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Manage") {
                            showingManageSubscriptions = true
                        }
                    }
                }
            }
        }
        .task {
            await subscriptionManager.requestProducts()
        }
        .alert("Error", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            if let error = subscriptionManager.errorMessage {
                Text(error)
            }
        }
        .confirmationDialog("Purchase Confirmation", isPresented: $showingPurchaseConfirmation) {
            Button("Purchase") {
                if let product = selectedProduct {
                    Task {
                        _ = try await subscriptionManager.purchase(product)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let product = selectedProduct {
                Text("Purchase \(product.displayName) for \(product.formattedPrice)?")
            }
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("Unlock Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get unlimited access to all templates, advanced features, and priority support")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading subscription options...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Templates",
                    description: "Access to all premium templates in the marketplace"
                )
                
                FeatureRow(
                    icon: "chart.bar.xaxis",
                    title: "Advanced Analytics",
                    description: "Detailed insights and usage pattern tracking"
                )
                
                FeatureRow(
                    icon: "icloud.and.arrow.up",
                    title: "Cloud Sync",
                    description: "Sync your data across all your devices"
                )
                
                FeatureRow(
                    icon: "bell.badge",
                    title: "Smart Notifications",
                    description: "Personalized reminders and alerts"
                )
                
                FeatureRow(
                    icon: "doc.on.doc",
                    title: "Data Export",
                    description: "Export your collections in multiple formats"
                )
                
                FeatureRow(
                    icon: "headphones",
                    title: "Priority Support",
                    description: "Get help when you need it most"
                )
            }
        }
    }
    
    // MARK: - Subscription Options Section
    
    private var subscriptionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                    SubscriptionOptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onTap: {
                            selectedProduct = product
                            showingPurchaseConfirmation = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Current Subscription Section
    
    private var currentSubscriptionSection: some View {
        Group {
            if subscriptionManager.isPremiumSubscriber() {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current Subscription")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let activeSubscription = subscriptionManager.getActiveSubscription() {
                        ActiveSubscriptionCard(product: activeSubscription)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            if !subscriptionManager.isPremiumSubscriber() {
                Button("Restore Purchases") {
                    Task {
                        try await subscriptionManager.restore()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Link("Terms of Service", destination: URL(string: "https://favoritestracker.com/terms")!)
                    Text("•")
                    Link("Privacy Policy", destination: URL(string: "https://favoritestracker.com/privacy")!)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isPopular: Bool {
        product.isYearly
    }
    
    private var monthlySavings: String? {
        guard product.isYearly else { return nil }
        // Calculate savings compared to monthly option
        let yearlyMonthlyPrice = product.price / 12
        let monthlySavings = 2.99 - NSDecimalNumber(decimal: yearlyMonthlyPrice).doubleValue
        let percentSavings = (monthlySavings / 2.99) * 100
        return String(format: "Save %.0f%%", percentSavings)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Popular badge
                if isPopular {
                    HStack {
                        Spacer()
                        Text("Most Popular")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                        Spacer()
                    }
                }
                
                VStack(spacing: 8) {
                    Text(product.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(product.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text(product.subscriptionPeriodDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let savings = monthlySavings {
                        Text(savings)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    if let introOffer = product.introductoryOfferDescription {
                        Text(introOffer)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveSubscriptionCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Active Subscription")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("\(product.formattedPrice) / \(product.subscriptionPeriodDescription)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
}
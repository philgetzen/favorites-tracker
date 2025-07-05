import SwiftUI

/// Shows current subscription status in user profile/settings
struct SubscriptionStatusView: View {
    @StateObject private var subscriptionService = UserSubscriptionService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscriptionView = false
    @State private var showingCancelConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Current status section
            currentStatusSection
            
            Divider()
                .padding(.vertical, 16)
            
            // Actions section
            actionsSection
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
        .confirmationDialog("Cancel Subscription", isPresented: $showingCancelConfirmation) {
            Button("Go to App Store Settings", role: .destructive) {
                Task {
                    try await subscriptionService.cancelSubscription()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To cancel your subscription, you'll be taken to the App Store settings where you can manage your subscriptions.")
        }
    }
    
    // MARK: - Current Status Section
    
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Subscription")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                subscriptionBadge
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(subscriptionService.subscriptionTier.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if subscriptionService.isTrialActive {
                    trialStatusView
                } else if subscriptionService.hasActiveSubscription {
                    activeSubscriptionView
                } else {
                    freeSubscriptionView
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if !subscriptionService.hasActiveSubscription {
                // Upgrade button for free users
                Button(action: {
                    showingSubscriptionView = true
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Premium")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Trial button if not already used
                if !subscriptionService.isTrialActive {
                    Button(action: {
                        Task {
                            try await subscriptionService.startTrial()
                        }
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                            Text("Start 7-Day Free Trial")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                    }
                }
            } else {
                // Manage subscription for premium users
                Button(action: {
                    showingSubscriptionView = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage Subscription")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Cancel subscription
                Button(action: {
                    showingCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel Subscription")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            }
            
            // Restore purchases
            Button("Restore Purchases") {
                Task {
                    try await subscriptionManager.restore()
                }
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Status Views
    
    private var subscriptionBadge: some View {
        HStack {
            if subscriptionService.hasActiveSubscription {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Premium")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
            } else if subscriptionService.isTrialActive {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Trial")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "person.circle")
                    .foregroundColor(.secondary)
                Text("Free")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(currentBadgeColor.opacity(0.1))
        )
    }
    
    private var trialStatusView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let remainingDays = subscriptionService.remainingTrialDays() {
                Text("\(remainingDays) days remaining")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("All premium features included")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var activeSubscriptionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let activeSubscription = subscriptionManager.getActiveSubscription() {
                Text("\(activeSubscription.formattedPrice) / \(activeSubscription.subscriptionPeriodDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("All premium features included")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var freeSubscriptionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Limited features")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Upgrade to unlock all premium features")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentBadgeColor: Color {
        if subscriptionService.hasActiveSubscription {
            return .yellow
        } else if subscriptionService.isTrialActive {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - List Row Version

struct SubscriptionStatusRow: View {
    @StateObject private var subscriptionService = UserSubscriptionService.shared
    @State private var showingSubscriptionView = false
    
    var body: some View {
        Button(action: {
            showingSubscriptionView = true
        }) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Subscription")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                subscriptionBadge
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
    }
    
    private var statusDescription: String {
        if subscriptionService.hasActiveSubscription {
            return "Premium features active"
        } else if subscriptionService.isTrialActive {
            if let days = subscriptionService.remainingTrialDays() {
                return "\(days) days of trial remaining"
            } else {
                return "Free trial active"
            }
        } else {
            return "Limited features"
        }
    }
    
    private var subscriptionBadge: some View {
        HStack(spacing: 4) {
            if subscriptionService.hasActiveSubscription {
                Text("Premium")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
            } else if subscriptionService.isTrialActive {
                Text("Trial")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            } else {
                Text("Free")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(currentBadgeColor.opacity(0.1))
        )
    }
    
    private var currentBadgeColor: Color {
        if subscriptionService.hasActiveSubscription {
            return .yellow
        } else if subscriptionService.isTrialActive {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Full View") {
    NavigationView {
        List {
            Section {
                SubscriptionStatusView()
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("Row View") {
    NavigationView {
        List {
            Section {
                SubscriptionStatusRow()
                Text("Other Setting")
                Text("Another Setting")
            }
        }
        .navigationTitle("Settings")
    }
}
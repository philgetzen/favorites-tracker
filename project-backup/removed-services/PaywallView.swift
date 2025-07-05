import SwiftUI

/// Paywall component for premium feature access
struct PaywallView: View {
    let feature: PremiumFeature
    let onDismiss: () -> Void
    let onStartTrial: () -> Void
    let onSubscribe: () -> Void
    
    @StateObject private var subscriptionService = UserSubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            headerSection
            featureHighlightSection
            trialSection
            subscriptionSection
            footerSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .overlay(
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: featureIcon)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce)
            
            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(feature.displayName)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Feature Highlight Section
    
    private var featureHighlightSection: some View {
        VStack(spacing: 16) {
            Text("What you'll get:")
                .font(.headline)
                .fontWeight(.semibold)
            
            FeatureHighlightCard(feature: feature)
            
            // Additional premium features
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Unlimited access to all premium templates")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Advanced analytics and insights")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Priority customer support")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No ads and unlimited storage")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Trial Section
    
    private var trialSection: some View {
        VStack(spacing: 16) {
            if !subscriptionService.isTrialActive {
                VStack(spacing: 12) {
                    Text("Start Your Free Trial")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Try all premium features free for 7 days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            try await subscriptionService.startTrial()
                            onStartTrial()
                        }
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                            Text("Start Free Trial")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                )
            } else if let remainingDays = subscriptionService.remainingTrialDays() {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Trial Active")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Text("\(remainingDays) days remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Continue using all premium features or subscribe to keep access after your trial ends.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Monthly plan
                SubscriptionPlanCard(
                    title: "Monthly Premium",
                    price: "$2.99",
                    period: "per month",
                    isPopular: false,
                    onSelect: onSubscribe
                )
                
                // Yearly plan
                SubscriptionPlanCard(
                    title: "Yearly Premium",
                    price: "$29.99",
                    period: "per year",
                    subtitle: "Save 17%",
                    isPopular: true,
                    onSelect: onSubscribe
                )
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Subscriptions automatically renew. Cancel anytime in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Link("Terms", destination: URL(string: "https://favoritestracker.com/terms")!)
                Text("•")
                Link("Privacy", destination: URL(string: "https://favoritestracker.com/privacy")!)
                Text("•")
                Link("Support", destination: URL(string: "https://favoritestracker.com/support")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var featureIcon: String {
        switch feature {
        case .unlimitedTemplates:
            return "rectangle.stack.fill"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        case .cloudSync:
            return "icloud.and.arrow.up.fill"
        case .dataExport:
            return "doc.on.doc.fill"
        case .prioritySupport:
            return "headphones.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct FeatureHighlightCard: View {
    let feature: PremiumFeature
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: featureIcon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
        )
    }
    
    private var featureIcon: String {
        switch feature {
        case .unlimitedTemplates:
            return "rectangle.stack.fill"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        case .cloudSync:
            return "icloud.and.arrow.up.fill"
        case .dataExport:
            return "doc.on.doc.fill"
        case .prioritySupport:
            return "headphones.circle.fill"
        }
    }
}

struct SubscriptionPlanCard: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String?
    let isPopular: Bool
    let onSelect: () -> Void
    
    init(title: String, price: String, period: String, subtitle: String? = nil, isPopular: Bool = false, onSelect: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.period = period
        self.subtitle = subtitle
        self.isPopular = isPopular
        self.onSelect = onSelect
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
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
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        
                        Text(period)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPopular ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        feature: .unlimitedTemplates,
        onDismiss: {},
        onStartTrial: {},
        onSubscribe: {}
    )
}
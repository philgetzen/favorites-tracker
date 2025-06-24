import SwiftUI

#if DEBUG
/// Centralized preview configuration for consistent SwiftUI previews
/// This file provides standard preview setups and device configurations
struct PreviewConfiguration {
    
    // MARK: - Device Configurations
    
    /// Standard iPhone devices for previews
    static let iPhoneDevices: [String] = [
        "iPhone 16",
        "iPhone 16 Pro",
        "iPhone 16 Plus",
        "iPhone 16 Pro Max"
    ]
    
    /// Standard iPad devices for previews
    static let iPadDevices: [String] = [
        "iPad Pro (12.9-inch)",
        "iPad Pro (11-inch)",
        "iPad Air (5th generation)"
    ]
    
    /// All supported devices
    static let allDevices: [String] = iPhoneDevices + iPadDevices
    
    // MARK: - Preview Builders
    
    /// Create previews for multiple iPhone devices
    static func iPhonePreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            ForEach(iPhoneDevices.prefix(2), id: \.self) { device in
                content()
                    .previewDevice(PreviewDevice(rawValue: device))
                    .previewDisplayName(device)
            }
        }
    }
    
    /// Create previews for iPad devices
    static func iPadPreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            ForEach(iPadDevices.prefix(1), id: \.self) { device in
                content()
                    .previewDevice(PreviewDevice(rawValue: device))
                    .previewDisplayName(device)
            }
        }
    }
    
    /// Create color scheme previews (light and dark)
    static func colorSchemePreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            content()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            content()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
    
    /// Create accessibility previews with different font sizes
    static func accessibilityPreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            content()
                .environment(\.sizeCategory, .medium)
                .previewDisplayName("Medium Text")
            
            content()
                .environment(\.sizeCategory, .extraLarge)
                .previewDisplayName("Large Text")
            
            content()
                .environment(\.sizeCategory, .accessibilityExtraLarge)
                .previewDisplayName("Extra Large Text")
        }
    }
    
    /// Create orientation previews
    static func orientationPreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            content()
                .previewInterfaceOrientation(.portrait)
                .previewDisplayName("Portrait")
            
            content()
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape")
        }
    }
    
    /// Create comprehensive preview suite
    static func comprehensivePreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            // Default state
            content()
                .previewDisplayName("Default")
            
            // Color schemes
            colorSchemePreviews(content: content)
            
            // Key devices
            content()
                .previewDevice("iPhone 16")
                .previewDisplayName("iPhone 16")
            
            content()
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad Pro")
        }
    }
}

// MARK: - View Extensions for Easy Preview Setup

extension View {
    /// Apply iPhone-specific preview configuration
    func iPhonePreviews() -> some View {
        PreviewConfiguration.iPhonePreviews { self }
    }
    
    /// Apply iPad-specific preview configuration
    func iPadPreviews() -> some View {
        PreviewConfiguration.iPadPreviews { self }
    }
    
    /// Apply color scheme preview configuration
    func colorSchemePreviews() -> some View {
        PreviewConfiguration.colorSchemePreviews { self }
    }
    
    /// Apply accessibility preview configuration
    func accessibilityPreviews() -> some View {
        PreviewConfiguration.accessibilityPreviews { self }
    }
    
    /// Apply orientation preview configuration
    func orientationPreviews() -> some View {
        PreviewConfiguration.orientationPreviews { self }
    }
    
    /// Apply comprehensive preview suite
    func comprehensivePreviews() -> some View {
        PreviewConfiguration.comprehensivePreviews { self }
    }
}

// MARK: - Preview Provider Utilities

/// Utility for setting up preview environment
struct PreviewEnvironment {
    /// Setup mock data and dependencies for previews
    static func setup() {
        PreviewHelpers.setupPreviewDI()
    }
    
    /// Standard preview wrapper with environment setup
    static func wrapper<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        content()
            .onAppear {
                setup()
            }
    }
}

// MARK: - Sample Preview Views for Testing

/// Test view to demonstrate preview configurations
struct PreviewTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Preview Test View")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This view demonstrates different preview configurations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Test Button") {
                // Test action
            }
            .buttonStyle(.borderedProminent)
            
            HStack {
                Label("Feature 1", systemImage: "star")
                Spacer()
                Label("Feature 2", systemImage: "heart")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

// MARK: - Preview Test Previews

#Preview("Single Preview") {
    PreviewTestView()
}

#Preview("Color Schemes") {
    PreviewTestView()
        .colorSchemePreviews()
}

#Preview("iPhone Devices") {
    PreviewTestView()
        .iPhonePreviews()
}

#Preview("iPad Devices") {
    PreviewTestView()
        .iPadPreviews()
}

#Preview("Accessibility") {
    PreviewTestView()
        .accessibilityPreviews()
}

#Preview("Comprehensive") {
    PreviewTestView()
        .comprehensivePreviews()
}

#endif
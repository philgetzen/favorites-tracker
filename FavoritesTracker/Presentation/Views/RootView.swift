import SwiftUI

/// Root view that handles authentication routing
struct RootView: View {
    @StateObject var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            switch authManager.authenticationState {
            case .loading:
                LoadingView()
            case .authenticated:
                HomeView()
            case .unauthenticated:
                AuthenticationRootView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.authenticationState)
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse, options: .repeating)
            
            // App Title
            Text("FavoritesTracker")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Loading Indicator
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    RootView()
}

#Preview("Loading") {
    RootView()
}

#Preview("Unauthenticated") {
    RootView()
}
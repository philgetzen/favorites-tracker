import SwiftUI

/// Container view handling authentication flow navigation
struct AuthenticationRootView: View {
    @StateObject var authManager = AuthenticationManager.shared
    @State private var selectedTab: AuthTab = .signIn
    
    enum AuthTab: CaseIterable {
        case signIn, signUp
        
        var title: String {
            switch self {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Sign Up"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.authenticationState == .loading {
                loadingView
            } else {
                authenticationView
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("FavoritesTracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Authentication View
    
    private var authenticationView: some View {
        VStack(spacing: 0) {
            // App Logo and Title
            headerSection
            
            // Tab Selector
            tabSelector
            
            // Tab Content
            TabView(selection: $selectedTab) {
                SignInView()
                    .tag(AuthTab.signIn)
                
                SignUpView()
                    .tag(AuthTab.signUp)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            // App Title and Subtitle
            VStack(spacing: 8) {
                Text("FavoritesTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your favorite items across all your hobbies")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Rectangle()
                                .fill(Color.clear)
                                .overlay(
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(height: 2),
                                    alignment: .bottom
                                )
                                .opacity(selectedTab == tab ? 1 : 0)
                        )
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    AuthenticationRootView()
}

#Preview("Loading State") {
    AuthenticationRootView()
}
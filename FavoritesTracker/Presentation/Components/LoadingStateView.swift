import SwiftUI

/// Reusable loading state view for async operations
struct LoadingStateView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Error state view for failed operations
struct ErrorStateView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Empty state view for when no data is available
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Previews

#Preview("Loading State") {
    LoadingStateView()
}

#Preview("Loading with Custom Message") {
    LoadingStateView(message: "Fetching your collections...")
}

#Preview("Error State") {
    ErrorStateView(
        error: NSError(domain: "PreviewError", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "Unable to connect to the server. Please check your internet connection."
        ]),
        retryAction: { print("Retry tapped") }
    )
}

#Preview("Error State without Retry") {
    ErrorStateView(
        error: NSError(domain: "PreviewError", code: 403, userInfo: [
            NSLocalizedDescriptionKey: "You don't have permission to access this resource."
        ])
    )
}

#Preview("Empty Collections") {
    EmptyStateView(
        title: "No Collections Yet",
        message: "Start organizing your favorites by creating your first collection.",
        systemImage: "folder.badge.plus",
        actionTitle: "Create Collection",
        action: { print("Create collection tapped") }
    )
}

#Preview("Empty Items") {
    EmptyStateView(
        title: "No Items Found",
        message: "This collection is empty. Add your first item to get started.",
        systemImage: "plus.circle",
        actionTitle: "Add Item",
        action: { print("Add item tapped") }
    )
}

#Preview("Empty Search Results") {
    EmptyStateView(
        title: "No Results",
        message: "We couldn't find anything matching your search. Try different keywords.",
        systemImage: "magnifyingglass"
    )
}

#Preview("Dark Mode States") {
    VStack(spacing: 40) {
        LoadingStateView()
            .frame(height: 150)
        
        EmptyStateView(
            title: "No Collections",
            message: "Start by creating your first collection",
            systemImage: "folder.badge.plus",
            actionTitle: "Create Collection",
            action: { }
        )
        .frame(height: 200)
    }
    .preferredColorScheme(.dark)
}

#Preview("iPad Layout", traits: .landscapeLeft) {
    HStack(spacing: 40) {
        LoadingStateView()
            .frame(maxWidth: .infinity)
        
        EmptyStateView(
            title: "No Collections",
            message: "Start organizing your favorites by creating collections",
            systemImage: "folder.badge.plus",
            actionTitle: "Create Collection",
            action: { }
        )
        .frame(maxWidth: .infinity)
    }
    .padding()
}
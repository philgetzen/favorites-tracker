import SwiftUI
import Combine

/// Simple UI component that displays network connectivity status
/// Uses Firebase's built-in offline capabilities rather than complex custom sync
struct OfflineStatusView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showDetails = false
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                // Offline indicator
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Details button
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .sheet(isPresented: $showDetails) {
                OfflineStatusDetailsView(networkMonitor: networkMonitor, isPresented: $showDetails)
            }
        }
    }
}

/// Detailed offline status view shown in a sheet
struct OfflineStatusDetailsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection status
                VStack(spacing: 12) {
                    Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(networkMonitor.isConnected ? .green : .orange)
                    
                    Text(networkMonitor.connectionDescription)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !networkMonitor.isConnected {
                        Text("You're currently offline. Firebase will sync your changes when connection is restored.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Information about offline capabilities
                VStack(alignment: .leading, spacing: 16) {
                    Text("Offline Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(
                            icon: "checkmark.circle.fill",
                            title: "View Data", 
                            description: "Access your cached collections and items"
                        )
                        
                        FeatureRow(
                            icon: "plus.circle.fill",
                            title: "Create Items", 
                            description: "Add new items that will sync when online"
                        )
                        
                        FeatureRow(
                            icon: "pencil.circle.fill",
                            title: "Edit Items", 
                            description: "Make changes that will be saved automatically"
                        )
                        
                        FeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Auto Sync", 
                            description: "Changes sync automatically when connection returns"
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Connection Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Row component for displaying offline feature information
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Online") {
    OfflineStatusView()
        .padding()
}

#Preview("Offline") {
    // Note: In real usage, NetworkMonitor will automatically detect offline state
    OfflineStatusView()
        .padding()
}
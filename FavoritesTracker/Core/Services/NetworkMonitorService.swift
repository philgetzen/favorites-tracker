import Foundation
import Network
import Combine

/// Service for monitoring network connectivity status
/// Provides real-time updates about network availability and connection quality
final class NetworkMonitorService: ObservableObject, @unchecked Sendable {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var connectionType: NetworkConnectionType = .none
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Performs a quick connectivity test
    /// - Returns: True if a connection can be established to a test endpoint
    func testConnectivity() async -> Bool {
        guard isConnected else { return false }
        
        do {
            let url = URL(string: "https://www.apple.com/")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            return false
        }
    }
    
    /// Gets detailed network status information
    func getDetailedNetworkStatus() -> NetworkStatus {
        return NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained,
            lastChecked: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func updateNetworkStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.usesInterfaceType(.other) {
            connectionType = .other
        } else {
            connectionType = .none
        }
    }
}

// MARK: - Supporting Types

/// Represents the type of network connection
enum NetworkConnectionType: String, CaseIterable {
    case none = "none"
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .none: return "No Connection"
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "wifi.slash"
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        }
    }
}

/// Detailed network status information
struct NetworkStatus {
    let isConnected: Bool
    let connectionType: NetworkConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let lastChecked: Date
    
    /// Returns true if the connection is suitable for large data transfers
    var isHighQuality: Bool {
        return isConnected && !isExpensive && !isConstrained
    }
    
    /// Returns true if data usage should be minimized
    var shouldConserveData: Bool {
        return isExpensive || isConstrained
    }
    
    /// Returns a user-friendly description of the network status
    var description: String {
        if !isConnected {
            return "No internet connection"
        }
        
        var description = "Connected via \(connectionType.displayName)"
        
        if isExpensive {
            description += " (expensive)"
        }
        
        if isConstrained {
            description += " (limited)"
        }
        
        return description
    }
}
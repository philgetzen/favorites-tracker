import Foundation
import Network
import Combine

/// Simple network connectivity monitor  
/// Provides basic online/offline state without complex sync logic
final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    
    // MARK: - Published Properties
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnection(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateConnection(_ path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }
    }
    
    // MARK: - Public Interface
    
    var connectionDescription: String {
        guard isConnected else { return "Offline" }
        
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .none:
            return "Connected"
        default:
            return "Connected"
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        monitor.cancel()
    }
}
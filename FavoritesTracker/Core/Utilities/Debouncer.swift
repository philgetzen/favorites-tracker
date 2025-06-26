import Foundation

/// Utility class for debouncing rapid function calls
/// Prevents excessive API calls during user input
final class Debouncer: @unchecked Sendable {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    
    /// Initialize with delay and optional custom queue
    /// - Parameters:
    ///   - delay: Time to wait before executing the debounced action
    ///   - queue: Queue to execute the action on (defaults to main)
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    /// Debounce the provided action
    /// - Parameter action: Action to execute after the delay
    func debounce(action: @escaping () -> Void) {
        // Cancel any pending work
        workItem?.cancel()
        
        // Create new work item
        workItem = DispatchWorkItem(block: action)
        
        // Schedule execution after delay
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    /// Cancel any pending debounced action
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

/// AsyncDebouncer for async operations
actor AsyncDebouncer {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    /// Debounce an async action
    func debounce(action: @escaping () async -> Void) {
        // Cancel existing task
        task?.cancel()
        
        // Create new task with delay
        task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await action()
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }
    
    /// Cancel any pending debounced action
    func cancel() {
        task?.cancel()
        task = nil
    }
}
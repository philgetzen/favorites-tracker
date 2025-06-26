import Foundation

/// Memoization utilities for caching expensive computation results
/// Improves performance by avoiding repeated calculations

// MARK: - Memoized Function Cache

/// Thread-safe cache for memoizing function results
final class MemoizedCache<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private var cache: [Key: Value] = [:]
    private let maxSize: Int
    private let queue = DispatchQueue(label: "memoized-cache", attributes: .concurrent)
    
    init(maxSize: Int = 100) {
        self.maxSize = maxSize
    }
    
    func value(for key: Key, compute: () -> Value) -> Value {
        return queue.sync {
            if let cached = cache[key] {
                return cached
            }
            
            let value = compute()
            
            // Write with barrier to ensure thread safety
            queue.async(flags: .barrier) {
                // Evict oldest entries if cache is full
                if self.cache.count >= self.maxSize {
                    let keysToRemove = Array(self.cache.keys.prefix(self.maxSize / 2))
                    keysToRemove.forEach { self.cache.removeValue(forKey: $0) }
                }
                
                self.cache[key] = value
            }
            
            return value
        }
    }
    
    func removeValue(for key: Key) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// MARK: - Memoized Function

/// Creates a memoized version of a function
func memoized<Input: Hashable & Sendable, Output: Sendable>(
    _ function: @escaping (Input) -> Output,
    maxSize: Int = 100
) -> (Input) -> Output {
    let cache = MemoizedCache<Input, Output>(maxSize: maxSize)
    
    return { input in
        cache.value(for: input) {
            function(input)
        }
    }
}


// MARK: - Performance Utilities

/// Measures and caches expensive calculations with timing
struct PerformanceMemoizer<Key: Hashable & Sendable, Value: Sendable> {
    private let cache = MemoizedCache<Key, (value: Value, computeTime: TimeInterval)>()
    private let name: String
    
    init(name: String = "Unknown") {
        self.name = name
    }
    
    func value(for key: Key, compute: () -> Value) -> Value {
        return cache.value(for: key) {
            let startTime = CFAbsoluteTimeGetCurrent()
            let value = compute()
            let computeTime = CFAbsoluteTimeGetCurrent() - startTime
            
            #if DEBUG
            if computeTime > 0.016 { // > 16ms (one frame at 60fps)
                print("⚠️ Slow computation '\(name)': \(String(format: "%.2f", computeTime * 1000))ms")
            }
            #endif
            
            return (value: value, computeTime: computeTime)
        }.value
    }
}


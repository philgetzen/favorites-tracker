import Foundation
import Combine

/// Base view model class providing common functionality
/// Follows MVVM pattern with Clean Architecture principles
@MainActor
class BaseViewModel: ObservableObject {
    
    // MARK: - Common State
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private nonisolated(unsafe) var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Auto-hide error message after showing
        $showError
            .filter { !$0 }
            .delay(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Error Handling
    
    internal func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.errorMessage = error.localizedDescription
            self?.showError = true
        }
    }
    
    internal func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Loading State
    
    internal func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearError()
        }
    }
    
    // MARK: - Async Task Helper
    
    internal func performTask<T: Sendable>(
        _ task: @escaping @Sendable () async throws -> T,
        onSuccess: @escaping @Sendable (T) -> Void = { _ in },
        onError: @escaping @Sendable (Error) -> Void = { _ in }
    ) {
        Task {
            await MainActor.run {
                setLoading(true)
            }
            
            do {
                let result = try await task()
                await MainActor.run {
                    setLoading(false)
                    onSuccess(result)
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    onError(error)
                }
            }
        }
    }
}

/// Sample ViewModel demonstrating dependency injection usage
@MainActor
final class SampleViewModel: BaseViewModel {
    
    // MARK: - Dependencies (using @Inject property wrapper)
    // Note: These will be uncommented once repository implementations are created
    
    // @Inject private var itemRepository: ItemRepositoryProtocol
    // @Inject private var collectionRepository: CollectionRepositoryProtocol
    
    // MARK: - Published Properties
    
    @Published var items: [Item] = []
    @Published var collections: [Collection] = []
    
    // MARK: - Manual Dependency Resolution (temporary example)
    
    override init() {
        super.init()
        
        // Example of manual dependency resolution
        // let userDefaults = DIContainer.shared.resolve(UserDefaults.self)
        // print("UserDefaults resolved: \(userDefaults)")
    }
    
    // MARK: - Sample Methods
    
    func loadItems() {
        // This will be implemented once repositories are available
        performTask {
            // return try await itemRepository.getItems(for: "currentUserId")
            return [Item]() // Placeholder
        } onSuccess: { [weak self] items in
            Task { @MainActor in
                self?.items = items
            }
        }
    }
    
    func loadCollections() {
        // This will be implemented once repositories are available
        performTask {
            // return try await collectionRepository.getCollections(for: "currentUserId")
            return [Collection]() // Placeholder
        } onSuccess: { [weak self] collections in
            Task { @MainActor in
                self?.collections = collections
            }
        }
    }
}
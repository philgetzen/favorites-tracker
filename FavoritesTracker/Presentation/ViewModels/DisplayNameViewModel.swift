import Foundation
import Combine

/// ViewModel focused on display name validation and management
@MainActor
final class DisplayNameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var displayName: String = ""
    @Published var displayNameError: String?
    
    // MARK: - Private Properties
    
    private let signUpService: SignUpServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isDisplayNameValid: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var hasDisplayName: Bool {
        !trimmedDisplayName.isEmpty
    }
    
    // MARK: - Initialization
    
    init(signUpService: SignUpServiceProtocol = SignUpService()) {
        self.signUpService = signUpService
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        $displayName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] displayName in
                self?.validateDisplayName(displayName)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    private func validateDisplayName(_ displayName: String) {
        displayNameError = signUpService.validateDisplayName(displayName)
    }
    
    // MARK: - Public Methods
    
    func clearDisplayName() {
        displayName = ""
        displayNameError = nil
    }
}
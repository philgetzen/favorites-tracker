import Foundation
import Combine

/// ViewModel focused on email validation and management
@MainActor
final class EmailValidationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var emailError: String?
    
    // MARK: - Private Properties
    
    private let signUpService: SignUpServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isEmailValid: Bool {
        !email.isEmpty && signUpService.isValidEmail(email)
    }
    
    // MARK: - Initialization
    
    init(signUpService: SignUpServiceProtocol = SignUpService()) {
        self.signUpService = signUpService
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    private func validateEmail(_ email: String) {
        emailError = signUpService.validateEmail(email)
    }
    
    // MARK: - Public Methods
    
    func clearEmail() {
        email = ""
        emailError = nil
    }
}
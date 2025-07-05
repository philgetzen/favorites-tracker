import SwiftUI
import Combine

/// ViewModel responsible for form validation and error handling
@MainActor
final class ItemFormValidationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var validationErrors: [String] = []
    @Published var fieldErrors: [String: String] = [:]
    @Published var isFormValid: Bool = false
    
    // MARK: - Properties
    
    private let service: ItemFormServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(service: ItemFormServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func validateForm(name: String, imageCount: Int) {
        validationErrors.removeAll()
        fieldErrors.removeAll()
        
        let errors = service.validateItem(name: name, imageCount: imageCount)
        
        for error in errors {
            switch error {
            case .emptyName:
                fieldErrors["name"] = error.localizedDescription
            case .tooManyImages:
                validationErrors.append(error.localizedDescription)
            case .invalidImageData:
                validationErrors.append(error.localizedDescription)
            }
        }
        
        isFormValid = errors.isEmpty
    }
    
    func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Name is required"
        }
        return nil
    }
    
    func validateDescription(_ description: String) -> String? {
        // Description is optional, but could add length validation
        if description.count > 1000 {
            return "Description must be less than 1000 characters"
        }
        return nil
    }
    
    func validateTags(_ tags: [String]) -> String? {
        if tags.count > 20 {
            return "Maximum of 20 tags allowed"
        }
        return nil
    }
    
    func addError(_ error: Error) {
        validationErrors.append(error.localizedDescription)
    }
    
    func clearErrors() {
        validationErrors.removeAll()
        fieldErrors.removeAll()
    }
    
    // MARK: - Real-time Validation
    
    func setupRealTimeValidation(
        namePublisher: AnyPublisher<String, Never>,
        imageCountPublisher: AnyPublisher<Int, Never>
    ) {
        Publishers.CombineLatest(namePublisher, imageCountPublisher)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] name, imageCount in
                self?.validateForm(name: name, imageCount: imageCount)
            }
            .store(in: &cancellables)
    }
}
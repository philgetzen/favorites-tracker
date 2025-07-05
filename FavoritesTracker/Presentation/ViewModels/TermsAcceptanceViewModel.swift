import Foundation

/// ViewModel focused on terms and privacy policy acceptance
@MainActor
final class TermsAcceptanceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var acceptedTerms: Bool = false
    @Published var acceptedPrivacy: Bool = false
    
    // MARK: - Computed Properties
    
    var hasAcceptedBoth: Bool {
        acceptedTerms && acceptedPrivacy
    }
    
    var termsAcceptanceValid: Bool {
        acceptedTerms
    }
    
    var privacyAcceptanceValid: Bool {
        acceptedPrivacy
    }
    
    // MARK: - Actions
    
    func toggleTermsAcceptance() {
        acceptedTerms.toggle()
    }
    
    func togglePrivacyAcceptance() {
        acceptedPrivacy.toggle()
    }
    
    func acceptBoth() {
        acceptedTerms = true
        acceptedPrivacy = true
    }
    
    func clearAcceptance() {
        acceptedTerms = false
        acceptedPrivacy = false
    }
}
import SwiftUI
import Combine

/// ViewModel responsible for form presentation logic in the Home screen
@MainActor
final class HomeFormViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var showingItemForm = false
    @Published var showingAdvancedSearch = false
    
    // MARK: - Properties
    
    private let dataViewModel: HomeDataViewModel
    
    // MARK: - Computed Properties
    
    /// Indicates whether any form is currently being shown
    var isShowingAnyForm: Bool {
        return showingItemForm || showingAdvancedSearch
    }
    
    // MARK: - Initialization
    
    init(dataViewModel: HomeDataViewModel) {
        self.dataViewModel = dataViewModel
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Shows the item creation form
    func showItemForm() {
        // Create a default collection if none exist
        if !dataViewModel.hasCollections {
            Task {
                await dataViewModel.ensureDefaultCollection()
                await MainActor.run {
                    showingItemForm = true
                }
            }
        } else {
            showingItemForm = true
        }
    }
    
    /// Hides the item creation form
    func hideItemForm() {
        showingItemForm = false
    }
    
    /// Shows the advanced search form
    func showAdvancedSearch() {
        showingAdvancedSearch = true
    }
    
    /// Hides the advanced search form
    func hideAdvancedSearch() {
        showingAdvancedSearch = false
    }
    
    /// Handles form dismissal and refreshes data if needed
    func handleItemFormDismissal() {
        showingItemForm = false
        dataViewModel.refreshAfterItemCreation()
    }
    
    /// Handles advanced search form dismissal
    func handleAdvancedSearchDismissal() {
        showingAdvancedSearch = false
    }
    
    /// Toggles the item form visibility
    func toggleItemForm() {
        if showingItemForm {
            hideItemForm()
        } else {
            showItemForm()
        }
    }
    
    /// Toggles the advanced search form visibility
    func toggleAdvancedSearch() {
        if showingAdvancedSearch {
            hideAdvancedSearch()
        } else {
            showAdvancedSearch()
        }
    }
    
    /// Dismisses all forms
    func dismissAllForms() {
        showingItemForm = false
        showingAdvancedSearch = false
    }
    
    /// Prepares the environment for item creation
    func prepareForItemCreation() async {
        // Ensure we have at least one collection before showing the form
        if !dataViewModel.hasCollections {
            await dataViewModel.ensureDefaultCollection()
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HomeFormViewModel {
    static func preview() -> HomeFormViewModel {
        let dataViewModel = HomeDataViewModel.preview()
        let viewModel = HomeFormViewModel(dataViewModel: dataViewModel)
        
        return viewModel
    }
}
#endif
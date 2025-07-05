import SwiftUI
import Combine

/// ViewModel responsible for item image management and viewing
@MainActor
final class ItemImageViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var showingImageViewer: Bool = false
    @Published var selectedImageIndex: Int = 0
    
    // MARK: - Properties
    
    private var imageURLs: [URL] = []
    
    // MARK: - Computed Properties
    
    var hasImages: Bool {
        !imageURLs.isEmpty
    }
    
    var imageCount: Int {
        imageURLs.count
    }
    
    var currentImageURL: URL? {
        guard selectedImageIndex >= 0 && selectedImageIndex < imageURLs.count else {
            return nil
        }
        return imageURLs[selectedImageIndex]
    }
    
    var canNavigatePrevious: Bool {
        selectedImageIndex > 0
    }
    
    var canNavigateNext: Bool {
        selectedImageIndex < imageURLs.count - 1
    }
    
    // MARK: - Public Methods
    
    /// Updates the image URLs from an item
    /// - Parameter imageURLs: The image URLs to display
    func updateImageURLs(_ imageURLs: [URL]) {
        self.imageURLs = imageURLs
        
        // Reset selection if current index is out of bounds
        if selectedImageIndex >= imageURLs.count {
            selectedImageIndex = 0
        }
    }
    
    /// Shows the image viewer at a specific index
    /// - Parameter index: The index of the image to show
    func showImage(at index: Int) {
        guard index >= 0 && index < imageURLs.count else { return }
        
        selectedImageIndex = index
        showingImageViewer = true
    }
    
    /// Navigates to the previous image
    func navigateToPrevious() {
        guard canNavigatePrevious else { return }
        selectedImageIndex -= 1
    }
    
    /// Navigates to the next image
    func navigateToNext() {
        guard canNavigateNext else { return }
        selectedImageIndex += 1
    }
    
    /// Closes the image viewer
    func closeImageViewer() {
        showingImageViewer = false
    }
    
    /// Gets the image URL at a specific index
    /// - Parameter index: The index of the image
    /// - Returns: The URL at the index or nil if out of bounds
    func imageURL(at index: Int) -> URL? {
        guard index >= 0 && index < imageURLs.count else { return nil }
        return imageURLs[index]
    }
}
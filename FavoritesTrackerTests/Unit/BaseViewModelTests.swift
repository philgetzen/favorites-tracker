import XCTest
import Combine
@testable import FavoritesTracker

/// Tests for BaseViewModel functionality
@MainActor
final class BaseViewModelTests: XCTestCase {
    
    private var viewModel: TestViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = TestViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Loading State Tests
    
    func testInitialLoadingState() {
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSetLoadingTrue() {
        // When
        viewModel.setLoadingPublic(true)
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testSetLoadingFalse() {
        // Given
        viewModel.setLoadingPublic(true)
        
        // When
        viewModel.setLoadingPublic(false)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testInitialErrorState() {
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testHandleError() {
        // Given
        let error = TestError.mockNotConfigured
        
        // When
        viewModel.handleErrorPublic(error)
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testClearError() {
        // Given
        viewModel.handleErrorPublic(TestError.mockNotConfigured)
        
        // When
        viewModel.clearErrorPublic()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testSetLoadingClearsError() {
        // Given
        viewModel.handleErrorPublic(TestError.mockNotConfigured)
        
        // When
        viewModel.setLoadingPublic(true)
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.isLoading)
    }
    
    // MARK: - Async Task Tests
    
    func testPerformTaskSuccess() async {
        // Given
        let expectedResult = "success"
        var onSuccessCalled = false
        var successResult: String?
        
        // When
        viewModel.performTaskPublic {
            return expectedResult
        } onSuccess: { result in
            onSuccessCalled = true
            successResult = result
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(onSuccessCalled)
        XCTAssertEqual(successResult, expectedResult)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testPerformTaskError() async {
        // Given
        let expectedError = TestError.mockNotConfigured
        var onErrorCalled = false
        var errorResult: Error?
        
        // When
        viewModel.performTaskPublic {
            throw expectedError
        } onSuccess: { _ in
            XCTFail("onSuccess should not be called")
        } onError: { error in
            onErrorCalled = true
            errorResult = error
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(onErrorCalled)
        XCTAssertTrue(errorResult is TestError)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testPerformTaskSetsAndClearsLoading() async {
        // Given
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { loading in
                loadingStates.append(loading)
            }
            .store(in: &cancellables)
        
        // When
        viewModel.performTaskPublic {
            return "success"
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    // MARK: - Error Auto-Hide Tests
    
    func testErrorAutoHides() {
        // Given
        let expectation = expectation(description: "Error should auto-hide")
        
        viewModel.$errorMessage
            .dropFirst() // Skip initial nil
            .sink { errorMessage in
                if errorMessage == nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.handleErrorPublic(TestError.mockNotConfigured)
        viewModel.showError = false // Simulate error dismissal
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Support

@MainActor
private class TestViewModel: BaseViewModel {
    
    // Expose protected methods for testing
    func setLoadingPublic(_ loading: Bool) {
        setLoading(loading)
    }
    
    func handleErrorPublic(_ error: Error) {
        handleError(error)
    }
    
    func clearErrorPublic() {
        clearError()
    }
    
    func performTaskPublic<T>(
        _ task: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        performTask(task, onSuccess: onSuccess, onError: onError)
    }
}
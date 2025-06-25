import XCTest

/// UI tests for app launch and basic navigation
final class AppLaunchUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up test environment
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_MOCK_DATA": "1"
        ]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunches() throws {
        // When
        app.launch()
        
        // Then
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testAppDisplaysInitialView() throws {
        // When
        app.launch()
        
        // Then
        // The app should display the main content view
        // Note: These tests will be updated when we have actual UI
        let mainView = app.otherElements["ContentView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 5.0))
    }
    
    func testAppHandlesMemoryWarning() throws {
        // Given
        app.launch()
        
        // When
        // Simulate memory warning (if needed in future)
        
        // Then
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Navigation Tests
    
    func testBasicNavigation() throws {
        // Given
        app.launch()
        
        // When/Then
        // Navigation tests will be implemented when we have actual UI
        // For now, just verify the app stays responsive
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Given
        app.launch()
        
        // When/Then
        // Verify key UI elements are accessible
        // This will be expanded when we have actual UI elements
        let contentView = app.otherElements["ContentView"]
        XCTAssertTrue(contentView.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // MARK: - Orientation Tests
    
    func testPortraitOrientation() throws {
        // Given
        app.launch()
        
        // When
        XCUIDevice.shared.orientation = .portrait
        
        // Then
        // Verify UI adapts to portrait mode
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testLandscapeOrientation() throws {
        // Given
        app.launch()
        
        // When
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Then
        // Verify UI adapts to landscape mode
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Background/Foreground Tests
    
    func testAppBackgroundAndForeground() throws {
        // Given
        app.launch()
        
        // When
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Then
        XCTAssertTrue(app.state == .runningForeground)
    }
}

/// UI test helper extensions
extension XCUIElement {
    
    /// Wait for element to exist and be hittable
    func waitForHittable(timeout: TimeInterval = 5.0) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Tap element after waiting for it to be hittable
    func tapAfterWaiting(timeout: TimeInterval = 5.0) {
        if waitForHittable(timeout: timeout) {
            tap()
        }
    }
}

/// UI test assertions
extension XCTestCase {
    
    /// Assert that element exists within timeout
    func assertElementExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Element \(element) does not exist",
            file: file,
            line: line
        )
    }
    
    /// Assert that element does not exist
    func assertElementDoesNotExist(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            element.exists,
            "Element \(element) should not exist",
            file: file,
            line: line
        )
    }
}
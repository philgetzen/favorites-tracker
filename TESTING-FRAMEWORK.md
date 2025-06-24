# Testing Framework - Favorites Tracker

## Overview
Comprehensive test framework supporting Clean Architecture principles with unit, integration, and UI testing capabilities.

## Test Architecture

### Test Structure
```
FavoritesTrackerTests/
├── Unit/                       # Unit tests for individual components
│   ├── DIContainerTests.swift  # Dependency injection tests
│   ├── BaseViewModelTests.swift # MVVM base functionality
│   └── DomainEntitiesTests.swift # Domain model tests
├── Integration/                # Integration tests between layers
│   └── MockRepositoryIntegrationTests.swift
├── UI/                        # UI and end-to-end tests
│   └── AppLaunchUITests.swift
├── Mocks/                     # Mock implementations
│   └── MockRepositories.swift
├── Helpers/                   # Test utilities and extensions
│   ├── XCTestCase+Extensions.swift
│   └── TestDIContainer.swift
└── TestData/                  # Sample data and configuration
    └── TestConfiguration.swift
```

## Test Types

### 1. Unit Tests
**Purpose**: Test individual components in isolation
**Location**: `FavoritesTrackerTests/Unit/`

#### Coverage Areas:
- **Domain Entities**: Business model validation and behavior
- **ViewModels**: Presentation logic and state management
- **Use Cases**: Business logic implementation
- **Dependency Injection**: Service registration and resolution
- **Utilities**: Helper functions and extensions

#### Example:
```swift
func testUserCreation() {
    // Given
    let email = "test@example.com"
    
    // When
    let user = User(id: "123", email: email, displayName: "Test")
    
    // Then
    XCTAssertEqual(user.email, email)
    XCTAssertNotNil(user.createdAt)
}
```

### 2. Integration Tests
**Purpose**: Test interactions between multiple components
**Location**: `FavoritesTrackerTests/Integration/`

#### Coverage Areas:
- **Repository Layer Integration**: Data flow between repositories
- **Use Case + Repository**: Business logic with data access
- **ViewModel + Use Case**: Presentation logic with business logic
- **Cross-Layer Communication**: Clean Architecture layer interactions

#### Example:
```swift
func testCompleteUserWorkflow() async throws {
    // Test complete user journey: Auth → Collection → Items
    let user = try await authRepository.signIn(email: email, password: password)
    let collection = try await collectionRepository.createCollection(collection)
    let item = try await itemRepository.createItem(item)
    
    XCTAssertEqual(item.userId, user.id)
}
```

### 3. UI Tests
**Purpose**: Test user interface and user interactions
**Location**: `FavoritesTrackerTests/UI/`

#### Coverage Areas:
- **App Launch**: Application startup and initial state
- **Navigation**: Screen transitions and user flow
- **User Interactions**: Tap, swipe, input handling
- **Accessibility**: VoiceOver and accessibility compliance
- **Performance**: Launch time and responsiveness

#### Example:
```swift
func testAppLaunches() throws {
    app.launch()
    XCTAssertTrue(app.state == .runningForeground)
}
```

## Mock System

### Mock Repositories
Located in `FavoritesTrackerTests/Mocks/MockRepositories.swift`

#### Features:
- **Configurable Behavior**: Error simulation, delays, custom responses
- **Call Tracking**: Monitor method invocations and parameters
- **State Management**: Maintain in-memory data for testing
- **Reset Functionality**: Clean state between tests

#### Usage:
```swift
// Configure mock behavior
mockRepository.shouldThrowError = true
mockRepository.errorToThrow = TestError.networkFailure

// Verify interactions
XCTAssertEqual(mockRepository.createItemCallCount, 1)
XCTAssertEqual(mockRepository.lastCreatedItem?.name, "Test Item")
```

### Test DI Container
Located in `FavoritesTrackerTests/Helpers/TestDIContainer.swift`

#### Features:
- **Clean Isolation**: Fresh container for each test
- **Mock Injection**: Easy replacement of services with mocks
- **Test Environment**: Separate from production configuration

#### Usage:
```swift
override func setUp() {
    TestDIContainer.shared.setupTestEnvironment()
    TestDIContainer.shared.registerMock(ItemRepositoryProtocol.self, mock: mockRepository)
}
```

## Test Utilities

### XCTestCase Extensions
Located in `FavoritesTrackerTests/Helpers/XCTestCase+Extensions.swift`

#### Async Testing:
```swift
func testAsyncOperation() async {
    let result = await assertNoThrow {
        try await repository.getData()
    }
    XCTAssertNotNil(result)
}
```

#### Error Testing:
```swift
await assertThrowsError(ExpectedError.notFound) {
    try await repository.getItem(id: "invalid")
}
```

### Test Data Factory
Located in `FavoritesTrackerTests/TestData/TestConfiguration.swift`

#### Sample Data:
```swift
let user = TestObjectFactory.createUser()
let collection = TestObjectFactory.createCollection(userId: user.id)
let scenario = TestData.createTestScenario()
```

## Test Configuration

### Environment Setup
```swift
// In test setUp()
TestConfiguration.configureTestEnvironment()
TestDIContainer.shared.setupTestEnvironment()

// In test tearDown()
TestDIContainer.shared.tearDown()
TestConfiguration.cleanupTestEnvironment()
```

### UI Test Configuration
```swift
// App launch arguments
app.launchArguments = ["--uitesting"]
app.launchEnvironment = [
    "UITEST_DISABLE_ANIMATIONS": "1",
    "UITEST_MOCK_DATA": "1"
]
```

## Running Tests

### Command Line
```bash
# Run all tests
xcodebuild test -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test suite
xcodebuild test -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FavoritesTrackerTests/Unit

# Run single test
xcodebuild test -project FavoritesTracker.xcodeproj -scheme FavoritesTracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FavoritesTrackerTests/Unit/DIContainerTests/testRegisterSingleton
```

### Xcode
1. **Product → Test** (⌘U): Run all tests
2. **Test Navigator**: Run specific test suites or individual tests
3. **Test Report**: View detailed results and coverage

## Test Guidelines

### 1. Test Naming
```swift
// Structure: test[What]_[When]_[Expected]
func testCreateItem_WithValidData_ReturnsCreatedItem()
func testSignIn_WithInvalidCredentials_ThrowsAuthError()
func testViewModel_WhenLoadingData_SetsLoadingState()
```

### 2. Test Structure (Given/When/Then)
```swift
func testExample() {
    // Given - Set up test conditions
    let input = "test data"
    
    // When - Execute the operation
    let result = systemUnderTest.process(input)
    
    // Then - Verify the outcome
    XCTAssertEqual(result, expectedValue)
}
```

### 3. Test Independence
- Each test should be independent
- Use setUp/tearDown for clean state
- Don't rely on test execution order

### 4. Mock Configuration
- Reset mocks between tests
- Configure behavior explicitly
- Verify interactions when relevant

### 5. Async Testing
- Use proper async/await patterns
- Handle timeouts appropriately
- Test both success and failure cases

## Coverage Goals

### Target Coverage Levels:
- **Unit Tests**: 90%+ for business logic
- **Integration Tests**: 80%+ for critical workflows
- **UI Tests**: 70%+ for key user journeys

### Critical Areas (100% Coverage):
- Authentication flows
- Data persistence
- Business rule validation
- Error handling
- Security-sensitive operations

## Continuous Integration

### Test Automation
- Run tests on every pull request
- Generate coverage reports
- Fail builds on test failures
- Performance regression detection

### Test Reporting
- Code coverage metrics
- Test execution time tracking
- Flaky test identification
- Performance benchmarks

## Best Practices

### 1. Fast Tests
- Use mocks for external dependencies
- Minimize file I/O and network calls
- Parallel test execution where possible

### 2. Reliable Tests
- Avoid time-dependent assertions
- Use deterministic test data
- Handle async operations properly

### 3. Maintainable Tests
- Clear test names and structure
- Minimal setup/teardown
- Shared test utilities
- Regular test refactoring

### 4. Comprehensive Coverage
- Test happy paths and edge cases
- Include error scenarios
- Validate boundary conditions
- Test accessibility features

## Future Enhancements

### Planned Additions:
1. **Snapshot Testing**: UI layout verification
2. **Performance Tests**: Benchmark critical operations
3. **Property-Based Testing**: Random input validation
4. **Contract Testing**: API interface validation
5. **Load Testing**: Concurrent operation handling

### Tools Integration:
- **SwiftLint**: Code quality enforcement
- **Fastlane**: Automated test execution
- **Firebase Test Lab**: Cloud device testing
- **Code Coverage**: Detailed coverage reporting
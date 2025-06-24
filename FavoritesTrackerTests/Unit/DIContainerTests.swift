import XCTest
@testable import FavoritesTracker

/// Tests for the dependency injection container
final class DIContainerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        TestDIContainer.shared.setupTestEnvironment()
    }
    
    override func tearDown() {
        TestDIContainer.shared.tearDown()
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterSingleton() {
        // Given
        let testService = "test-service"
        
        // When
        DIContainer.shared.register(String.self, instance: testService)
        
        // Then
        let resolved = DIContainer.shared.resolve(String.self)
        XCTAssertEqual(resolved, testService)
    }
    
    func testRegisterFactory() {
        // Given
        var callCount = 0
        DIContainer.shared.register(Int.self, factory: {
            callCount += 1
            return callCount
        })
        
        // When
        let first = DIContainer.shared.resolve(Int.self)
        let second = DIContainer.shared.resolve(Int.self)
        
        // Then
        XCTAssertEqual(first, 1)
        XCTAssertEqual(second, 2)
        XCTAssertEqual(callCount, 2)
    }
    
    func testSingletonInstanceReused() {
        // Given
        let testService = TestService()
        DIContainer.shared.register(TestService.self, instance: testService)
        
        // When
        let first = DIContainer.shared.resolve(TestService.self)
        let second = DIContainer.shared.resolve(TestService.self)
        
        // Then
        XCTAssertTrue(first === testService)
        XCTAssertTrue(second === testService)
        XCTAssertTrue(first === second)
    }
    
    // MARK: - Resolution Tests
    
    func testResolveOptional() {
        // Given - no registration
        
        // When
        let resolved = DIContainer.shared.resolveOptional(String.self)
        
        // Then
        XCTAssertNil(resolved)
    }
    
    func testResolveOptionalWithRegistration() {
        // Given
        let testService = "test-service"
        DIContainer.shared.register(String.self, instance: testService)
        
        // When
        let resolved = DIContainer.shared.resolveOptional(String.self)
        
        // Then
        XCTAssertEqual(resolved, testService)
    }
    
    func testResolveMissingServiceThrows() {
        // Given - no registration
        
        // When/Then
        XCTAssertThrowsError(try {
            _ = DIContainer.shared.resolve(String.self)
        }())
    }
    
    // MARK: - Clear Tests
    
    func testClearRemovesAllRegistrations() {
        // Given
        DIContainer.shared.register(String.self, instance: "test")
        DIContainer.shared.register(Int.self, instance: 42)
        
        // When
        DIContainer.shared.clear()
        
        // Then
        XCTAssertNil(DIContainer.shared.resolveOptional(String.self))
        XCTAssertNil(DIContainer.shared.resolveOptional(Int.self))
    }
    
    // MARK: - Inject Property Wrapper Tests
    
    func testInjectPropertyWrapper() {
        // Given
        let testService = TestService()
        DIContainer.shared.register(TestService.self, instance: testService)
        
        // When
        let testObject = TestObjectWithInjection()
        
        // Then
        XCTAssertTrue(testObject.testService === testService)
    }
}

// MARK: - Test Support Classes

private class TestService {
    let id = UUID()
}

private class TestObjectWithInjection {
    @Inject var testService: TestService
}
import XCTest
import Foundation

/// Common extensions for XCTestCase to support Clean Architecture testing
extension XCTestCase {
    
    /// Wait for async operation with timeout
    func waitForAsync<T>(
        timeout: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Create expectation and wait for it
    func waitForExpectation(
        description: String,
        timeout: TimeInterval = 1.0,
        handler: @escaping (@escaping () -> Void) -> Void
    ) {
        let expectation = expectation(description: description)
        handler {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Assert that async operation throws specific error
    func assertThrowsError<T, E: Error & Equatable>(
        _ expectedError: E,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected error \(expectedError) but no error was thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected error \(expectedError) but got \(error)", file: file, line: line)
        }
    }
    
    /// Assert that async operation doesn't throw
    func assertNoThrow<T>(
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
            return nil
        }
    }
}

/// Common test errors
enum TestError: Error, Equatable {
    case timeout
    case mockNotConfigured
    case invalidTestData
}

/// Test utility for creating test objects
struct TestObjectFactory {
    
    /// Create test user
    static func createUser(
        id: String = "test-user-id",
        email: String = "test@example.com",
        displayName: String = "Test User"
    ) -> User {
        User(id: id, email: email, displayName: displayName)
    }
    
    /// Create test collection
    static func createCollection(
        userId: String = "test-user-id",
        name: String = "Test Collection",
        templateId: String? = nil
    ) -> Collection {
        Collection(userId: userId, name: name, templateId: templateId)
    }
    
    /// Create test item
    static func createItem(
        userId: String = "test-user-id",
        collectionId: String = "test-collection-id",
        name: String = "Test Item"
    ) -> Item {
        Item(userId: userId, collectionId: collectionId, name: name)
    }
    
    /// Create test template
    static func createTemplate(
        creatorId: String = "test-user-id",
        name: String = "Test Template",
        description: String = "Test Description",
        category: String = "Test Category"
    ) -> Template {
        Template(creatorId: creatorId, name: name, description: description, category: category)
    }
}
import XCTest
@testable import DynamoModel

final class DynamoModelTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DynamoModel().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

import XCTest
import DynamoDB
@testable import DynamoModel

final class DynamoModelTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(DynamoModel().text, "Hello, World!")
    }

    func testModelEncoding() throws {
        let model = TestModel()
        model.id = .init()
        model.sortKey = "foo"
        model.title = "bar"
        model.order = 1
        model.completed = false

        let encoded = try DynamoEncoder().encode(model)
        let decoded = try DynamoDecoder().decode(TestModel.self, from: encoded)
        XCTAssertEqual(model, decoded)

        let asDynamoAttributes = try DynamoDecoder().decode([String: DynamoDB.AttributeValue].self, from: encoded)
        XCTAssertEqual(asDynamoAttributes["id"]?.s, model.id.uuidString)
        XCTAssertEqual(asDynamoAttributes["sortKey"]?.s, model.sortKey)
        XCTAssertEqual(asDynamoAttributes["title"]?.s, model.title)
        XCTAssertEqual(asDynamoAttributes["order"]?.n!, "\(model.order!)")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}



import XCTest
import DynamoDB
@testable import SwiftDynamo

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
        model.title = "bar"
        model.order = 1
        model.completed = false

        let encoded = try DynamoEncoder().encode(model)
        let decoded = try DynamoDecoder().decode(TestModel.self, from: encoded)
        XCTAssertEqual(model, decoded)

        let asDynamoAttributes = try DynamoDecoder().decode([String: DynamoDB.AttributeValue].self, from: encoded)
        XCTAssertEqual(asDynamoAttributes["id"]?.s, model.id!.uuidString)
        XCTAssertEqual(asDynamoAttributes["title"]?.s, model.title)
        XCTAssertEqual(asDynamoAttributes["order"]?.n!, "\(model.order!)")
    }

    func testModelEncodingWithADictValue() throws {
        final class ModelWithDict: DynamoModel {

            static var schema: DynamoSchema = "foo"

            @ID(key: "foo")
            var id: Int?

            @Field(key: "dict")
            var dict: [String: String]

            @Field(key: "list")
            var list: [Int]

            init() { }

        }

        let model = ModelWithDict()
        model.id = 1
        model.dict = ["bar": "baz"]
        model.list = [0, 1, 2, 3, 4]

        let encoded = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(ModelWithDict.self, from: encoded)
        XCTAssertEqual(decoded.id!, 1)
        XCTAssertEqual(decoded.dict, ["bar": "baz"])
        XCTAssertEqual(decoded.list, [0, 1, 2, 3, 4])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}



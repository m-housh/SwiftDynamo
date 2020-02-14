import XCTest
import DynamoDB
import DynamoCoder
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

        let asDynamoAttributes = encoded
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

    func testNestedCodables() throws {

        struct Name: Codable {
            let first: String
            let last: String

            init(first: String, last: String) {
                self.first = first
                self.last = last
            }
        }

        final class ModelWithNestedCodable: DynamoModel {
            static var schema: DynamoSchema = "foo"

            @ID(key: "ID")
            var id: UUID?

            @Field(key: "Name")
            var name: Name

            init() { }
        }

        let model = ModelWithNestedCodable()
        model.id = .init()
        model.name = .init(first: "foo", last: "bar")

//        let converted = try DynamoEnocder().convert(model)
//        print("Converted: \(converted)")
        do {
            let data = try DynamoEncoder().encode(model)
            print("DATA: \(data)")
            let decoded = try DynamoDecoder().decode(ModelWithNestedCodable.self, from: data)
            XCTAssertEqual(decoded.name.first, "foo")
            XCTAssertEqual(decoded.name.last, "bar")
        }
        catch {
            print("Error: \(error)")
            throw error
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}



//
//  File.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import XCTest
import DynamoDB
@testable import DynamoModel


final class DynamoEncoderTests: XCTestCase {

    func testSimpleEncoding() throws {
        struct TestModel: Codable {
            let string = "foo"
            let int = 1
            let double = 20.05
            let optionalString: String? = "some"
            let bool = true
        }

        let encoder = DynamoEncoder()
        let result = try encoder.encode(TestModel())
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result["string"]!.s!, "foo")
        XCTAssertEqual(result["int"]!.n!, "1")
        XCTAssertEqual(result["double"]!.n!, "20.05")
        XCTAssertEqual(result["optionalString"]!.s!, "some")
        XCTAssertEqual(result["bool"]!.bool!, true)

    }


    func testArrayEncoding() throws {
        struct TestModel: Codable {
            let strings = ["foo", "bar"]
            let numbers = [1, 2, 3, 4]
            let doubles = [1.0, 2.0, 2.5]
        }

        let encoder = DynamoEncoder()
        let result = try encoder.encode(TestModel())
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["strings"]?.ss, ["foo", "bar"])
        XCTAssertEqual(result["numbers"]?.ns, ["1", "2", "3", "4"])
        XCTAssertEqual(result["doubles"]?.ns, ["1.0", "2.0", "2.5"])

    }

    func testSimpleNestedCodable() throws {
        struct Foo: Codable {
            let name = "Foo"
        }

        struct Bar: Codable {
            let foo = Foo()
            let number = 1
        }

        let encoder = DynamoEncoder()
        let result = try encoder.encode(Bar())

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["number"]?.n, "1")
        XCTAssertNotNil(result["foo"]?.m)
        let map = result["foo"]!.m!
        let expectted = ["name": "Foo"]
        let mapResult = [map.first!.key: map.first!.value.s!]
        XCTAssertEqual(mapResult, expectted)

    }
}

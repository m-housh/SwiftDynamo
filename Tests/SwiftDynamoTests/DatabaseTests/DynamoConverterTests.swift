//
//  File.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import XCTest
import DynamoDB
@testable import SwiftDynamo


final class DynamoConverterTests: XCTestCase {

    func testSimpleEncoding() throws {
        struct TestModel: Codable {
            let string = "foo"
            let int = 1
            let double = 20.05
            let optionalString: String? = "some"
            let optionalNil: String? = nil
            let bool = true
            let int8 = Int8(exactly: 8.0)!
            let int16 = Int16(exactly: 16.0)!
            let int32 = Int32(exactly: 32.0)!
            let int64 = Int64(exactly: 64.0)!
            let uInt = UInt(exactly: 1.0)!
            let uInt8 = UInt8(exactly: 8.0)!
            let uInt16 = UInt16(exactly: 16.0)!
            let uInt32 = UInt32(exactly: 32.0)!
            let uInt64 = UInt64(exactly: 64.0)!
            let float = Float(exactly: 10.0)!
            let dictionary = ["Foo": 1, "Bar": 2]
        }

        let result = try DynamoConverter().convert(TestModel())
        XCTAssertEqual(result.count, 16)
        XCTAssertEqual(result["string"]!.s!, "foo")
        XCTAssertEqual(result["int"]!.n!, "1")
        XCTAssertEqual(result["double"]!.n!, "20.05")
        XCTAssertEqual(result["optionalString"]!.s!, "some")
        XCTAssertEqual(result["bool"]!.bool!, true)
        XCTAssertEqual(result["int8"]!.n!, "8")
        XCTAssertEqual(result["int16"]!.n!, "16")
        XCTAssertEqual(result["int32"]!.n!, "32")
        XCTAssertEqual(result["int64"]!.n!, "64")
        XCTAssertEqual(result["uInt"]!.n!, "1")
        XCTAssertEqual(result["uInt8"]!.n!, "8")
        XCTAssertEqual(result["uInt16"]!.n!, "16")
        XCTAssertEqual(result["uInt32"]!.n!, "32")
        XCTAssertEqual(result["uInt64"]!.n!, "64")
        XCTAssertEqual(result["float"]!.n!, "10.0")
        XCTAssertEqual(result["dictionary"]!.m!["Foo"]!.n, "1")
        XCTAssertEqual(result["dictionary"]!.m!["Bar"]!.n, "2")

    }


    func testArrayEncoding() throws {
        struct TestModel: Codable {
            let strings = ["foo", "bar"]
            let numbers = [1, 2, 3, 4]
            let doubles = [1.0, 2.0, 2.5]
            let emptyStrings: [String] = []
            let int8 = [Int8(exactly: 8.0)!]
            let int16 = [Int16(exactly: 16.0)!]
            let int32 = [Int32(exactly: 32.0)!]
            let int64 = [Int64(exactly: 64.0)!]
            let uInt = [UInt(exactly: 1.0)!]
            let uInt8 = [UInt8(exactly: 8.0)!]
            let uInt16 = [UInt16(exactly: 16.0)!]
            let uInt32 = [UInt32(exactly: 32.0)!]
            let uInt64 = [UInt64(exactly: 64.0)!]
            let float = [Float(exactly: 10.0)!]
        }

        let result = try DynamoConverter().convert(TestModel())
        XCTAssertEqual(result.count, 14)
        XCTAssertEqual(result["strings"]?.ss, ["foo", "bar"])
        XCTAssertEqual(result["numbers"]?.ns, ["1", "2", "3", "4"])
        XCTAssertEqual(result["doubles"]?.ns, ["1.0", "2.0", "2.5"])
        // empty arrays get avoided.
        XCTAssertEqual(result["emptStrings"]?.ss, nil)
        XCTAssertEqual(result["int8"]!.ns!, ["8"])
        XCTAssertEqual(result["int16"]!.ns!, ["16"])
        XCTAssertEqual(result["int32"]!.ns!, ["32"])
        XCTAssertEqual(result["int64"]!.ns!, ["64"])
        XCTAssertEqual(result["uInt"]!.ns!, ["1"])
        XCTAssertEqual(result["uInt8"]!.ns!, ["8"])
        XCTAssertEqual(result["uInt16"]!.ns!, ["16"])
        XCTAssertEqual(result["uInt32"]!.ns!, ["32"])
        XCTAssertEqual(result["uInt64"]!.ns!, ["64"])
        XCTAssertEqual(result["float"]!.ns!, ["10.0"])

    }

    func testSimpleNestedCodable() throws {
        struct Foo: Codable {
            let name = "Foo"
        }

        struct Bar: Codable {
            let foo = Foo()
            let number = 1
        }

        let result = try DynamoConverter().convert(Bar())

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["number"]?.n, "1")
        XCTAssertNotNil(result["foo"]?.m)
        let map = result["foo"]!.m!
        let expectted = ["name": "Foo"]
        let mapResult = [map.first!.key: map.first!.value.s!]
        XCTAssertEqual(mapResult, expectted)

    }

    func testEncodingArrayOfEncodables() throws {
        struct TestObject: Codable {
            let name: String = "Foo"
            let number: Int
        }

        let items = [TestObject(number: 1), TestObject(number: 2), TestObject(number: 3)]
        let result = try DynamoConverter().convert(items)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0]["name"]?.s, "Foo")
        XCTAssertEqual(result[0]["number"]?.n, "1")
        XCTAssertEqual(result[1]["name"]?.s, "Foo")
        XCTAssertEqual(result[1]["number"]?.n, "2")
        XCTAssertEqual(result[2]["name"]?.s, "Foo")
        XCTAssertEqual(result[2]["number"]?.n, "3")
    }

    func testSingleValueEncoding() throws {
        let encoder = DynamoConverter()
        XCTAssertEqual(try encoder.convertToAttribute("foo").s, "foo")
        XCTAssertEqual(try encoder.convertToAttribute(1).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(1.0).n, "1.0")
        XCTAssertEqual(try encoder.convertToAttribute(false).bool, false)
        XCTAssertEqual(try encoder.convertToAttribute(["foo", "bar"]).ss, ["foo", "bar"])
        XCTAssertEqual(try encoder.convertToAttribute([1, 2]).ns, ["1", "2"])
        let map = try encoder.convertToAttribute(["foo": "bar"]).m!
        XCTAssertEqual(map["foo"]?.s, "bar")
        XCTAssertEqual(try encoder.convertToAttribute(UInt(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(UInt8(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(UInt16(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(UInt32(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(UInt64(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(Int8(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(Int16(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(Int32(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(Int64(exactly: 1.0)!).n, "1")
        XCTAssertEqual(try encoder.convertToAttribute(Float(exactly: 1.0)!).n, "1.0")
    }

    func testWithCustomEncodable() throws {
        struct TestCustom: Codable {
            let foo = "Foo"
            let bar = "Bar"

            enum CodingKeys: String, CodingKey {
                case bar = "BarKey"
                case foo = "FooKey"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(foo, forKey: .foo)
                try container.encode(bar, forKey: .bar)
            }
        }

        let result = try DynamoConverter().convert(TestCustom())
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["BarKey"]?.s, "Bar")
        XCTAssertEqual(result["FooKey"]?.s, "Foo")
    }
}

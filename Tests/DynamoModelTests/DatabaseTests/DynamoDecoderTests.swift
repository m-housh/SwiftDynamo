//
//  DynamoDecoderTests.swift
//  
//
//  Created by Michael Housh on 1/19/20.
//

import XCTest
import DynamoDB
@testable import DynamoModel

final class DynamoDecoderTests: XCTestCase {

    func testPrimitiveDecoding() throws {
        let encoded = try JSONEncoder().encode(1)
        let decoded = try DynamoDecoder().decode(Int.self, from: encoded)
        XCTAssertEqual(decoded, 1)
    }

    func testSimpleDecoding() throws {
        struct Simple: Codable, Equatable {
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
            let dict: [String: Int] = ["foo": 1, "bar": 2]
        }

        let dictionary = try DynamoEncoder().encode(Simple())
        let decoded = try DynamoDecoder().decode(Simple.self, from: dictionary)

        XCTAssertEqual(decoded, Simple())

        struct NestedSimple: Codable, Equatable {
            let simple = Simple()
            let dictionary = ["simple": Simple()]
        }

        let nestedEncoded = try DynamoEncoder().encode(NestedSimple())
        let nestedDecoded = try DynamoDecoder().decode(NestedSimple.self, from: nestedEncoded)
        XCTAssertEqual(nestedDecoded, NestedSimple())
    }

    func testArrayDecoding() throws {
        struct TestModel: Codable, Equatable {
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

        let encoded = try DynamoEncoder().encode(TestModel())
        let decoded = try DynamoDecoder().decode(TestModel.self, from: encoded)

        XCTAssertEqual(decoded, TestModel())

        let multiEncoded = try DynamoEncoder().encode([TestModel(), TestModel(),  TestModel()])
        let multiDecoded = try DynamoDecoder().decode([TestModel].self, from: multiEncoded)

        XCTAssertEqual(multiDecoded, [TestModel(), TestModel(),  TestModel()])

    }

    func testSimpleNestedCodable() throws {
        struct Foo: Codable, Equatable {
            let name = "Foo"
        }

        struct Bar: Codable, Equatable {
            let foo = Foo()
            let number = 1
        }

        let encoded = try DynamoEncoder().encode(Bar())
        let decoded = try DynamoDecoder().decode(Bar.self, from: encoded)

        XCTAssertEqual(decoded, Bar())
    }

    func testWithCustomDecodable() throws {
        struct TestCustom: Codable, Equatable {
            let foo: String
            let bar: String

            init(foo: String = "Foo", bar: String = "Bar") {
                self.foo = foo
                self.bar = bar
            }

            enum CodingKeys: String, CodingKey {
                case bar = "BarKey"
                case foo = "FooKey"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let fooString = try container.decode(String.self, forKey: .foo)
                let barString = try container.decode(String.self, forKey: .bar)
                self.init(foo: fooString, bar: barString)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(foo, forKey: .foo)
                try container.encode(bar, forKey: .bar)
            }
        }

        let encoded = try DynamoEncoder().encode(TestCustom(foo: "Bar", bar: "Foo"))
        let decoded = try DynamoDecoder().decode(TestCustom.self, from: encoded)
        XCTAssertEqual(decoded, TestCustom(foo: "Bar", bar: "Foo"))
    }

    func testSingleValueDecoding() {
        let decoder = DynamoDecoder()
        XCTAssertEqual(try decoder.decode(Bool.self, from: DynamoDB.AttributeValue(bool: false)), false)
        XCTAssertEqual(try decoder.decode(String.self, from: DynamoDB.AttributeValue(s: "foo")), "foo")
        XCTAssertEqual(try decoder.decode(Int.self, from: DynamoDB.AttributeValue(n: "1")), 1)
        XCTAssertEqual(try decoder.decode(Float.self, from: DynamoDB.AttributeValue(n: "1.0")), 1.0)
        XCTAssertEqual(try decoder.decode(Double.self, from: DynamoDB.AttributeValue(n: "4.56")), 4.56)
        XCTAssertEqual(try decoder.decode(Int8.self, from: DynamoDB.AttributeValue(n: "10")), 10)
        XCTAssertEqual(try decoder.decode(Int16.self, from: DynamoDB.AttributeValue(n: "11")), 11)
        XCTAssertEqual(try decoder.decode(Int32.self, from: DynamoDB.AttributeValue(n: "12")), 12)
        XCTAssertEqual(try decoder.decode(Int64.self, from: DynamoDB.AttributeValue(n: "13")), 13)
        XCTAssertEqual(try decoder.decode(UInt8.self, from: DynamoDB.AttributeValue(n: "13")), 13)
        XCTAssertEqual(try decoder.decode(UInt32.self, from: DynamoDB.AttributeValue(n: "13")), 13)
        XCTAssertEqual(try decoder.decode(UInt64.self, from: DynamoDB.AttributeValue(n: "13")), 13)
        XCTAssertEqual(try decoder.decode(UInt16.self, from: DynamoDB.AttributeValue(n: "13")), 13)
        XCTAssertEqual(try decoder.decode(UInt.self, from: DynamoDB.AttributeValue(n: "13")), 13)
    }

    func testKeyedDecoding() throws {
        struct TestCodable: Codable, Equatable {
            let foo: String = "Foo"
        }

        let input: [String: Any] = [
            "string": "foo",
            "bool": false,
            "int": 1,
            "double": 1.0,
            "float": Float(exactly: 13.0)!,
            "int8": Int8(exactly: 8.0)!,
            "int16": Int16(exactly: 16.0)!,
            "int32": Int32(exactly: 32.0)!,
            "int64": Int64(exactly: 64.0)!,
            "uInt": UInt(exactly: 1.0)!,
            "uInt8": UInt8(exactly: 8.0)!,
            "uInt16": UInt16(exactly: 16.0)!,
            "uInt32": UInt32(exactly: 32.0)!,
            "uInt64": UInt64(exactly: 64.0)!,
            "dict": ["foo": 1, "bar": 2],
            "nestedDict": ["foo": ["bing": "bam"], "bar": ["baz": "boom"]],
            "codable": TestCodable(),
            "stringArray": ["foo", "bar", "baz", "boom"],
            "nestedArrays": [["foo"], ["bar", "baz"], ["bing", "boom"]]
        ]
        let topDecoder = _DynamoDecoder(referencing: input)
        let keyedDecoder = try topDecoder.container(keyedBy: _DynamoCodingKey.self)
        XCTAssertEqual(keyedDecoder.allKeys.count, 19)
        XCTAssert(keyedDecoder.contains(.string("string")))
        XCTAssertEqual(try keyedDecoder.decode(String.self, forKey: .string("string")), "foo")
        XCTAssertEqual(try keyedDecoder.decode(Bool.self, forKey: .string("bool")), false)
        XCTAssertEqual(try keyedDecoder.decode(Int.self, forKey: .string("int")), 1)
        XCTAssertEqual(try keyedDecoder.decode(Double.self, forKey: .string("double")), 1.0)
        XCTAssertEqual(try keyedDecoder.decode(Float.self, forKey: .string("float")), 13.0)
        XCTAssertEqual(try keyedDecoder.decode(Int8.self, forKey: .string("int8")), 8)
        XCTAssertEqual(try keyedDecoder.decode(Int16.self, forKey: .string("int16")), 16)
        XCTAssertEqual(try keyedDecoder.decode(Int32.self, forKey: .string("int32")), 32)
        XCTAssertEqual(try keyedDecoder.decode(Int64.self, forKey: .string("int64")), 64)
        XCTAssertEqual(try keyedDecoder.decode(UInt.self, forKey: .string("uInt")), 1)
        XCTAssertEqual(try keyedDecoder.decode(UInt8.self, forKey: .string("uInt8")), 8)
        XCTAssertEqual(try keyedDecoder.decode(UInt16.self, forKey: .string("uInt16")), 16)
        XCTAssertEqual(try keyedDecoder.decode(UInt32.self, forKey: .string("uInt32")), 32)
        XCTAssertEqual(try keyedDecoder.decode(UInt64.self, forKey: .string("uInt64")), 64)
        XCTAssertEqual(try keyedDecoder.decode([String: Int].self, forKey: .string("dict")), ["foo": 1, "bar": 2])
        XCTAssertEqual(try keyedDecoder.decode([String: [String: String]].self, forKey: .string("nestedDict")), ["foo": ["bing": "bam"], "bar": ["baz": "boom"]])
        XCTAssertEqual(try keyedDecoder.decode(TestCodable.self, forKey: .string("codable")), TestCodable())
        XCTAssertEqual(try keyedDecoder.decode([String].self, forKey: .string("stringArray")), ["foo", "bar", "baz", "boom"])
        XCTAssertEqual(try keyedDecoder.decode([[String]].self, forKey: .string("nestedArrays")), [["foo"], ["bar", "baz"], ["bing", "boom"]])

        // Error throwing
        XCTAssertThrowsError(try keyedDecoder.decode(String.self, forKey: .string("int")))
        XCTAssertThrowsError(try keyedDecoder.decode(Bool.self, forKey: .string("int")))
        XCTAssertThrowsError(try keyedDecoder.decode(Double.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(Float.self, forKey: .string("dict")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int8.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int16.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int32.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int64.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt8.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt16.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt32.self, forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt64.self, forKey: .string("string")))

        // Invalid key
        XCTAssertThrowsError(try keyedDecoder.decode(String.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Bool.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Double.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Float.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int8.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int16.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int32.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(Int64.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt8.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt16.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt32.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(UInt64.self, forKey: .string("foo")))
        XCTAssertThrowsError(try keyedDecoder.decode(TestCodable.self, forKey: .string("foo")))

        XCTAssertFalse(try keyedDecoder.decodeNil(forKey: .string("string")))
        XCTAssertThrowsError(try keyedDecoder.decodeNil(forKey: .string("foo")))
    }

    func unkeyedDecoderTests() throws {
        let input: [Any] = [
            "foo",
            false,
            1,
            3.0,
            Float(exactly: 13.0)!,
            Int8(exactly: 8.0)!,
            Int16(exactly: 16.0)!,
            Int32(exactly: 32.0)!,
            Int64(exactly: 64.0)!,
            UInt(exactly: 1.0)!,
            UInt8(exactly: 8.0)!,
            UInt16(exactly: 16.0)!,
            UInt32(exactly: 32.0)!,
            UInt64(exactly: 64.0)!,
            ["foo": 1, "bar": 2],
            ["foo": ["bing": "bam"], "bar": ["baz": "boom"]],
        ]

        let topDecoder = _DynamoDecoder(referencing: input)
        var unkeyedDecoder = try topDecoder.unkeyedContainer() as! _UnkeyedDecoder
        XCTAssertEqual(try unkeyedDecoder.decode(String.self), "foo")
        XCTAssertEqual(try unkeyedDecoder.decode(Bool.self), false)
        XCTAssertEqual(try unkeyedDecoder.decode(Int.self), 1)
        XCTAssertEqual(try unkeyedDecoder.decode(Double.self), 3.0)
        XCTAssertEqual(try unkeyedDecoder.decode(Float.self), 13.0)
        XCTAssertEqual(try unkeyedDecoder.decode(Int8.self), 8)
        XCTAssertEqual(try unkeyedDecoder.decode(Int16.self), 16)
        XCTAssertEqual(try unkeyedDecoder.decode(Int32.self), 32)
        XCTAssertEqual(try unkeyedDecoder.decode(Int64.self), 64)
        XCTAssertEqual(try unkeyedDecoder.decode(UInt.self), 1)
        XCTAssertEqual(try unkeyedDecoder.decode(UInt8.self), 8)
        XCTAssertEqual(try unkeyedDecoder.decode(UInt16.self), 16)
        XCTAssertEqual(try unkeyedDecoder.decode(UInt32.self), 32)
        XCTAssertEqual(try unkeyedDecoder.decode(UInt64.self), 64)
        XCTAssertEqual(try unkeyedDecoder.decode([String: Int].self), ["foo": 1, "bar": 2])
        XCTAssertEqual(try unkeyedDecoder.decode([String: [String: String]].self), ["foo": ["bing": "bam"], "bar": ["baz": "boom"]])
        // throws when done decoding all it's items.
        XCTAssertThrowsError(try unkeyedDecoder.decode(String.self))

        // Decode an invalid type at current index.
        var unkeyedDecoder2 = try topDecoder.unkeyedContainer()
        XCTAssertThrowsError(try unkeyedDecoder2.decode(Bool.self))

    }

    func testDecodeData() throws {
        struct Simple: Codable, Equatable {
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
            let dict: [String: Int] = ["foo": 1, "bar": 2]
        }

        let encoded = try DynamoEncoder().encode(Simple())
        let decoded = try DynamoDecoder().decode(Simple.self, from: encoded)
        XCTAssertEqual(decoded, Simple())

        let arrayEncoded = try DynamoEncoder().encode([Simple(), Simple(), Simple()])
        let decodedArray = try DynamoDecoder().decode([Simple].self, from: arrayEncoded)
        XCTAssertEqual(decodedArray, [Simple(), Simple(), Simple()])

        let simpleData = try DynamoEncoder().encode(1)
        XCTAssertEqual(try DynamoDecoder().decode(Int.self, from: simpleData), 1)
    }
}

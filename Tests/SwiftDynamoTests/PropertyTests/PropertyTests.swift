//
//  PropertyTests.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//

import XCTest
@testable import SwiftDynamo

final class PropertyTests: XCTestCase {

    func testFieldOutputFails() {
        let field = Field<String>(key: "Foo")
        XCTAssertThrowsError(
            try field.output(from: .init(database: .testing, output: .dictionary(["Foo" : .init(null: true)])))
        )
    }

    func testFieldAttributeValue() {
        let field = Field<String>(key: "bar")
        XCTAssertNil(try! field.attributeValue())
        field.wrappedValue = "foo"
        XCTAssertEqual(try! field.attributeValue()!.s, "foo")
    }

    func testDecodeOptionalType() {
        let field = Field<Int?>(key: "int")
        let optional: Int? = nil
        let decoder = _DynamoDecoder(referencing: optional as Any)
        try! field.decode(from: decoder)
    }

    func testIDGeneratorDoesNothingForUserType() {
        let id = ID<String>(key: "foo", generatedBy: .user)
        XCTAssertNil(id.inputValue)
        id.generate()
        XCTAssertNil(id.inputValue)

        let generated = ID<UUID>(key: "bar")
        XCTAssertNil(generated.inputValue)
        generated.generate()
        XCTAssertNotNil(generated.inputValue)
    }

    func testSortKeyCodable() {
        let sortKey = SortKey<String>(key: "Foo")
        sortKey.wrappedValue = "bar"
        let encoder = _DynamoEncoder()
        try! sortKey.encode(to: encoder)

        let decoder = _DynamoDecoder(referencing: "notBar")
        try! sortKey.decode(from: decoder)
        XCTAssertEqual(sortKey.wrappedValue, "notBar")

        let output = DatabaseOutput.init(database: .testing, output: .dictionary(["Foo": .init(s: "boom")]))
        try! sortKey.output(from: output)
        XCTAssertEqual(sortKey.wrappedValue, "boom")

        XCTAssertEqual(sortKey.key, "Foo")
    }
}

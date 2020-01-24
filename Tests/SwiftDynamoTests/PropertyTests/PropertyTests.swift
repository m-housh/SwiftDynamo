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

    func testAnyFieldPassesToWrappedField() {
        let model = TestModel()
        let anyField = model._$id as AnyField
        XCTAssertEqual(anyField.key, "TodoID")
        XCTAssertNil(anyField.inputValue)
        XCTAssertEqual(anyField.partitionKey, false)
        XCTAssertEqual(anyField.sortKey, true)
        let id = UUID.generateRandom()
        anyField.inputValue = .bind(id)
        let attributeValue = try! anyField.attributeValue()
        XCTAssertEqual(id.uuidString, attributeValue!.s!)
    }

    func testAnyPropertyPassesToWrappedField() throws {
        let model = TestModel()
        model.id = .init()
        let anyProperty = model.$id as AnyProperty
        try anyProperty.encode(to: _DynamoEncoder())
        try anyProperty.decode(from: _DynamoDecoder(referencing: "\(model.id!)"))
    }

    func testDefaultGeneratorForIDIsSetToUser() {
        let id = ID<Int>(key: "Foo")
        XCTAssertEqual(id.generator, .user)
        XCTAssertEqual(ID<String>.Generator.default(for: String.self), .user)
        XCTAssertEqual(ID<UUID>.Generator.default(for: UUID.self), .random)
    }

    func testAnyModelHasChangesAttribute() {
        let model = TestModel()
        XCTAssertFalse(model.hasChanges)
        model.id = .init()
        XCTAssertTrue(model.hasChanges)
    }

    func testAnyModelWithNonFields() {
        final class ModelWithExtras: DynamoModel {

            static var schema: DynamoSchema = "FooBar"

            @ID(key: "Foo")
            var id: Int?

            @Field(key: "Bar")
            var bar: String

            var dummy = DummyProperty()

            var extra: Bool = false

            init() { }

            class DummyProperty: AnyProperty {
                func encode(to encoder: Encoder) throws {
                    fatalError()
                }

                func decode(from decoder: Decoder) throws {
                    fatalError()
                }

                func output(from output: DatabaseOutput) throws {
                    fatalError()
                }

                init() { }
            }
        }

        let properties = ModelWithExtras().properties
        XCTAssert(!properties.contains(where: { $0.0 == "extra" }))

        let fields = ModelWithExtras().fields
        XCTAssert(!fields.contains(where: { $0.0 == "dummy" }))

    }
}

//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import XCTest
import DynamoDB
@testable import SwiftDynamo

final class DynamoQueryTests: XCTestCase {

    func testFieldKey() {
        let fieldKey = DynamoQuery.Filter.FieldFilterKey.init("foo", isPartitionKey: false, isSortKey: true)
        XCTAssertEqual(fieldKey.key, "foo")
        XCTAssertEqual(fieldKey.isPartitionKey, false)
        XCTAssertEqual(fieldKey.isSortKey, true)

    }

    func testAnyBindableOnOptional() {
        let some = try! (Optional<String>.some("Foo") as AnyBindable).convertToAttribute()
        XCTAssertEqual(some.s!, "Foo")
        let none = try! (Optional<String>.none as AnyBindable).convertToAttribute()
        XCTAssertEqual(none.null, true)
    }

    func testAddFilterExpression() {
        var options = DynamoQuery.OptionsContainer()
        options.addFilterExpression("foo", .equal, "bar")
        options.addFilterExpression("baz", .equal, "boom")
        XCTAssertEqual(options.filterExpression!, "foo = bar and baz = boom")
    }

    func testOptionsFromQuery() {
        var query = DynamoQuery(schema: "foo")
        query.options.append(.expressionAttributeValues([":foo": .init(s: "baz")]))
        query.filters.append(.field(.init("foo", isPartitionKey: false, isSortKey: false), .equal, .bind("bar")))
        let container = query.optionsContainer
        XCTAssertEqual(container.expressionAttributeValues![":foo"]!.s, "bar")
    }

    func testSchemaSetsSortAndPartitionKey() {
        let query = DynamoQuery(schema: DynamoSchema("foo", partitionKey: .init(key: "fooID", default: "bar"), sortKey: .init(key: "bazID", default: "boom")))

        XCTAssertNotNil(query.sortKey)
        XCTAssertNotNil(query.partitionKey)

        XCTAssertEqual(query.sortKey!.0, "bazID")
        XCTAssertEqual(query.partitionKey!.0, "fooID")
    }
}

//
//  QueryBuilderTests.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import XCTest
import DynamoDB
@testable import SwiftDynamo

final class QueryBuilderTests: XCTestCase {

    let database = DynamoDB.testing

    func testSetOptions() {
        let builder = TestModel
            .query(on: database)
            .setOption(.limit(1))
            .setOption(.consistentRead(true))
            .setOption(.exclusiveStartKey(["foo": .init(s: "bar")]))
            .setOption(.expressionAttributeNames(["bar": "boom"]))
            .setOption(.expressionAttributeValues(["bar": .init(s: "bing")]))
            .setOption(.filterExpression("filtering"))
            .setOption(.indexName("index"))
            .setOption(.keyConditionExpression("key-condition"))
            .setOption(.keyConditions(["foo": .init(comparisonOperator: .eq)]))
            .setOption(.projectionExpression("project"))
            .setOption(.queryFilter(["foo": .init(comparisonOperator: .eq)]))
            .setOption(.returnConsumedCapacity(.none))
            .setOption(.scanIndexForward(true))
            .setOption(.select(.allAttributes))
            .setOption(.conditionalOperator(.and))
            .setOption(.conditionExpression("boom"))
            .setOption(.returnItemCollectionMetrics(.size))

        let options = builder.query.optionsContainer

        XCTAssertEqual(options.limit!, 1)
        XCTAssertEqual(options.consistentRead!, true)
        XCTAssertEqual(options.exclusiveStartKey!["foo"]!.s, "bar" )
        XCTAssertEqual(options.expressionAttributeNames!["bar"], "boom")
        XCTAssertEqual(options.expressionAttributeValues!["bar"]!.s, "bing")
        XCTAssertEqual(options.filterExpression!, "filtering")
        XCTAssertEqual(options.indexName!, "index")
        XCTAssertEqual(options.keyConditionExpression!, "key-condition")
        XCTAssertEqual(options.keyConditions!["foo"]!.comparisonOperator, .eq)
        XCTAssertEqual(options.projectionExpression!, "project")
        XCTAssertEqual(options.queryFilter!["foo"]?.comparisonOperator, .eq)
        XCTAssertEqual(options.returnConsumedCapacity!, .none)
        XCTAssertEqual(options.scanIndexForward!, true)
        XCTAssertEqual(options.select!, .allAttributes)
        XCTAssertEqual(options.conditionalOperator!, .and)
        XCTAssertEqual(options.conditionExpression!, "boom")
        XCTAssertEqual(options.returnItemCollectionMetrics!, .size)
    }

    func testQueryMethods() {
        let builder = TestModel
            .query(on: .testing)
            .limit(1)

        XCTAssertEqual(builder.query.options.count, 2)
    }

    func testQueryBuilderWithSortKeyReference() {
        final class ModelWithSortKey: DynamoModel {

            static var schema: DynamoSchema = "ModelWithSortKey"

            @ID(key: "ID")
            var id: Int?

            @SortKey(key: "SortKey")
            var sortKey: String

            init() { }

        }

        let builder = ModelWithSortKey
            .query(on: .testing)
            .setSortKey(\.$sortKey, to: "foo")

        XCTAssertNotNil(builder.query.sortKey)
        XCTAssertEqual(builder.query.sortKey!.0, "SortKey")
        XCTAssertEqual(try! builder.query.sortKey!.1.attributeValue().s, "foo")

    }

}

//
//  QueryBuilderTests.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import XCTest
import DynamoDB
@testable import DynamoModel

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

        XCTAssertEqual(builder.query.options.count, 1)
    }

    func testQueryBuilderWithSortKeyReference() {
//        let builder = TestModel
//            .query(on: .testing)
//            .sortKey(\TestModel.$sortKey)
    }

    func testFetchAll() throws {
        do {
            let models = try TestModel
                .query(on: database)
                .all()
                .wait()
            XCTAssert(models.count > 0)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testFirst() throws {
        let model = try TestModel
            .query(on: database)
            .first()
            .wait()

        XCTAssertNotNil(model)
    }

    func testCreate() throws {
        do {
            let model = TestModel()
            model.completed = false
            model.title = "Test Create"
            model.order = 2

            let saved = try model.save(on: database).wait()
            XCTAssertNotNil(saved.id)
            XCTAssertEqual(saved.title, "Test Create")
            XCTAssertFalse(saved.completed)
            XCTAssertEqual(saved.order, 2)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testUpdate() throws {
        do {
            let model = try TestModel.query(on: database).first().wait()!
            model.title = "Updated"

            let saved = try model.save(on: database).wait()
            XCTAssertEqual(saved.title, "Updated")
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testFindID() throws {
        do {
            let model = try TestModel.query(on: database).first().wait()!
            let fetched = try TestModel.find(id: model.id!, on: database).wait()!
            XCTAssertEqual(model, fetched)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testDeleteID() throws {
        do {
            let models = try TestModel.query(on: database).all().wait()
            try TestModel.delete(id: models[0].id!, on: database).wait()
            let after = try TestModel.query(on: database).all().wait()
            XCTAssertEqual(models.count - 1, after.count)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }
}

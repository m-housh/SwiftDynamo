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
            model.sortKey = "list"
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
}

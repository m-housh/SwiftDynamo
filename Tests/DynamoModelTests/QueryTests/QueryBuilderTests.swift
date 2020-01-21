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

    func testQueryMethods() {
        let builder = TestModel
            .query(on: .testing)
//            .sortKey("foo")
            .limit(1)

//        XCTAssertEqual(builder.query.sortKey!.key, "foo")
        XCTAssertEqual(builder.query.limit!, 1)
    }

    func testQueryBuilderWithSortKeyReference() {
//        let builder = TestModel
//            .query(on: .testing)
//            .sortKey(\TestModel.$sortKey)
    }
}

//
//  DynamoDatabaseTests.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import XCTest
@testable import SwiftDynamo

final class DynamoDatabaseTests: XCTestCase {

    func testDatabaseSchemaTests() {
        let fromString: DynamoSchema = "foo"
        let explicit = DynamoSchema("foo")
        XCTAssertEqual(fromString, explicit)

        let withSortKey = DynamoSchema("foo", sortKey: .init(key: "SortID", default: "bar"))
        let withSortKey2 = DynamoSchema("foo", sortKey: .init(key: "SortID", default: "bar"))
        XCTAssertNotEqual(fromString, withSortKey)
        XCTAssertEqual(withSortKey, withSortKey2)

    }
}

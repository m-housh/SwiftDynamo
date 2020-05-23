//
//  AttributeConvertibleTests.swift
//  
//
//  Created by Michael Housh on 5/23/20.
//

import XCTest
@testable import SwiftDynamo

final class AttributeConvertibleTests: XCTestCase {

    let tableName = "TodoTest"
    let database = DynamoDB.testing

    func test_AttributeConvertible_query() throws {
        let sut1 = try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .all()
            .wait()
        XCTAssertEqual(sut1.count, 0)
    }

    func test_AttributeConvertible_save() throws {
        let newitem = AttributeConvertibleTestModel(id: .init(), title: "test", order: nil, completed: true)
        try AttributeConvertibleTestModel
            .query(DynamoSchema(tableName), on: database)
            .set(newitem)
            .create()
            .wait()

        let sut1 = try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .all()
            .wait()

        XCTAssertEqual(sut1.count, 1)

        try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .setSortKey(sortKey: "TodoID", to: newitem.id)
            .setPartitionKey(partitionKey: "ListID", to: "list")
            .delete()
            .wait()
    }

    func test_AttributeConvertibal_save_as_array() throws {
        let items = [
            AttributeConvertibleTestModel(id: .init(), title: "one", order: 1, completed: true),
            AttributeConvertibleTestModel(id: .init(), title: "two", order: 2, completed: false)
        ]

        let sut1 = try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .all()
            .wait()

        XCTAssertEqual(sut1.count, 0)

        try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .set(items)
            .setAction(to: .batchCreate)
            .run()
            .wait()

        let sut2 = try AttributeConvertibleTestModel
            .query(tableName, on: database)
            .all()
            .wait()

        XCTAssertEqual(sut2.count, 2)

        for item in items {
            try AttributeConvertibleTestModel
                .query(tableName, on: database)
                .setSortKey(sortKey: "TodoID", to: item.id)
                .setPartitionKey(partitionKey: "ListID", to: "list")
                .delete()
                .wait()
        }
    }
}

extension AttributeConvertibleTests {

    struct AttributeConvertibleTestModel: Codable, Equatable {
        var id: UUID
        var title: String
        var order: Int?
        var completed: Bool
    }
}

extension AttributeConvertibleTests.AttributeConvertibleTestModel: AttributeConvertible {

    init(from output: [String : DynamoDB.AttributeValue]) throws {
        guard let idString = output["TodoID"]?.s,
            let id = UUID(uuidString: idString),
            let title = output["Title"]?.s,
            let completed = output["Completed"]?.bool else {
                throw AttributeError.invalidAttribute
        }
        self.id = id
        self.title = title
        self.completed = completed
        if let orderString = output["Order"]?.n {
            self.order = Int(orderString)
        }
    }

    func encode() -> [String : DynamoQuery.Value] {
        var encoded = [
            "TodoID": id.description.queryValue,
            "Title": title.queryValue,
            "Completed": completed.queryValue,
            "ListID": "list".queryValue
        ]
        if let strongOrder = self.order {
            encoded["Order"] = strongOrder.queryValue
        }
        return encoded
    }
}

enum AttributeError: Error {
    case invalidAttribute
}

//
//  Helpers.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoModel
import DynamoDB

final class TestModel: DynamoModel, Equatable, Codable {

    static var schema: DynamoSchema = "TestDynamoModel"

    @ID(key: "TestID")
    var id: UUID

    @SortKey(key: "TestSortID")
    var sortKey: String

    @Field(key: "TestString")
    var string: String

    @Field(key: "TestInt")
    var int: Int

    init() { }

    static func ==(lhs: TestModel, rhs: TestModel) -> Bool {
        lhs.id == rhs.id &&
            lhs.sortKey == rhs.sortKey &&
            lhs.string == rhs.string &&
            lhs.int == rhs.int
    }
}

extension DynamoDB {

    static var testing: DynamoDB {
        .init()
    }
}

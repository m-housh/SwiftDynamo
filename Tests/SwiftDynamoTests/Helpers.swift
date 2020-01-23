//
//  Helpers.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import SwiftDynamo
import DynamoDB
import AWSSDKSwiftCore

final class TestModel: DynamoModel, Equatable, Codable, CustomStringConvertible {

    static var schema = DynamoSchema("TodoTest", partitionKey: .init(key: "ListID", default: "list"))

    @ID(key: "TodoID", type: .sortKey, generatedBy: .user)
    var id: UUID?

    @Field(key: "Title")
    var title: String

    @Field(key: "Order")
    var order: Int?

    @Field(key: "Completed")
    var completed: Bool

    init() { }

    init(id: UUID? = nil, title: String, completed: Bool = false, order: Int? = nil) {
        self.id = id
        self.title = title
        self.completed = completed
        self.order = order
    }

    static func ==(lhs: TestModel, rhs: TestModel) -> Bool {
        lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.order == rhs.order
    }

    var description: String {
        let idString = id?.uuidString ?? "not set"
        let orderString = order?.description ?? "nil"
        return "TestModel(id: \(idString), title: \(title), completed: \(completed), order: \(orderString))"
    }
}

extension DynamoDB {

    static var testing: DynamoDB {
        .init(
            accessKeyId: nil,
            secretAccessKey: nil,
            sessionToken: nil,
            region: Region(rawValue: "us-east-2"),
            endpoint: "http://localhost:8000",
            middlewares: [],
            eventLoopGroupProvider: .useAWSClientShared
        )
    }
}

struct PatchTodo: Codable {

    let title: String?
    let order: Int?
    let completed: Bool?

    func patchQuery(_ query: inout DynamoQueryBuilder<TestModel>) {

        if let title = self.title {
            query.set(\.$title, to: title)
        }

        if let order = self.order {
            query.set(\.$order, to: order)
        }

        if let completed = self.completed {
            query.set(\.$completed, to: completed)
        }
    }
}

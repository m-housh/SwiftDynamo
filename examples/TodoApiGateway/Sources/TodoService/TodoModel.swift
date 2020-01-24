//
//  TodoModel.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//

import Foundation
import SwiftDynamo

public final class TodoModel: DynamoModel {

    public static var schema: DynamoSchema {
        DynamoSchema(
            // the table name
            "SwiftLambdaTodo",
            // use a static partition key.
            partitionKey: .init(key: "ListID", default: "list")
        )
    }

    // MARK: - Properties
    @ID(key: "TodoID", generatedBy: .random)
    public var id: UUID?

    @Field(key: "Title")
    public var title: String

    @Field(key: "Order")
    public var order: Int?

    @Field(key: "Completed")
    public var completed: Bool

    // MARK: - Initialization
    public init() { }

    public init(id: UUID? = nil, title: String, completed: Bool = false, order: Int? = nil) {
        self.id = id
        self.title = title
        self.completed = completed
        self.order = order
    }
}

// MARK: - PatchTodo

public struct PatchTodo: Codable {
    var title: String?
    var order: Int?
    var completed: Bool?

    func patchQuery(query: inout DynamoQueryBuilder<TodoModel>) {
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

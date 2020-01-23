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
            "SwiftLambdaTodo",
            partitionKey: .init(key: "ListID", default: "list")
        )
    }

    @ID(key: "TodoID", generatedBy: .random)
    public var id: UUID?

    @Field(key: "Title")
    public var title: String

    @Field(key: "Order")
    public var order: Int?

    @Field(key: "Completed")
    public var completed: Bool

    public init() { }

    public init(id: UUID? = nil, title: String, completed: Bool = false, order: Int? = nil) {
        self.id = id
        self.title = title
        self.completed = completed
        self.order = order
    }
}

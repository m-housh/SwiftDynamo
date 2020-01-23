//
//  DynamoTodoStore.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//

import Foundation
import NIO
import DynamoDB

public struct DynamoTodoStore: TodoStore {

    let dynamoDB: DynamoDB

    public init(
        eventLoopGroup: EventLoopGroup,
        accessKeyId: String,
        secretAccessKey: String,
        sessionToken: String?,
        region: Region)
    {
        self.dynamoDB = DynamoDB(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: sessionToken,
            region: region,
            eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    public func getTodos() -> EventLoopFuture<[TodoModel]> {
        TodoModel.query(on: dynamoDB).all()
    }

    public func getTodo(id: UUID) -> EventLoopFuture<TodoModel> {
        TodoModel.find(id: id, on: dynamoDB)
            .flatMapThrowing { optional in
                guard let model = optional else {
                    throw TodoError.notFound
                }

                return model
            }
    }

    public func saveTodo(_ todo: TodoModel) -> EventLoopFuture<TodoModel> {
        todo.save(on: dynamoDB)
    }

    public func deleteTodo(id: UUID) -> EventLoopFuture<Void> {
        TodoModel.delete(id: id, on: dynamoDB)
    }

}

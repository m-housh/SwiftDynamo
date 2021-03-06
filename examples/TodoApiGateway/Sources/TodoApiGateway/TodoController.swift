//
//  TodoController.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//

import Foundation
import NIO
import NIOHTTP1
import LambdaRuntime
import TodoService

struct TodoController {

    let store: TodoStore

    static let sharedHeader = HTTPHeaders([
          ("Access-Control-Allow-Methods", "OPTIONS,GET,POST,DELETE"),
          ("Access-Control-Allow-Origin" , "*"),
          ("Access-Control-Allow-Headers", "Content-Type"),
          ("Server", "Swift on AWS Lambda"),
    ])

    init(store: TodoStore) {
        self.store = store
    }

    func listTodos(request: APIGateway.Request, context: Context) ->    EventLoopFuture<APIGateway.Response> {
        return self.store.getTodos()
            .flatMapThrowing { (items) -> APIGateway.Response in
                return try APIGateway.Response(
                    statusCode: .ok,
                    headers: TodoController.sharedHeader,
                    payload: items)
            }
    }

    func createTodo(request: APIGateway.Request, context: Context) ->   EventLoopFuture<APIGateway.Response> {
        let newTodo: TodoModel
        do {
            let payload = try request.decodeBody(TodoModel.self)
            newTodo = payload
        }
        catch {
            return context.eventLoop.makeFailedFuture(error)
        }

      return self.store.saveTodo(newTodo)
            .flatMapThrowing { (todo) -> APIGateway.Response in
                return try APIGateway.Response(
                    statusCode: .created,
                    headers: TodoController.sharedHeader,
                    payload: todo)
            }
    }

    func getTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
      guard let id = request.pathParameters?["id"], let uuid = UUID(uuidString: id) else {
        return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
      }

      return self.store.getTodo(id: uuid)
            .flatMapThrowing { (todo) -> APIGateway.Response in
                return try APIGateway.Response(
                    statusCode: .ok,
                    headers: TodoController.sharedHeader,
                    payload: todo)
            }
            .flatMapErrorThrowing { (error) -> APIGateway.Response in
                switch error {
                case TodoError.notFound:
                    return APIGateway.Response(statusCode: .notFound)
                default:
                    throw error
                }
            }
    }

    func deleteTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
        guard let id = request.pathParameters?["id"], let uuid = UUID(uuidString: id) else {
            return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
        }

        return self.store.deleteTodo(id: uuid)
            .flatMapThrowing { _ -> APIGateway.Response in
                return try APIGateway.Response(
                    statusCode: .ok,
                    headers: TodoController.sharedHeader,
                    payload: [TodoModel]())
            }
    }

    func patchTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
        guard let id = request.pathParameters?["id"], let uuid = UUID(uuidString: id) else {
            return context.eventLoop
                .makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
        }

        let patchTodo: PatchTodo
        do {
            patchTodo = try request.decodeBody(PatchTodo.self)
        }
        catch {
            return context.eventLoop.makeFailedFuture(error)
        }

        return self.store.patchTodo(id: uuid, patchTodo)
            .flatMapThrowing { (todo) -> APIGateway.Response in
                return try APIGateway.Response(
                    statusCode: .ok,
                    headers: TodoController.sharedHeader,
                    payload: todo)
        }
    }

}

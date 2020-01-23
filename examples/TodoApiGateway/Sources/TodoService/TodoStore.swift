//
//  TodoStore.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//

import Foundation
import NIO

public protocol TodoStore {
    func getTodos() -> EventLoopFuture<[TodoModel]>
    func getTodo(id: UUID) -> EventLoopFuture<TodoModel>
    func saveTodo(_ todo: TodoModel) -> EventLoopFuture<TodoModel>
    func deleteTodo(id: UUID) -> EventLoopFuture<Void>
}

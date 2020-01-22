//
//  DynamoModel+CRUD.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB
import NIO

extension DynamoModel {

    public static func query(on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        DynamoQueryBuilder(database: database)
    }

    public func save(on database: DynamoDB) -> EventLoopFuture<Self> {
        if !self._$id.exists {
            return self._create(on: database)
                .map { return self }
        } else {
            return self._update(on: database)
                .map { return self }
        }
    }

    private func _create(on database: DynamoDB) -> EventLoopFuture<Void> {
        self._$id.generate()
        return Self.query(on: database)
            .set(self.inputFields)
            .action(.create)
            .run()
    }

    private func _update(on database: DynamoDB) -> EventLoopFuture<Void> {
        return Self.query(on: database)
            .filter(\._$id == self.id!)
            .set(self.inputFieldsWithChanges)
            .action(.update)
            .run()
    }

    public static func find(id: IDValue, on database: DynamoDB) -> EventLoopFuture<Self?> {
        return Self.query(on: database)
            .filter(\._$id == id)
            .first()
    }

    public static func delete(id: IDValue, on database: DynamoDB) -> EventLoopFuture<Void> {
        Self.query(on: database)
            .filter(\._$id == id)
            .action(.delete)
            .run()
    }
}
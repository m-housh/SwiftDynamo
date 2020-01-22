//
//  DynamoQueryBuilder.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB
import NIO

public final class DynamoQueryBuilder<Model> where Model: DynamoModel {

    public var query: DynamoQuery
    public let database: DynamoDB

    public init(database: DynamoDB) {
        self.database = database
        self.query = .init(schema: Model.schema)
        self.query.fields = Model().fields.map { (_, field) in
            return field.key
        }
//        self.query.sortKey = Model.schema.sortKey
    }

    @discardableResult
    public func sortKey(_ key: KeyPath<Model, SortKey<String>>) -> Self {
        query.sortKey = Model()[keyPath: key]
        return self
    }
//
//    @discardableResult
//    func sortKey(_ key: String) -> Self {
//        query.sortKey = DynamoSchema.SortKey.string(key)
//        return self
//    }

    @discardableResult
    public func limit(_ limit: Int) -> Self {
        return set(.limit(limit))
    }

//    @discardableResult
//    public func limitAttributes<Field>(to attributes: KeyPath<Model, Field>...) -> Self where Field: FieldRepresentible {
//        query.fields = []
//        query.fields += attributes.map { Model.key(for: $0) }
//        return self
//    }
//
//    @discardableResult
//    public func index(_ index: String) -> Self {
//        query.indexName = index
//        return self
//    }

    @discardableResult
    public func set(_ data: [String: DynamoQuery.Value]) -> Self {
        query.input.append(.dictionary(data))
        return self
    }

    @discardableResult
    public func set(_ option: DynamoQuery.Option) -> Self {
        query.options.append(option)
        return self
    }

    @discardableResult
    public func set(_ data: [AnyField]) -> Self {
        query.input.append(.fields(data))
        return self
    }

    @discardableResult
    internal func action(_ action: DynamoQuery.Action) -> Self {
        query.action = action
        return self
    }
}

extension DynamoQueryBuilder {

    public func all() -> EventLoopFuture<[Model]> {
        var models = [Result<Model, Error>]()
        return self.all { model in
            models.append(model)
        }
        .flatMapThrowing {
            return try models.map {
                try $0.get()
            }
        }
    }

    public func all(_ onOutput: @escaping (Result<Model, Error>) -> ()) -> EventLoopFuture<Void> {
        var all = [Model]()

        return self.run { output in
            switch output.output {
            case let .list(models):
                for _ in models {
                    onOutput(.init(catching: {
                        let model = Model()
                        try model.output(from: output)
                        all.append(model)
                        return model
                    }))
                }
            default:
                fatalError("Invalid database output, expected a list.")
            }
        }
    }

    public func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        database.execute(query: query, onResult: onOutput)
    }

    public func run() -> EventLoopFuture<Void> {
        self.run({ _ in })
    }
}

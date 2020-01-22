//
//  DynamoQueryBuilder.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB
import NIO

// MARK: - TODO
//  add partition key method.

/// Used to build / set options on a query before executing on the database.
public final class DynamoQueryBuilder<Model> where Model: DynamoModel {

    /// The query we are building.
    public var query: DynamoQuery

    /// The database to run the query on.
    public let database: DynamoDB

    /// Create a new query builder.
    ///
    /// - parameters:
    ///     - database: The database to run the query on.
    public init(database: DynamoDB) {
        self.database = database
        self.query = .init(schema: Model.schema)
//        self.query.fields = Model().fields.map { (_, field) in
//            return field.key
//        }
    }

    @discardableResult
    public func sortKey(_ key: KeyPath<Model, SortKey<String>>) -> Self {
        query.sortKey = Model()[keyPath: key]
        return self
    }

    @discardableResult
    public func limit(_ limit: Int) -> Self {
        return set(.limit(limit))
    }

    @discardableResult
    public func set(sortKey key: String, to value: CustomStringConvertible) -> Self {
        query.sortKey = DynamoQuery.SortKey(key: key, value: value.description)
        return self
    }

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
    func filter(_ filter: DynamoQuery.Filter) -> Self {
        query.filters.append(filter)
        return self
    }

    @discardableResult
    func filter(_ filter: DynamoModelValueFilter<Model>) -> Self {
        self.filter(
            .field(filter.key, filter.method, filter.value)
        )
    }


    @discardableResult
    public func filter<Value>(
        _ field: Field<Value>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        let attribute = try! DynamoConverter().convertToAttribute(value)
        return self.filter(.field(field.key, method, .attribute(attribute)))
    }

    @discardableResult
    public func filter<Value>(
        _ field: KeyPath<Model, Field<Value>>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        let attribute = try! DynamoConverter().convertToAttribute(value)
        return self.filter(.field(Model.key(for: field), method, .attribute(attribute)))
    }

    @discardableResult
    public func filter<Value, Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Field: FieldRepresentible, Field.Value == Value
    {
        let attribute = try! DynamoConverter().convertToAttribute(value)
        query.filters.append(.field(Model.key(for: field), method, .attribute(attribute)))
        return self
    }


    @discardableResult
    internal func action(_ action: DynamoQuery.Action) -> Self {
        query.action = action
        return self
    }
}

extension DynamoQueryBuilder {

    public func first() -> EventLoopFuture<Model?> {
        return self
            .limit(1)
            .all()
            .map { $0.first }
    }

    /// Runs the query and returns all items.
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

    /// Run the query and react to each model that was returned one at a time.
    ///
    /// - parameters:
    ///     - onOutput: The callback that reacts to the generated model.
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

    /// Run the query and react to the results.
    ///
    /// - parameters:
    ///     - onOutput: A callback that recieves the query results.
    public func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        database.execute(query: query, onResult: onOutput)
    }

    /// Runs the query and ignores results.
    public func run() -> EventLoopFuture<Void> {
        self.run({ _ in })
    }
}

// MARK: - Field Value Filters

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> DynamoModelValueFilter<Model>
        where Model: DynamoModel, Field: FieldRepresentible {
            .init(lhs, .equal, rhs)
}

public struct DynamoModelValueFilter<Model> where Model: DynamoModel {

    let key: String
    let method: DynamoQuery.Filter.Method
    let value: DynamoQuery.Value

    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Field.Value
    )
        where Field: FieldRepresentible
    {
        self.key = Model.init()[keyPath: lhs].field.key
        self.method = method
        self.value = .attribute(try! DynamoConverter().convertToAttribute(value))
    }
}
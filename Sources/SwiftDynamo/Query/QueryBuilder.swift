//
//  DynamoQueryBuilder.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB
import NIO

/// Used to build / set options on a query before executing on the database.
public final class DynamoQueryBuilder<Model> {

    /// The query we are building.
    public var query: DynamoQuery

    /// The database to run the query on.
    public let database: DynamoDB

    public init(schema: DynamoSchema, database: DynamoDB) {
        self.database = database
        self.query = DynamoQuery(schema: schema)
    }

    @discardableResult
    public func limit(_ limit: Int) -> Self {
        return setOption(.limit(limit))
    }

    // MARK: - Set

    // MARK: - TODO
    //          Add a `.set(_ encodable: Encodable)` to allow easier way to
    //          create `PATCH` request representations, this should also include
    //          a way to tell if the value is an optional and is `nil` and not `set`
    //          a value if the model expects a non-optional, if the model expects an
    //          optional we would probably want to send it as there is no way to tell
    //          if it's an update or not.
    //
    //          We could then most likely remove the `.set(_ data: _)` method or make it internal.
    //
    //          We would also need to make sure that it is an object that has `Fields`, so not exactly
    //          sure how to play that, perhaps the 

    @discardableResult
    public func setSortKey(sortKey key: String, to value: Encodable, method: DynamoQuery.Filter.Method = .equal) -> Self {
        query.sortKey = (key, .bind(value), method)
        return self
    }

    @discardableResult
    public func setPartitionKey(partitionKey key: String, to value: Encodable) -> Self {
        query.partitionKey = (key, .bind(value))
        return self
    }

    @discardableResult
    public func setAction(to action: DynamoQuery.Action) -> Self {
        return self.action(action)
    }

    @discardableResult
    public func set(_ data: [String: DynamoQuery.Value]) -> Self {
        query.input.append(.dictionary(data))
        return self
    }

    /// Set query input to an `AttributeEncodable` type.
    @discardableResult
    public func set<T>(_ data: T) -> Self where T: AttributeEncodable {
        query.input.append(.dictionary(data.encode()))
        return self
    }

    /// Used for batch create.
    @discardableResult
    public func set(_ data: [[String: DynamoQuery.Value]]) -> Self {
        query.input = data.reduce(into: query.input) { $0.append(.dictionary($1)) }
        return self
    }

    /// Used for batch delete.
    @discardableResult
    public func set(_ keys: [AnyDynamoDatabaseKey]) -> Self {
        query.input = keys.reduce(into: query.input) { $0.append(.key($1)) }
        return self
    }

    @discardableResult
    public func setOption(_ option: DynamoQuery.Option) -> Self {
        query.options.append(option)
        return self
    }

    // MARK: - Filter

    @discardableResult
    public func filter(_ filter: DynamoQuery.Filter) -> Self {
        query.filters.append(filter)
        return self
    }

    // MARK: - Actions

    @discardableResult
    internal func action(_ action: DynamoQuery.Action) -> Self {
        query.action = action
        return self
    }

    public func update() -> EventLoopFuture<Void> {
        query.action = .update
        return self.run()
    }

    public func create() -> EventLoopFuture<Void> {
        query.action = .create
        return self.run()
    }

    public func delete() -> EventLoopFuture<Void> {
        query.action = .delete
        return self.run()
    }

    /// Run the query and react to each `AttributeDecodable` that was returned one at a time.
    ///
    /// - parameters:
    ///     - onOutput: The callback that reacts to the generated model.
    public func all<T>(
        decodeTo: T.Type,
        _ onOutput: @escaping (Result<T, Error>, [String: DynamoDB.AttributeValue]?) -> Void
    ) -> EventLoopFuture<Void>
        where T: AttributeDecodable
    {
        var all = [T]()

        return self.run { output in
            switch output.output {
            case let .list(rows, last):
                for row in rows {
                    onOutput(.init(catching: {
                        let model = try T.init(from: row)
                        all.append(model)
                        return model
                    }), last)
                }
            case let .dictionary(row):
                onOutput(.init(catching: {
                    let model = try T.init(from: row)
                    all.append(model)
                    return model
                }), nil)
            }
        }
    }

    /// Run the query and react to the results.
    ///
    /// - parameters:
    ///     - onOutput: A callback that recieves the query results.
    public func run(_ onOutput: @escaping (DatabaseOutput) -> Void) -> EventLoopFuture<Void> {
        database.execute(query: query, onResult: onOutput)
    }

    /// Runs the query and ignores results.
    public func run() -> EventLoopFuture<Void> {
        self.run({ _ in })
    }
}

extension DynamoQueryBuilder where Model: AttributeDecodable {

    /// Runs the query returning the first item, if it exists.
    public func first() -> EventLoopFuture<Model?> {
        return self
            .limit(1)
            .all()
            .map { $0.first }
    }

    /// Runs the query and returns all items.
    public func all() -> EventLoopFuture<[Model]> {
        var models = [Result<Model, Error>]()
        return self.all { (model, _) in
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
    public func all(
        _ onOutput: @escaping (Result<Model, Error>, [String: DynamoDB.AttributeValue]?) -> Void
    ) -> EventLoopFuture<Void>
    {
        self.all(decodeTo: Model.self, onOutput)
    }

}

// MARK: - Field Value Filters

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> DynamoModelValueFilter<Model>
        where Model: DynamoModel, Field: FieldRepresentible {
            .init(lhs, .equal, rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> DynamoModelValueFilter<Model>
        where Model: DynamoModel, Field: FieldRepresentible {
            .init(lhs, .notEqual, rhs)
}

public struct DynamoModelValueFilter<Model> where Model: DynamoModel {

    let key: DynamoQuery.Filter.FieldFilterKey
    let method: DynamoQuery.Filter.Method
    let value: DynamoQuery.Value

    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Field.Value
    )
        where Field: FieldRepresentible
    {
        let field = Model()[keyPath: lhs].field
        self.key = .init(field: field)
        self.method = method
        self.value = .bind(value)
    }
}

extension DynamoQuery.Filter.FieldFilterKey {

    init(field: AnyField) {
        self.key = field.key
        self.isPartitionKey = field.partitionKey
        self.isSortKey = field.sortKey
    }
}

extension DynamoQueryBuilder where Model: DynamoModel {
    /// Create a new query builder.
    ///
    /// - parameters:
    ///     - database: The database to run the query on.
    public convenience init(database: DynamoDB) {
        self.init(schema: Model.schema, database: database)
    }


    @discardableResult
    public func setSortKey<Value>(_ sortKey: KeyPath<Model, SortKey<Value>>, to value: Value, method: DynamoQuery.Filter.Method = .equal) -> Self {
        query.sortKey = (Model.key(for: sortKey), .bind(value), method)
        return self
    }

    @discardableResult
    public func set<Value>(
        _ key: KeyPath<Model, Field<Value>>,
        to value: Value
    ) -> Self
        where Value: Codable
    {
        let fieldKey = Model()[keyPath: key].field.key
        query.input.append(.dictionary([fieldKey: .bind(value)]))
        return self
    }

    @discardableResult
    public func set<Value>(
        _ key: KeyPath<Model, ID<Value>>,
        to value: Value
    ) -> Self
        where Value: Codable
    {
        let fieldKey = Model()[keyPath: key].field.key
        query.input.append(.dictionary([fieldKey: .bind(value)]))
        return self
    }

    @discardableResult
    public func filter(_ filter: DynamoModelValueFilter<Model>) -> Self {
        self.filter(
            .field(filter.key, filter.method, filter.value)
        )
    }

    @discardableResult
    public func filter<Value>(
        _ field: KeyPath<Model, Field<Value>>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        return self.filter(.field(.init(field: Model()[keyPath: field].field), method, .bind(value)))
    }

    @discardableResult
    public func filter<Value, Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Field: FieldRepresentible, Field.Value == Value
    {
        query.filters.append(.field(.init(field: Model()[keyPath: field].field), method, .bind(value)))
        return self
    }
}

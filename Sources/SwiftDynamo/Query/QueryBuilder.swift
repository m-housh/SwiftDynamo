//
//  DynamoQueryBuilder.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB
import NIO

/// Used to build / set options on a query and execute the query on the database.
public final class DynamoQueryBuilder<Model> {

    /// The query we are building.
    public var query: DynamoQuery

    /// The database to run the query on.
    public let database: DynamoDB

    /// Create a new query builder for the given table schema and database.
    ///
    /// - Parameters:
    ///     - schema: The table schema for the query.
    ///     - database: The database to run the query on.
    public init(schema: DynamoSchema, database: DynamoDB) {
        self.database = database
        self.query = DynamoQuery(schema: schema)
    }

    /// Limit the results of the query to the given number.
    ///
    /// - Parameters:
    ///     - limit: The max number of results to return from the query.
    @discardableResult
    public func limit(_ limit: Int) -> Self {
        return setOption(.limit(limit))
    }

    // MARK: - Set Keys.

    /// Set a sort key filter on the query.
    ///
    /// - Parameters:
    ///     - sortKey: The key path to the sort key field on the model.
    ///     - value: The value for the sort key filter.
    ///     - method: The filter method
    @discardableResult
    public func setSortKey(
        sortKey key: String,
        to value: Encodable,
        method: DynamoQuery.Filter.Method = .equal
    ) -> Self {
        query.sortKey = (key, .bind(value), method)
        return self
    }

    /// Set a partition key filter on the query.
    ///
    /// - Parameters:
    ///     - partitionKey: The key path to the sort key field on the model.
    ///     - value: The value for the partition key filter.
    @discardableResult
    public func setPartitionKey(partitionKey key: String, to value: Encodable) -> Self {
        query.partitionKey = (key, .bind(value))
        return self
    }

    /// Sets the id keys on the query for batch delete requests.
    ///
    /// - Parameters:
    ///     - keys: The id keys to delete.
    @discardableResult
    public func set(_ keys: [AnyDynamoDatabaseKey]) -> Self {
        query.input = keys.reduce(into: query.input) { $0.append(.key($1)) }
        return self
    }


    // MARK: - Filter
    /// Adds a filter to the query.
    ///
    /// - Parameters:
    ///     - filter: The filter for the query.
    @discardableResult
    public func filter(_ filter: DynamoQuery.Filter) -> Self {
        query.filters.append(filter)
        return self
    }

    // MARK: - Set Input.

    /// Set the database input for the query.
    ///
    /// - Parameters:
    ///     - data: The database row values.
    @discardableResult
    public func set(_ data: [String: DynamoQuery.Value]) -> Self {
        query.input.append(.dictionary(data))
        return self
    }

    /// Set query input to an `AttributeEncodable` type.
    ///
    /// - Parameters:
    ///     - data: The attribute encodable to use for the database row values.
    @discardableResult
    public func set<T>(_ data: T) -> Self where T: AttributeEncodable {
        query.input.append(.dictionary(data.encode()))
        return self
    }

    /// Set the query input for multiple rows, used for batch create.
    ///
    /// - Parameters:
    ///     - data: The database row values.
    @discardableResult
    public func set(_ data: [[String: DynamoQuery.Value]]) -> Self {
        query.input = data.reduce(into: query.input) { $0.append(.dictionary($1)) }
        return self
    }

    /// Set the query input for multiple rows of `AttributeEncodable` types, used for batch create.
    ///
    /// - Parameters:
    ///     - data: The database row values.
    @discardableResult
    public func set<T>(_ data: [T]) -> Self where T: AttributeEncodable {
        self.set(data.map { $0.encode() })
    }

    // MARK: Set Options.

    /// Set options on the underlying `DynamoDB` query.  Not all options are valid for
    /// all query actions, but setting an invalid option will not affect the query operation, it will be ignored.
    ///
    /// - Parameters:
    ///     - option: The option to set on the query.
    @discardableResult
    public func setOption(_ option: DynamoQuery.Option) -> Self {
        query.options.append(option)
        return self
    }

    /// Set the global index for the query.
    ///
    /// - Parameters:
    ///     - index: The global index name.
    @discardableResult
    public func setIndex(_ index: String) -> Self {
        setOption(.indexName(index))
    }

    /// Override the table schema for the query.
    ///
    /// - Parameters:
    ///     - table: The table schema.
    @discardableResult
    public func setTable(_ table: DynamoSchema) -> Self {
        query.schema = table
        return self
    }

    /// Override the table schema for the query.
    ///
    /// - Parameters:
    ///     - table: The table name.
    @discardableResult
    public func setTable(_ table: String) -> Self {
        setTable(DynamoSchema(table))
    }

    // MARK: - Actions

    /// Set the action of the query.
    ///
    /// - Parameters:
    ///     - action: The action for the query.
    @discardableResult
    public func setAction(to action: DynamoQuery.Action) -> Self {
        query.action = action
        return self
    }

    /// Run an update operation disregarding the database output.
    public func update() -> EventLoopFuture<Void> {
        self.setAction(to: .update).run()
    }

    /// Run a create operation disregarding the database output.
    public func create() -> EventLoopFuture<Void> {
        self.setAction(to: .create).run()
    }

    /// Run a delete operation disregarding the database output.
    public func delete() -> EventLoopFuture<Void> {
        self.setAction(to: .delete).run()
    }

    /// Run the query and react to each `AttributeDecodable` that was returned one at a time.  This is
    /// primarily used internally.
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

extension DynamoQueryBuilder where Model: DynamoModel {
    // MARK: DynamoModel Operations.

    /// Create a new query builder.
    ///
    /// - parameters:
    ///     - database: The database to run the query on.
    public convenience init(database: DynamoDB) {
        self.init(schema: Model.schema, database: database)
    }

    /// Set a sort key filter on the query.
    ///
    /// - Parameters:
    ///     - sortKey: The key path to the sort key field on the model.
    ///     - value: The value for the sort key filter.
    ///     - method: The filter method
    @discardableResult
    public func setSortKey<Value>(
        _ sortKey: KeyPath<Model, SortKey<Value>>,
        to value: Value,
        method: DynamoQuery.Filter.Method = .equal
    ) -> Self {
        query.sortKey = (Model.key(for: sortKey), .bind(value), method)
        return self
    }

    /// Set the input value for a given field on the query.
    ///
    /// - Parameters:
    ///     - key: The key path to the field on the model.
    ///     - value: The value to set as the input.
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

    /// Set the input value for the given id field of the model.
    ///
    /// - Parameters:
    ///     - key: The key path to the id field on the model.
    ///     - value: The value to set as the input.
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

}

//
//  AttributeConvertible.swift
//  
//
//  Created by Michael Housh on 5/23/20.
//

import Foundation
import DynamoDB

/// Represents a type that encode itself to be used as database input.
public protocol AttributeEncodable: Encodable {

    /// Encode to database input values.
    func encode() -> [String: DynamoQuery.Value]
}

/// Represents a type that decode itself from database output.
public protocol AttributeDecodable: Decodable {

    /// Create a new instance from the given database output.
    ///
    /// - Parameters:
    ///     - output:  The database output.
    init(from output: [String: DynamoDB.AttributeValue]) throws
}

/// A type that encode / decode itself for database queries.
public protocol AttributeConvertible: AttributeDecodable, AttributeEncodable { }

extension AttributeConvertible {

    /// Create a query on  the  given schema and database.
    ///
    /// - Parameters:
    ///     - table: The table schema for the query.
    ///     - database: The database for the query.
    public static func query(_ table: DynamoSchema, on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        .init(schema: table, database: database)
    }

    /// Create a query on  the  given table name and database.
    ///
    /// - Parameters:
    ///     - table: The table name for the query.
    ///     - database: The database for the query.
    public static func query(_ table: String, on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        .init(schema: DynamoSchema(table), database: database)
    }
}

extension Encodable {

    /// Helper that converts an encodable to a `DynamoQuery.Value`
    public var queryValue: DynamoQuery.Value {
        .bind(self)
    }
}

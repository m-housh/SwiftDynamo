//
//  DynamoSchema.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation

// MARK: - TODO
//  rename `sortKey` to partition key on the schema.  It should also have an optional
//  default value.

/// Stores the `DynamoDB` table name a static sort key if needed for the table.
public struct DynamoSchema: ExpressibleByStringLiteral, Equatable {

    public typealias StringLiteralType = String

    /// The `DynamoDB` table name.
    public let tableName: String

    /// An optional static sort key used when querying the table.
    public let sortKey: SortKey?

    /// Create a new instance.
    ///
    /// - parameters:
    ///     - tableName: The table name.
    ///     - anySortKey: An optional sort key to use for this instance, defaults to `nil`.
//    public init(_ tableName: String, with anySortKey: AnySortKey? = nil) {
//        self.tableName = tableName
//        self.sortKey = anySortKey
//    }

    /// Create a new instance using the convenience `SortKey`.
    ///
    /// - parameters:
    ///     - tableName: The table name.
    ///     - sortKey: A `SortKey` to use for this instance.
    public init(_ tableName: String, sortKey: SortKey) {
        self.tableName = tableName
        self.sortKey = sortKey
    }

    /// Create a new instance from an inline string, with no sort key.
    ///
    /// Example
    /// ```
    /// let schema: DynamoSchema = "myTable"
    /// ```
    ///
    /// - parameters:
    ///     - value: The string to use for the table name.
    public init(stringLiteral value: String) {
        self.tableName = value
        self.sortKey = nil
    }
}

// MARK: - Equatable
extension DynamoSchema {
    public static func == (lhs: DynamoSchema, rhs: DynamoSchema) -> Bool {
        lhs.tableName == rhs.tableName &&
            lhs.sortKey?.key == rhs.sortKey?.key
    }
}

// MARK: - SortKey
extension DynamoSchema {

    /// A convenience for a sort key initialized in a schema.
    public enum SortKey: CustomStringConvertible, AnySortKey {

        case string(key: String, value: String)
        case int(key: String, value: Int)

        public var key: String {
            switch self {
            case let .string(key, _): return key
            case let .int(key, _): return key
            }
        }

        public var description: String {
            switch self {
            case let .string(_, string): return string
            case let .int(_, int): return int.description
            }
        }

        public var sortKeyValue: String? { description }

//        public var inputValue: DynamoQuery.Value? {
//            .bind(self)
//        }
    }
}

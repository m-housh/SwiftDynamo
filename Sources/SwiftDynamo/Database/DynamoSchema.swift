//
//  DynamoSchema.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation

/// Stores the `DynamoDB` table name a static sort key if needed for the table.
public struct DynamoSchema: ExpressibleByStringLiteral, Equatable {

    public typealias StringLiteralType = String

    /// The `DynamoDB` table name.
    public let tableName: String

    /// An optional static sort key used when querying the table.
    public let sortKey: SortKey?

    public var partitionKey: PartitionKey?

    /// Create a new instance using the convenience `SortKey`.
    ///
    /// - parameters:
    ///     - tableName: The table name.
    ///     - partitionKey: A partition key to use for the table.
    ///     - sortKey: A sort key to use for the table.
    public init(_ tableName: String, partitionKey: PartitionKey? = nil, sortKey: SortKey? = nil) {
        self.tableName = tableName
        self.sortKey = sortKey
        self.partitionKey = partitionKey
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
        self.partitionKey = nil
    }
}

// MARK: - Equatable
extension DynamoSchema {
    public static func == (lhs: DynamoSchema, rhs: DynamoSchema) -> Bool {
        lhs.tableName == rhs.tableName &&
            lhs.partitionKey?.key == rhs.partitionKey?.key &&
            lhs.sortKey?.key == rhs.sortKey?.key
    }
}

// MARK: - SortKey
extension DynamoSchema {

    /// A convenience for a sort key initialized in a schema.
    public struct SortKey {

        public let key: String
        public var value: CustomStringConvertible?

        public init(key: String, default value: CustomStringConvertible? = nil) {
            self.key = key
            self.value = value
        }
    }

    public struct PartitionKey {

        public let key: String
        public var value: CustomStringConvertible?

        public init(key: String, default value: CustomStringConvertible? = nil) {
            self.key = key
            self.value = value
        }
    }
}

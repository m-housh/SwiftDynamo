//
//  SortKey.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation

/// A database field that is used as sort key for the model.
@propertyWrapper
public final class SortKey<Value>: AnyField, FieldRepresentible, AnySortKey where Value: Codable, Value: CustomStringConvertible {

    // We delegate responsibilities to the field.
    public let field: Field<Value>

    // We delegate responsibilities to the field.
    public var wrappedValue: Value {
        get { self.field.wrappedValue }
        set { self.field.wrappedValue = newValue }
    }

    // We delegate responsibilities to the field.
    public var key: String { self.field.key }

    // We delegate responsibilities to the field.
    public var projectedValue: SortKey<Value> { self }

    public var sortKey: Bool = true
    public var partitionKey: Bool = false

    /// Create a new instance.
    ///
    /// - parameters:
    ///     - key: The database key for the sort key.
    public init(key: String) {
        self.field = .init(key: key, partitionKey: false, sortKey: true)
    }

    // We delegate responsibilities to the field.
    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    // We delegate responsibilities to the field.
    public func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }

    // We delegate responsibilities to the field.
    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }
}

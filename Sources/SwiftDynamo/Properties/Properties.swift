//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB

/// A property is a database item that is attached to another object.
public protocol AnyProperty: class {

    /// Encode the property.
    func encode(to encoder: Encoder) throws

    /// Decode the property.
    func decode(from decoder: Decoder) throws

    /// Convert itself from database output to user output.
    func output(from output: DatabaseOutput) throws
}

/// A database field that is attached to a model.  This could be an id, a sort key, or a regular database field.
public protocol AnyField: AnyProperty {

    /// The database key for the field.
    var key: String { get }

    /// Input from the user.  This get's set when a value has been set for the first time or
    /// updated based on user input.
    var inputValue: DynamoQuery.Value? { get set }

    /// Convert ourself to a valid `DynamoDB.AttributeValue`
    func attributeValue() throws -> DynamoDB.AttributeValue?

    /// A flag for if the field is a sort key.
    /// A sort key gets treated differently in queries and filter operations than a standard field.
    var sortKey: Bool { get }

    /// A flag for if the field is a partition key.
    /// A partition key gets treated differently in queries and filter operations than a standard field.
    var partitionKey: Bool { get }
}

/// A type that can be used as a sort key for a `DynamoSchema`.
public protocol AnySortKey: AnyField { }

/// A type that can expose a concrete `Field`.
public protocol FieldRepresentible {

    associatedtype Value: Codable

    /// A database field.
    var field: Field<Value> { get }
}

/// A specialized database field that is used as an identifier.
protocol AnyID: AnyField {

    /// Generate a random value, if applicable / available.
    func generate()

    /// Whether the id exists in the database.
    var exists: Bool { get set }

    var cachedOutput: DatabaseOutput? { get set }

}

// Delegate responsibilities to the field.
extension AnyField where Self: FieldRepresentible {

    public var key: String {
        self.field.key
    }

    public var inputValue: DynamoQuery.Value? {
        get { self.field.inputValue }
        set { self.field.inputValue = newValue }
    }

    public func attributeValue() throws -> DynamoDB.AttributeValue? {
        try self.field.attributeValue()
    }

    public var sortKey: Bool {
        field.sortKey
    }

    public var partitionKey: Bool {
        field.partitionKey
    }
}

extension AnyModel {

    /// Whether any fields have been set / modified on a model.
    var hasChanges: Bool {
        return input.count > 0
    }

    /// Returns all the fields attached / declared on a model. Along with their label.
    /// The label is not the same as the database key.  It will be the same as the variable
    /// name set on the model.
    var fields: [(String, AnyField)] {
        properties.compactMap {
            guard let field = $1 as? AnyField else { return nil }
            return ($0, field)
        }
    }

    /// Returns all the properties attached / declared on a model.
    var properties: [(String, AnyProperty)] {
        Mirror(reflecting: self)
            .children
            .compactMap { child in
                guard let label = child.label else { return nil }
                guard let property = child.value as? AnyProperty else { return nil }
                // remove the underscore.
                return (String(label.dropFirst()), property)
            }

    }
}

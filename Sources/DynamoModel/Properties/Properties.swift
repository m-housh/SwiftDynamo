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

// Delegate responsibilities to the fields.
extension AnyProperty where Self: FieldRepresentible {

    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }

    public func output(from output: DatabaseOutput) throws {
        try field.output(from: output)
    }
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
}

/// A type that can be used as a sort key for a `DynamoSchema`.
public protocol AnySortKey {

    /// The database key for the sort key.
    var key: String { get }

    /// The value for the sort key.
    var sortKeyValue: String? { get }
}

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
}

extension AnyModel {

    /// Whether any fields have been set / modified on a model.
    var hasChanges: Bool {
        return inputFieldsWithChanges.count > 0
    }

    /// Exposes only fields with changes.
    var inputFieldsWithChanges: [AnyField] {
        inputFields.filter { $0.inputValue != nil }
    }

    /// Exposes fields for database query operatiions.
    var inputFields: [AnyField] {
        fields
            .map { keyAndValue in
                let (_, field) = keyAndValue
                return field
            }
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

// Used in encoding / decoding of models.
enum _ModelCodingKey: CodingKey {

    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case let .string(string): return string
        case let .int(int): return int.description
        }
    }

    var intValue: Int? {
        switch self {
        case let .string(string): return Int(string)
        case let .int(int): return int
        }
    }

    init?(stringValue: String) {
        self = .string(stringValue)
    }

    init?(intValue: Int) {
        self = .int(intValue)
    }

}


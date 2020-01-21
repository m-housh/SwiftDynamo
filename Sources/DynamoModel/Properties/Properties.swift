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
    var key: String { get }
    var inputValue: DynamoQuery.Value? { get set }
}

/// A type that can be used as a sort key for a `DynamoSchema`.
public protocol AnySortKey {
    var key: String { get }
//    var inputValue: DynamoQuery.SortKeyValue? { get }
}

/// A type that can expose a concrete `Field`.
public protocol FieldRepresentible {
    associatedtype Value: Codable
    var field: Field<Value> { get }
}

/// A database id field.
protocol AnyID: AnyField {
    func generate()
    var exists: Bool { get set }
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
}

extension AnyModel {

    /// Returns all the fields attached / declared on a model.
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


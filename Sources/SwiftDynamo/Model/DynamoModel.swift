//
//  DynamoModel.swift
//
//
//  Created by Michael Housh on 1/15/20.
//

import Foundation
import NIO
import DynamoDB

/// A generic model representation.
public protocol AnyModel: class, Codable {

    /// The database schema / table the model references.
    static var schema: DynamoSchema { get }

    // Required to be empty initializable for
    // reflection operations.
    init()
}

// MARK: - TODO:
//          Fix ID so it doesn't need to be optional, may need to get rid
//          of ID all together and find a way to create / mark composite keys.

/// A model that is specifically for `DynamoDB`.
public protocol DynamoModel: AnyModel {

    /// The id value used for the model.
    associatedtype IDValue: Codable, Hashable

    /// The model's unique identifier.
    var id: IDValue? { get set }
}

extension AnyModel {

    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: ModelCodingKey.self)
        try self.properties.forEach { (label, property) in
            let decoder = _ModelDecoder(container: container, key: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: ModelCodingKey.self)
        try self.properties.forEach { (label, property) in
            let encoder = _ModelEncoder(container: container, key: .string(label))
            try property.encode(to: encoder)
        }
    }

}

// Custome model specific encoder.
private struct _ModelEncoder: Encoder, SingleValueEncodingContainer {

    var container: KeyedEncodingContainer<ModelCodingKey>
    let key: ModelCodingKey

    var codingPath: [CodingKey] { container.codingPath }

    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        var container = self.container
        return container.nestedContainer(keyedBy: type, forKey: key)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = self.container
        return container.nestedUnkeyedContainer(forKey: self.key)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        try self.container.encode(value, forKey: self.key)
    }

    mutating func encodeNil() throws {
        try self.container.encodeNil(forKey: self.key)
    }
}

// Custome model specifiic decoder.
private struct _ModelDecoder: Decoder, SingleValueDecodingContainer {

    let container: KeyedDecodingContainer<ModelCodingKey>
    let key: ModelCodingKey
    var codingPath: [CodingKey] { container.codingPath }
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try container.nestedContainer(keyedBy: type, forKey: key)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try container.nestedUnkeyedContainer(forKey: key)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try container.decode(type, forKey: key)
    }

    func decodeNil() -> Bool {
        do {
            return try container.decodeNil(forKey: key)
        } catch {
            return true
        }
    }

}

extension AnyModel {

    var input: [String: DynamoQuery.Value] {
        var input = [String: DynamoQuery.Value]()
        for (_, field) in self.fields {
            input[field.key] = field.inputValue
        }
        return input
    }

    /// Sets property values based on output from the database.
    ///
    /// - parameters:
    ///     - output: The database output to get values from.
    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
    }
}

extension DynamoModel {

    /// Generates the database key items for an instance.
    var databaseKey: [String: DynamoDB.AttributeValue] {
        var key = [String: DynamoDB.AttributeValue]()

        for (_, field) in self.fields {
            if field.partitionKey || field.sortKey {
                if let value = try? field.attributeValue() {
                    key[field.key] = value
                }
            }
        }

        if let globalPartitionKey = Self.schema.partitionKey {
            if let value = globalPartitionKey.value, key[globalPartitionKey.key] == nil {
                    key[globalPartitionKey.key] = .init(s: "\(value)")
            }
        }

        if let globalSortKey = Self.schema.sortKey {
            if let value = globalSortKey.value, key[globalSortKey.key] == nil {
                    key[globalSortKey.key] = .init(s: "\(value)")
            }
        }

        if key[anyID.key] == nil {
            if anyID.partitionKey || anyID.sortKey, let idValue = try? anyID.attributeValue() {
                key[anyID.key] = idValue
            }
            else {
                if let id = self.id, let idValue = try? id.convertToAttribute() {
                    key[anyID.key] = idValue
                }
            }
        }

        return key
    }
}

extension AnyModel {


    /// Get the database key for a given field.
    ///
    /// - parameters:
    ///     - field: The field to get the id for.
    public static func key<Field>(for field: KeyPath<Self, Field>) -> String where Field: FieldRepresentible {
        // This is primarily for internal use when creating / parsing attributes
        // for query operations.
        Self.init()[keyPath: field].field.key
    }

    /// Finds / references the id field on a model.
    var anyID: AnyID {
        guard let id = Mirror(reflecting: self).descendant("_id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! AnyID
    }

}

extension DynamoModel {

    /// A reference to our id field, this gets used to tell if an item / id
    /// already exists and to generate an id if applicable.
    var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }

}

enum ModelCodingKey: CodingKey {

    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case let .string(string): return string
        case let .int(int): return int.description
        }
    }

    init(int: Int) {
        self = .int(int)
    }

    init(string: String) {
        self = .string(string)
    }

    init?(stringValue: String) {
        self = .string(stringValue)
    }

    var intValue: Int? {
        switch self {
        case let .int(int): return int
        case .string: return nil
        }
    }

    init?(intValue: Int) {
        self = .int(intValue)
    }
}

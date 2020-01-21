//
//  DynamoModel.swift
//
//
//  Created by Michael Housh on 1/15/20.
//

import Foundation
import NIO
import DynamoDB

public protocol AnyModel: class, Codable {
    static var schema: DynamoSchema { get }
    init()
}

public protocol DynamoModel: AnyModel {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue { get set }
}

// MARK: - Codable
extension AnyModel {

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: _DynamoCodingKey.self)
        try self.properties.forEach { (label, property) in
            let decoder = _ModelDecoder(container: container, key: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: _DynamoCodingKey.self)
        try self.properties.forEach { (label, property) in
            let encoder = _ModelEncoder(container: container, key: .string(label))
            try property.encode(to: encoder)
        }
    }

}

private struct _ModelEncoder: Encoder, SingleValueEncodingContainer {

    var container: KeyedEncodingContainer<_DynamoCodingKey>
    let key: _DynamoCodingKey

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

private struct _ModelDecoder: Decoder, SingleValueDecodingContainer {

    let container: KeyedDecodingContainer<_DynamoCodingKey>
    let key: _DynamoCodingKey
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
        try container.decode(type, forKey: key)
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

    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
    }
}

extension AnyModel {

    var sortKey: AnySortKey? {
        return nil
//        guard let sortKeyField = fields.first(where: { $0.1 as? AnySortKey != nil }) else {
//            return Self.schema.sortKey
//        }
//        return sortKeyField.1 as? AnySortKey
    }

    public static func key<Field>(for field: KeyPath<Self, Field>) -> String where Field: FieldRepresentible {
        Self.init()[keyPath: field].field.key
    }
}

extension DynamoModel {

    static func query(on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        DynamoQueryBuilder(database: database)
    }

    func save(on database: DynamoDB) -> EventLoopFuture<Self> {
        fatalError()
    }

    static func find(id: IDValue) -> EventLoopFuture<Self?> {
        fatalError()
    }

    static func delete(id: IDValue) -> EventLoopFuture<Void> {
        fatalError()
    }
}

enum DynamoEmployeeModelError: Error {
    case invalidAttributes
    case invalidID
}

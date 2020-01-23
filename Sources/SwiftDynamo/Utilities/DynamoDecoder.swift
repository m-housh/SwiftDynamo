//
//  DynamoDecodert.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import Foundation
import DynamoDB

/// Decodes  to`Decodable` value types appropriately handling types that are `DynamoDB.AttributeValue`s.
public struct DynamoDecoder {

    /// Decode a single value from a `DynamoDB.AttributeValue`
    ///
    /// - parameters:
    ///     - type: The type to decode from the attribute.
    ///     - attribute: The attributte to decode the value from.
    public func decode<T: Decodable>(_ type: T.Type, from attribute: DynamoDB.AttributeValue) throws -> T {
        try _DynamoDecoder(referencing: attribute).decode(type)
    }

    /// Decode values from a dictionary.
    ///
    /// - parameters:
    ///     - type: The type to decode from the attribute.
    ///     - dictionary: The dictionary to decode the values from.
    public func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        try _DynamoDecoder(referencing: dictionary).decode(type)
    }

    /// Decode values from an array.
    ///
    /// - parameters:
    ///     - type: The type to decode from the attribute.
    ///     - array: The array to decode the values from.
    public func decode<T: Decodable>(_ type: T.Type, from array: [Any]) throws -> T {
        try _DynamoDecoder(referencing: array).decode(type)
    }

    /// Decode values from data.
    ///
    /// - parameters:
    ///     - type: The type to decode from the attribute.
    ///     - data: The data to decode the values from.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {

        do {
                // try to decode the data as dictionary of attributes.
            let dict = try JSONDecoder().decode([String: DynamoDB.AttributeValue].self, from: data)
            return try decode(type, from: dict)
        } catch {
            do {
                // try to decode the data as an array of dictionary attributes.
                let array = try JSONDecoder().decode([[String: DynamoDB.AttributeValue]].self, from: data)
                return try decode(type, from: array)
            } catch {
                do {
                    let attribute = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: data)
                    return try decode(type, from: attribute)
                } catch {
                    // defer to json decoder
                    return try JSONDecoder().decode(type, from: data)
                }
            }
        }
    }
}

/// Storage used during decoding procedures.
internal struct _DecoderStorage {

    /// The decoding container stack.
    var containers: [Any] = []

    /// Create new storage with empty container stack.
    init() { }

    /// Add a container to the stack.
    mutating func pushContainer(container: Any) {
        self.containers.append(container)
    }

    /// Remove the last container from the stack.
    mutating func popContainer() {
        precondition(!containers.isEmpty, "Attempting to pop container from empty stack.")
        containers.removeLast()
    }

    /// Access the most recent container on the stack.
    var topContainer: Any {
        precondition(!containers.isEmpty, "Empty container stack")
        return containers.last!
    }

    /// The current stack count.
    var count: Int { containers.count }
}

/// A custom decoder that can appropriately decode / parse `DynamoDB.AttributeValues`.
internal class _DynamoDecoder: Decoder {

    /// The coding path taken to get to this point.
    /// - SeeAlso: `Decoder`
    var codingPath: [CodingKey]

    /// - SeeAlso: `Decoder`
    var userInfo: [CodingUserInfoKey : Any] = [:]

    /// The internal storage used while decoding values.
    var storage: _DecoderStorage

    /// Create a new decoder instance.
    ///
    /// - parameters:
    ///     - container: The item to decode values from.
    ///     - codingPath: The coding path taken to get to this point, defaults to empty.
    init(referencing container: Any, at codingPath: [CodingKey] = []) {
        self.storage = _DecoderStorage()
        storage.pushContainer(container: container)
        self.codingPath = codingPath
    }

    /// - SeeAlso: `Decoder`
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let topContainer = self.storage.topContainer as? [String: Any] else {
            throw DecodingError.typeMismatch(expected: [String: Any].self)
        }

        let container = _KeyedDecoder<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }

    /// - SeeAlso: `Decoder`
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let topContainer = self.storage.topContainer as? [Any] else {
            throw DecodingError.typeMismatch(expected: [Any].self)
        }
        return _UnkeyedDecoder(referencing: self, wrapping: topContainer)
    }

    /// - SeeAlso: `Decoder`
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

}

/// The keyed decoding container used for decoding.
internal struct _KeyedDecoder<K: CodingKey>: KeyedDecodingContainerProtocol {

    typealias Key = K

    private let decoder: _DynamoDecoder

    private let container: [String: Any]

    var codingPath: [CodingKey]

    init(referencing decoder: _DynamoDecoder, wrapping container: [String: Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    var allKeys: [K] {
        self.container.compactMap { Key(stringValue: $0.key) }
    }

    func contains(_ key: K) -> Bool {
        self.container[key.stringValue] != nil
    }

    func decodeNil(forKey key: K) throws -> Bool {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }
        return item is NSNull
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Bool.self)!
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: String.self)!
    }

    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Double.self)!
    }

    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Float.self)!
    }

    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Int.self)!
    }

    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Int8.self)!
    }

    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Int16.self)!
    }

    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Int32.self)!
    }

    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: Int64.self)!
    }

    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: UInt.self)!
    }

    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: UInt8.self)!
    }

    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: UInt16.self)!
    }

    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: UInt32.self)!
    }

    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: UInt64.self)!
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        return try decoder.unbox(item, as: type)!
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {

        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        guard let dictionary = item as? [String: Any] else {
            throw DecodingError.typeMismatch(expected: [String: Any].self)
        }

        let container = _KeyedDecoder<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let item = self.container[key.stringValue] else {
            throw DecodingError.notFound
        }

        guard let array = item as? [Any] else {
            throw DecodingError.typeMismatch(expected: [Any].self)
        }

        return _UnkeyedDecoder(referencing: self.decoder, wrapping: array)
    }

    func superDecoder() throws -> Decoder {
        self.decoder
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        self.decoder
    }



}

// MARK: - UnkeyedDecoder
/// The unkeyed decoding container used for decoding.
internal struct _UnkeyedDecoder: UnkeyedDecodingContainer {
    // I'm not necessarily sure when / how these get called, but they're required
    // for `Decoder`.
    let container: [Any]
    var codingPath: [CodingKey]
    let decoder: _DynamoDecoder
    var count: Int? { self.container.count }
    var isAtEnd: Bool { self.currentIndex >= self.count! }
    var currentIndex: Int

    init(referencing decoder: _DynamoDecoder, wrapping container: [Any]) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.container = container
        self.currentIndex = 0
    }

    mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        if self.container[self.currentIndex] is NSNull {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        self.decoder.codingPath.append(_DynamoCodingKey(intValue: self.currentIndex)!)
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.notFound
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {

        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        let item = self.container[self.currentIndex]

        guard let dictionary = item as? [String: Any] else {
            throw DecodingError.typeMismatch(expected: [String: Any].self)
        }

        self.currentIndex += 1
        let container = _KeyedDecoder<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !self.isAtEnd else {
            throw DecodingError.notFound
        }

        let item = self.container[self.currentIndex]

        guard let array = item as? [Any] else {
            throw DecodingError.typeMismatch(expected: [Any].self)
        }

        self.currentIndex += 1
        return _UnkeyedDecoder(referencing: self.decoder, wrapping: array)
    }

    mutating func superDecoder() throws -> Decoder {
        self.decoder
    }
}

// MARK: - SingleValueDecoder
/// Decodes single values.
extension _DynamoDecoder: SingleValueDecodingContainer {

    func expectNonNil() throws {
        guard !decodeNil() else {
            throw DecodingError.notFound
        }
    }

    func decodeNil() -> Bool {
        if let attribute = storage.topContainer as? DynamoDB.AttributeValue {
            if let null = attribute.null { return null }
            return false
        }
        return storage.topContainer is NSNull
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    func decode(_ type: String.Type) throws -> String {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    func decode(_ type: Double.Type) throws -> Double {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }

    func decode(_ type: Float.Type) throws -> Float {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }

    func decode(_ type: Int.Type) throws -> Int {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try expectNonNil()
        return try self.unbox(self.storage.topContainer, as: T.self)!
    }


}

// MARK: - Unbox
/// Attempts to unbox concrete types from the input to decode.
extension _DynamoDecoder {

    private func findAttribute(_ value: Any) throws -> DynamoDB.AttributeValue? {
        if let attribute = value as? DynamoDB.AttributeValue { return attribute }
        if let dictionary = value as? [String: DynamoDB.AttributeValue] {
            guard dictionary.count == 1 else {
                throw DecodingError.tooManyValues
            }
            return dictionary.first!.value
        }

        throw DecodingError.notFound
    }

    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        if let bool = value as? Bool { return bool }
        return try findAttribute(value)?.bool
    }

    func unbox(_ value: Any, as type: String.Type) throws -> String? {
        if let string = value as? String { return string }
        return try findAttribute(value)?.s
    }

    func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        if let item = value as? Double { return item }
        guard let numberString = try findAttribute(value)?.n else {
            return value as? Double
        }
        return Double(numberString)
    }

    func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        if let item = value as? Float { return item }
        guard let numberString = try findAttribute(value)?.n else {
            return value as? Float
        }
        return Float(numberString)
    }

    func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        if let item = value as? Int { return item }
        guard let numberString = try findAttribute(value)?.n else {
            return value as? Int
        }
        return Int(numberString)
    }

    func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        if let item = value as? Int8 { return item }
        guard let numberString = try findAttribute(value)?.n else {
            return value as? Int8
        }
        return Int8(numberString)
    }

    func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        if let item = value as? Int16 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? Int16
        }
        return Int16(numberString)

    }

    func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        if let item = value as? Int32 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? Int32
        }
        return Int32(numberString)
    }

    func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        if let item = value as? Int64 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? Int64
        }
        return Int64(numberString)
    }

    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        if let item = value as? UInt { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? UInt
        }
        return UInt(numberString)
    }

    func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        if let item = value as? UInt8 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? UInt8
        }
        return UInt8(numberString)
    }

    func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        if let item = value as? UInt16 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? UInt16
        }
        return UInt16(numberString)
    }

    func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        if let item = value as? UInt32 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? UInt32
        }
        return UInt32(numberString)
    }

    func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        if let item = value as? UInt64 { return item }

        guard let numberString = try findAttribute(value)?.n else {
            return value as? UInt64
        }
        return UInt64(numberString)
    }

    func unbox<T>(_ value: Any, as type: T.Type) throws -> T? where T : Decodable {
        if let item = value as? T { return item }
        return try unbox_(value, as: type) as? T
    }

    func unbox_(_ value: Any, as type: Decodable.Type) throws -> Any? {
        self.storage.pushContainer(container: value)
        defer { self.storage.popContainer() }
        return try type.init(from: self)
    }

}

// MARK: - DecodingError
/// Errors thrown during the decoding process.
enum DecodingError: Error {
    case typeMismatch(expected: Any.Type)
    case tooManyValues
    case notFound
}

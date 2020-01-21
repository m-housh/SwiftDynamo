//
//  DynamoEncoder.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import Foundation
import DynamoDB

// MARK: TODO
// - Create encodable errors, instead of fatal errors.

/// Encodes `Encodable` objects to `DynamoDB.AttributeValue`s.
public struct DynamoEncoder {

    /// Create a new encoder.
    public init() { }

    public func encode<E: Encodable>(_ encodable: E) throws -> Data {
        do {
            return try JSONEncoder().encode(try convert(encodable))
        } catch { // we weren't something that could convert to a dictionary. try to encode a primitive.
            return try JSONEncoder().encode(try convertToDynamoAttribute(encodable))
        }
    }

    public func encode<E: Encodable>(_ encodable: [E]) throws -> Data {
        try JSONEncoder().encode(try convert(encodable))
    }

    /// Convert a list of encodables.
    internal func convert<E>(_ encodable: [E]) throws -> [[String: DynamoDB.AttributeValue]] where E: Encodable {
        return try encodable.map { try self.convert($0) }
    }

    /// Convert a single item to `DynamoDB.AttributeValue`
    internal func convertToDynamoAttribute<E>(_ encodable: E) throws -> DynamoDB.AttributeValue where E: Encodable {
        let encoder = _DynamoEncoder()
        try encoder.encode(encodable)
        guard let topContainer = encoder.storage.containers.first else {
            throw EncodingError.invalidTopContainer
        }
        if let singleValue = topContainer as? _DynamoSingleValueContainer {
            return singleValue.attribute
        } else if let dictionary = topContainer as? NSMutableDictionary {
            return .init(m: try parseDict(dictionary))
        } else if let array = topContainer as? _DynamoArrayContainer {
            return try array.serialize()
        } else {
            fatalError("Failed to encode: \(encodable)")
        }
    }

    /// Convert a single encodable to a dictionary.
    public func convert<E>(_ encodable: E) throws -> [String: DynamoDB.AttributeValue] where E: Encodable {
        let encoder = _DynamoEncoder()
        try encodable.encode(to: encoder)
        guard let topContainer = encoder.storage.containers.first as? NSMutableDictionary else {
            throw EncodingError.invalidTopContainer
        }
        return try parseDict(topContainer)
    }

    /// Converts dictionary values to the appropriate `DynamoDB.AttributeValue`.
    /// Some values don't automatically get converted to a concrete `DynamoDB.AttributeValue`, so this bridges
    /// that gap.
    private func parseDict(_ dict: NSMutableDictionary) throws -> [String: DynamoDB.AttributeValue] {

        var rv = [String: DynamoDB.AttributeValue]()

        for (key, value) in dict {
            let key = key as! String
            if let array = value as? _DynamoArrayContainer {
                rv[key] = try array.serialize()
            } else if let attribute = value as? DynamoDB.AttributeValue {
                rv[key] = attribute
            } else if let map = value as? [String: DynamoDB.AttributeValue] {
                rv[key] = DynamoDB.AttributeValue(m: map)
            } else if let singleValue = value as? _DynamoSingleValueContainer {
                rv[key] = singleValue.attribute
            } else if let dictionary = value as? [String: _DynamoSingleValueContainer] {
                var newDict = [String: DynamoDB.AttributeValue]()
                for (key, value) in dictionary {
                    newDict[key] = value.attribute
                }
                rv[key] = .init(m: newDict)
            } else if let nsDictionary = value as? NSMutableDictionary {
                rv[key] = .init(m: try parseDict(nsDictionary))
            } else {
                fatalError("Invalid item in encoding chain: \(value)")
            }
        }

        return rv
    }

}

fileprivate protocol _DynamoDictionaryEncodable { }
extension Dictionary: _DynamoDictionaryEncodable where Key == String, Value: Encodable { }

/// Used when encoding an array of objects inside an item that is being encoded.
/// This is needed because the container stack requires items to be `NSObject`s.
fileprivate class _DynamoArrayContainer: NSObject {

    /// The valid array types we can encode.
    enum ArrayType {
        case string
        case number
    }

    /// The type of array this instance is for.
    var _type: ArrayType? = nil

    /// The type of array this instance is for.
    ///
    /// The type gets set when encoding the first item for this array. All the folllowing items must be
    /// of the same type `number` or `string` or a fatal error will be thrown.
    var type: ArrayType {
        get { _type ?? .string }
        set {
            guard _type == nil || newValue == _type else {
                fatalError("Attempting to change array encoding type after it's been set.")
            }

            _type = newValue
        }
    }

    /// The array that stores our encoded values, this should already be pushed on to the container stack,
    /// so mutations will reflect in the container.
    var array: NSMutableArray

    /// Create a new container.
    ///
    /// - parameters:
    ///     - array: The array that we are encoding values into.
    init(wrapping array: NSMutableArray) {
        self.array = array
    }

    /// Add an item to our encoded values.
    func append(_ string: String) { array.add(string) }

    /// Encodes our values into a `DynamoDB.AttributeValue`.
    /// If an array is empty it will not get encoded because we don't have a type reference.
    func serialize() throws -> DynamoDB.AttributeValue {

        guard let strings = array as? [String] else {
            fatalError("Casting to string array failed.")
        }

        switch type {
        case .number: return DynamoDB.AttributeValue(ns: strings)
        case .string: return DynamoDB.AttributeValue(ss: strings)
        }
    }
}

/// A container used when encoding a single item.  This is needed because the container stack requires items to be `NSObject`s.
fileprivate class _DynamoSingleValueContainer: NSObject {

    /// The attribute we are holding.
    var attribute: DynamoDB.AttributeValue

    /// Create a new single value container holding the attribute.
    ///
    /// - parameters:
    ///     - attribute: The `DynamoDB.AttributeValue` we are holding for the encoder.
    init(_ attribute: DynamoDB.AttributeValue) {
        self.attribute = attribute
    }
}

/// The object used to store the container stack during an encoding process.
fileprivate struct _DynamoStorage {

    /// The container stack.
    var containers: [NSObject] = []

    /// Add a keyed container to the stack.
    mutating func pushKeyedContainer() -> NSMutableDictionary {
        let container = NSMutableDictionary()
        containers.append(container)
        return container
    }

    /// Add an unkeyed container to the stack.
    mutating func pushUnkeyedContainer() -> _DynamoArrayContainer {
        let array = NSMutableArray()
        let container = _DynamoArrayContainer(wrapping: array)
        containers.append(container)
        return container
    }

    /// Remove the last container from the stack.
    fileprivate mutating func popContainer() -> NSObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return containers.popLast()!
    }

    /// Push any container onto the stack (typically used in single value operations).
    mutating func push(container: NSObject) {
        containers.append(container)
    }

    /// Our current container stack count.
    var count: Int { containers.count }
}

/// The actual encoder used to encode items to `[String: DynamoDB.AttributeValue]`.
/// This will not encode an array of encodables, so they must be encoded seperately.  This is due to the way array's encoded.
/// The workaround is to have a method on the top encoder that just maps arrays to this encoder.  See, `DynamoEncoder.encode(_:)`
fileprivate class _DynamoEncoder: Encoder {

    /// - SeeAlso: `Encoder`
    var userInfo: [CodingUserInfoKey : Any] = [:]

    /// The coding path taken to get to this point.
    /// - SeeAlso: `Encoder`
    var codingPath: [CodingKey]

    /// Our container stack.
    var storage: _DynamoStorage

    /// Create a new encoder at the given coding path.
    ///
    /// - parameters:
    ///     - codingPath: The current path, defaults to empty.
    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.storage = _DynamoStorage()
    }

    /// Internal helper that tells if a container has been pushed onto the stack for this coding path level.
    var canEncodeNewValue: Bool {
        self.codingPath.count == self.storage.count
    }

    /// Create a keyed encoding container.
    /// - SeeAlso: `Encoder`
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {

        let topContainer: NSMutableDictionary

        if canEncodeNewValue { // push a new container onto the stack.
            topContainer = storage.pushKeyedContainer()
        } else { // we've already started encoding at this level, so get the last container off of the stack.
            guard let container = storage.containers.last as? NSMutableDictionary else {
                fatalError("Attempting to push a new keyed container when already encoded at this path.")
            }
            topContainer = container
        }

        // create a keyed encoding container.
        let keyedContainer = _DynamoKeyedContainer<Key>(
            referencing: self,
            codingPath: self.codingPath,
            container: topContainer
        )

        return KeyedEncodingContainer(keyedContainer)
    }

    /// Create an unkeyed encoding container.
    /// - SeeAlso: `Encoder`
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = storage.pushUnkeyedContainer()
        return _DynamoUnkeyedContainer(
            referencing: self,
            codingPath: self.codingPath,
            container: container
        )
    }

    /// Create a single value encoding container.
    /// - SeeAlso: `Encoder`
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }

}

/// Used when encoding keyed items.
fileprivate struct _DynamoKeyedContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {

    /// The coding path taken to get to this point.
    /// - SeeAlso: `Encoder`
    private(set) var codingPath: [CodingKey]

    /// The parent encoder.
    private let encoder: _DynamoEncoder

    /// The container we are encoding values into.
    private var container: NSMutableDictionary

    /// Create a new keyed container.
    ///
    /// - parameters:
    ///     - encoder: Our parent encoder.
    ///     - codingPath: The coding path taken to get to this point.
    ///     - container: The container we are encoding values into.
    init(referencing encoder: _DynamoEncoder, codingPath: [CodingKey], container: NSMutableDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    /// - SeeAlso: `Encoder`
    mutating func encodeNil(forKey key: Key) throws {
        container[key.stringValue] = encoder.boxNil()
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: String, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Double, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Float, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        container[key.stringValue] = try encoder.box(value)
    }

    /// - SeeAlso: `Encoder`
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Implement")
    }
    /// - SeeAlso: `Encoder`
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }

    /// - SeeAlso: `Encoder`
    mutating func superEncoder() -> Encoder {
        self.encoder
    }

    /// - SeeAlso: `Encoder`
    mutating func superEncoder(forKey key: Key) -> Encoder {
        self.encoder
    }
}

fileprivate struct _DynamoUnkeyedContainer: UnkeyedEncodingContainer {

    private(set) var codingPath: [CodingKey]
    let encoder: _DynamoEncoder
    var container: _DynamoArrayContainer

    private var encodingType: _DynamoArrayContainer.ArrayType {
        get { container.type }
        set { container.type = newValue }
    }

    init(referencing encoder: _DynamoEncoder, codingPath: [CodingKey], container: _DynamoArrayContainer) {
        self.encoder = encoder
        self.container = container
        self.codingPath = codingPath
    }

    var count: Int { container.array.count }
    /// - SeeAlso: `Encoder`
    mutating func encodeNil() throws { fatalError("Value must be a string or number.") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Bool)   throws { fatalError("Value must be a string or number.") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int)    throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int8)   throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int16)  throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int32)  throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Int64)  throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt)   throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt8)  throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt16) throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt32) throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: UInt64) throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: String) throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Double) throws { self.container.append("\(value)") }
    /// - SeeAlso: `Encoder`
    mutating func encode(_ value: Float)  throws { self.container.append("\(value)") }

    /// - SeeAlso: `Encoder`
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        self.encoder.codingPath.append(_DynamoCodingKey(intValue: count)!)
        defer { self.encoder.codingPath.removeLast() }

        if let string = value as? String {
            encodingType = .string
            try self.encode(string)
        } else if let int = value as? Int {
            encodingType = .number
            try self.encode(int)
        } else if let num = value as? Double {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? Int8 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? Int16 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? Int32 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? Int64 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? UInt {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? UInt8 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? UInt16 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? UInt32 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? UInt64 {
            encodingType = .number
            try self.encode(num)
        } else if let num = value as? Float {
            encodingType = .number
            try self.encode(num)
        } else {
            fatalError("Value must be a string or number.")
        }

//        // add our path to the coding path and add our string value to the container.
//        self.encoder.codingPath.append(_DynamoCodingKey(intValue: count)!)
//        container.append(stringValue)

    }

    /// - SeeAlso: `Encoder`
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Value must be a string or number.")
    }

    /// - SeeAlso: `Encoder`
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Value must be a string or number.")
    }

    /// - SeeAlso: `Encoder`
    mutating func superEncoder() -> Encoder {
        self.encoder
    }

}

// MARK: SingleValueEncodingContainer
extension _DynamoEncoder: SingleValueEncodingContainer {

    func encodeNil() throws {
        storage.push(container: _DynamoSingleValueContainer(boxNil()))
    }

    func encode(_ value: Bool) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: String) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Double) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Float) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Int) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Int8) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Int16) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Int32) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: Int64) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: UInt) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: UInt8) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: UInt16) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: UInt32) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode(_ value: UInt64) throws {
        storage.push(container: _DynamoSingleValueContainer(box(value)))
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        storage.push(container: try box(value))
    }
}


// MARK: - Box Methods
// These methods are used to convert items to `DynamoDB.AttributeValue`s approriately for their
// given type.
extension _DynamoEncoder {

    func boxNil() -> DynamoDB.AttributeValue {
        .init(null: true)
    }

    func box(_ value: Bool) -> DynamoDB.AttributeValue  {
        .init(bool: value)
    }

    func box(_ value: String) -> DynamoDB.AttributeValue {
        .init(s: value)
    }

    func box(_ value: Double) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Float) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Int) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Int8) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Int16) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Int32) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: Int64) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: UInt) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: UInt8) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: UInt16) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: UInt32) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: UInt64) -> DynamoDB.AttributeValue {
        .init(n: "\(value)")
    }

    func box(_ value: [String: Encodable]) throws -> NSObject? {
        let depth = storage.count
        let result = storage.pushKeyedContainer()

        do {
            for (key, value) in value {
                self.codingPath.append(_DynamoCodingKey(stringValue: key)!)
                defer { self.codingPath.removeLast() }
                result[key] = try box(value)
            }
        } catch {
            // if the value pushed a container before it failed.
            if self.storage.count > depth {
                let _ = storage.popContainer()
            }

            throw error
        }

        // the top container should be our encoded dict.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }

    func box(_ value: Encodable) throws -> NSObject {
        try self.box_(value) ?? NSMutableDictionary()
    }

    // Boxes an encodable using the current stack, then pops it off and returns it,
    // if it was successful, if it fails we return nil.
    func box_(_ value: Encodable) throws -> NSObject? {

        // check if it's an encodable dictionary.
        if let dictionary = value as? _DynamoDictionaryEncodable {
            return try box(dictionary as! [String: Encodable])
        }

        // get our current depth to ensure a container gets pushed onto the stack.
        let depth = storage.count
        do {
            try value.encode(to: self)
        } catch {
            // remove the last container on failure.
            if self.storage.count > depth {
                _ = storage.popContainer()
            }
            throw error
        }

        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}

// MARK: - _DynamoCodingKey
/// Used for internal coding keys used primarily when encoding array items.
enum _DynamoCodingKey: CodingKey {

    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case let .string(string): return string
        case let .int(int): return int.description
        }
    }

    init?(stringValue: String) {
        self = .string(stringValue)
    }

    var intValue: Int? {
        switch self {
        case let .int(int): return int
        case let .string(string): return Int(string)
        }
    }

    init?(intValue: Int) {
        self = .int(intValue)
    }
}

// MARK: - Encoding Error
enum EncodingError: Error {
    case invalidTopContainer
}

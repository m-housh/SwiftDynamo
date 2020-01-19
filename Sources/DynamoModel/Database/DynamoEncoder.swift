//
//  File.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import Foundation
import DynamoDB

public struct DynamoEncoder {

    public init() { }

    public func encode<E>(_ encodable: E) throws -> [String: DynamoDB.AttributeValue] where E: Encodable {
        let encoder = _DynamoEncoder()
        try encodable.encode(to: encoder)
        print("Encoder.Storage: \(encoder.storage.containers)")
        guard let topContainer = encoder.storage.containers.first as? NSMutableDictionary else {
            fatalError("Invalid top container.")
        }
        var rv = [String: DynamoDB.AttributeValue]()

        for (key, value) in topContainer {
            let key = key as! String
            if let array = value as? _DynamoArrayObject {
                rv[key] = try array.serialize()
            } else if let attribute = value as? DynamoDB.AttributeValue {
                rv[key] = attribute
            } else if let map = value as? [String: DynamoDB.AttributeValue] {
                rv[key] = DynamoDB.AttributeValue(m: map)
            } else {
                fatalError("Invalid item in encoding chain.")
            }
        }

        return rv
    }
}

internal class _DynamoArrayObject: NSObject {

    enum ArrayType {
        case string
        case number
    }

    var _type: ArrayType? = nil
    var type: ArrayType? {
        get { _type }
        set {
            guard _type == nil || newValue == _type else {
                fatalError("Attempting to change array encoding type after it's been set.")
            }

            _type = newValue
        }
    }

    var array: NSMutableArray

    init(wrapping array: NSMutableArray) {
        self.array = array
    }

    func append(_ string: String) { array.add(string) }

    func serialize() throws -> DynamoDB.AttributeValue {
        guard let type = self.type else {
            fatalError("Attempting to serialize an array without an encoding type")
        }

        guard let strings = array as? [String] else {
            fatalError("Casting to string array failed.")
        }

        switch type {
        case .number: return .init(ns: strings)
        case .string: return .init(ss: strings)
        }
    }
}

struct _DynamoStorage {
    var containers: [NSObject] = []

    mutating func pushKeyedContainer() -> NSMutableDictionary {
        let container = NSMutableDictionary()
        containers.append(container)
        return container
    }

    mutating func pushUnkeyedContainer() -> _DynamoArrayObject {
        let array = NSMutableArray()
        let container = _DynamoArrayObject(wrapping: array)
        containers.append(container)
        return container
    }

    fileprivate mutating func popContainer() -> NSObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return containers.popLast()!
    }

    var count: Int { containers.count }
}

internal class _DynamoEncoder: Encoder {

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var codingPath: [CodingKey] = []
    var storage: _DynamoStorage

    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.storage = _DynamoStorage()
    }

    var canEncodeNewValue: Bool {
        self.codingPath.count == self.storage.count
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {

        let topContainer: NSMutableDictionary

        if canEncodeNewValue {
            topContainer = storage.pushKeyedContainer()
        } else {
            guard let container = storage.containers.last as? NSMutableDictionary else {
                fatalError("Attempting to push a new keyed container when already encoded at this path.")
            }
            topContainer = container
        }

        let container = _DynamoKeyedContainer<Key>(
            referencing: self,
            codingPath: self.codingPath,
            container: topContainer
        )

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
//        fatalError("Implement")
        let container = storage.pushUnkeyedContainer()
        return _DynamoUnkeyedContainer(
            referencing: self,
            codingPath: self.codingPath,
            container: container
        )
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Implement")
    }


}

//extension _DynamoEncoder {
//
//    fileprivate func assertCanEncodeNewValue() {
//        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
//    }
//}

fileprivate struct _DynamoKeyedContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {

    private(set) var codingPath: [CodingKey]
    private let encoder: _DynamoEncoder
    private var container: NSMutableDictionary

    init(referencing encoder: _DynamoEncoder, codingPath: [CodingKey], container: NSMutableDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    mutating func encodeNil(forKey key: Key) throws {
        container[key.stringValue] = encoder.boxNil()
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: [String], forKey key: Key) throws {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: [Int], forKey key: Key) throws  {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: [Double], forKey key: Key) throws  {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode(_ value: [Float], forKey key: Key) throws  {
        container[key.stringValue] = encoder.box(value)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        container[key.stringValue] = try encoder.box(value)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Implement")
//        let dictionary = [String: DynamoDB.AttributeValue]()
//        container[key.stringValue] = .init(m: dictionary)
//        codingPath.append(key)
//        defer { self.codingPath.removeLast() }
//        let container = _DynamoKeyedContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, container: dictionary)
//        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }

    mutating func superEncoder() -> Encoder {
        self.encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        self.encoder

//        _DynamoReferencingEncoder(referencing: self.encoder, for: key, with: self.container)
    }

}

struct _DynamoUnkeyedContainer: UnkeyedEncodingContainer {

    internal enum EncodingType {
        case number
        case string
    }

    private(set) var codingPath: [CodingKey]
    let encoder: _DynamoEncoder
    var container: _DynamoArrayObject

    private var encodingType: _DynamoArrayObject.ArrayType? {
        get { container.type }
        set { container.type = newValue }
    }

    init(referencing encoder: _DynamoEncoder, codingPath: [CodingKey], container: _DynamoArrayObject) {
        self.encoder = encoder
        self.container = container
        self.codingPath = codingPath
    }

    var count: Int { container.array.count }

    mutating func encodeNil() throws { fatalError("Value must be a string or number.") }
    mutating func encode(_ value: Bool)   throws { fatalError("Value must be a string or number.") }
    mutating func encode(_ value: Int)    throws { self.container.append("\(value)") }
    mutating func encode(_ value: Int8)   throws { self.container.append("\(value)") }
    mutating func encode(_ value: Int16)  throws { self.container.append("\(value)") }
    mutating func encode(_ value: Int32)  throws { self.container.append("\(value)") }
    mutating func encode(_ value: Int64)  throws { self.container.append("\(value)") }
    mutating func encode(_ value: UInt)   throws { self.container.append("\(value)") }
    mutating func encode(_ value: UInt8)  throws { self.container.append("\(value)") }
    mutating func encode(_ value: UInt16) throws { self.container.append("\(value)") }
    mutating func encode(_ value: UInt32) throws { self.container.append("\(value)") }
    mutating func encode(_ value: UInt64) throws { self.container.append("\(value)") }
    mutating func encode(_ value: String) throws { self.container.append("\(value)") }
    mutating func encode(_ value: Double) throws { self.container.append("\(value)") }
    mutating func encode(_ value: Float)  throws { self.container.append("\(value)") }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        print("Unkeyed.encode<T>: \(value)")
        let stringValue: String

        if let string = value as? String {
            stringValue = string
            encodingType = .string
        } else if let int = value as? Int {
            stringValue = int.description
            encodingType = .number
        } else if let double = value as? Double {
            stringValue = double.description
            encodingType = .number
        } else {
            fatalError("Value must be a string or number.")
        }

        self.encoder.codingPath.append(_DynamoCodingKey(intValue: count)!)
        container.append(stringValue)
        print("Container: \(container)")
        print("Storage.Containers: \(encoder.storage.containers)")

    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Value must be a string or number.")
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Value must be a string or number.")
    }

    mutating func superEncoder() -> Encoder {
        self.encoder
//        _DynamoReferencingEncoder(referencing: self.encoder, at: self.count, with: self.container)
    }


}

internal class _DynamoReferencingEncoder: _DynamoEncoder {

    private enum Reference {
        case array(NSMutableArray, Int)
//        case dictionary([String: DynamoDB.AttributeValue], String)
    }

    private let encoder: _DynamoEncoder
    private let reference: Reference

    init(referencing encoder: _DynamoEncoder, at index: Int, with array: NSMutableArray) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(codingPath: encoder.codingPath)
        self.codingPath.append(_DynamoCodingKey(intValue: index)!)
        print("Initialized referencing encoder at index: \(index)")
    }

//    init(referencing encoder: _DynamoEncoder, for key: CodingKey,
//         with dictionary: [String: DynamoDB.AttributeValue]) {
//        self.encoder = encoder
//        self.reference = .dictionary(dictionary, key.stringValue)
//        super.init(codingPath: encoder.codingPath)
//        self.codingPath.append(key)
//    }

    // MARK: - Coding Path Operations

    internal override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // MARK: - Deinitialization

    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: Any
        switch self.storage.count {
        case 0: value = NSMutableArray()
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .array(let array, let index):
            print("Refrencing encoder inserting value: \(value), at index: \(index)")
            array.insert(value, at: index)

//        case .dictionary(let dictionary, let key):
//            dictionary[key] = value
        }
    }
}


// MARK: - Box
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

    func box(_ value: [String]) -> DynamoDB.AttributeValue  {
        .init(ss: value)
    }

    func box(_ value: [Int]) -> DynamoDB.AttributeValue  {
        .init(ns: value.map { $0.description })
    }

    func box(_ value: [Double]) -> DynamoDB.AttributeValue  {
        .init(ns: value.map { $0.description })
    }

    func box(_ value: [Float]) -> DynamoDB.AttributeValue  {
        .init(ns: value.map { $0.description })
    }

    func box(_ value: String, for encodingType: _DynamoUnkeyedContainer.EncodingType) {

    }

    func box(_ value: Encodable) throws -> NSObject {
        try self.box_(value) ?? NSMutableDictionary()
    }


    func box_(_ value: Encodable) throws -> NSObject? {
        let depth = storage.count
        do {
            try value.encode(to: self)
        } catch {
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

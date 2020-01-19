//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB

protocol AnyProperty: class {
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
    func output(from output: DatabaseOutput) throws
}

extension AnyProperty where Self: FieldRepresentible {

    func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }

    func output(from output: DatabaseOutput) throws {
        try field.output(from: output)
    }
}

protocol AnyField: AnyProperty {
    var key: String { get }
    var inputValue: DynamoQuery.Value? { get set }
}

public protocol FieldRepresentible {
    associatedtype Value: Codable
    var field: Field<Value> { get }
}

protocol AnyID: AnyField {
    func generate()
    var exists: Bool { get set }
}

extension AnyField where Self: FieldRepresentible {

    var key: String {
        self.field.key
    }

    var inputValue: DynamoQuery.Value? {
        get { self.field.inputValue }
        set { self.field.inputValue = newValue }
    }
}

extension AnyModel {

    var fields: [(String, AnyField)] {
        properties.compactMap {
            guard let field = $1 as? AnyField else { return nil }
            return ($0, field)
        }
    }

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

indirect enum _DynamoValue: Equatable {
    case string(String)
    case bool(Bool)
    case number(String)
    case list([_DynamoValue])
    case dictionary([String: _DynamoValue])
    case data(Data)
    case null(Bool)
    case stringSet([String])
    case numberSet([String])
    case dataSet([Data])

    var value: Any {
        switch self {
        case let .string(string): return string
        case let .bool(bool): return bool
        case let .number(number): return number
        case let .list(list): return list.compactMap { $0.value }
        case let .dictionary(dict):
            return dict.reduce(into: [String: Any]()) { dict, keyAndAttribute in
                let (key, attribute) = keyAndAttribute
                dict[key] = attribute.value
            }
        case let .data(data): return data
        case .null(_): return Optional<Any>.none as Any
        case let .stringSet(strings): return strings
        case let .numberSet(numbers): return numbers
        case let .dataSet(data): return data
        }
    }
}

extension DynamoDB.AttributeValue {

    func _dynamoValue() throws -> _DynamoValue? {
        if let string = s {
            return .string(string)
        }
        if let bool = bool {
            return .bool(bool)
        }
        if let data = b {
            return .data(data)
        }
        if let null = null {
            return .null(null)
        }
        if let number = n {
            return .number(number)
        }
        if let map = m {
            let dictionary = map.reduce(into: [String: _DynamoValue]()) { (dict, keyAndAttribute) in
                let (key, attribute) = keyAndAttribute

                if let value = try? attribute._dynamoValue() {
                    dict[key] = value
                }
            }
            return .dictionary(dictionary)
        }
        if let stringSet = ss {
            return .stringSet(stringSet)
        }
        if let numberSet = ns {
            return .numberSet(numberSet)
        }
        if let dataSet = bs {
            return .dataSet(dataSet)
        }
        if let list = l {
            return .list(list.compactMap { try? $0._dynamoValue() })
        }
        // should maybe be a fatal error.
        throw DynamoModelError.attributeError
    }
}

extension _DynamoValue {

    var dynamoAttribute: DynamoDB.AttributeValue {
        switch self {
        case let .string(string):
            return .init(s: string)
        case let .stringSet(set):
            return .init(ss: set)
        case let .number(number):
            return .init(n: number)
        case let .numberSet(set):
            return .init(ns: set)
        case let .data(data):
            return .init(b: data)
        case let .dataSet(set):
            return .init(bs: set)
        case let .null(null):
            return .init(null: null)
        case let .bool(bool):
            return .init(bool: bool)
        case let .dictionary(dictionary):
            let map = dictionary.reduce(into: [String: DynamoDB.AttributeValue]()) { dict, keyAndValue in
                let (key, value) = keyAndValue
                dict[key] = value.dynamoAttribute
            }
            return .init(m: map)
        case let .list(values):
            return .init(l: values.map { $0.dynamoAttribute })

        }
    }
}

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


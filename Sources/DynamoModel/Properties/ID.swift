//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation

public protocol RandomGeneratable {
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        return .init()
    }
}

@propertyWrapper
public class ID<Value>: AnyID, FieldRepresentible where Value: Codable {

    public enum Generator {
        case user
        case random

        static func `default`<T>(for type: T.Type) -> Generator {
            if T.self is RandomGeneratable.Type {
                return .random
            } else {
                return .user
            }
        }
    }

    public let field: Field<Value>
    public var exists: Bool
    let generator: Generator
    var cachedOutput: DatabaseOutput?

    public var wrappedValue: Value {
        get { self.field.wrappedValue }
        set { self.field.wrappedValue = newValue }
    }

    public var key: String { self.field.key }

    public var inputValue: DynamoQuery.Value? {
        get { self.field.inputValue }
        set { self.field.inputValue = newValue }
    }

    public var projectedValue: ID<Value> { self }

    public init(key: String, generatedBy generator: Generator? = nil) {
        self.field = .init(key: key)
        self.generator = generator ?? Generator.default(for: Value.self)
        self.exists = false
        self.cachedOutput = nil
    }

    public func generate() {
        switch self.generator {
        case .random:
            let generatable = Value.self as! (RandomGeneratable & Encodable).Type
            self.inputValue = .bind(generatable.generateRandom())
        case .user:
            break
        }
    }

    public func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }
}

//
//  ID.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation

/// A type that can generate a random representation of itself.
public protocol RandomGeneratable {

    /// Create a random instance.
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        return .init()
    }
}

/// An identifier field.
@propertyWrapper
public class ID<Value>: AnyID, FieldRepresentible where Value: Codable {

    /// How the id get's generated.
    public enum Generator {
        case user
        case random

        /// Parse default generator for a given type.
        static func `default`<T>(for type: T.Type) -> Generator {
            if T.self is RandomGeneratable.Type {
                return .random
            } else {
                return .user
            }
        }
    }

    // The field used to delegate some responsibilities to.
    public let field: Field<Value>

    // Whether the item / id exists in the database.
    public var exists: Bool

    /// The id generator type.
    let generator: Generator

    /// The latest reference to the database output.
    var cachedOutput: DatabaseOutput?

    // The value exposed to the user, delegated to our `field`.
    public var wrappedValue: Value {
        get { self.field.wrappedValue }
        set { self.field.wrappedValue = newValue }
    }

    // The database key, delegated to our `field`.
    public var key: String { self.field.key }

    // The value used in queries, delegated to our `field`.
    public var inputValue: DynamoQuery.Value? {
        get { self.field.inputValue }
        set { self.field.inputValue = newValue }
    }

    // Expose ourself through the `$` prefix.
    public var projectedValue: ID<Value> { self }

    /// Create a new instance.
    ///
    /// - parameters:
    ///     - key: The database key for the id.
    ///     - generator: The generator type for the id, will use the default for the `Value` if not supplied.
    public init(key: String, generatedBy generator: Generator? = nil) {
        self.field = .init(key: key)
        self.generator = generator ?? Generator.default(for: Value.self)
        self.exists = false
        self.cachedOutput = nil
    }

    // Generate a value if applicable.
    public func generate() {
        switch self.generator {
        case .random:
            let generatable = Value.self as! (RandomGeneratable & Encodable).Type
            self.inputValue = .bind(generatable.generateRandom())
        case .user:
            break
        }
    }

    // Parse / set our state from the database output.
    public func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.field.output(from: output)
    }

    // Encode ourself, delegated to our `field`.
    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    // Decode ourself, delegated to our `field`.
    public func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }
}

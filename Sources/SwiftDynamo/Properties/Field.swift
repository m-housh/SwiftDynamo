//
//  Field.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB

/// A database field.
@propertyWrapper
public class Field<Value>: AnyField, FieldRepresentible where Value: Codable {

    /// The database key.
    public let key: String

    // Value from the database.
    var outputValue: Value?

    // Value from user input.
    public var inputValue: DynamoQuery.Value?

    // The value that gets exposed to the user.
    public var wrappedValue: Value {
        get {
            if let value = inputValue { // Check if we have user input and use that.
                switch value {
                case let .bind(bind):
                    return bind as! Value
                default:
                    fatalError("Unexpected input value: \(value)")
                }
            } else if let value = outputValue { // Check if we have a value from the database.
                return value
            } else { // We have no value, so blow up.
                fatalError("Can not access field before it's initialized or fetched")
            }
        }

        set { // We have user input, so set a bind.
            self.inputValue = .bind(newValue)
        }
    }

    /// Create a new field.
    ///
    /// - parameters:
    ///     - key: The database key for the field.
    public init(key: String) {
        self.key = key
    }

    // The value exposed when referencing with `$`.
    // Allows access to internal values / methods on a property wrapper.
    public var projectedValue: Field<Value> { self }

    // Exposes our self for database query operations.
    public var field: Field<Value> { self }

    // Sets our state based on database output.
    public func output(from output: DatabaseOutput) throws {
        if output.contains(self.key) {
            self.inputValue = nil
            do {
                self.outputValue = try output.decode(self.key, as: Value.self)
            } catch {
                throw DynamoModelError.invalidField(
                    key: self.key,
                    valueType: Value.self,
                    error: error
                )
            }
        }
    }

    /// Encode ourself.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    /// Decode ourself.
    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? _Optional.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType._none as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
    }

    public func attributeValue() throws -> DynamoDB.AttributeValue? {
        guard inputValue != nil else {
            return nil
        }
        return try DynamoConverter().convertToAttribute(wrappedValue)
    }
}

private protocol _Optional {
    static var _none: Any { get }
}
extension Optional: _Optional {
    static var _none: Any {
        return Self.none as Any
    }
}
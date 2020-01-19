//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB

@propertyWrapper
public class Field<Value>: AnyField, FieldRepresentible where Value: Codable {
    func encode() throws {
        //
    }


    public let key: String
    var outputValue: Value?
    public var inputValue: DynamoQuery.Value?

    public var wrappedValue: Value {
        get {
            if let value = inputValue {
                switch value {
                case let .bind(bind):
                    return bind as! Value
                default:
                    fatalError("Unexpected input value: \(value)")
                }
            } else if let value = outputValue {
                return value
            } else {
                fatalError("Can not access field before it's initialized or fetched")
            }
        }

        set {
            self.inputValue = .bind(newValue)
        }
    }

    public init(key: String) {
        self.key = key
    }

//    public init(wrappedValue: Value, key: String) {
//        self.wrappedValue = wrappedValue
//        self.key = key
//    }

    public var projectedValue: Field<Value> { self }


    public var field: Field<Value> { self }

    func encode() throws -> DynamoDB.AttributeValue {
        .init(s: "Foo")
    }

    func output(from output: DatabaseOutput) throws {
        do {
            self.inputValue = nil
        }
    }
}

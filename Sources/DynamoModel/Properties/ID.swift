//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation

@propertyWrapper
public struct ID<Value>: DynamoFieldWrapper where Value: DynamoAttributeValueRepresentible {

    public var wrappedValue: Value
    public let key: String

    public init(wrappedValue: Value, key: String) {
        self.wrappedValue = wrappedValue
        self.key = key
    }

    public var projectedValue: Self { self }
}

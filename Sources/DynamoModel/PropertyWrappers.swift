//
//  PropertyWrappers.swift
//  
//
//  Created by Michael Housh on 1/15/20.
//

import Foundation
import DynamoDB

public protocol DynamoFieldWrapper: DynamoAttributeValueRepresentible {

    associatedtype Value: DynamoAttributeValueRepresentible

    var wrappedValue: Value { get set }
    var projectedValue: Self { get }
    var attributeContainer: DynamoDBAttributeContainer { get }
    var key: String { get }
}

extension DynamoFieldWrapper {

    public var attributeContainer: DynamoDBAttributeContainer {
        [key: wrappedValue.dynamoAttributeValue]
    }

    public var dynamoAttributeValue: DynamoDB.AttributeValue {
        wrappedValue.dynamoAttributeValue
    }

}

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

@propertyWrapper
public struct SortKey<Value>: DynamoFieldWrapper where Value: DynamoAttributeValueRepresentible {

    public var wrappedValue: Value
    public let key: String

    public init(wrappedValue: Value, key: String) {
        self.wrappedValue = wrappedValue
        self.key = key
    }

    public var projectedValue: Self { self }
}

@propertyWrapper
public struct Field<Value>: DynamoFieldWrapper where Value: DynamoAttributeValueRepresentible {

    public var wrappedValue: Value
    public let key: String

    public init(wrappedValue: Value, key: String) {
        self.wrappedValue = wrappedValue
        self.key = key
    }

    public var projectedValue: Self { self }
}

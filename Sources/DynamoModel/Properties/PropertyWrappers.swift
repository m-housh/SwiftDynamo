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


//
//  DynamoConverter.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB

public struct DynamoConverter {

    private let encoder = DynamoEncoder()

    public func convert<T: Encodable>(_ encodable: T) throws -> [String: DynamoDB.AttributeValue] {
        try encoder.convert(encodable)
    }

    public func convert<T: Encodable>(_ encodables: [T]) throws -> [[String: DynamoDB.AttributeValue]] {
        try encoder.convert(encodables)
    }

    public func convertToAttribute<T: Encodable>(_ encodable: T) throws -> DynamoDB.AttributeValue {
        try encoder.convertToDynamoAttribute(encodable)
    }
}

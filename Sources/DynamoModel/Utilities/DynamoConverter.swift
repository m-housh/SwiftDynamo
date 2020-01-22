//
//  DynamoConverter.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB

/// Converts encodable types to an `AWS` representation.
public struct DynamoConverter {

    /// Encoder used to convert the values.
    private let encoder = DynamoEncoder()

    /// Converts a single encodable item to `dictionary` representation of itself, with
    /// attributes converted to `DynamoDB.AttributeValue`s.
    public func convert<T: Encodable>(_ encodable: T) throws -> [String: DynamoDB.AttributeValue] {
        try encoder.convert(encodable)
    }

    /// Converts a list encodable item to a list of `dictionary` representations of itself, with
    /// attributes converted to `DynamoDB.AttributeValue`s.
    public func convert<T: Encodable>(_ encodables: [T]) throws -> [[String: DynamoDB.AttributeValue]] {
        try encoder.convert(encodables)
    }

    /// Converts a single value / attribute to a `DynamoDB.AttributeValue`
    public func convertToAttribute<T: Encodable>(_ encodable: T) throws -> DynamoDB.AttributeValue {
        try encoder.convertToDynamoAttribute(encodable)
    }
}

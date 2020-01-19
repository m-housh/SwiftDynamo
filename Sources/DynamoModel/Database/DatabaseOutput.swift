//
//  DatabaseOutput.swift
//  
//
//  Created by Michael Housh on 1/17/20.
//

import Foundation
import DynamoDB


public struct DatabaseOutput {

    public let database: DynamoDB
    public let output: Output

    public enum Output {
        case list([[String: DynamoDB.AttributeValue]])
        case dictionary([String: DynamoDB.AttributeValue])
    }

    public func contains(_ field: String) -> Bool {
        return attribute(field) != nil
    }

    private func attribute(_ field: String) -> DynamoDB.AttributeValue? {
        switch output {
        case let .list(list):
            let dict = list.first(where: { $0.keys.contains(field) })
            return dict?[field]
        case let .dictionary(dict):
            return dict[field]
        }
    }

    public func decode<T>(_ field: String, as type: T.Type) throws -> T {
        guard let attribute = attribute(field) else {
            throw DynamoModelError.notFound
        }

        guard let decoded = try? attribute._dynamoValue()?.value as? T else {
            throw DynamoModelError.attributeError
        }

        return decoded
    }
}

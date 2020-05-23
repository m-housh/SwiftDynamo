//
//  DatabaseOutput.swift
//  
//
//  Created by Michael Housh on 1/17/20.
//

import Foundation
import DynamoDB
import DynamoCoder

/// Holds database output from a query.
public struct DatabaseOutput {

    /// The database the output was created on.
    public let database: DynamoDB?

    /// The actual output.
    public let output: Output

    public init(
        database: DynamoDB? = nil,
        output: Output
    ) {
        self.database = database
        self.output = output
    }

    /// Output from a database query / event.
    /// These should come in as either a single item representation (`dictionary`) or
    /// a multi-item representation (`list` of `dictionaries`).
    public enum Output {
        case list([[String: DynamoDB.AttributeValue]], [String: DynamoDB.AttributeValue]?)
        case dictionary([String: DynamoDB.AttributeValue])
    }

    /// Whether we contain a key / field name or not.
    public func contains(_ field: String) -> Bool {
        return attribute(field) != nil
    }

    /// Returns the attribute for a given key / field name.
    private func attribute(_ field: String) -> DynamoDB.AttributeValue? {
        switch output {
        case let .list(list, _):
            let dict = list.first(where: { $0.keys.contains(field) })
            return dict?[field]
        case let .dictionary(dict):
            return dict[field]
        }
    }

    /// Decodes the attribute for a given key / field name.
    public func decode<T: Decodable>(_ field: String, as type: T.Type) throws -> T {
        guard let attribute = attribute(field) else {
            throw DynamoModelError.notFound
        }

        do {
            return try DynamoDecoder().decode(type, from: attribute)
        }
        catch {
            throw DynamoModelError.invalidField(key: field, valueType: type, error: error)
        }
    }
}

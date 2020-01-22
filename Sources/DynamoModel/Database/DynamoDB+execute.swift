//
//  DynamoDB+execute.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB
import NIO

extension DynamoDB {

    func execute(
        query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        switch query.action {
        case .read: return _executeReadQuery(query, onResult: callback)
        case .create: return _create(query, onResult: callback)
        default:
            fatalError()
        }
    }

    func _executeReadQuery(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        if query.sortKey == nil {
            return self.scan(.init(tableName: query.schema.tableName))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!)))
                }
        } else {
            return self.query(.from(query))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!)))
                }
        }
    }

    func _create(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let putItemInput = DynamoDB.PutItemInput.from(query)
        return self.putItem(putItemInput)
            .map { output in
                callback(.init(database: self, output: .dictionary(putItemInput.item)))
        }
    }
}

extension DynamoQuery {

    private var _sortKey: (String, String)? {
        guard let sortKey = self.sortKey else { return nil }
        guard let value = sortKey.sortKeyValue else { return nil }
        return (sortKey.key, value)
    }


}

extension DynamoQuery.Value {

    func convertToPutItem() throws -> [String: DynamoDB.AttributeValue] {
        switch self {
        case let .fields(fields):
            return try fields.reduce(into: [String: DynamoDB.AttributeValue]()) { result, field in
                result[field.key] = try field.attributeValue()
            }
        default:
            fatalError("Invalid input type for put item.")
        }
    }
}

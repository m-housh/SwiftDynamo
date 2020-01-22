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
            return self.query(query.queryInput)
                .map { output in
                    callback(.init(database: self, output: .list(output.items!)))
                }
        }
    }

    func _create(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let putItemInput = query.putItemInput
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

    var optionsContainer: OptionsContainer {
        var options = OptionsContainer()
        _ = self.options.map { $0.setOption(&options) }
        return options
    }

    var queryInput: DynamoDB.QueryInput {
        let options = optionsContainer
        return DynamoDB.QueryInput(
            attributesToGet: fields,
            conditionalOperator: options.conditionalOperator,
            consistentRead: options.consistentRead,
            exclusiveStartKey: options.exclusiveStartKey,
            expressionAttributeNames: options.expressionAttributeNames,
            expressionAttributeValues: options.expressionAttributeValues,
            filterExpression: options.filterExpression,
            indexName: options.indexName,
            keyConditionExpression: options.keyConditionExpression,
            keyConditions: options.keyConditions,
            limit: options.limit,
            projectionExpression: options.projectionExpression,
            queryFilter: options.queryFilter,
            returnConsumedCapacity: options.returnConsumedCapacity,
            scanIndexForward: options.scanIndexForward,
            select: options.select,
            tableName: schema.tableName
        )
    }

    private var _putItem: [String: DynamoDB.AttributeValue] {
        precondition(input.count != 0)
        fatalError()
//        let item = input[0]
//        switch item {
//        case let .dictionary(dict):
//            return dict.reduce(into: [String: Encodable]()) { result, keyAndValue in
//                let (key, queryValue) = keyAndValue
//                switch queryValue {
//                case let .bind(encodable):
//                    result[key] = encodable
//                case let .dictionary(dict):
//                    r
//                }
//            }
//        default:
//            fatalError("Invalid input, should be a dictionary.")
//        }
    }

    var putItemInput: DynamoDB.PutItemInput {
        precondition(input.count == 1, "Invalid input count for put item.")
        return DynamoDB.PutItemInput(
            conditionalOperator: nil,
            conditionExpression: nil,
            expected: nil,
            expressionAttributeNames: nil,
            expressionAttributeValues: nil,
            item: try! input[0].convertToPutItem(),
            returnConsumedCapacity: nil,
            returnItemCollectionMetrics: nil,
            returnValues: nil,
            tableName: schema.tableName
        )
    }
}

extension DynamoQuery.Value {

//    private func _convertDictToAttributes(_ dict: [String: DynamoQuery.Value]) -> [String: DynamoDB.AttributeValue] {
//        var encodables = [String: DynamoDB.AttributeValue]()
//        let converter = DynamoConverter()
//        for (key, value) in dict {
//            switch value {
//            case .list(_):
//                fatalError("Can not convert list")
//            case let .bind(anyValue):
//                guard let encodeable = anyValue as? Encodable else {
//                    fatalError("invalid bind.")
//                }
//                encodables[key] = try converter.convertToAttribute(encodeable)
//            case let .dictionary(dictionaryValue):
////                encodable = _convertDictToEncodables(dictionaryValue) as! [String: Encodable]
//            }
//        }
//    }
//
//    func convertToPutItem() throws -> [String: DynamoDB.AttributeValue] {
//        switch self {
//        case let .dictionary(dict):
//            // do something
//        case let .bind(encodable):
//            // do something
//        case let .list(_):
//            fatalError("Can not convert a list to a put item.")
//        }
//    }

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

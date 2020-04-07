//
//  DynamoInputs+Options.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB
import DynamoCoder

extension DynamoDB.QueryInput {

    // MARK: - QueryInput

    static func from(_ query: DynamoQuery) -> DynamoDB.QueryInput {
        let options = query.optionsContainer
        return .init(
            attributesToGet: nil, // can not use this when sort key is provided
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
            tableName: query.schema.tableName
        )
    }
}

extension DynamoDB.PutItemInput {
    // MARK: - PutItemInput

    static func from(_ query: DynamoQuery) -> DynamoDB.PutItemInput {
        precondition(query.input.count > 0, "Invalid input count for put item.")
        let options = query.optionsContainer

        // convert the query input to [String: DynamoDB.AttributeValue]
        var item = try! query.input.reduceIntoAttributes()

        // check for a default partition key and add it.
        if let partitionKey = query.partitionKey {
            item[partitionKey.0] = try! partitionKey.1.attributeValue()
        }

        return .init(
            conditionalOperator: options.conditionalOperator,
            conditionExpression: options.conditionExpression,
            expected: nil,
            expressionAttributeNames: nil,
            expressionAttributeValues: nil,
            item: item,
            returnConsumedCapacity: options.returnConsumedCapacity,
            returnItemCollectionMetrics: options.returnItemCollectionMetrics,
            returnValues: nil,
            tableName: query.schema.tableName
        )
    }
}

extension DynamoDB.UpdateItemInput {
    // MARK: UpdateItemInput

    static func from(_ query: DynamoQuery) -> DynamoDB.UpdateItemInput {
        precondition(query.input.count > 0, "Invalid input count for update item.")
        precondition(query.filters.count > 0, "Invalid filter count for update item.")

        let key = query.key
        assert(key.count > 0, "Invalid update item key")

        let options = query.optionsContainer
        let attributeUpdates = try! query.input
            .reduceIntoAttributes()
            .convertToAttributeUpdates()

        return .init(
            attributeUpdates: attributeUpdates,
            conditionalOperator: options.conditionalOperator,
            conditionExpression: options.conditionExpression,
            expected: nil,
            expressionAttributeNames: nil,
            expressionAttributeValues: nil,
            key: key, // [String: DynamoDB.AttributeValue]
            returnConsumedCapacity: options.returnConsumedCapacity,
            returnItemCollectionMetrics: options.returnItemCollectionMetrics,
            returnValues: .allNew,
            tableName: query.schema.tableName,
            updateExpression: nil
        )
    }
}

// MARK: - Delete
extension DynamoDB.BatchWriteItemInput {

    static func batchDeleteRequest(from query: DynamoQuery) -> DynamoDB.BatchWriteItemInput {
        precondition(query.input.count > 0, "Invalid input count for batch delete.")

        let items = query.input.reduce(into: [DynamoDB.WriteRequest]()) { array, item in
            switch item {
            case let .key(key):
                precondition(key.key.count > 0, "Invalid database key.")
                var databaseKey = key.key

                // add default sort and partition keys.
                if let partitionKey = query.partitionKey, databaseKey[partitionKey.0] == nil {
                    databaseKey[partitionKey.0] = try! partitionKey.1.attributeValue()
                }

                if let sortKey = query.sortKey, databaseKey[sortKey.0] == nil {
                    databaseKey[sortKey.0] = try! sortKey.1.attributeValue()
                }

                array.append(.init(deleteRequest: .init(key: databaseKey), putRequest: nil))
            default:
                fatalError("Invalid item in the batch delete input: \(item)")
            }
        }

        return .init(requestItems: [query.schema.tableName: items])
    }

    static func deleteRequest(from query: DynamoQuery) -> DynamoDB.BatchWriteItemInput {
        .init(requestItems: [query.schema.tableName: [DynamoDB.WriteRequest.deleteRequest(from: query)]])
    }

    static func createRequest(from query: DynamoQuery) throws -> DynamoDB.BatchWriteItemInput {
        precondition(query.input.count > 0, "Invalid input count for update item.")
        return try .init(requestItems: [query.schema.tableName: DynamoDB.WriteRequest.createRequest(from: query)])
    }
}

extension DynamoDB.WriteRequest {

    static func deleteRequest(from query: DynamoQuery) -> DynamoDB.WriteRequest {
        precondition(query.action == .delete)
        return .init(deleteRequest: .from(query))
    }

    static func createRequest(from query: DynamoQuery) throws -> [DynamoDB.WriteRequest] {
        precondition(query.action == .batchCreate)
        return try query.input.reduce(into: [DynamoDB.WriteRequest]()) { currentRequests, item in
            var dict = try item
                .assertDictionary()
                .convertToAttributes()

            // add a sort and partition key, if needed.
            if let partitionKey = query.partitionKey, dict[partitionKey.0] == nil {
                dict[partitionKey.0] = try partitionKey.1.attributeValue()
            }

            if let sortKey = query.sortKey, dict[sortKey.0] == nil {
                dict[sortKey.0] = try sortKey.1.attributeValue()
            }

            currentRequests.append(.init(deleteRequest: nil, putRequest: .init(item: dict)))

        }
    }
}

extension DynamoDB.DeleteRequest {

    static func from(_ query: DynamoQuery) -> DynamoDB.DeleteRequest {
        .init(key: query.key)
    }
}

extension DynamoDB.ScanInput {

    static func from(_ query: DynamoQuery) -> DynamoDB.ScanInput {

        let options = query.optionsContainer

        return DynamoDB.ScanInput(
            attributesToGet: nil,
            conditionalOperator: options.conditionalOperator,
            consistentRead: options.consistentRead,
            exclusiveStartKey: options.exclusiveStartKey,
            expressionAttributeNames: options.expressionAttributeNames,
            expressionAttributeValues: options.expressionAttributeValues,
            filterExpression: options.filterExpression,
            indexName: options.indexName,
            limit: options.limit,
            projectionExpression: options.projectionExpression,
            returnConsumedCapacity: options.returnConsumedCapacity,
            scanFilter: nil,
            segment: nil,
            select: options.select,
            tableName: query.schema.tableName,
            totalSegments: nil
        )
    }
}

// MARK: - Helpers

extension DynamoQuery.Value {

    func assertDictionary() throws -> [String: DynamoQuery.Value] {
        switch self {
        case let .dictionary(dictionary): return dictionary
        default:
            fatalError("Expected dictionary: \(self)")
        }
    }

//    func assertList() throws -> [[String: DynamoQuery.Value]] {
//        switch self {
//        case let .list(items):
//            return try items.reduce(into: [[String: DynamoQuery.Value]]()) { currentList, item in
//                currentList.append(try item.assertDictionary())
//            }
//        default:
//            fatalError("Expected a list: \(self)")
//        }
//    }

    func attributeValue() throws -> DynamoDB.AttributeValue {
        switch self {
        case let .bind(encodable):
            if let _ = encodable as? DynamoDB.AttributeValue {
                return encodable as! DynamoDB.AttributeValue
            }
            return try encodable.convertToAttribute()
        case let .dictionary(dictionary):
            return .init(m: try dictionary.convertToAttributes())
        default:
            fatalError("Unexpected value: \(self)")

        }
    }
}

extension DynamoQuery.Filter {

    var key: [String: DynamoDB.AttributeValue] {
        switch self {
        case let .field(fieldKey, _, value):
            return [fieldKey.key: try! value.attributeValue()]
        }
    }
}

extension DynamoQuery {

    var key: [String: DynamoDB.AttributeValue] {
        var key = [String: DynamoDB.AttributeValue]()

        // add filters to the key.
        if filters.count > 0 {
            key = filters.reduce(into: key) { currentKey, filter in
                for (key, value) in filter.key {
                    currentKey[key] = value
                }
            }
        }

        // add partition key if it's available.
        if let partitionKey = self.partitionKey {
            key[partitionKey.0] = try! partitionKey.1.attributeValue()
        }

        return key
    }
}

extension Array where Element == DynamoQuery.Value {

    func reduceIntoAttributes() throws -> [String: DynamoDB.AttributeValue] {
        try reduce(into: [String: DynamoDB.AttributeValue]()) { result, queryValue in
            let dictionary = try queryValue.assertDictionary()
            for (key, value) in dictionary {
                result[key] = try value.attributeValue()
            }
        }
    }
}

extension Dictionary where Value == DynamoDB.AttributeValue, Key == String {

    func convertToAttributeUpdates(action: DynamoDB.AttributeAction = .put) throws -> [String: DynamoDB.AttributeValueUpdate] {

        reduce(into: [String: DynamoDB.AttributeValueUpdate]()) { result, keyAndValue in
            let (key, value) = keyAndValue
            result[key] = .init(action: action, value: value)
        }
    }
}

extension Dictionary where Value == DynamoQuery.Value, Key == String {

    func convertToAttributes() throws -> [String: DynamoDB.AttributeValue] {
        try reduce(into: [String: DynamoDB.AttributeValue]()) { result, keyAndValue in
            let (key, value) = keyAndValue
            result[key] = try value.attributeValue()
        }
    }
}

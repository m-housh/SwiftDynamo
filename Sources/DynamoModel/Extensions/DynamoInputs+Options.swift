//
//  DynamoInputs+Options.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB


extension DynamoDB.QueryInput {

    // MARK: - QueryInput

    static func from(_ query: DynamoQuery) -> DynamoDB.QueryInput {
        let options = query.optionsContainer
        return .init(
            attributesToGet: query.sortKey == nil ? query.fields : nil, // can not use this when sort key is provided
            conditionalOperator: query.optionsContainer.conditionalOperator,
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
        precondition(query.input.count == 1, "Invalid input count for put item.")
        let options = query.optionsContainer

        // convert the query input to [String: DynamoDB.AttributeValue]
        var item = try! query.input[0].convertFieldsToAttributes()

        // check for a default partition key and add it.
        if let partitionKey = query.partitionKey, let partitionValue = partitionKey.value {
            item[partitionKey.key] = .init(s: partitionValue.description)
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
        precondition(query.input.count == 1, "Invalid input count for update item.")
        precondition(query.filters.count > 0, "Invalid filter count for update item.")

        let key = query.key
        assert(key.count > 0, "Invalid update item key")

        let options = query.optionsContainer

        return .init(
            attributeUpdates: try! query.input[0].convertToAttributeValueUpdate(),
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

extension DynamoDB.BatchWriteItemInput {

    static func deleteRequest(from query: DynamoQuery) -> DynamoDB.BatchWriteItemInput {
        .init(requestItems: [query.schema.tableName: [DynamoDB.WriteRequest.deleteRequest(from: query)]])
    }
}

extension DynamoDB.WriteRequest {

    static func deleteRequest(from query: DynamoQuery) -> DynamoDB.WriteRequest {
        precondition(query.action == .delete)
        return .init(deleteRequest: .from(query))
    }
}

extension DynamoDB.DeleteRequest {

    static func from(_ query: DynamoQuery) -> DynamoDB.DeleteRequest {
        .init(key: query.key)
    }
}

extension DynamoQuery.Value {

    func convertFieldsToAttributes() throws -> [String: DynamoDB.AttributeValue] {
        switch self {
        case let .fields(fields):
            return try fields.reduce(into: [String: DynamoDB.AttributeValue]()) { result, field in
                result[field.key] = try field.attributeValue()
            }
        default:
            fatalError("Invalid input type for put item.")
        }

    }

    func convertToAttributeValueUpdate(action: DynamoDB.AttributeAction = .put) throws -> [String: DynamoDB.AttributeValueUpdate] {
        try convertFieldsToAttributes()
            .reduce(into: [String: DynamoDB.AttributeValueUpdate]()) { result, keyAndAttribute in
                result[keyAndAttribute.key] = .init(action: action, value: keyAndAttribute.value)
            }
    }

    func attributeValue() throws -> DynamoDB.AttributeValue {
        switch self {
        case let .attribute(attribute): return attribute
        default:
            fatalError("No attribute found or is the wrong type.")
        }
    }
}

extension DynamoQuery.Filter {

    var key: [String: DynamoDB.AttributeValue] {
        switch self {
        case let .field(fieldName, _, value):
            return [fieldName: try! value.attributeValue()]
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
        if let partitionKey = self.partitionKey, let partitionValue = partitionKey.value {
            key[partitionKey.key] = .init(s: partitionValue.description)
        }

        return key
    }
}
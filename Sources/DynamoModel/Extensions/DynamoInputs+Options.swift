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
        return .init(
            conditionalOperator: options.conditionalOperator,
            conditionExpression: options.conditionExpression,
            expected: nil,
            expressionAttributeNames: options.expressionAttributeNames,
            expressionAttributeValues: options.expressionAttributeValues,
            item: try! query.input[0].convertToPutItem(),
            returnConsumedCapacity: options.returnConsumedCapacity,
            returnItemCollectionMetrics: options.returnItemCollectionMetrics,
            returnValues: nil,
            tableName: query.schema.tableName
        )
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

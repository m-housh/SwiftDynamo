//
//  DynamoInputs+Options.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB

extension DynamoDB.QueryInput {

    static func from(_ query: DynamoQuery) -> DynamoDB.QueryInput {
        let options = query.optionsContainer
        return .init(
            attributesToGet: query.sortKey == nil ? query.fields : nil, // can not use this when sort key is providedß
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

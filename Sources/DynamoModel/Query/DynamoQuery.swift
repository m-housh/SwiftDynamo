//
//  DynamoQuery.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB
import NIO

public struct DynamoQuery {

    // MARK: - TODO
    //  these probably only need set when queries are limited instead of every
    //  query, as the default behavior is to return all the fields in a table.
    
    // fields that get returned with the query.
    // will default to all the fields found on a model.
    public var fields: [String]

    // the action we are taking on the database.
    public var action: Action

    // the schema we are interacting with.
    public var schema: DynamoSchema

    // an optional sort key for the table.
    public var sortKey: AnySortKey?

    // values to be saved to the database.
    public var input: [Value]

    // common `aws` options that can be set.
    public var options: [Option]

    // create an options container from current state.
    var optionsContainer: OptionsContainer {
        // create the container and set the default options.
        var options = self.options
            .reduce(into: OptionsContainer()) { $1.setOption(&$0) }

        // parse and set any sort key values.
        if let sortKey = self.sortKey, let sortKeyValue = sortKey.sortKeyValue {
            options.expressionAttributeValues = [":sortKey": .init(s: sortKeyValue)]
            options.keyConditionExpression = "\(sortKey.key) = :sortKey"
        }

        // return the options for our current state.
        return options
    }

    public init(schema: DynamoSchema) {
        self.action = .read
        self.schema = schema
        self.fields = []
        self.input = []
        self.sortKey = schema.sortKey
        self.options = []
    }
}

extension DynamoQuery {

    /// The action the query is invoking.
    public enum Action {
        case create
        case read
        case update
        case delete
    }

    /// Value types that can be passed to the database.
    public enum Value {

        // this is not used to pass values, however marks values
        // set on properties that they have been modified and need
        // passed in the query.
        case bind(Encodable)

        // Fields that need to be saved during a `create` or `update` query.
        case fields([AnyField])

        // these are not currently used, but should be capable
        // of passing `batch` type of queries.
        case list([[String: Value]])
        case dictionary([String: Value])
    }

    // A sort key for a table, this may need re-thought out during
    // usage of partition keys.
    public struct SortKey: AnySortKey {
        public let key: String
        public let value: String
        public var sortKeyValue: String? { value }
    }


    public enum Option {
        // Holds `aws` specific options for query inputs.  Not all options
        // are valid for all types of queries, but we will allow users to
        // set them and only use what's valid for a specific input.
        //
        // These are items that aren't used as commonly / required or have an
        // abstraction built around them to make them more meaningful.
        case limit(Int)
        case consistentRead(Bool)
        case exclusiveStartKey([String: DynamoDB.AttributeValue])
        case expressionAttributeNames([String: String])
        case expressionAttributeValues([String: DynamoDB.AttributeValue])
        case filterExpression(String)
        case indexName(String)
        case keyConditionExpression(String)
        case keyConditions([String: DynamoDB.Condition])
        case projectionExpression(String)
        case queryFilter([String: DynamoDB.Condition])
        case returnConsumedCapacity(DynamoDB.ReturnConsumedCapacity)
        case scanIndexForward(Bool)
        case select(DynamoDB.Select)
        case conditionalOperator(DynamoDB.ConditionalOperator)
        case conditionExpression(String)
        case returnItemCollectionMetrics(DynamoDB.ReturnItemCollectionMetrics)

        /// Set our value onto an options container.
        func setOption(_ options: inout OptionsContainer) {
            switch self {
            case let .limit(limit): options.limit = limit
            case let .consistentRead(bool): options.consistentRead = bool
            case let .exclusiveStartKey(dict): options.exclusiveStartKey = dict
            case let .expressionAttributeNames(dict): options.expressionAttributeNames = dict
            case let .expressionAttributeValues(dict): options.expressionAttributeValues = dict
            case let .filterExpression(string): options.filterExpression = string
            case let .indexName(string): options.indexName = string
            case let .keyConditionExpression(string): options.keyConditionExpression = string
            case let .keyConditions(dict): options.keyConditions = dict
            case let .projectionExpression(string): options.projectionExpression = string
            case let .queryFilter(dict): options.queryFilter = dict
            case let .returnConsumedCapacity(consumed): options.returnConsumedCapacity = consumed
            case let .scanIndexForward(bool): options.scanIndexForward = bool
            case let .select(select): options.select = select
            case let .conditionalOperator(_operator): options.conditionalOperator = _operator
            case let .conditionExpression(string): options.conditionExpression = string
            case let .returnItemCollectionMetrics(metrics): options.returnItemCollectionMetrics = metrics
            }
        }

    }

    /// A helper used for `aws` specific options set for a query.
    internal struct OptionsContainer {
        var limit: Int? = nil
        var consistentRead: Bool? = nil
        var exclusiveStartKey: [String: DynamoDB.AttributeValue]? = nil
        var expressionAttributeNames: [String: String]? = nil
        var expressionAttributeValues: [String: DynamoDB.AttributeValue]? = nil
        var filterExpression: String? = nil
        var indexName: String? = nil
        var keyConditionExpression: String? = nil
        var keyConditions: [String: DynamoDB.Condition]? = nil
        var projectionExpression: String? = nil
        var queryFilter: [String: DynamoDB.Condition]? = nil
        var returnConsumedCapacity: DynamoDB.ReturnConsumedCapacity? = nil
        var scanIndexForward: Bool? = nil
        var select: DynamoDB.Select? = nil
        var conditionalOperator: DynamoDB.ConditionalOperator? = nil
        var conditionExpression: String? = nil
        var returnItemCollectionMetrics: DynamoDB.ReturnItemCollectionMetrics? = nil
    }
}

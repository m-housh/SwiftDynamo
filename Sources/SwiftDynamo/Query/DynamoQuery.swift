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
    
    // fields that get returned with the query.
    // will default to all the fields found on a model.
    public var fields: [String]

    // the action we are taking on the database.
    public var action: Action

    // the schema we are interacting with.
    public var schema: DynamoSchema

    // values to be saved to the database.
    public var input: [Value]

    // an optional sort key that get's set on the query.
    public var sortKey: (String, Value)? {
        get { optionsContainer.sortKey }
        set {
            if let value = newValue {
                options.append(.sortKey(value.0, value.1))
            }
        }
    }

    // an optional partition key that gets set on the query.
    public var partitionKey: (String, Value)? {
        get { optionsContainer.partitionKey }
        set {
            if let value = newValue {
                options.append(.partitionKey(value.0, value.1))
            }
        }
    }

    // common `aws` options that can be set.
    public var options: [Option]

    // filters that get set on the query.
    public var filters: [Filter]
    
    // create an options container from current state.
    var optionsContainer: OptionsContainer {
        OptionsContainer(query: self)
    }

    public init(schema: DynamoSchema) {
        self.action = .read
        self.schema = schema
        self.fields = []
        self.input = []
        self.options = []
        self.filters = []

        if let partitionKey = schema.partitionKey, let value = partitionKey.value {
            self.partitionKey = (partitionKey.key, .bind(value.description))
        }

        if let sortKey = schema.sortKey, let value = sortKey.value {
            self.sortKey = (sortKey.key, .bind(value.description))
        }
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

        case bind(Encodable)

        case dictionary([String: Value])
    }

    // MARK: - Options

    public enum Option {
        // Holds primarily `aws` specific options for query inputs.  Not all options
        // are valid for all types of queries, but we will allow users to
        // set them and only use what's valid for a specific input.
        //
        // These are items that aren't used as commonly / required or have an
        // abstraction built around them to make them more meaningful.

        case sortKey(String, Value)
        case partitionKey(String, Value)
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
            case let .sortKey(key, value):
                options.sortKey = (key, value)
                let attribute = try! value.attributeValue()
                let expression = ":sortKey"
                options.setExpressionAttribute(expression, attribute)
                options.addKeyConditionExpression(key, .equal, expression)
            case let .partitionKey(key, value):
                options.partitionKey = (key, value)
                let attribute = try! value.attributeValue()
                let expression = ":partitionID"
                options.setExpressionAttribute(expression, attribute)
                options.addKeyConditionExpression(key, .equal, expression)
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
        var sortKey: (String, Value)? = nil
        var partitionKey: (String, Value)? = nil
    }

    // MARK: - Filter

    public enum Filter {

        public enum Method: CustomStringConvertible {

            public static var equal: Method {
                .equality(inverse: false)
            }

            public static var notEqual: Method {
                .equality(inverse: true)
            }

            // LHS is equal to RHS
            case equality(inverse: Bool)

            public var description: String {
                switch self {
                case let .equality(direction):
                    return direction != true ? "=" : "<>"
                }
            }
        }

        public struct FieldFilterKey {
            let key: String
            let isPartitionKey: Bool
            let isSortKey: Bool

            public init(_ key: String, isPartitionKey: Bool = false, isSortKey: Bool = false) {
                self.key = key
                self.isSortKey = isSortKey
                self.isPartitionKey = isPartitionKey
            }
        }

        case field(FieldFilterKey, Method, Value)
    }
}

// MARK: - Helpers
protocol AnyBindable {

    func convertToAttribute() throws -> DynamoDB.AttributeValue
}

extension Encodable {
    func convertToAttribute() throws -> DynamoDB.AttributeValue {
        try DynamoConverter().convertToAttribute(self)
    }
}

extension Optional: AnyBindable where Wrapped: Encodable {
    func convertToAttribute() throws -> DynamoDB.AttributeValue {
        guard let strongSelf = self else {
            return .init(null: true)
        }
        return try DynamoConverter().convertToAttribute(strongSelf)
    }
}

extension DynamoQuery.OptionsContainer {

    mutating func setExpressionAttribute(_ expression: String, _ value: DynamoDB.AttributeValue) {
        if expressionAttributeValues == nil {
            self.expressionAttributeValues = [expression: value]
        } else {
            self.expressionAttributeValues![expression] = value
        }
    }

    mutating func addKeyConditionExpression(
        _ key: String,
        _ method: DynamoQuery.Filter.Method,
        _ expression: String)
    {

        guard method.description != "<>" else {
            fatalError("Can not use not equal expression on sort key or partition key")
        }

        if keyConditionExpression == nil {
            keyConditionExpression = "\(key) \(method) \(expression)"
        } else {
            keyConditionExpression! += " and \(key) \(method) \(expression)"
        }
    }

    mutating func addFilterExpression(_ key: String, _ method: DynamoQuery.Filter.Method, _ expression: String) {
        if filterExpression == nil {
            filterExpression = "\(key) \(method) \(expression)"
        } else {
            filterExpression = " and \(key) \(method) \(expression)"
        }
    }

    init(query: DynamoQuery) {
        // create the container and set the default options.
        var options = query.options
            .reduce(into: Self()) { $1.setOption(&$0) }

        if query.filters.count > 0 {
            for filter in query.filters {
                switch filter {
                case let .field(fieldKey, method, value):

                    // set non-key condition filters.
                    if !(options.expressionAttributeValues?.contains(where: { $0.key == fieldKey.key }) ?? false) {
                        let expression = ":\(fieldKey.key)"
                        options.setExpressionAttribute(expression, try! value.attributeValue())
                        if (fieldKey.isPartitionKey || fieldKey.isSortKey) {
                            options.addKeyConditionExpression(fieldKey.key, method, expression)
                        }
                        else {
                            options.addFilterExpression(fieldKey.key, method, expression)
                        }
                    }
                }
            }
        }
        self = options
    }
}

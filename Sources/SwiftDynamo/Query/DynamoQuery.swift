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

    /// The action we are taking on the database.
    public var action: Action

    /// The schema we are interacting with.  This at least needs to have the table-name,
    /// but can optionally hold a partition key and / or a sort-key.
    public var schema: DynamoSchema

    /// A stack for values to be saved to the database.  This should in most cases not be
    /// manipulated directly as placing the wrong values could cause fatal errors to occur
    /// when running the query.
    public var input: [Value]

    /// An optional convenience to set / override a sort key on the query.
    ///
    /// This can be set from several different places, globally on the schema, declared as a
    /// property on the model, or set directly on the query builder.  That means that whatever
    /// gets set last is what gets set on the request.
    public var sortKey: (String, Value)? {
        get { optionsContainer.sortKey }
        set {
            if let value = newValue {
                options.append(.sortKey(value.0, value.1))
            }
        }
    }

    /// An optional convenience to set / override a partition key on the query.
    ///
    /// This can be set from several different places, globally on the schema, declared as a
    /// property on the model, or set directly on the query builder.  That means that whatever
    /// gets set last is what gets set on the request.
    public var partitionKey: (String, Value)? {
        get { optionsContainer.partitionKey }
        set {
            if let value = newValue {
                options.append(.partitionKey(value.0, value.1))
            }
        }
    }

    /// A stack of options set on the query.  Most of these are `aws` options that we allow a user to
    /// pass in if needed, the ones that we directly use will have an abstraction around them, however they
    /// get stored in order in the stack, so if the some option re-occurs whatever was set last will win.
    public var options: [Option]

    /// A stack of filters that get set on the query.
    public var filters: [Filter]
    
    /// Create an options container from current state.
    ///
    /// The options container is just a helper to properly set our current state and
    /// pass it along to the methods that build the `aws` request inputs.
    internal var optionsContainer: OptionsContainer {
        OptionsContainer(query: self)
    }

    /// Create a new query for the given schema.
    ///
    /// - parameters:
    ///     - schema: The dynamo schema the query is operating on.
    public init(schema: DynamoSchema) {
        self.action = .read
        self.schema = schema
        self.input = []
        self.options = []
        self.filters = []

        // check for a partition key on the schema.
        if let partitionKey = schema.partitionKey, let value = partitionKey.value {
            self.partitionKey = (partitionKey.key, .bind(value.description))
        }
        // check for a sort key on the schema.
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

    /// Value types that can be passed to the database.  These should typically not need to be
    /// created manually, they are created during operations on properties or on a query.
    /// Setting the wrong values will cause most queries to throw fatal errors.
    public enum Value {

        /// A bind is used on a property or during a call
        /// to `filter` on a query.  It ensures values are `Encodable` and
        /// also is used as marker for if a property needs updated in the database vs. the
        /// in memory state.
        case bind(Encodable)

        /// This is the equivalent to a row or a document in the database.
        /// The keys should map to the database key and the values will get converted
        /// to a dynamo attribute type and saved to the database.
        case dictionary([String: Value])
    }

    // MARK: - Options

    /// Holds primarily `aws` specific options for query inputs.  Not all options
    /// are valid for all types of queries, but we will allow users to
    /// set them and only use what's valid for a specific input.
    ///
    /// These are items that aren't used as commonly / required or have an
    /// abstraction built around them to make them more meaningful.
    public enum Option {

        // These are the most common options we work with.
        case sortKey(String, Value)
        case partitionKey(String, Value)
        case limit(Int)

        // AWS - Specific
        // Most of these are kind of cryptic, some are legacy parameters... We just allow
        // a user to set them and pass them along, aside from the few types we need for
        // sort keys, filtering, limits, etc.
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
        /// Builds up an options container for the current state of the query.
        /// Most of the items we just pas along.
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

            // Sort keys and partition keys get set as expression attributes and
            // key condition expressions.  A partition key is required, the sort key
            // is optional.  These can get set from several different places
            // (global on a schema definition, as a property / field, or directly in the query builder).
            // Whatever get's set last will win, the precedence will typically follow.
            // global get's set first, a field value or setting on a query will override the global, or
            // whatever was set before it, depending on the order.
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
    /// This get's built up from the options stack that is currently set on the query.
    /// Most options are not used, some are legacy parameters, but we pass them along anyways.
    ///
    /// Not all options are valid for each type of query, but we hold them all and only use what is needed
    /// for a given request.
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

    /// A query filter.
    public enum Filter {

        /// The filter method.
        ///
        /// - Note:
        ///     You can not use a not equal `!=` test on a partition or a sort key.
        ///     This will cause a fatal error if tried.
        public enum Method: CustomStringConvertible {

            /// An equality test.
            public static var equal: Method {
                .equality(inverse: false)
            }

            /// A not equal test.
            public static var notEqual: Method {
                .equality(inverse: true)
            }

            // LHS is equal to RHS
            case equality(inverse: Bool)

            /// Converts the method to the `aws` string representation for
            /// building the filter expression.
            public var description: String {
                switch self {
                case let .equality(direction):
                    return direction != true ? "=" : "<>"
                }
            }
        }

        /// The field database key along with flags on if it is
        /// a sort-key or partition-key, as they get treated differently in most
        /// instances.
        public struct FieldFilterKey {

            /// The database key for the field.
            let key: String

            /// A flag for if the field is a partition key or not.
            let isPartitionKey: Bool

            /// A flag for if the field is a sort key or not.
            let isSortKey: Bool

            /// Create a new instance.
            ///
            /// - parameters:
            ///     - key: The database key for the field.
            ///     - isPartitionKey: A flag for if the fielld is a partition key, default is false.
            ///     - isSortKey: A flag for if the field is a sort key, default is false.
            public init(
                _ key: String,
                isPartitionKey: Bool = false,
                isSortKey: Bool = false)
            {
                self.key = key
                self.isSortKey = isSortKey
                self.isPartitionKey = isPartitionKey
            }
        }

        /// A filter on a specific field in the database.
        case field(FieldFilterKey, Method, Value)
    }
}

// MARK: - Helpers

/// This is required for the `bind` to work, because `Encodable` is not a concrete type, so
/// we have to cast it to an `AnyBindable` in order to convert it's value.
protocol AnyBindable {

    /// Convert to a dynamodb attribute value.
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
            filterExpression! += " and \(key) \(method) \(expression)"
        }
    }

    init(query: DynamoQuery) {
        // create the container and set the options.
        var options = query.options
            .reduce(into: Self()) { $1.setOption(&$0) }

        // Add filter expressions.
        if query.filters.count > 0 {
            for filter in query.filters {
                switch filter {
                case let .field(fieldKey, method, value):
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
        self = options
    }
}

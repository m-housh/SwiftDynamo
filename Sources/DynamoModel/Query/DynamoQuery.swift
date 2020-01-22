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

    // an optional sort key for the table.
    public var sortKey: AnySortKey?

    // values to be saved to the database.
    public var input: [Value]

    // common `aws` options that can be set.
    public var options: [Option]

    var optionsContainer: OptionsContainer {
        var options = OptionsContainer()
        _ = self.options.map { $0.setOption(&options) }
        if let sortKey = self.sortKey, let sortKeyValue = sortKey.sortKeyValue {
            options.expressionAttributeValues = [":sortKey": .init(s: sortKeyValue)]
            options.keyConditionExpression = "\(sortKey.key) = :sortKey"
        }
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

    public enum Action {
        case create
        case read
        case update
        case delete
    }

    public enum Value {
        case bind(Encodable)
        case fields([AnyField])
        case list([[String: Value]])
        case dictionary([String: Value])
    }

    public struct SortKey: AnySortKey {
        public let key: String
        public let value: String
        public var sortKeyValue: String? { value }
    }

    public enum Option {
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

    struct OptionsContainer {
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

/*
extension DynamoQuery {
    // MARK: - AWS Values

    /// This is a legacy parameter. Use ProjectionExpression instead. For more information, see AttributesToGet in the Amazon DynamoDB Developer Guide.
    public var attributesToGet: [String]? = nil

    /// This is a legacy parameter. Use FilterExpression instead. For more information, see ConditionalOperator in the Amazon DynamoDB Developer Guide.
    public var conditionalOperator: DynamoDB.ConditionalOperator? = nil

    /// Determines the read consistency model: If set to true, then the operation uses strongly consistent reads; otherwise, the operation uses eventually consistent reads. Strongly consistent reads are not supported on global secondary indexes. If you query a global secondary index with ConsistentRead set to true, you will receive a ValidationException.
    public var consistentRead: Bool? = nil

    /// The primary key of the first item that this operation will evaluate. Use the value that was returned for LastEvaluatedKey in the previous operation. The data type for ExclusiveStartKey must be String, Number, or Binary. No set data types are allowed.
    public var exclusiveStartKey: [String: DynamoDB.AttributeValue]? = nil

    /// One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames:   To access an attribute whose name conflicts with a DynamoDB reserved word.   To create a placeholder for repeating occurrences of an attribute name in an expression.   To prevent special characters in an attribute name from being misinterpreted in an expression.   Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name:    Percentile    The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames:    {"#P":"Percentile"}    You could then use this substitution in an expression, as in this example:    #P = :val     Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime.  For more information on expression attribute names, see Specifying Item Attributes in the Amazon DynamoDB Developer Guide.
    public var expressionAttributeNames: [String: String]? = nil

    /// One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following:   Available | Backordered | Discontinued  You would first need to specify ExpressionAttributeValues as follows:  { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} }  You could then use these values in an expression, such as this:  ProductStatus IN (:avail, :back, :disc)  For more information on expression attribute values, see Specifying Conditions in the Amazon DynamoDB Developer Guide.
    public var expressionAttributeValues: [String: DynamoDB.AttributeValue]? = nil

    /// A string that contains conditions that DynamoDB applies after the Query operation, but before the data is returned to you. Items that do not satisfy the FilterExpression criteria are not returned. A FilterExpression does not allow key attributes. You cannot define a filter expression based on a partition key or a sort key.  A FilterExpression is applied after the items have already been read; the process of filtering does not consume any additional read capacity units.  For more information, see Filter Expressions in the Amazon DynamoDB Developer Guide.
    public var filterExpression: String? = nil

    /// The name of an index to query. This index can be any local secondary index or global secondary index on the table. Note that if you use the IndexName parameter, you must also provide TableName.
    public var indexName: String? = nil

    /// The condition that specifies the key values for items to be retrieved by the Query action. The condition must perform an equality test on a single partition key value. The condition can optionally perform one of several comparison tests on a single sort key value. This allows Query to retrieve one item with a given partition key value and sort key value, or several items that have the same partition key value but different sort key values. The partition key equality test is required, and must be specified in the following format:  partitionKeyName = :partitionkeyval  If you also want to provide a condition for the sort key, it must be combined using AND with the condition for the sort key. Following is an example, using the = comparison operator for the sort key:  partitionKeyName = :partitionkeyval AND sortKeyName = :sortkeyval  Valid comparisons for the sort key condition are as follows:    sortKeyName = :sortkeyval - true if the sort key value is equal to :sortkeyval.    sortKeyName &lt; :sortkeyval - true if the sort key value is less than :sortkeyval.    sortKeyName &lt;= :sortkeyval - true if the sort key value is less than or equal to :sortkeyval.    sortKeyName &gt; :sortkeyval - true if the sort key value is greater than :sortkeyval.    sortKeyName &gt;=  :sortkeyval - true if the sort key value is greater than or equal to :sortkeyval.    sortKeyName BETWEEN :sortkeyval1 AND :sortkeyval2 - true if the sort key value is greater than or equal to :sortkeyval1, and less than or equal to :sortkeyval2.    begins_with ( sortKeyName, :sortkeyval ) - true if the sort key value begins with a particular operand. (You cannot use this function with a sort key that is of type Number.) Note that the function name begins_with is case-sensitive.   Use the ExpressionAttributeValues parameter to replace tokens such as :partitionval and :sortval with actual values at runtime. You can optionally use the ExpressionAttributeNames parameter to replace the names of the partition key and sort key with placeholder tokens. This option might be necessary if an attribute name conflicts with a DynamoDB reserved word. For example, the following KeyConditionExpression parameter causes an error because Size is a reserved word:    Size = :myval    To work around this, define a placeholder (such a #S) to represent the attribute name Size. KeyConditionExpression then is as follows:    #S = :myval    For a list of reserved words, see Reserved Words in the Amazon DynamoDB Developer Guide. For more information on ExpressionAttributeNames and ExpressionAttributeValues, see Using Placeholders for Attribute Names and Values in the Amazon DynamoDB Developer Guide.
    public var keyConditionExpression: String? = nil

    /// This is a legacy parameter. Use KeyConditionExpression instead. For more information, see KeyConditions in the Amazon DynamoDB Developer Guide.
    public var keyConditions: [String: DynamoDB.Condition]? = nil

    /// The maximum number of items to evaluate (not necessarily the number of matching items). If DynamoDB processes the number of items up to the limit while processing the results, it stops the operation and returns the matching values up to that point, and a key in LastEvaluatedKey to apply in a subsequent operation, so that you can pick up where you left off. Also, if the processed dataset size exceeds 1 MB before DynamoDB reaches this limit, it stops the operation and returns the matching values up to the limit, and a key in LastEvaluatedKey to apply in a subsequent operation to continue the operation. For more information, see Query and Scan in the Amazon DynamoDB Developer Guide.
    public var limit: Int? = nil

    /// A string that identifies one or more attributes to retrieve from the table. These attributes can include scalars, sets, or elements of a JSON document. The attributes in the expression must be separated by commas. If no attribute names are specified, then all attributes will be returned. If any of the requested attributes are not found, they will not appear in the result. For more information, see Accessing Item Attributes in the Amazon DynamoDB Developer Guide.
    public var projectionExpression: String? = nil

    /// This is a legacy parameter. Use FilterExpression instead. For more information, see QueryFilter in the Amazon DynamoDB Developer Guide.
    public var queryFilter: [String: DynamoDB.Condition]? = nil

    public var returnConsumedCapacity: DynamoDB.ReturnConsumedCapacity? = nil

    /// Specifies the order for index traversal: If true (default), the traversal is performed in ascending order; if false, the traversal is performed in descending order.  Items with the same partition key value are stored in sorted order by sort key. If the sort key data type is Number, the results are stored in numeric order. For type String, the results are stored in order of UTF-8 bytes. For type Binary, DynamoDB treats each byte of the binary data as unsigned. If ScanIndexForward is true, DynamoDB returns the results in the order in which they are stored (by sort key value). This is the default behavior. If ScanIndexForward is false, DynamoDB reads the results in reverse order by sort key value, and then returns the results to the client.
    public var scanIndexForward: Bool? = nil

    /// The attributes to be returned in the result. You can retrieve all item attributes, specific item attributes, the count of matching items, or in the case of an index, some or all of the attributes projected into the index.    ALL_ATTRIBUTES - Returns all of the item attributes from the specified table or index. If you query a local secondary index, then for each matching item in the index, DynamoDB fetches the entire item from the parent table. If the index is configured to project all item attributes, then all of the data can be obtained from the local secondary index, and no fetching is required.    ALL_PROJECTED_ATTRIBUTES - Allowed only when querying an index. Retrieves all attributes that have been projected into the index. If the index is configured to project all attributes, this return value is equivalent to specifying ALL_ATTRIBUTES.    COUNT - Returns the number of matching items, rather than the matching items themselves.    SPECIFIC_ATTRIBUTES - Returns only the attributes listed in AttributesToGet. This return value is equivalent to specifying AttributesToGet without specifying any value for Select. If you query or scan a local secondary index and request only attributes that are projected into that index, the operation will read only the index and not the table. If any of the requested attributes are not projected into the local secondary index, DynamoDB fetches each of these attributes from the parent table. This extra fetching incurs additional throughput cost and latency. If you query or scan a global secondary index, you can only request attributes that are projected into the index. Global secondary index queries cannot fetch attributes from the parent table.   If neither Select nor AttributesToGet are specified, DynamoDB defaults to ALL_ATTRIBUTES when accessing a table, and ALL_PROJECTED_ATTRIBUTES when accessing an index. You cannot use both Select and AttributesToGet together in a single request, unless the value for Select is SPECIFIC_ATTRIBUTES. (This usage is equivalent to specifying AttributesToGet without any value for Select.)  If you use the ProjectionExpression parameter, then the value for Select can only be SPECIFIC_ATTRIBUTES. Any other value for Select will return an error.
    public var select: DynamoDB.Select? = nil
}
*/

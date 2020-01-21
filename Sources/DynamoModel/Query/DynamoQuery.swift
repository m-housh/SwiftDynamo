//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation
import DynamoDB
import NIO

public protocol DynamoFetchQueryRepresentible {
    var fetchQuery: DynamoDB.QueryInput { get }
}

public struct DynamoQuery {

    // fields that get returned with the query.
    public var fields: [String]

    // the action we are taking on the database.
    public var action: Action

    // the schema we are interacting with.
    public var schema: DynamoSchema

    // an optional sort key for the table.
    public var sortKey: AnySortKey?

    // values to be saved to the database.
    public var input: [Value]

    // limit
    /// The maximum number of items to evaluate (not necessarily the number of matching items). If DynamoDB processes the number of items up to the limit while processing the results, it stops the operation and returns the matching values up to that point, and a key in LastEvaluatedKey to apply in a subsequent operation, so that you can pick up where you left off. Also, if the processed dataset size exceeds 1 MB before DynamoDB reaches this limit, it stops the operation and returns the matching values up to the limit, and a key in LastEvaluatedKey to apply in a subsequent operation to continue the operation. For more information, see Query and Scan in the Amazon DynamoDB Developer Guide.
    public var limit: Int?

    public var attributesToGet: [String]

    public init(schema: DynamoSchema) {
        self.action = .read
        self.schema = schema
        self.fields = []
        self.input = []
        self.sortKey = nil
        self.limit = nil
        self.attributesToGet = []
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
        case list([[String: DynamoDB.AttributeValue]])
        case dictionary([String: DynamoDB.AttributeValue])
    }
}

extension DynamoQuery {

    func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        fatalError()
    }
}

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

    var queryInput: DynamoDB.QueryInput

    init(_ queryInput: DynamoDB.QueryInput) {
        self.queryInput = queryInput
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

//
//  PaginatedResponse.swift
//  
//
//  Created by Michael Housh on 5/22/20.
//

import Foundation
import DynamoDB

/// The response type for a paginated query.  Which includes the models and the last evaluated key that is used
/// to retrieve the next page of results.
public struct PaginatedResponse<Model>: Codable where Model: DynamoModel {

    /// The models returned from the query.
    public let items: [Model]

    /// The last evaluated key used as the start key for retrieving the next page of results.
    /// If this is `nil` then you have reached the last page of results.
    public let lastEvaluatedKey: [String: DynamoDB.AttributeValue]?

    /// Create a new paginated response.
    ///
    /// - Parameters:
    ///     - items:  The models returned from the query.
    ///     - lastEvauatedKey:  The last evaluated key.
    public init(
        items: [Model],
        lastEvaluatedKey: [String: DynamoDB.AttributeValue]? = nil
    ) {
        self.items = items
        self.lastEvaluatedKey = lastEvaluatedKey
    }
}

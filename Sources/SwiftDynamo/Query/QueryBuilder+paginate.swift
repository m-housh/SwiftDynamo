//
//  PaginatedResponse.swift
//  
//
//  Created by Michael Housh on 5/22/20.
//

import Foundation
import NIO
import DynamoDB

/// The response type for a paginated query.  Which includes the models and the last evaluated key that is used
/// to retrieve the next page of results.
public struct PaginatedResponse<Model>: Codable where Model: Codable {

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

extension DynamoQueryBuilder {

    /// Runs the query and returns a paginated result of `AttributeDecodable` types.  You retrieve the first page by not passing in a last evaluated key.
    /// You can retrieve the next page by passing in the last evaluated key.
    ///
    /// - Parameters:
    ///     - limit:  The number of items per page.
    ///     - last:  The last evaluated key, returned by previous paginated query.
    public func paginate<T>(
        decodeTo: T.Type,
        limit: Int = 50,
        last: [String: DynamoDB.AttributeValue]? = nil
    ) -> EventLoopFuture<PaginatedResponse<T>>
        where T: AttributeDecodable
    {
        var models = [Result<T, Error>]()
        var lastEvaluatedKey: [String: DynamoDB.AttributeValue]?
        // set the start key, if this is not the first page request.
        if let strongLast = last {
            self.setOption(.exclusiveStartKey(strongLast))
        }

        // Set the limit
        self.limit(limit)

        return self.all(decodeTo: T.self) { (model, lastEvaluated) in
            models.append(model)
            lastEvaluatedKey = lastEvaluated
        }
        .flatMapThrowing {
            return try models.map {
                try $0.get()
            }
        }
        .map { PaginatedResponse(items: $0, lastEvaluatedKey: lastEvaluatedKey) }
    }
}

extension DynamoQueryBuilder where Model: AttributeConvertible {
    /// Runs the query and returns a paginated result.  You retrieve the first page by not passing in a last evaluated key.
    /// You can retrieve the next page by passing in the last evaluated key.
    ///
    /// - Parameters:
    ///     - limit:  The number of items per page.
    ///     - last:  The last evaluated key, returned by previous paginated query.
    public func paginate(limit: Int = 50, last: [String: DynamoDB.AttributeValue]? = nil) -> EventLoopFuture<PaginatedResponse<Model>> {
        self.paginate(decodeTo: Model.self, limit: limit, last: last)
    }
}

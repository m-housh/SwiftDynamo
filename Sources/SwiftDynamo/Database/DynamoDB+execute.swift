//
//  DynamoDB+execute.swift
//  
//
//  Created by Michael Housh on 1/21/20.
//

import Foundation
import DynamoDB
import NIO

extension DynamoDB {

    /// Execute a query and react to it's output.
    ///
    /// - parameters:
    ///     - query: The query to execute.
    ///     - onResult: A callback to run with the resulting output.
    public func execute(
        query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        switch query.action {
        case .read, .scan, .query: return _read(query, onResult: callback)
        case .create: return _create(query, onResult: callback)
        case .update: return _update(query, onResult: callback)
        case .delete: return _delete(query)
        case .batchDelete: return _batchDelete(query)
        case .batchCreate: return _batchCreate(query, onResult: callback)
//        default:
//            fatalError()
        }
    }

    private func _delete(
        _ query: DynamoQuery
    ) -> EventLoopFuture<Void> {
        self.batchWriteItem(.deleteRequest(from: query))
            .map { _ in }
    }

    // run a read query.
    // If no sort key / partition keys are on the query then we use
    // the more intrusive `scan`.  We use `query` otherwise.
    private func _read(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {

        if _shouldUseScan(for: query) {
            // use scan.
            return self.scan(.from(query))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!, output.lastEvaluatedKey)))
                }
        } else {
            // use query when a sort / partition key is available.
            return self.query(.from(query))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!, output.lastEvaluatedKey)))
                }
        }
    }

    private func _shouldUseScan(for query: DynamoQuery) -> Bool {
        if query.action == .scan { return true }
        if query.action == .query { return false }
        if query.sortKey != nil || query.partitionKey != nil {
            return false
        }
        // check options
        let options = query.optionsContainer

        if options.keyConditionExpression != nil { return false }

        return true
    }

    // Create a single item in the database.
    private func _create(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        let putItemInput = DynamoDB.PutItemInput.from(query)
        return self.putItem(putItemInput)
            .map { output in
                callback(.init(database: self, output: .dictionary(putItemInput.item)))
        }
    }

    // update a single item in the database
    private func _update(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        let updateItemInput = DynamoDB.UpdateItemInput.from(query)
        return self.updateItem(updateItemInput)
            .map { output in
                callback(.init(database: self, output: .dictionary(output.attributes ?? [:])))
            }
    }

    // the batch items need to be limited to 25 items, so either need to loop over them
    // or add a precondition.
    private func _batchCreate(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        // swiftlint:disable force_try
        let batchInput = try! DynamoDB.BatchWriteItemInput.createRequest(from: query)
        return self.batchWriteItem(batchInput)
            .map { output in
                callback(.init(database: self, output: .dictionary([:])))
            }
    }

    private func _batchDelete(_ query: DynamoQuery) -> EventLoopFuture<Void> {
        return self.batchWriteItem(.batchDeleteRequest(from: query))
            .map { _ in }
    }
}

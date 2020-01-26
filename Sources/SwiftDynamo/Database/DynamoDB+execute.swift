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
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        switch query.action {
        case .read: return _read(query, onResult: callback)
        case .create: return _create(query, onResult: callback)
        case .update: return _update(query, onResult: callback)
        case .delete: return _delete(query)
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

    // MARK: - TODO
    //          We need to build a filter expression for scan and
    //          only run query if both a partition key is available
    
    // run a read query.
    // If no sort key / partition keys are on the query then we use
    // the more intrusive `scan`.  We use `query` otherwise.
    private func _read(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {

        if _shouldUseScan(for: query) {
            // use scan.
            return self.scan(.init(tableName: query.schema.tableName))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!)))
                }
        } else {
            // use query when a sort / partition key is available.
            return self.query(.from(query))
                .map { output in
                    callback(.init(database: self, output: .list(output.items!)))
                }
        }
    }

    // MARK: - TODO
    //          This needs to be based off of partition key only,
    //          to allow for scan to be used with a sort-key to filter
    //          the results.  We also need to build the filter expression
    //          for a scan request instead of scanning entire table.
    private func _shouldUseScan(for query: DynamoQuery) -> Bool {
        if query.sortKey != nil || query.partitionKey != nil {
            return false
        }
        // check options
        let options = query.optionsContainer

        if let _ = options.keyConditionExpression { return false }

        return true
    }

    // Create a single item in the database.
    private func _create(
        _ query: DynamoQuery,
        onResult callback: @escaping (DatabaseOutput) -> ()
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
        onResult callback: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let updateItemInput = DynamoDB.UpdateItemInput.from(query)
        return self.updateItem(updateItemInput)
            .map { output in
                callback(.init(database: self, output: .dictionary(output.attributes ?? [:])))
            }
    }
}

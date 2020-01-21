//
//  DynamoQueryBuilder.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import DynamoDB

public final class DynamoQueryBuilder<Model> where Model: DynamoModel {

    public var query: DynamoQuery
    public let database: DynamoDB

    public init(database: DynamoDB) {
        self.database = database
        self.query = .init(schema: Model.schema)
        self.query.fields = Model().fields.map { (_, field) in
            return field.key
        }
//        self.query.sortKey = Model.schema.sortKey
    }

    @discardableResult
    func sortKey(_ key: KeyPath<Model, SortKey<String>>) -> Self {
        query.sortKey = Model()[keyPath: key]
        return self
    }
//
//    @discardableResult
//    func sortKey(_ key: String) -> Self {
//        query.sortKey = DynamoSchema.SortKey.string(key)
//        return self
//    }

    @discardableResult
    func limit(_ limit: Int) -> Self {
        query.limit = limit
        return self
    }

    @discardableResult
    func limitAttributes<Field>(to attributes: KeyPath<Model, Field>...) -> Self where Field: FieldRepresentible {
        query.attributesToGet += attributes.map { Model.key(for: $0) }
        return self
    }
}

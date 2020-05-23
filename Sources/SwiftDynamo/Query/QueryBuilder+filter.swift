//
//  QueryBuilder+filter.swift
//  
//
//  Created by Michael Housh on 5/23/20.
//

import Foundation


// MARK: - Field Value Filters
public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> DynamoModelValueFilter<Model>
        where Model: DynamoModel, Field: FieldRepresentible {
            .init(lhs, .equal, rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> DynamoModelValueFilter<Model>
        where Model: DynamoModel, Field: FieldRepresentible {
            .init(lhs, .notEqual, rhs)
}

public struct DynamoModelValueFilter<Model> where Model: DynamoModel {

    let key: DynamoQuery.Filter.FieldFilterKey
    let method: DynamoQuery.Filter.Method
    let value: DynamoQuery.Value

    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Field.Value
    )
        where Field: FieldRepresentible
    {
        let field = Model()[keyPath: lhs].field
        self.key = .init(field: field)
        self.method = method
        self.value = .bind(value)
    }
}

extension DynamoQuery.Filter.FieldFilterKey {

    init(field: AnyField) {
        self.key = field.key
        self.isPartitionKey = field.partitionKey
        self.isSortKey = field.sortKey
    }
}

extension DynamoQueryBuilder where Model: DynamoModel {

    @discardableResult
    public func filter(_ filter: DynamoModelValueFilter<Model>) -> Self {
        self.filter(
            .field(filter.key, filter.method, filter.value)
        )
    }

    @discardableResult
    public func filter<Value>(
        _ field: KeyPath<Model, Field<Value>>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        return self.filter(.field(.init(field: Model()[keyPath: field].field), method, .bind(value)))
    }

    @discardableResult
    public func filter<Value, Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DynamoQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Field: FieldRepresentible, Field.Value == Value
    {
        query.filters.append(.field(.init(field: Model()[keyPath: field].field), method, .bind(value)))
        return self
    }
}

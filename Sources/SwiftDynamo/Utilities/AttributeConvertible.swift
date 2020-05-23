//
//  AttributeConvertible.swift
//  
//
//  Created by Michael Housh on 5/23/20.
//

import Foundation
import DynamoDB

public protocol AttributeEncodable: Encodable {
    func encode() -> [String: DynamoQuery.Value]
}

public protocol AttributeDecodable: Decodable {
    init(from output: [String: DynamoDB.AttributeValue]) throws
}

public protocol AttributeConvertible: AttributeDecodable, AttributeEncodable { }

extension AttributeConvertible {

    public static func query(_ table: DynamoSchema, on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        .init(schema: table, database: database)
    }

    public static func query(_ table: String, on database: DynamoDB) -> DynamoQueryBuilder<Self> {
        .init(schema: DynamoSchema(table), database: database)
    }
}

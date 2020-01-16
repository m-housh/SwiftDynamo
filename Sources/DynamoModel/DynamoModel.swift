//
//  DynamoModel.swift
//
//
//  Created by Michael Housh on 1/15/20.
//

import Foundation
import DynamoDB

public protocol DynamoModel {

    static var tableName: String { get }

    init(attributes: DynamoDBAttributeContainer) throws

    var attributesContainer: DynamoDBAttributeContainer { get }
}

extension UUID: DynamoAttributeValueRepresentible {

    public var dynamoAttributeValue: DynamoDB.AttributeValue {
        .init(s: uuidString)
    }
}

extension String: DynamoAttributeValueRepresentible {
    public var dynamoAttributeValue: DynamoDB.AttributeValue {
        .init(s: self)
    }
}

enum DynamoEmployeeModelError: Error {
    case invalidAttributes
    case invalidID
}

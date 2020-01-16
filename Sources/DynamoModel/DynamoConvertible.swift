//
//  DynamoConvertible.swift
//  
//
//  Created by Michael Housh on 1/15/20.
//

import Foundation
import DynamoDB

public typealias DynamoDBAttributeContainer = [String: DynamoDB.AttributeValue]

public protocol DynamoAttributeValueRepresentible {
    var dynamoAttributeValue: DynamoDB.AttributeValue { get }
}

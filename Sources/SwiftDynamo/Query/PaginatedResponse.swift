//
//  PaginatedResponse.swift
//  
//
//  Created by Michael Housh on 5/22/20.
//

import Foundation
import DynamoDB

public struct PaginatedResponse<Model> where Model: DynamoModel {
    public let items: [Model]
    public let lastEvaluatedKey: [String: DynamoDB.AttributeValue]?
}

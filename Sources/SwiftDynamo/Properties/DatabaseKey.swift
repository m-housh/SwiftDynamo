//
//  DatabaseKey.swift
//  
//
//  Created by Michael Housh on 4/5/20.
//

import Foundation
import DynamoDB

public protocol AnyDynamoDatabaseKey {
    var key: [String: DynamoDB.AttributeValue] { get }
}

struct DatabaseKey: AnyDynamoDatabaseKey {

    var key: [String : DynamoDB.AttributeValue]

}

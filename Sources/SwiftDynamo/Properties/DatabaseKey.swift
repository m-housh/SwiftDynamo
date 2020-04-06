//
//  DatabaseKey.swift
//  
//
//  Created by Michael Housh on 4/5/20.
//

import Foundation
import DynamoDB

public protocol AnyDatabaseKey {
    var key: [String: DynamoDB.AttributeValue] { get }
}

struct DatabaseKey: AnyDatabaseKey {

    var key: [String : DynamoDB.AttributeValue]

}

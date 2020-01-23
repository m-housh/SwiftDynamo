//
//  DynamoModelError.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import Foundation

public enum DynamoModelError: Error {

    case attributeError
    case notFound
    case invalidField(key: String, valueType: Any.Type, error: Error?)
}

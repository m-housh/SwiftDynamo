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

    public var localizedDescription: String {
        switch self {
        case .attributeError: return "Attribute Error"
        case .notFound: return "Not Found"
        case let .invalidField(key, type, error):
            let errorDescription = error == nil ? "Unknown Error" : error!.localizedDescription
            return "Invalid Field, expected: '\(type)' for key: '\(key)', error: '\(errorDescription)'"

        }
    }
}

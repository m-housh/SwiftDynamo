//
//  Parent.swift
//  
//
//  Created by Michael Housh on 1/24/20.
//

import Foundation

@propertyWrapper
public final class Parent<To> where To: DynamoModel {

    @Field
    public var id: To.IDValue

    public var wrappedValue: To {
        get {
            guard let value = self.eagerLoadedValue else {
                fatalError("Parent relation not eager loaded, use $ prefix to access")
            }
            return value
        }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: Parent<To> {
        return self
    }

    var eagerLoadedValue: To?

    public init(key: String) {
        self._id = .init(key: key)
    }

}

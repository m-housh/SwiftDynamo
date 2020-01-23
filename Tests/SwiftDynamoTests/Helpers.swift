//
//  Helpers.swift
//  
//
//  Created by Michael Housh on 1/20/20.
//

import Foundation
import SwiftDynamo
import DynamoDB
import AWSSDKSwiftCore

final class TestModel: DynamoModel, Equatable, Codable {

    static var schema = DynamoSchema("TodoTest", partitionKey: .init(key: "ListID", default: "list"))

    @ID(key: "TodoID")
    var id: UUID?

    @Field(key: "Title")
    var title: String

    @Field(key: "Order")
    var order: Int?

    @Field(key: "Completed")
    var completed: Bool

    init() { }

    static func ==(lhs: TestModel, rhs: TestModel) -> Bool {
        lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.order == rhs.order
    }
}

extension DynamoDB {

    static var testing: DynamoDB {
        .init(
            accessKeyId: nil,
            secretAccessKey: nil,
            sessionToken: nil,
            region: Region(rawValue: "us-east-2"),
            endpoint: "http://localhost:8000",
            middlewares: [],
            eventLoopGroupProvider: .useAWSClientShared
        )
    }
}

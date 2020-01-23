//
//  XCTDynamo.swift
//  
//
//  Created by Michael Housh on 1/23/20.
//

import XCTest
import SwiftDynamo


public protocol XCTDynamoTestCase {
    var database: DynamoDB { get }
    associatedtype Model: DynamoModel
}

extension XCTDynamoTestCase where Self: XCTestCase {

    @discardableResult
    public func save(
        _ model: Model,
        callback: @escaping (Model) -> ()
    ) throws -> Self
    {
        let model = try model.save(on: database).wait()
        callback(model)
        return self
    }

    @discardableResult
    public func find(
        id: Model.IDValue,
        callback: @escaping (Model?) throws -> ()
    ) throws -> Self
    {
        let model = try Model.find(id: id, on: database).wait()
        try callback(model)
        return self
    }

    @discardableResult
    public func fetchAll(
        callback: @escaping ([Model]) throws -> ()
    ) throws -> Self
    {
        let models = try Model.query(on: database).all().wait()
        try callback(models)
        return self
    }

    @discardableResult
    public func delete(
        _ id: Model.IDValue,
        callback: @escaping () throws -> ()
    ) throws -> Self
    {
        try Model.delete(id: id, on: database).wait()
        try callback()
        return self
    }

    @discardableResult
    public func run(
        _ query: DynamoQueryBuilder<Model>,
        callback: @escaping (DatabaseOutput) throws -> ()
    ) throws -> Self {
        var output: DatabaseOutput? = nil
        try query.run({ output = $0 }).wait()
        try callback(output!)
        return self
    }

    public func deleteAll() {
        try! fetchAll() { models in
            _ = models.map { try! Model.delete(id: $0.id!, on: self.database).wait() }
        }
    }

    public func runTest(
        _ function: StaticString = #function,
        _ file: String = #file,
        _ line: Int = #line,
        closure: () throws -> ()
    ) throws {
        do {
            try closure()
        }
        catch {
            print("error: \(error)", function, file, line)
            throw error
        }
    }
}

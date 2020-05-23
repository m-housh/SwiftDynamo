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
    var seeds: [Model] { get }
    associatedtype Model: DynamoModel
}

extension XCTDynamoTestCase where Self: XCTestCase {

    @discardableResult
    public func save(
        _ model: Model,
        callback: @escaping (Model) -> Void
    ) throws -> Self
    {
        let model = try model.save(on: database).wait()
        callback(model)
        return self
    }

    @discardableResult
    public func update(
        _ model: Model,
        callback: @escaping (Model) -> Void
    ) throws -> Self
    {
        let model = try model.update(on: database).wait()
        callback(model)
        return self
    }

    @discardableResult
    public func find(
        id: Model.IDValue,
        callback: @escaping (Model?) throws -> Void
    ) throws -> Self
    {
        let model = try Model.find(id: id, on: database).wait()
        try callback(model)
        return self
    }

    @discardableResult
    public func fetchAll(
        callback: @escaping ([Model]) throws -> Void
    ) throws -> Self
    {
        let models = try Model.query(on: database).all().wait()
        try callback(models)
        return self
    }

    @discardableResult
    public func delete(
        _ id: Model.IDValue,
        callback: @escaping () throws -> Void
    ) throws -> Self
    {
        try Model.delete(id: id, on: database).wait()
        try callback()
        return self
    }

    @discardableResult
    public func run(
        _ query: DynamoQueryBuilder<Model>,
        callback: @escaping (DatabaseOutput) throws -> Void
    ) throws -> Self {
        var output: DatabaseOutput?
        try query.run({ output = $0 }).wait()
        try callback(output!)
        return self
    }

    // swiftlint:disable force_try
    public func deleteAll() {
        try! fetchAll { models in
            _ = try models.map { try Model.delete(id: $0.id!, on: self.database).wait() }
//            try! Model.batchDelete(models, on: self.database).wait()
        }
    }

    public func runTest(
        _ function: StaticString = #function,
        _ file: String = #file,
        _ line: Int = #line,
        seed: Bool = false,
        deleteAll: Bool = true,
        closure: () throws -> Void
    ) throws {

        do {
            if seed == true {
                _ = try seeds.map { try save($0) {_ in } }
            }
            try closure()
        }
        catch {
            print("error: \(String(describing: error))")
            print("error: \(error.localizedDescription)", function, file, line)
            throw error
        }

        if deleteAll == true {
            self.deleteAll()
        }

    }
}

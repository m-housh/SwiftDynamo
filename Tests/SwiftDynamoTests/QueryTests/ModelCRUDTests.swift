//
//  File.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//


import XCTest
import DynamoDB
import XCTDynamo
@testable import SwiftDynamo

final class ModelCRUDTests: XCTestCase, XCTDynamoTestCase {

    let database = DynamoDB.testing
    typealias Model = TestModel

    func testFetchAll() throws {
        deleteAll()
        saveSeeds()

        try self.fetchAll() { models in
            XCTAssertEqual(models.count, self.seeds.count)
        }
    }

    func testFetchAll2() throws {
        try runTest(seed: true) {
            try fetchAll() { XCTAssert($0.count > 0) }
        }
    }

    func testFirst() throws {
        try runTest(seed: true) {
            let model = try TestModel
                .query(on: database)
                .first()
                .wait()

            XCTAssertNotNil(model)
        }
    }

    func testCreate() throws {

        try runTest {
            let model2 = TestModel()
            model2.id = .init()
            model2.completed = false
            model2.title = "Two"
            model2.order = 2

            var beforeCount = 0
            try fetchAll() { models in
                beforeCount = models.count
            }
            .save(model2) { saved in
                XCTAssertEqual(saved.completed, false)
                XCTAssertEqual(saved.title, "Two")
                XCTAssertEqual(saved.order, 2)
            }
            .fetchAll() { models in
                XCTAssertEqual(models.count, beforeCount + 1)
            }
            .find(id: model2.id!) { fetched in
                XCTAssertEqual(fetched!.id, model2.id)
                XCTAssertEqual(fetched!.title, "Two")
                XCTAssertEqual(fetched!.completed, false)
                XCTAssertEqual(fetched!.order, 2)
            }
            .delete(model2.id!) { }
            .fetchAll() { models in
                XCTAssertEqual(models.count, beforeCount)
            }
        }
    }

    func testUpdate() throws {
        try runTest(seed: true) {
            var random: TestModel!
            var beforeCount: Int = 0
            try fetchAll() {
                random = $0.randomElement()!
                beforeCount = $0.count
            }

            random.title = "Updated"
            try save(random) { saved in
                XCTAssertEqual(random, saved)
                XCTAssertEqual(saved.title, "Updated")
            }
            .fetchAll() {
                XCTAssertEqual(beforeCount, $0.count)
            }

        }
    }

    func testUpdateWithPatch() throws {
        try runTest(seed: true) {
            var random: TestModel!
            var beforeCount = 0

            try fetchAll {
                random = $0.randomElement()!
                beforeCount = $0.count
            }

            let patch = PatchTodo(title: "Patched", order: 80, completed: false)
            var query = TestModel
                .query(on: database)
                .filter(\.$id == random.id!)

            patch.patchQuery(&query)
            try query.update().wait()

            try find(id: random.id!) { afterSave in
                XCTAssertNotNil(afterSave)
                XCTAssertEqual(afterSave!.order, 80)
                XCTAssertEqual(afterSave!.title, "Patched")
                XCTAssertEqual(afterSave!.completed, false)
            }
            .fetchAll() {
                XCTAssertEqual($0.count, beforeCount)
            }
        }
    }

    func testFindID() throws {
        try runTest(seed: true) {
            let random = self.seeds.randomElement()!
            try self.find(id: random.id!) { fetched in
                XCTAssertNotNil(fetched)
                XCTAssertEqual(fetched, random)
            }
        }
    }

    func testDeleteID() throws {
        try runTest(seed: true) {
            let random = self.seeds.randomElement()!

            var beforeCount = 0

            try fetchAll() { models in
                _ = models.map { print($0) }
                beforeCount = models.count
                XCTAssertNotEqual(beforeCount, 0)
            }
            .delete(random.id!) { }
            .fetchAll() { after in
                XCTAssertEqual(after.count, beforeCount - 1)
                XCTAssertNil(after.first(where: { $0.id == random.id }))
            }
        }
    }

    func testFilter() throws {
        try runTest(seed: true) {
            var random: TestModel!

            try fetchAll() { models in
                random = models.randomElement()!
            }
//            .find(id: random.id!) { fetched in
//                XCTAssertEqual(fetched, random)
//            }
            let fetched = try TestModel.query(on: database)
                .filter(\.$title == random.title)
                .first()
                .wait()

            XCTAssertNotNil(fetched)
            XCTAssertEqual(fetched?.title, random.title)
        }
    }

    var seeds: [TestModel] = [
        TestModel(id: .init(), title: "One", completed: false, order: 1),
        TestModel(id: .init(), title: "Two", completed: true, order: 2),
        TestModel(id: .init(), title: "Three", completed: false, order: 3),
        TestModel(id: .init(), title: "Four", completed: true, order: 4),
        TestModel(id: .init(), title: "Five", completed: false, order: 5),
        TestModel(id: .init(), title: "Six", completed: false, order: 6)
    ]


    func saveSeeds() {
        _ = seeds.map { try! $0.save(on: database).wait() }
    }

    func deleteSeeds() {
        _ = seeds.map { try! TestModel.delete(id: $0.id!, on: database).wait() }
    }

    func deleteAll() {
        try! fetchAll() { models in
            _ = models.map { try! TestModel.delete(id: $0.id!, on: self.database).wait() }
        }
    }

    func runTest(
        _ function: StaticString = #function,
        _ file: String = #file,
        _ line: Int = #line,
        seed: Bool = false,
        closure: () throws -> ()) throws
    {
        if seed == true {
            saveSeeds()
        }
        do {
            try closure()
            deleteAll()
        }
        catch {
            deleteAll()
            print("Error: \(error)", file, line, function)
            throw error
        }
    }
}

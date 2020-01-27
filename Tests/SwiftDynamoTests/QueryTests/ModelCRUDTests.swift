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
        try runTest(seed: true) {
            try self.fetchAll() { models in
                XCTAssertEqual(models.count, self.seeds.count)
            }
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
            try update(random) { saved in
                XCTAssertEqual(random, saved)
                XCTAssertEqual(saved.title, "Updated")
            }
            .fetchAll() {
                XCTAssertEqual(beforeCount, $0.count)
            }
        }
    }

    func testUpdate2() throws {
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
                .filter(\.$id, .equal, random.id!)

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

    func testUpdatesWithPatch2() throws {
        try runTest(seed: true) {
            var random: TestModel!
            var beforeCount: Int!

            try fetchAll() {
                random = $0.randomElement()!
                beforeCount = $0.count
            }
            let data: [String: DynamoQuery.Value] = [
                "Title": .bind("FooBar"),
                "Completed": .bind(true)
            ]

            try TestModel
                .query(on: database)
                .filter(\.$id == random.id)
                .set(data)
                .update()
                .wait()

            try fetchAll() {
                XCTAssertEqual($0.count, beforeCount)
            }
            .find(id: random.id!) { updated in
                XCTAssertNotNil(updated)
                XCTAssertEqual(updated?.title, "FooBar")
                XCTAssertEqual(updated?.completed, true)
            }

        }
    }

    func testUpdateWithPatch3() throws {
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
                .filter(\.$id, .equal, random.id!)

            patch.patchQuery(&query)
            let saved = try query
                .setAction(to: .update)
                .first()
                .wait()

            XCTAssertNotNil(saved)

            try find(id: random.id!) { afterSave in
                XCTAssertNotNil(afterSave)
                XCTAssertEqual(afterSave!.order, 80)
                XCTAssertEqual(afterSave!.title, "Patched")
                XCTAssertEqual(afterSave!.completed, false)
                XCTAssertEqual(saved, afterSave)
            }
            .fetchAll() {
                XCTAssertEqual($0.count, beforeCount)
            }
        }
    }

    func testCreateAction() throws {
        try runTest {
            let model = TestModel(id: .init(), title: "Created", completed: true, order: 10)

            try TestModel.query(on: database)
                .set(\.$id,  to: model.id!)
                .set(\.$title, to: model.title)
                .set(\.$completed, to: model.completed)
                .set(\.$order, to: model.order!)
                .create()
                .wait()

            try find(id: model.id!) { fetched in
                XCTAssertNotNil(fetched)
                XCTAssertEqual(fetched, model)
            }
        }
    }

    func testDeleteAction() throws {
        try runTest(seed: true) {

            var random: TestModel!
            var beforeCount: Int!

            try fetchAll() {
                beforeCount = $0.count
                random = $0.randomElement()!
            }

            try TestModel.query(on: database)
                .filter(\.$id.field, .equal, random.id!)
                .delete()
                .wait()

            try fetchAll() {
                XCTAssertEqual($0.count, beforeCount - 1)
            }
            .find(id: random.id!) {
                XCTAssertNil($0)
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
            .find(id: random.id!) { fetched in
                XCTAssertEqual(fetched, random)
            }
            .run(
                // We have to use run or it fails when running in parallel with other tests,
                // works when run by itself -\_0_/-
                TestModel.query(on: database)
                    .filter(\.$title == random.title)
            ) { output in
                let model = TestModel()
                try model.output(from: output)
                XCTAssertEqual(model.title, random.title)
            }

        }
    }

    func testNotEqualFilter() throws {
        try runTest(seed: true) {

            var random: TestModel!
            var count: Int = 0

            try fetchAll() {
                random = $0.randomElement()!
                count = $0.count
            }

            let fetched = try TestModel
                .query(on: database)
                .filter(\.$title != random.title)
                .all()
                .wait()

            XCTAssertEqual(count - 1, fetched.count)
            XCTAssertNil(fetched.first(where: { $0.id == random.id! }))
        }
    }

    func testQueryOnPartitionOnlyKeyTable() throws {
        final class PartitionTodo: DynamoModel {
            static var schema: DynamoSchema = "TodoPartitionTest"

            @ID(key: "TodoID", type: .partitionKey)
            var id: UUID?

            @Field(key: "Completed")
            var completed: Bool

            @Field(key: "Order")
            var order: Int?

            @Field(key: "Title")
            var title: String

            init() { }

            convenience init(model: TestModel) {
                self.init()
                self.id = model.id
                self.completed = model.completed
                self.order = model.order
                self.title = model.title
            }
        }

        try runTest {
            let seeds = self.seeds.map { PartitionTodo(model: $0) }
            _ = try seeds.map { try $0.save(on: database).wait() }

            let random = seeds.last!

//            let builder = PartitionTodo.query(on: database).filter(\.$id == random.id!)

            let fetched = try PartitionTodo.find(id: random.id!, on: database).wait()
            XCTAssertEqual(random.id, fetched!.id)

            _ = try seeds.map { try PartitionTodo.delete(id: $0.id!, on: database).wait() }
        }
    }

    // Empty lists work on our end, but `aws` fails when decoding
    // items from the database because they think they are empty string sets.
    func testEmptyListsWorkCorrectly() throws {
        final class PartitionTodo: DynamoModel {
            static var schema: DynamoSchema = "TodoPartitionTest"

            @ID(key: "TodoID", type: .partitionKey)
            var id: UUID?

            @Field(key: "Completed")
            var completed: Bool

            @Field(key: "Order")
            var order: Int?

            @Field(key: "Title")
            var titles: [String]

            @Field(key: "Names")
            var names: [Name]

            init() { }

            struct Name: Codable {
                var first: String
                var last: String
            }
        }

        let model = PartitionTodo()
        model.id = .init()
        model.completed = false
        model.order = 1
        model.titles = [] // test with primitive types
        model.names = [] // test with non-primitive types

        let saved = try model.save(on: database).wait()
        XCTAssertEqual(saved.titles.count, 0)
        XCTAssertEqual(saved.names.count, 0)

        try PartitionTodo.delete(id: model.id!, on: database).wait()

    }

    func testListsOfEncodablesWorkCorrectly() throws {
        final class PartitionTodo: DynamoModel {
            static var schema: DynamoSchema = "TodoPartitionTest"

            @ID(key: "TodoID", type: .partitionKey)
            var id: UUID?

            @Field(key: "Completed")
            var completed: Bool

            @Field(key: "Order")
            var order: Int?

            @Field(key: "Names")
            var names: [Name]

            init() { }

            struct Name: Codable {
                var first: String
                var last: String
            }
        }

        let model = PartitionTodo()
        model.id = .init()
        model.completed = false
        model.order = 1
        model.names = [.init(first: "foo", last: "bar"), .init(first: "joan", last: "jett")] // test with non-primitive types

        let saved = try model.save(on: database).wait()
        XCTAssertEqual(saved.names.count, 2)
//
//        let all = try PartitionTodo.query(on: database).first().wait()
//        print(all)

        let fetched = try PartitionTodo.find(id: model.id!, on: database).wait()
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched!.names.count, 2)
        let firsts = ["foo", "joan"]
        let lasts = ["bar", "jett"]
        let fetchedFirsts = fetched!.names.map { $0.first }
        let fetchedLasts = fetched!.names.map { $0.last }

        for first in fetchedFirsts { XCTAssert(firsts.contains(first)) }
        for last in fetchedLasts { XCTAssert(lasts.contains(last)) }

        let _all = try PartitionTodo.query(on: database).all().wait()

        _ = try _all.map { try PartitionTodo.delete(id: $0.id!, on: database).wait() }

    }

    func testWithSortKeyAsRelationshipKey() {
        final class RelationTodo: DynamoModel {
            static var schema: DynamoSchema {
                .init("Todo", sortKey: .init(key: "SortKey", default: "Keys"))
            }

            @ID(key: "TodoID", type: .partitionKey)
            var id: UUID?

            @Field(key: "Title")
            var titles: [String]

            init() { }

        }

        final class TodoDetails: DynamoModel {
            static var schema: DynamoSchema {
                .init("Todo", sortKey: .init(key: "SortKey", default: "Details"))
            }

            @ID(key: "DetailsID", type: .none)
            var id: UUID?

            @Field(key: "TodoID", partitionKey: true)
            var todoID: UUID

            init() { }

        }

        let builder = RelationTodo.query(on: database).query.optionsContainer
        print(builder)

        let relation = TodoDetails
            .query(on: database)
            .filter(\.$todoID == UUID())

        print(relation.query.optionsContainer)
    }

    // MARK: - Helpers
    var seeds: [TestModel] = [
        TestModel(id: .init(), title: "One", completed: false, order: 1),
        TestModel(id: .init(), title: "Two", completed: true, order: 2),
        TestModel(id: .init(), title: "Three", completed: false, order: 3),
        TestModel(id: .init(), title: "Four", completed: true, order: 4),
        TestModel(id: .init(), title: "Five", completed: false, order: 5),
        TestModel(id: .init(), title: "Six", completed: false, order: 6)
    ]

}

//
//  File.swift
//  
//
//  Created by Michael Housh on 1/22/20.
//


import XCTest
import DynamoDB
@testable import SwiftDynamo

final class ModelCRUDTests: XCTestCase {

    let database = DynamoDB.testing

    func testFetchAll() throws {
        do {
            let models = try TestModel
                .query(on: database)
                .all()
                .wait()
            XCTAssert(models.count > 0)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testFirst() throws {
        let model = try TestModel
            .query(on: database)
            .first()
            .wait()

        XCTAssertNotNil(model)
    }

    func testCreate() throws {
        do {
            let model = TestModel()
            model.completed = false
            model.title = "Test Create"
            model.order = 2

            let saved = try model.save(on: database).wait()
            XCTAssertNotNil(saved.id)
            XCTAssertEqual(saved.title, "Test Create")
            XCTAssertFalse(saved.completed)
            XCTAssertEqual(saved.order, 2)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testUpdate() throws {
        do {
            let model = try TestModel.query(on: database).first().wait()!
            model.title = "Updated"

            let saved = try model.save(on: database).wait()
            XCTAssertEqual(saved.title, "Updated")
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testFindID() throws {
        do {
            let model = try TestModel.query(on: database).first().wait()!
            let fetched = try TestModel.find(id: model.id!, on: database).wait()!
            XCTAssertEqual(model, fetched)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testDeleteID() throws {
        do {
            let models = try TestModel.query(on: database).all().wait()
            try TestModel.delete(id: models[0].id!, on: database).wait()
            let after = try TestModel.query(on: database).all().wait()
            XCTAssertEqual(models.count - 1, after.count)
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }

    func testFilter() throws {
        do {
            let models = try TestModel.query(on: database).all().wait()
            let random = models.randomElement()!
            let filtered = try TestModel.query(on: database)
                .filter(\.$title == random.title)
                .first()
                .wait()!

            XCTAssertEqual(filtered, random)

        }
    }
}

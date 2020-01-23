//
//  File.swift
//  
//
//  Created by Michael Housh on 1/16/20.
//

import XCTest
import DynamoDB
@testable import SwiftDynamo

final class DynamoQueryTests: XCTestCase {

//    func testDynamoAttributeMapper() {
//        let attributes: [DynamoDB.AttributeValue] = [
//            .init(s: "foo"),
//            .init(ss: ["foo", "bar"]),
//            .init(bool: false),
//            .init(l: [.init(bool: true), .init(bool: false)]),
//            .init(n: "1"),
//            .init(ns: ["0", "1"]),
//            .init(b: try! JSONEncoder().encode("foo")),
//            .init(bs: [try! JSONEncoder().encode("foo"), try! JSONEncoder().encode("bar")]),
//            .init(null: true),
//            .init(m: ["foo": .init(s: "bar"), "bar": .init(n: "1")])
//        ]
//
//        let expectations: [_DynamoValue] = [
//            .string("foo"),
//            .stringSet(["foo", "bar"]),
//            .bool(false),
//            .list([.bool(true), .bool(false)]),
//            .number("1"),
//            .numberSet(["0", "1"]),
//            .data(try! JSONEncoder().encode("foo")),
//            .dataSet([try! JSONEncoder().encode("foo"), try! JSONEncoder().encode("bar")]),
//            .null(true),
//            .dictionary(["foo": .string("bar"), "bar": .number("1")])
//        ]
//
//        for i in 0..<attributes.count {
//            XCTAssertEqual(try! attributes[i]._dynamoValue(), expectations[i])
//        }
//
//        XCTAssertEqual(expectations[0].dynamoAttribute.s, "foo")
//        XCTAssertEqual(expectations[1].dynamoAttribute.ss, ["foo", "bar"])
//        XCTAssertEqual(expectations[2].dynamoAttribute.bool, false)
////        XCTAssertEqual(expectations[3].dynamoAttribute.l.map { $0.dynamoAttribute.b! }, [true, false])
//        XCTAssertEqual(expectations[4].dynamoAttribute.n, "1")
//        XCTAssertEqual(expectations[5].dynamoAttribute.ns, ["0", "1"])
//        XCTAssertEqual(expectations[6].dynamoAttribute.b, try! JSONEncoder().encode("foo"))
//        XCTAssertEqual(expectations[7].dynamoAttribute.bs, [try! JSONEncoder().encode("foo"), try! JSONEncoder().encode("bar")])
//        XCTAssertEqual(expectations[8].dynamoAttribute.null, true)
//        let list = expectations[3].dynamoAttribute.l!.map { try! $0._dynamoValue()!.dynamoAttribute.bool! }
//        XCTAssertEqual(list, [true, false])
//        let map = expectations[9].dynamoAttribute.m!
//        var convertedMap = [String: String]()
//        for (key, value) in map {
//            if key == "foo" {
//                convertedMap[key] = try! value._dynamoValue()!.dynamoAttribute.s!
//            }
//            else if key == "bar" {
//                convertedMap[key] = try! value._dynamoValue()!.dynamoAttribute.n!
//
//            } else {
//                XCTFail("invalid key")
//            }
//        }
//        XCTAssertEqual(convertedMap, ["foo": "bar", "bar": "1"])
//
//    }

   
}

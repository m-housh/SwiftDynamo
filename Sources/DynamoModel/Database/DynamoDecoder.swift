//
//  DynamoDecodert.swift
//  
//
//  Created by Michael Housh on 1/18/20.
//

import Foundation


struct DynamoDecoder: Decoder, SingleValueDecodingContainer {

    let container: KeyedDecodingContainer<_ModelCodingKey>
    let key: _ModelCodingKey

    var codingPath: [CodingKey] { container.codingPath }

    var userInfo: [CodingUserInfoKey : Any] { [:] }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try container.nestedContainer(keyedBy: Key.self, forKey: key)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try container.nestedUnkeyedContainer(forKey: key)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

    func decodeNil() -> Bool {
        do {
            return try container.decodeNil(forKey: key)
        } catch {
            return true
        }
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try container.decode(type, forKey: key)
    }


}

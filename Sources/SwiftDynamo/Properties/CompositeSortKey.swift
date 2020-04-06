//
//  File.swift
//  
//
//  Created by Michael Housh on 4/6/20.
//

import Foundation

/// A database field that is used as sort key for the model.
@propertyWrapper
public final class CompositeSortKey<Model>: AnyField, FieldRepresentible, AnySortKey where Model: AnyModel {

    // We delegate responsibilities to the field.
    public let field: Field<String>

    private var hasInput: Bool = false
    // We delegate responsibilities to the field.
    public var wrappedValue: String {
        get { self.field.wrappedValue }
        set {
            self.hasInput = true
            self.field.wrappedValue = newValue
        }
    }

    // We delegate responsibilities to the field.
    public var key: String { self.field.key }

    // We delegate responsibilities to the field.
    public var projectedValue: CompositeSortKey<Model> { self }

    public var sortKey: Bool = true
    public var partitionKey: Bool = false

    public var generateSortKey: (Model) -> String

    public func generate(_ model: Model) {
        // if there is user input, then don't generate the value.
        if inputValue == nil {
            self.inputValue = .bind(generateSortKey(model))
        }
    }

    /// Create a new instance.
    ///
    /// - parameters:
    ///     - key: The database key for the sort key.
    public init(_ model: Model.Type, key: String, generate: @escaping (Model) -> String) {
        self.field = .init(key: key, partitionKey: false, sortKey: true)
        self.generateSortKey = generate
    }

    // We delegate responsibilities to the field.
    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    // We delegate responsibilities to the field.
    public func decode(from decoder: Decoder) throws {
        try field.decode(from: decoder)
    }

    // We delegate responsibilities to the field.
    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }
}

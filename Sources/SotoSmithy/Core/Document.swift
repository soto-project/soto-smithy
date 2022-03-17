//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Struct used for holding generic schemaless values
///
/// To ease reading of this data I have added subscript functions to return a new Document for elements of arrays
/// and dictionary values eg You can index values as follow `document["key"]["address"][2].string`
public struct Document {
    public let value: Any?
    public init(value: Any?) {
        self.value = value
    }

    /// return value as an integer
    public var int: Int? { return self.value as? Int }

    /// return value as a float
    public var float: Float? { return self.value as? Float }

    /// return value as a double
    public var double: Double? { return self.value as? Double }

    /// return value as a bool
    public var bool: Bool? { return self.value as? Bool }

    /// return value as a string
    public var string: String? {
        return self.value as? String
    }

    /// return value as a dictionary
    public var dictionary: [String: Any]? { return self.value as? [String: Any] }

    /// return value as an array
    public var array: [Any]? { return self.value as? [Any] }

    /// subscript value as if it is an array
    public subscript(index: Int) -> Document { return Document(value: (self.value as? [Any])?[index]) }

    /// subscript value as if it is a dictionary
    public subscript(key: String) -> Document { Document(value: (self.value as? [String: Any])?[key]) }
}

extension Document: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.init(value: nil)
        } else if let bool = try? container.decode(Bool.self) {
            self.init(value: bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(value: int)
        } else if let double = try? container.decode(Double.self) {
            self.init(value: double)
        } else if let string = try? container.decode(String.self) {
            self.init(value: string)
        } else if let array = try? container.decode([Document].self) {
            self.init(value: array.map { $0.value })
        } else if let dictionary = try? container.decode([String: Document].self) {
            self.init(value: dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value cannot be decoded")
        }
    }
}

extension Document {
    func isShape(_ shape: Shape, model: Model) -> Bool {
        if self.string != nil {
            guard shape is StringShape else { return false }
        } else if self.bool != nil {
            guard shape is BooleanShape else { return false }
        } else if self.double != nil {
            guard shape is DoubleShape || shape is FloatShape else { return false }
        } else if self.int != nil {
            guard shape is IntegerShape else { return false }
        } else if let array = self.array {
            guard let arrayShape = shape as? ListShape else { return false }
            guard let memberShape = model.shape(for: arrayShape.member.target) else { return false }
            for value in array {
                guard Document(value: value).isShape(memberShape, model: model) else { return false }
            }
        } else if let dictionary = self.dictionary {
            if let collectionShape = shape as? CollectionShape {
                // test for required members
                if let members = collectionShape.members {
                    for member in members {
                        if member.value.hasTrait(type: RequiredTrait.self) {
                            guard dictionary[member.key] != nil else { return false }
                        }
                    }
                }
                // test for members existence
                for parameter in dictionary {
                    guard let member = collectionShape.members?[parameter.key] else { return false }
                    guard let memberShape = model.shape(for: member.target) else { return false }
                    guard Document(value: parameter.value).isShape(memberShape, model: model) else { return false }
                }
            } else if let mapShape = shape as? MapShape {
                guard let valueShape = model.shape(for: mapShape.value.target) else { return false }
                for entry in dictionary {
                    guard Document(value: entry.value).isShape(valueShape, model: model) else { return false }
                }

            } else {
                return false
            }
        }
        return true
    }
}

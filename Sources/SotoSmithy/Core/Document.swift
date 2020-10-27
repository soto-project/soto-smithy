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
    public var int : Int? { return value as? Int }

    /// return value as a float
    public var float : Float? { return value as? Float }

    /// return value as a double
    public var double : Double? { return value as? Double }

    /// return value as a bool
    public var bool : Bool? { return value as? Bool }

    /// return value as a string
    public var string : String? {
        return value as? String
    }

    /// return value as a dictionary
    public var dictionary : [String:Any]? { return value as? [String:Any] }

    /// return value as an array
    public var array : [Any]? { return value as? [Any] }

    /// subscript value as if it is an array
    public subscript(index:Int) -> Document { return Document(value: (value as? [Any])?[index]) }

    /// subscript value as if it is a dictionary
    public subscript(key:String) -> Document { Document(value: (value as? [String:Any])?[key]) }
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

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

/// This protocol is used to ease decoding of single value traits.
public protocol SingleValueTrait: StaticTrait {
    associatedtype Value: Decodable
    var value: Value { get }
    init(value: Value)
}

extension SingleValueTrait {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Value.self)
        self.init(value: value)
    }

    // Need to make Document encodable before we can re-implement Encodable SingleValueTraits
    /* public func encode(to encoder: Encoder) throws {
         var container = encoder.singleValueContainer()
         try container.encode(value)
     } */
}

public protocol OptionalSingleValueTrait: StaticTrait {
    associatedtype Value: Decodable
    var value: Value? { get }
    init(value: Value?)
}

extension OptionalSingleValueTrait {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.init(value: nil)
        } else {
            let value = try container.decode(Value.self)
            self.init(value: value)
        }
    }
}

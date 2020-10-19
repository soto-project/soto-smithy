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

/// Protocol for traits defined in code
public protocol StaticTrait: Trait, Decodable {
    /// name of trait
    static var staticName: String { get }
}

extension StaticTrait {
    public static func decode<Key: CodingKey>(from decoder: Decoder, key: Key) throws -> Self {
        let container = try decoder.container(keyedBy: Key.self)
        let value = try container.decode(Self.self, forKey: key)
        return value
    }

    public var traitName: String { return Self.staticName }
    static var traitSelector: Selector { TraitSelector<Self>() }
}

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

public protocol Trait: Decodable {
    static var selector: Selector { get }
    func validate(using model: Model, shape: Shape) throws
    var name: String { get }
}

extension Trait {
    static func decode<Key: CodingKey>(from decoder: Decoder, key: Key) throws -> Self {
        let container = try decoder.container(keyedBy: Key.self)
        let value = try container.decode(Self.self, forKey: key)
        return value
    }
    public static var selector: Selector { return AllSelector() }
    public func validate(using model: Model, shape: Shape) throws {
        guard Self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(name) cannot be applied to \(type(of: shape).type)")
        }
    }
}

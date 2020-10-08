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

struct DecodableSelector: Selector, Decodable {
    let selector: Selector

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.selector = try Self.convert(from: string)
    }

    func select(using model: Model, shape: Shape) -> Bool {
        return self.selector.select(using: model, shape: shape)
    }

    static func convert(from string: String) throws -> Selector {
        return AllSelector()
    }
}

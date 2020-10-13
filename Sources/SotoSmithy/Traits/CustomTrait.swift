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

/// Trait reference structure defined in Smithy file
public struct CustomTrait: Trait {
    public let shapeId: ShapeId
    public var selector: Selector { return CustomTraitSelector(self.shapeId) }
    public var traitName: String { return self.shapeId.description }
}

/// Trait indicating this is a structure that can be referenced as a trait
public struct TraitTrait: StaticTrait {
    public static var staticName = "smithy.api#trait"
    public var selectorToApply: Selector
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.selectorToApply = try container.decode(DecodableSelector.self, forKey: .selector).selector
    }
    private enum CodingKeys: String, CodingKey {
        case selector
    }
}

/// Selector ensuring custom traits are selecting a structure tagged a trait
struct CustomTraitSelector: Selector {
    let shapeId: ShapeId

    init(_ shapeId: ShapeId) {
        self.shapeId = shapeId
    }

    func select(using model: Model, shape: Shape) -> Bool {
        guard let traitShape = model.shape(for: self.shapeId) else { return false }
        guard let traitSelector = traitShape.trait(type: TraitTrait.self)?.selectorToApply else { return false }
        return traitSelector.select(using: model, shape: shape)
    }
}


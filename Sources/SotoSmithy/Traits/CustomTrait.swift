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

/// Reference to trait structure defined in Smithy file
public struct CustomTrait: Trait {
    public let shapeId: ShapeId
    public var selector: Selector { return CustomTraitSelector(self.shapeId) }
    public var traitName: ShapeId { return self.shapeId }
    public var parameters: [String: Any]

    public func validate(using model: Model, shape: Shape) throws {
        guard model.shape(for: self.shapeId) != nil else {
            throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** does not exist")
        }
        guard self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(traitName) cannot be applied to shape **")
        }
        // the selector has already tested for existence of trait shape so can use !
        let traitShape = model.shape(for: self.shapeId) as! StructureShape
        // test for required members
        if let members = traitShape.members {
            for member in members {
                if member.value.hasTrait(type: RequiredTrait.self) {
                    guard parameters[member.key] != nil else {
                        throw Smithy.ValidationError(reason: "Required parameter \(member.key) in trait \(traitName) is not in trait attached to shape **")
                    }
                }
            }
        }
        // test for members existence
        for parameter in self.parameters {
            guard traitShape.members?[parameter.key] != nil else {
                throw Smithy.ValidationError(reason: "Supplied parameter \(parameter.key) in trait attached to shape ** does not exist in \(traitName)")
            }
        }
    }
}

/// Trait indicating this is a structure that can be referenced as a trait
public struct TraitTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#trait"
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
        guard traitShape as? StructureShape != nil else { return false }
        guard let traitSelector = traitShape.trait(type: TraitTrait.self)?.selectorToApply else { return false }
        return traitSelector.select(using: model, shape: shape)
    }
}


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
    public var parameters: Document

    public func validate(using model: Model, shape: Shape) throws {
        guard let traitShape = model.shape(for: self.shapeId) else {
            throw Smithy.ValidationError(reason: "Trait \(self.traitName) applied to shape ** does not exist")
        }
        guard self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(self.traitName) cannot be applied to shape **")
        }

        guard self.parameters.isShape(traitShape, model: model) else {
            throw Smithy.ValidationError(reason: "Trait \(self.traitName) applied to shape ** has invalid parameters")
        }
        /* if parameters.string != nil {
             guard traitShape is StringShape else {
                 throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** parameters are invalid")
             }
         } else if parameters.double != nil {
             guard traitShape is DoubleShape || traitShape is FloatShape else {
                 throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** parameters are invalid")
             }
         } else if parameters.int != nil {
             guard traitShape is IntegerShape  else {
                 throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** parameters are invalid")
             }
         } else if parameters.array != nil {
             guard traitShape is ListShape else {
                 throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** parameters are invalid")
             }
         } else if parameters.dictionary != nil {
             if let collectionShape = traitShape as? CollectionShape {
                 // test for required members
                 if let members = collectionShape.members {
                     for member in members {
                         if member.value.hasTrait(type: RequiredTrait.self) {
                             guard parameters[member.key].value != nil else {
                                 throw Smithy.ValidationError(reason: "Required parameter \(member.key) in trait \(traitName) is not in trait attached to shape **")
                             }
                         }
                     }
                 }
                 // test for members existence
                 if let parameterDictionary = self.parameters.dictionary {
                     for parameter in parameterDictionary {
                         guard collectionShape.members?[parameter.key] != nil else {
                             throw Smithy.ValidationError(reason: "Supplied parameter \(parameter.key) in trait attached to shape ** does not exist in \(traitName)")
                         }
                     }
                 }
             } else {
                 guard traitShape is MapShape else {
                     throw Smithy.ValidationError(reason: "Custom trait \(traitName) applied to shape ** parameters are invalid")
                 }
             }
         } */
    }
}

/// Trait indicating this is a structure that can be referenced as a trait
public struct TraitTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#trait"
    public var selectorToApply: Selector?
    public var conflicts: [ShapeId]?
    public var structurallyExclusive: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.selectorToApply = try container.decodeIfPresent(DecodableSelector.self, forKey: .selector)?.selector
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
        guard let traitShapeTrait = traitShape.trait(type: TraitTrait.self) else { return false }
        if let traitSelector = traitShapeTrait.selectorToApply {
            return traitSelector.select(using: model, shape: shape)
        }
        return true
    }
}

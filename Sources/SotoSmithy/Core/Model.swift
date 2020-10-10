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

public struct Model {
    let version: String
    let metadata: [String: MetadataValue]?
    var shapes: [ShapeId: Shape]

    public func shape(for identifier: ShapeId) -> Shape? {
        if let member = identifier.member {
            if let shape = shapes[identifier.rootShapeId] {
                switch shape {
                case let structure as StructureShape:
                    return structure.members?[member]
                default:
                    break
                }
            }
            return nil
        } else {
            return self.shapes[identifier]
        }
    }

    public func validate() throws {
        try self.shapes.forEach {
            do {
                try $0.value.validate(using: self)
            } catch let error as Smithy.ValidationError {
                // replace "**" with name of shape
                throw Smithy.ValidationError(reason: error.reason.replacingOccurrences(of: "**", with: $0.key.rawValue))
            }
        }
    }

    public func select(with selector: Selector) -> [ShapeId: Shape] {
        return self.shapes.compactMapValues { selector.select(using: self, shape: $0) ? $0 : nil }
    }

    public func select(from string: String) throws -> [ShapeId: Shape] {
        let selector = try SelectorParser.parse(from: string)
        return select(with: selector)
    }

    public func select<S: Shape>(type shapeType: S.Type) -> [ShapeId: S] {
        return self.shapes.compactMapValues { $0 as? S }
    }

    public mutating func add(trait: Trait, to identifier: ShapeId) throws {
        if let member = identifier.member {
            guard try self.shapes[identifier.rootShapeId]?.add(trait: trait, to: member) != nil else {
                throw Smithy.ShapeDoesNotExistError(id: identifier)
            }
        } else {
            guard self.shapes[identifier]?.add(trait: trait) != nil else {
                throw Smithy.ShapeDoesNotExistError(id: identifier)
            }
        }
    }

    public mutating func remove(trait: StaticTrait.Type, from identifier: ShapeId) throws {
        if let member = identifier.member {
            guard try self.shapes[identifier.rootShapeId]?.remove(trait: trait, from: member) != nil else {
                throw Smithy.ShapeDoesNotExistError(id: identifier)
            }
        } else {
            guard self.shapes[identifier]?.remove(trait: trait) != nil else {
                throw Smithy.ShapeDoesNotExistError(id: identifier)
            }
        }
    }

    public static func registerShapeTypes(_ shapes: [Shape.Type]) {
        for shape in shapes {
            self.possibleShapes[shape.type] = shape
        }
    }

    static var possibleShapes: [String: Shape.Type] = [:]

    private enum CodingKeys: String, CodingKey {
        case version = "smithy"
        case metadata
        case shapes
    }
}

extension Model: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(String.self, forKey: .version)
        self.metadata = try container.decodeIfPresent([String: MetadataValue].self, forKey: .metadata)
        var shapes = Smithy.preludeShapes
        if let decodedShapes = try container.decodeIfPresent([String: DecodableShape].self, forKey: .shapes) {
            for shape in decodedShapes {
                guard !(shape.value.value is ApplyShape) else { continue }
                shapes[ShapeId(rawValue: shape.key)] = shape.value.value
            }
            // Apply changes from AppyShapes
            for shape in decodedShapes {
                guard let applyShape = shape.value.value as? ApplyShape,
                      let traitsToApply = applyShape.traits else { continue }
                let applyToShapeId = ShapeId(rawValue: shape.key)
                // assume shapes are members as we cannot have two keys the same in one Smithy JSON file
                guard let member = applyToShapeId.member else { continue }
                for trait in traitsToApply {
                    try shapes[applyToShapeId.rootShapeId]?.add(trait: trait, to: member)
                }
            }
        }
        self.shapes = shapes
    }


}

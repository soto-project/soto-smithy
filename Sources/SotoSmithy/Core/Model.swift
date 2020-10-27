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

/// Class for holding Smithy Model
public class Model: Decodable {
    public let version: String
    public let metadata: [String: Any]?
    public var shapes: [ShapeId: Shape]

    init() {
        self.version = "1.0"
        self.metadata = nil
        self.shapes = [:]
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(String.self, forKey: .version)
        if let metadata = try container.decodeIfPresent([String: Document].self, forKey: .metadata) {
            self.metadata = metadata.mapValues{ $0.value }
        } else {
            self.metadata = nil
        }
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
    
    /// Return Shape given ShapeId
    /// - Parameter identifier: shape identifier
    /// - Returns: Returns Shape if it exists in Model
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
    
    /// Validate Model. Runs validate on all Shapes and verifies Trait selectors
    /// - Throws: `Smithy.ValidationError`
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
    
    /// Return shapes from model that are matched by Selector
    /// - Parameter selector: Selector to match shapes
    /// - Returns: Map of shapeIds to Shapes that match selector
    public func select(with selector: Selector) -> [ShapeId: Shape] {
        return self.shapes.compactMapValues { selector.select(using: self, shape: $0) ? $0 : nil }
    }

    /// Return shapes from model that are matched by Selector IDL string.
    /// See https://awslabs.github.io/smithy/1.0/spec/core/selectors.html for more info. Only a basuc set of
    /// selectors are supported at the moment.
    ///
    /// - Parameter selector: Selector IDL string to match shapes
    /// - Returns: Map of shapeIds to Shapes that match selector
    public func select(from string: String) throws -> [ShapeId: Shape] {
        let selector = try SelectorParser.parse(from: string)
        return select(with: selector)
    }
    
    /// Return shapes from model that are of a certain type
    /// - Parameter shapeType: Shape type to match
    /// - Returns: Map of shapeIds to Shapes that match shape
    public func select<S: Shape>(type shapeType: S.Type) -> [ShapeId: S] {
        return self.shapes.compactMapValues { $0 as? S }
    }
    
    /// Add trait to shape. This function will also match shape members if shape id is referencing a shape member
    /// - Parameters:
    ///   - trait: Trait to add
    ///   - identifier: Shape identifier of Shape.
    /// - Throws: `Smithy.ShapeDoesNotExistError`, `Smithy.MemberDoesNotExistError`
    public func add(trait: Trait, to identifier: ShapeId) throws {
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

    /// Remove trait of type from shape. This function will also match shape members if shape id is referencing a shape member
    /// - Parameters:
    ///   - trait: Trait to add
    ///   - identifier: Shape identifier of Shape.
    /// - Throws: `Smithy.ShapeDoesNotExistError`, `Smithy.MemberDoesNotExistError`
    public func remove(trait: StaticTrait.Type, from identifier: ShapeId) throws {
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

    static func registerShapeTypes(_ shapes: [Shape.Type]) {
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

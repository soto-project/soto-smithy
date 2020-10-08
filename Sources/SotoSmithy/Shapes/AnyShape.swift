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

public struct AnyShape: Decodable {
    static var possibleShapes: [String: Shape.Type] = [:]
    public var value: Shape
    public var traits: TraitList? {
        get { return self.shapeSelf.traits }
        set { self.value.traits = newValue }
    }

    public var shapeSelf: Shape { return self.value }

    init(value: Shape) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        guard let shapeType = Self.possibleShapes[type] else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: "Unrecognised shape type")
        }
        self.value = try shapeType.init(from: decoder)
    }

    /*public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type(of:value).type, forKey: .type)
        try self.value.encode(to: encoder)
    }*/

    public func validate(using model: Model) throws {
        try self.value.validate(using: model)
    }

    public mutating func add(trait: Trait, to member: String) throws {
        try self.value.add(trait: trait, to: member)
    }

    public mutating func remove(trait: StaticTrait.Type, from member: String) throws {
        try self.value.remove(trait: trait, from: member)
    }

    public static func registerShapeTypes(_ shapes: [Shape.Type]) {
        for shape in shapes {
            self.possibleShapes[shape.type] = shape
        }
    }

    private enum CodingKeys: CodingKey {
        case type
    }
}

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

/// Internal Shape type used to decode Shapes from JSON. Decodes shape name first to decide what shape is meant to be created
struct DecodableShape: Decodable {
    var value: Shape
    var traits: TraitList? {
        get { return self.value.traits }
        set { self.value.traits = newValue }
    }

    init(value: Shape) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        guard let shapeType = Model.possibleShapes[type] else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.type, in: container, debugDescription: "Unrecognised shape type \(type)")
        }
        self.value = try shapeType.init(from: decoder)
    }

    func validate(using model: Model) throws {
        try self.value.validate(using: model)
    }

    mutating func add(trait: Trait, to member: String) throws {
        try self.value.add(trait: trait, to: member)
    }

    mutating func remove(trait: StaticTrait.Type, from member: String) throws {
        try self.value.remove(trait: trait, from: member)
    }

    private enum CodingKeys: CodingKey {
        case type
    }
}

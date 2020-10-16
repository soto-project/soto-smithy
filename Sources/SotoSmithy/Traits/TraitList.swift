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

/// List of traits.
public struct TraitList: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var traits: [String: Trait] = [:]
        for key in container.allKeys {
            let trait: Trait
            if let traitType = Self.possibleTraits[key.stringValue] {
                trait = try traitType.decode(from: decoder, key: key)
            } else {
                trait = CustomTrait(shapeId: ShapeId(rawValue: key.stringValue))
            }
            traits[trait.traitName] = trait
        }
        self.traits = traits
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("TraitList.encode Not implemented")
    }
    
    /// Return trait of type from list if it exists
    /// - Parameter type: Trait type
    /// - Returns: Trait if found
    public func trait<T: StaticTrait>(type: T.Type) -> T? {
        return self.traits[T.staticName].map { $0 as! T }
    }

    /// Return if trait is in list
    /// - Parameter type: Trait type
    /// - Returns: Is trait in the list
    public func hasTrait(type: StaticTrait.Type) -> Bool {
        return self.traits[type.staticName] != nil
    }

    /// Return trait with name from list if it exists
    /// - Parameter named: Trait nam
    /// - Returns: Trait if found
    public func trait(named: String) -> Trait? {
        return self.traits[named]
    }

    /// Add trait to list
    /// - Parameter trait: trait to add
    public mutating func add(trait: Trait) {
        self.traits[trait.traitName] = trait
    }
    
    /// Remove trait of type from list
    /// - Parameter trait: trait type to remove
    public mutating func remove(trait: StaticTrait.Type) {
        self.traits[trait.staticName] = nil
    }

    /// Remove trait of type from list
    /// - Parameter trait: trait type to remove
    public mutating func removeTrait(named: String) {
        self.traits[named] = nil
    }

    static func registerTraitTypes(_ traitTypes: [StaticTrait.Type]) {
        for trait in traitTypes {
            self.possibleTraits[trait.staticName] = trait
        }
    }

    func validate(using model: Model, shape: Shape) throws {
        try self.traits.forEach {
            try $0.value.validate(using: model, shape: shape)
        }
    }

    init(traits traitsArray: [Trait]) {
        var traits: [String: Trait] = [:]
        traitsArray.forEach {
            traits[$0.traitName] = $0
        }
        self.traits = traits
    }

    static var possibleTraits: [String: StaticTrait.Type] = [:]

    private var traits: [String: Trait]

    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? { return nil }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

extension TraitList: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Trait
    public init(arrayLiteral elements: Trait...) {
        self.init(traits: elements)
    }
}

extension TraitList: Sequence {
    public typealias Element = Trait
    public typealias Iterator = Dictionary<String, Trait>.Values.Iterator

    public func makeIterator() -> Iterator {
        return self.traits.values.makeIterator()
    }
}

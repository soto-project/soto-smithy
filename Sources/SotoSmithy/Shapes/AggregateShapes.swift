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

/// Shape representing a member of an aggregate shape
public class MemberShape: Shape {
    public static let type = "member"
    public let target: ShapeId
    public var traits: TraitList?

    public init(target: ShapeId, traits: TraitList? = nil) {
        self.target = target
        self.traits = traits
    }

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else {
            throw Smithy.ValidationError(
                reason: "Member of ** references non-existent shape \(self.target)")
        }
        guard !(shape is OperationShape),
            !(shape is ResourceShape),
            !(shape is ServiceShape)
        else {
            throw Smithy.ValidationError(
                reason: "Member of ** references illegal shape \(self.target)")
        }
        try self.validateTraits(using: model)
    }
}

/// Shape representing a list of items
public class ListShape: Shape {
    public static let type = "list"
    public var traits: TraitList?
    public let member: MemberShape

    public init(traits: TraitList? = nil, member: MemberShape) {
        self.traits = traits
        self.member = member
    }

    public func validate(using model: Model) throws {
        try self.member.validate(using: model)
        try self.validateTraits(using: model)
    }
}

/// Shape representing a list of unique items
public class SetShape: Shape {
    public static let type = "set"
    public var traits: TraitList?
    public let member: MemberShape

    public init(traits: TraitList? = nil, member: MemberShape) {
        self.traits = traits
        self.member = member
    }

    public func validate(using model: Model) throws {
        try self.member.validate(using: model)
        try self.validateTraits(using: model)
    }
}

/// Shape representing a map of string value to items
public class MapShape: Shape {
    public static let type = "map"
    public var traits: TraitList?
    public let key: MemberShape
    public let value: MemberShape

    public init(traits: TraitList? = nil, key: MemberShape, value: MemberShape) {
        self.traits = traits
        self.key = key
        self.value = value
    }

    public func validate(using model: Model) throws {
        try self.key.validate(using: model)
        try self.value.validate(using: model)
        try self.validateTraits(using: model)
    }
}

/// Protocol for shape holding a key/value collection of member shapes
public protocol CollectionShape: Shape {
    var members: [String: MemberShape]? { get set }
}

extension CollectionShape {
    public func validate(using model: Model) throws {
        try self.validateMembers(using: model)
        try self.validateTraits(using: model)
    }

    func validateMembers(using model: Model) throws {
        if let members = self.members {
            for member in members {
                do {
                    try member.value.validate(using: model)
                } catch let error as Smithy.ValidationError {
                    // replace "**" with name of shape
                    throw Smithy.ValidationError(
                        reason: error.reason.replacingOccurrences(
                            of: "**", with: "**$\(member.key)"))
                }
            }
        }
    }

    public func add(trait: Trait, to member: String) throws {
        guard self.members?[member]?.add(trait: trait) != nil else {
            throw Smithy.MemberDoesNotExistError(name: member)
        }
    }

    public func remove(trait: StaticTrait.Type, from member: String) throws {
        guard self.members?[member]?.remove(trait: trait) != nil else {
            throw Smithy.MemberDoesNotExistError(name: member)
        }
    }
}

/// Shape representing a set of named, unordered, heterogeneous values. Contains a set of members mapping
/// to other shapes in the model
public class StructureShape: CollectionShape {
    public static let type = "structure"
    public var traits: TraitList?
    public var members: [String: MemberShape]?

    public init(traits: TraitList? = nil, members: [String: MemberShape]? = nil) {
        self.traits = traits
        self.members = members
    }
}

/// The union type represents a tagged union data structure that can take on several different, but fixed, types.
/// Unions function similarly to structures except that only one member can be used at any one time.
public class UnionShape: CollectionShape {
    public static let type = "union"
    public var traits: TraitList?
    public var members: [String: MemberShape]?

    public init(traits: TraitList? = nil, members: [String: MemberShape]? = nil) {
        self.traits = traits
        self.members = members
    }

    public func validate(using model: Model) throws {
        guard let members = self.members, members.count > 0 else {
            throw Smithy.ValidationError(reason: "Union has no members")
        }
        try self.validateMembers(using: model)
        try self.validateTraits(using: model)
    }
}

/// The enum shape is used to represent a fixed set of one or more string values.
public class EnumShape: CollectionShape {
    public static let type = "enum"
    public var traits: TraitList?
    public var members: [String: MemberShape]?

    public init(traits: TraitList? = nil, members: [String: MemberShape]? = nil) {
        self.traits = traits
        self.members = members
    }

    public func validate(using model: Model) throws {
        guard let version = Double(model.version), version >= 2.0 else {
            throw Smithy.ValidationError(
                reason: "Enum Shapes are only available in Smithy 2.0 or later")
        }
        guard let members = self.members, members.count > 0 else {
            throw Smithy.ValidationError(reason: "Enum has no members")
        }
        try members.forEach {
            if let valueTrait = $0.value.trait(type: EnumValueTrait.self) {
                guard case .string = valueTrait.value else {
                    throw Smithy.ValidationError(
                        reason: "String based Enum has none string enum value trait")
                }
            }
        }
        try self.validateMembers(using: model)
        try self.validateTraits(using: model)
    }
}

/// An intEnum is used to represent an enumerated set of one or more integer values.
public class IntEnumShape: CollectionShape {
    public static let type = "intEnum"
    public var traits: TraitList?
    public var members: [String: MemberShape]?

    public init(traits: TraitList? = nil, members: [String: MemberShape]? = nil) {
        self.traits = traits
        self.members = members
    }

    public func validate(using model: Model) throws {
        guard let version = Double(model.version), version >= 2.0 else {
            throw Smithy.ValidationError(
                reason: "Enum Shapes are only available in Smithy 2.0 or later")
        }
        guard let members = self.members, members.count > 0 else {
            throw Smithy.ValidationError(reason: "Enum has no members")
        }
        try members.forEach {
            guard let valueTrait = $0.value.trait(type: EnumValueTrait.self) else {
                throw Smithy.ValidationError(reason: "IntEnum members require a enumValue trait")
            }
            guard case .integer = valueTrait.value else {
                throw Smithy.ValidationError(reason: "IntEnum has none integer enum value trait")
            }
        }
        try self.validateMembers(using: model)
        try self.validateTraits(using: model)
    }
}

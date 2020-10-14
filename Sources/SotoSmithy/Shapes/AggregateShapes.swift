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

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(self.target)") }
        guard !(shape is OperationShape),
            !(shape is ResourceShape),
            !(shape is ServiceShape)
        else {
            throw Smithy.ValidationError(reason: "Member of ** references illegal shape \(self.target)")
        }
        try self.validateTraits(using: model)
    }
}

/// Shape representing a list of items
public class ListShape: Shape {
    public static let type = "list"
    public var traits: TraitList?
    public let member: MemberShape
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
    public func validate(using model: Model) throws {
        try self.key.validate(using: model)
        try self.value.validate(using: model)
        try self.validateTraits(using: model)
    }
}

/// Protocol for shape holding a collection of member shapes
public protocol CollectionShape: Shape {
    var members: [String: MemberShape]? { get }
}

extension CollectionShape {
    public func validate(using model: Model) throws {
        try self.members?.forEach { try $0.value.validate(using: model) }
        try self.validateTraits(using: model)
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
}

/// The union type represents a tagged union data structure that can take on several different, but fixed, types.
/// Unions function similarly to structures except that only one member can be used at any one time.
public class UnionShape: CollectionShape {
    public static let type = "union"
    public var traits: TraitList?
    public var members: [String: MemberShape]?
    public func validate(using model: Model) throws {
        guard let members = self.members, members.count > 0 else { throw Smithy.ValidationError(reason: "Union has no members") }
        try members.forEach { try $0.value.validate(using: model) }
        try self.validateTraits(using: model)
    }
}

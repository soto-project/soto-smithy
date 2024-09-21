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

/// Shape representing endpoint of an API that holds operations and resources
public class ServiceShape: Shape {
    public static let type = "service"
    public var traits: TraitList?
    public let version: String?
    public let operations: [OperationMemberShape]?
    public let resources: [ResourceMemberShape]?
}

/// Shape representing operation member of service shape
public class OperationMemberShape: Shape {
    public static let type = "member"
    public var traits: TraitList?
    public let target: ShapeId

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(self.target)") }
        guard shape is OperationShape else { throw Smithy.ValidationError(reason: "Operation ** references illegal shape \(self.target)") }
        try self.validateTraits(using: model)
    }
}

/// Shape representing an operation from an API
public class OperationShape: Shape {
    public static let type = "operation"
    public var traits: TraitList?
    public var input: MemberShape?
    public var output: MemberShape?
    public let errors: [MemberShape]?

    public func validate(using model: Model) throws {
        try self.input?.validate(using: model)
        try self.output?.validate(using: model)
        try self.validateTraits(using: model)
    }
}

/// Shape representing resource member of service shape
public class ResourceMemberShape: Shape {
    public static let type = "member"
    public var traits: TraitList?
    public let target: ShapeId

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(self.target)") }
        guard shape is ResourceShape else { throw Smithy.ValidationError(reason: "Operation ** references illegal shape \(self.target)") }
        try self.validateTraits(using: model)
    }
}

/// Shape representing an entity with a set of operations attached
public class ResourceShape: Shape {
    public static let type = "resource"
    public var traits: TraitList?
    public let identifiers: [String: MemberShape]?
    public let create: MemberShape?
    public let put: MemberShape?
    public let read: MemberShape?
    public let update: MemberShape?
    public let delete: MemberShape?
    public let list: MemberShape?
    public let operations: [MemberShape]?
    public let collectionOperations: [MemberShape]?
    public let resources: [MemberShape]?
}

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

public struct ServiceShape: Shape {
    public static let type = "service"
    public var traits: TraitList?
    public let version: String
    public let operations: [OperationMemberShape]?
    public let resources: [ResourceMemberShape]?
}

public struct OperationMemberShape: Shape {
    public var traits: TraitList?
    public let target: ShapeId

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else { throw Smithy.ValidationError(reason: "Member references non-existent shape \(self.target)") }
        guard shape is OperationShape else { throw Smithy.ValidationError(reason: "Operation references illegal shape \(self.target)") }
        try self.traits?.validate(using: model, shape: self)
    }
}

public struct OperationShape: Shape {
    public static let type = "operation"
    public var traits: TraitList?
    public let input: MemberShape?
    public let output: MemberShape?
    public let errors: [MemberShape]?
}

public struct ResourceMemberShape: Shape {
    public var traits: TraitList?
    public let target: ShapeId

    public func validate(using model: Model) throws {
        guard let shape = model.shape(for: target) else { throw Smithy.ValidationError(reason: "Member references non-existent shape \(self.target)") }
        guard shape is ResourceShape else { throw Smithy.ValidationError(reason: "Operation references illegal shape \(self.target)") }
        try self.traits?.validate(using: model, shape: self)
    }
}

public struct ResourceShape: Shape {
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

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

/// Indicates that the put lifecycle operation of a resource can only be used to create a resource and cannot replace
/// an existing resource.
public struct NoReplaceTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#noReplace"
    public static var selector: Selector = TypeSelector<ResourceShape>()
    public init() {}
}

/// Defines a design-time reference to Resource shapes. Resource references allow tooling to understand the
/// relationships between resources and how to dereference the location of a resource.
public struct ReferencesTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#references"
    public static var selector: Selector { OrSelector(TypeSelector<StructureShape>(), TypeSelector<StringShape>()) }
    public struct Reference: Codable {
        public let service: ShapeId?
        public let resource: ShapeId
        public let ids: [String: String]?
        public let rel: String?
    }

    public typealias Value = [Reference]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

/// Indicates that the targeted structure member provides an identifier for a resource.
public struct ResourceIdentifierTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#resourceIdentifier"
    public static var selector: Selector {
        AndSelector(
            TypeSelector<MemberShape>(),
            TraitSelector<RequiredTrait>(),
            TargetSelector(TypeSelector<StringShape>())
        )
    }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Allows the binding of resource properties to occur within a nested structure deeper than the lifecycle
/// operation's input or output shape.
public struct NestedPropertiesTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#nestedProperties"
    public static var selector: Selector = TypeSelector<MemberShape>()
}

/// Indicates that a top-level input or output shape member is not bound to a resource property. This trait
/// can also mark another trait as a carrier for @notProperty so that if that trait is applied to a member,
/// the member is considered implicitly marked with @notProperty.
public struct NotPropertyTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#notProperty"
    public static var selector: Selector = TypeSelector<MemberShape>()
}

/// Binds a top-level input or output structure member to a resource property with a different name.
public struct PropertyTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#property"
    public static var selector: Selector = TypeSelector<MemberShape>()

    public let name: String?

    public init(name: String?) {
        self.name = name
    }
}

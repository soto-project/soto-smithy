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

/// Marks a shape or member as deprecated.
public struct DeprecatedTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#deprecated"
    public let message: String?
    public let since: String?

    public init(message: String?, since: String?) {
        self.message = message
        self.since = since
    }
}

/// Adds documentation to a shape or member using the CommonMark format.
public struct DocumentationTrait: SingleValueTrait {
    public init(value: String) {
        self.value = value
    }

    public static let staticName: ShapeId = "smithy.api#documentation"
    public let value: String
}

/// Provides example inputs and outputs for operations.
public struct ExamplesTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#examples"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public struct Example: Decodable {
        public let title: String
        public let documentation: String?
        public let input: Document?
        public let output: Document?
        public let error: ErrorExample?
    }

    public struct ErrorExample: Decodable {
        public let shapeId: ShapeId?
        public let content: Document?
    }

    public typealias Value = [Example]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

/// Provides named links to external documentation for a shape.
public struct ExternalDocumentationTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#externalDocumentation"
    public typealias Value = [String: String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

/// Shapes marked with the internal trait are meant only for internal use. Tooling can use the internal trait to filter
/// out shapes from models that are not intended for external customers.
public struct InternalTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#internal"
    public init() {}
}

/// Indicates that a structure member SHOULD be set. This trait is useful when the majority of use cases for a
/// structure benefit from providing a value for a member, but the member is not actually required or cannot be
/// made required backward compatibly.
public struct RecommendedTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#recommended"
    public var selector: Selector { AndSelector(TypeSelector<MemberShape>(), NotSelector(TraitSelector<RequiredTrait>())) }
    public let reason: String?
    public init(reason: String?) {
        self.reason = reason
    }
}

/// Indicates that the data stored in the shape or member is sensitive and MUST be handled with care.
public struct SensitiveTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#sensitive"
    public var selector: Selector { NotSelector(
        OrSelector(
            TypeSelector<OperationShape>(),
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>()
        )
    ) }
    public init() {}
}

/// Defines the version or date in which a shape or member was added to the model.
public struct SinceTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#since"
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Tags a shape with arbitrary tag names that can be used to filter and group shapes in the model.
public struct TagsTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#tags"
    public typealias Value = [String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

/// Defines a proper name for a service or resource shape. This title can be used in automatically generated
/// documentation and other contexts to provide a user friendly name for services and resources.
public struct TitleTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#title"
    public var selector: Selector { OrSelector(TypeSelector<ServiceShape>(), TypeSelector<ResourceShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Indicates a shape is unstable and MAY change in the future. This trait can be applied to trait shapes to
/// indicate that a trait is unstable or experimental. If possible, code generators SHOULD use this trait to
/// warn when code generated from unstable features are used.
public struct UnstableTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#unstable"
    public init() {}
}

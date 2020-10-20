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

/// A meta-trait that marks a trait as an authentication scheme. Traits that are marked with this trait are applied to
/// service shapes to indicate how a client can authenticate with the service.
public struct AuthDefinitionTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#authDefinition"
    public init() {}
}

/// Indicates that a service supports HTTP Basic Authentication as defined in RFC 2617.
public struct HttpBasicAuthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpBasicAuth"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

/// Indicates that a service supports HTTP Digest Authentication as defined in RFC 2617.
public struct HttpDigestAuthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpDigestAuth"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

/// Indicates that a service supports HTTP Bearer Authentication as defined in RFC 6750.
public struct HttpBearerAuthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpBearerAuth"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

/// Indicates that a service supports HTTP-specific authentication using an API key sent in a header or query
/// string parameter.
public struct HttpApiKeyAuthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpApiKeyAuth"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public let name: String
    public let `in`: String
}

/// Indicates that an operation MAY be invoked without authentication, regardless of any authentication traits applied
/// to the operation.
public struct OptionalAuthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#optionalAuth"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public init() {}
}

/// Defines the priority ordered authentication schemes supported by a service or operation. When applied to a
/// service, it defines the default authentication schemes of every operation in the service. When applied to an
/// operation, it defines the list of all authentication schemes supported by the operation, overriding any auth trait
/// specified on a service.
public struct AuthTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#auth"
    public var selector: Selector { OrSelector(TypeSelector<ServiceShape>(), TypeSelector<OperationShape>()) }
    public typealias Value = [String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

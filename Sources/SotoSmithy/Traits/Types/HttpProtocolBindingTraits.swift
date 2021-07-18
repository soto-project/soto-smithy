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

/// Configures the HTTP bindings of an operation.
public struct HttpTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#http"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let method: String
    public let uri: String
    public let code: Int?
}

/// Defines an HTTP response code for an operation error.
public struct HttpErrorTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#httpError"
    public var selector: Selector { AndSelector(TypeSelector<StructureShape>(), TraitSelector<ErrorTrait>()) }
    public typealias Value = Int
    public var value: Int
    public init(value: Int) {
        self.value = value
    }
}

/// Binds a structure member to an HTTP header.
public struct HttpHeaderTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#httpHeader"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        NumberSelector(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>(),
        // TODO: really need to check member of List/Set
        TypeSelector<ListShape>(),
        TypeSelector<SetShape>()
    )) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Binds an operation input structure member to an HTTP label.
public struct HttpLabelTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpLabel"
    public var selector: Selector { AndSelector(
        TargetSelector(OrSelector(
            TypeSelector<BooleanShape>(),
            NumberSelector(),
            TypeSelector<StringShape>(),
            TypeSelector<TimestampShape>()
        )),
        TraitSelector<RequiredTrait>()
    ) }
    public init() {}
}

/// Binds a single structure member to the body of an HTTP request.
public struct HttpPayloadTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpPayload"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<StringShape>(),
        TypeSelector<BlobShape>(),
        TypeSelector<StructureShape>(),
        TypeSelector<UnionShape>(),
        TypeSelector<DocumentShape>()
    )) }
    public init() {}
}

/// Binds a map of key-value pairs to prefixed HTTP headers.
public struct HttpPrefixHeadersTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#httpPrefixHeaders"
    public var selector: Selector { TargetSelector(TypeSelector<MapShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Binds an operation input structure member to a query string parameter.
public struct HttpQueryTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#httpQuery"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        NumberSelector(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>(),
        // TODO: really need to check member of List/Set
        TypeSelector<ListShape>(),
        TypeSelector<SetShape>()
    )) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Binds an operation input structure member to a query string parameter.
public struct HttpQueryParamsTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpQueryParams"
    public var selector: Selector { TargetSelector(TypeSelector<MapShape>()) }
}

/// Indicates that the structure member represents an HTTP response status code.
public struct HttpResponseCodeTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#httpResponseCode"
    public var selector: Selector { TargetSelector(TypeSelector<IntegerShape>()) }
    public init() {}
}

/// Defines how a service supports cross-origin resource sharing
public struct HttpCorsTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#cors"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public let origin: String?
    public let maxAge: Int?
    public let additionalAllowedHeaders: [String]?
    public let additionalExposedHeaders: [String]?
}

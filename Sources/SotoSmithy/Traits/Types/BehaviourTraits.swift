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

/// Defines the input member of an operation that is used by the server to identify and discard replayed requests.
public struct IdempotencyTokenTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#idempotencyToken"
    public var selector: Selector { TargetSelector(TypeSelector<StringShape>()) }
    public init() {}
}

/// Indicates that the intended effect on the server of multiple identical requests with an operation is the same as
/// the effect for a single such request.
public struct IdempotentTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#idempotent"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public init() {}
}

/// Indicates that an operation is effectively read-only.
public struct ReadonlyTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#readonly"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public init() {}
}

/// Indicates that an error MAY be retried by the client.
public struct RetryableTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#retryable"
    public var selector: Selector { AndSelector(TypeSelector<StructureShape>(), TraitSelector<ErrorTrait>()) }
    public let throttling: Bool?

    public init(throttling: Bool?) {
        self.throttling = throttling
    }
}

/// The paginated trait indicates that an operation intentionally limits the number of results returned in a single
/// response and that multiple invocations might be necessary to retrieve all results.
public struct PaginatedTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#paginated"
    public var selector: Selector { OrSelector(TypeSelector<OperationShape>(), TypeSelector<ServiceShape>()) }
    public let inputToken: String?
    public let outputToken: String?
    public let items: String?
    public let pageSize: String?

    public init(inputToken: String?, outputToken: String?, items: String?, pageSize: String?) {
        self.inputToken = inputToken
        self.outputToken = outputToken
        self.items = items
        self.pageSize = pageSize
    }
}

/// Indicates that an operation requires a checksum in its HTTP request. By default, the checksum used for a
/// service is a MD5 checksum passed in the Content-MD5 header.
public struct HttpChecksumRequiredTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#httpChecksumRequired"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public init() {}
}

/// Indicates that an operation requires a checksum in its HTTP request.
public struct HttpChecksumTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#httpChecksum"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public struct Property: Decodable {
        let algorithm: String
        let `in`: String
        let name: String
    }

    public let request: [Property]?
    public let response: [Property]?
}

/// Defines the shape to be a unit type similar to Void or None
public struct UnitTypeTrait: StaticTrait {
    public static var staticName: ShapeId = "smithy.api#unitType"
    public var selector: Selector { TypeSelector<UnitShape>() }
    public init() {}
}

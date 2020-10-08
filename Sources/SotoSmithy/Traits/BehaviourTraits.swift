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

public struct IdempotencyTokenTrait: StaticTrait {
    public static var staticName = "smithy.api#idempotencyToken"
    public static var selector: Selector = TargetSelector(TypeSelector<StringShape>())
    public init() {}
}

public struct IdempotentTrait: StaticTrait {
    public static var staticName = "smithy.api#idempotent"
    public static var selector: Selector = TypeSelector<OperationShape>()
    public init() {}
}

public struct ReadonlyTrait: StaticTrait {
    public static var staticName = "smithy.api#readonly"
    public static var selector: Selector = TypeSelector<OperationShape>()
    public init() {}
}

public struct RetryableTrait: StaticTrait {
    public static var staticName = "smithy.api#retryable"
    public static var selector: Selector = AndSelector(TypeSelector<StructureShape>(), TraitSelector<ErrorTrait>())
    public let throttling: Bool?
}

public struct PaginatedTrait: StaticTrait {
    public static var staticName = "smithy.api#paginated"
    public static var selector: Selector = OrSelector(TypeSelector<OperationShape>(), TypeSelector<ServiceShape>())
    public let inputToken: String?
    public let outputToken: String?
    public let items: String?
    public let pageSize: String?
}

public struct HttpChecksumRequiredTrait: StaticTrait {
    public static var staticName = "smithy.api#httpChecksumRequired"
    public static var selector: Selector = TypeSelector<OperationShape>()
    public init() {}
}

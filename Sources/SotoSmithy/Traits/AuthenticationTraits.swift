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

public struct AuthDefinitionTrait: StaticTrait {
    public static let staticName = "smithy.api#authDefinition"
    public init() {}
}

public struct HttpBasicAuthTrait: StaticTrait {
    public static let staticName = "smithy.api#httpBasicAuth"
    public static let selector: Selector = TypeSelector<ServiceShape>()
    public init() {}
}

public struct HttpDigestAuthTrait: StaticTrait {
    public static let staticName = "smithy.api#httpDigestAuth"
    public static let selector: Selector = TypeSelector<ServiceShape>()
    public init() {}
}

public struct HttpBearerAuthTrait: StaticTrait {
    public static let staticName = "smithy.api#httpBearerAuth"
    public static let selector: Selector = TypeSelector<ServiceShape>()
    public init() {}
}

public struct HttpApiKeyAuthTrait: StaticTrait {
    public static let staticName = "smithy.api#httpApiKeyAuth"
    public static let selector: Selector = TypeSelector<ServiceShape>()
    public let name: String
    public let `in`: String
}

public struct OptionalAuthTrait: StaticTrait {
    public static let staticName = "smithy.api#optionalAuth"
    public static let selector: Selector = TypeSelector<OperationShape>()
    public init() {}
}

public struct AuthTrait: SingleValueTrait {
    public static let staticName = "smithy.api#auth"
    public static let selector: Selector = OrSelector(TypeSelector<ServiceShape>(), TypeSelector<OperationShape>())
    public typealias Value = [String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

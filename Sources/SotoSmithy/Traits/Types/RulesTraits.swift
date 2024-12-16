//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// List of dummy traits for `smithy.rules` traits. While these have no spec I am leaving
// them empty.

public struct EndpointRuleSetTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.rules#endpointRuleSet"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

public struct EndpointTestsTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.rules#endpointTests"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

public struct ContextParamTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.rules#contextParam"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public init() {}
}

public struct ClientContextParamsTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.rules#clientContextParams"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public init() {}
}

public struct StaticContextParamsTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.rules#staticContextParams"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public var value: [String: Document]
    public init(value: [String: Document]) {
        self.value = value
    }
}

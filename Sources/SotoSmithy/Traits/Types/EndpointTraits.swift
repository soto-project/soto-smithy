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

/// Configures a custom operation endpoint
public struct EndpointTrait: StaticTrait {
    public static let staticName = "smithy.api#endpoint"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let hostPrefix: String
}

/// Binds a top-level operation input structure member to a label in the hostPrefix of an endpoint trait.
public struct HostLabelTrait: StaticTrait {
    public static let staticName = "smithy.api#hostLabel"
    public var selector: Selector { AndSelector(TraitSelector<RequiredTrait>(), TargetSelector(TypeSelector<StringShape>())) }
    public init() {}
}

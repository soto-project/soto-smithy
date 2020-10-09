//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// traits required for loading AWS models and generating service files

import SotoSmithy

public struct AwsServiceTrait: StaticTrait {
    public static let staticName = "aws.api#service"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let sdkId: String
    public let arnNamespace: String
    public let cloudFormationName: String?
    public let cloudTrailEventSource: String
}

public struct AwsArnTrait: StaticTrait {
    public static let staticName = "aws.api#arn"
    public var selector: Selector { return TypeSelector<ResourceShape>() }
    public let template: String
    public let absolute: Bool
    public let noAccount: Bool
    public let noRegion: Bool
}

public struct AwsArnReferenceTrait: StaticTrait {
    public static let staticName = "aws.api#arnReference"
    public var selector: Selector { return TypeSelector<StringShape>() }
    public let type: String?
    public let service: ShapeId?
    public let resource: ShapeId?
}

public struct AwsDataTrait: SingleValueTrait {
    public static let staticName = "aws.api#data"
    public var selector: Selector {
        return OrSelector(
            NumberSelector(),
            CollectionSelector(),
            TypeSelector<StructureShape>(),
            TypeSelector<UnionShape>(),
            TypeSelector<MemberShape>()
        )
    }
    public enum DataValue: String, Codable {
        case content
        case account
        case usage
        case tagging
        case permissions
    }
    public typealias Value = DataValue
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

public struct AwsControlPlaneTrait: StaticTrait {
    public static let staticName = "aws.api#controlPlane"
    public var selector: Selector {
        return OrSelector(
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>(),
            TypeSelector<OperationShape>()
        )
    }
}

public struct AwsDataPlaneTrait: StaticTrait {
    public static let staticName = "aws.api#dataPlane"
    public var selector: Selector {
        return OrSelector(
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>(),
            TypeSelector<OperationShape>()
        )
    }
}

public struct AwsClientEndpointDiscoveryTrait: StaticTrait {
    public static let staticName = "aws.api#clientEndpointDiscovery"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let operation: ShapeId
    public let error: ShapeId
}

public struct AwsClientDiscoveredEndpointTrait: StaticTrait {
    public static let staticName = "aws.api#clientDiscoveredEndpoint"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let required: Bool?
}

public struct AwsClientEndpointDiscoveryIdTrait: StaticTrait {
    public static let staticName = "aws.api#clientEndpointDiscoveryId"
}

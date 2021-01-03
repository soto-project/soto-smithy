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

/// An AWS service is defined using the aws.api#service trait. This trait provides information about the service
/// like the name used to generate AWS SDK client classes and the namespace used in ARNs.
public struct AwsServiceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#service"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let sdkId: String
    public let arnNamespace: String
    public let cloudFormationName: String?
    public let cloudTrailEventSource: String?
    public let endpointPrefix: String?
}

/// Defines an ARN of a Smithy resource shape.
public struct AwsArnTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#arn"
    public var selector: Selector { return TypeSelector<ResourceShape>() }
    public let template: String
    public let absolute: Bool
    public let noAccount: Bool
    public let noRegion: Bool
}

/// Specifies that a string shape contains a fully formed AWS ARN.
public struct AwsArnReferenceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#arnReference"
    public var selector: Selector { return TypeSelector<StringShape>() }
    public let type: String?
    public let service: ShapeId?
    public let resource: ShapeId?
}

/// Indicates that the target contains data of the specified classification.
public struct AwsDataTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.api#data"
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

/// Indicates that a service, resource, or operation is considered part of the control plane.
public struct AwsControlPlaneTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#controlPlane"
    public var selector: Selector {
        return OrSelector(
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>(),
            TypeSelector<OperationShape>()
        )
    }
}

/// Indicates that a service, resource, or operation is considered part of the data plane.
public struct AwsDataPlaneTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#dataPlane"
    public var selector: Selector {
        return OrSelector(
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>(),
            TypeSelector<OperationShape>()
        )
    }
}

/// The clientEndpointDiscovery trait indicates the operation that the client should use to discover endpoints
/// for the service and the error returned when the endpoint being accessed has expired.
public struct AwsClientEndpointDiscoveryTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#clientEndpointDiscovery"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let operation: ShapeId
    public let error: ShapeId
}

/// The clientDiscoveredEndpoint trait indicates that the target operation should use the client's endpoint
/// discovery logic.
public struct AwsClientDiscoveredEndpointTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#clientDiscoveredEndpoint"
    public var selector: Selector { return TypeSelector<OperationShape>() }
    public let required: Bool?
}

/// The clientEndpointDiscoveryId trait indicates which member(s) of the operation input should be used to
/// discover an endpoint for the service.
public struct AwsClientEndpointDiscoveryIdTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#clientEndpointDiscoveryId"
    public var selector: Selector { return AndSelector(
        TypeSelector<OperationShape>(),
        TraitSelector<AwsClientEndpointDiscoveryTrait>()
    ) }
}

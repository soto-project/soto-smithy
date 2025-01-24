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
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public let sdkId: String
    public let arnNamespace: String?
    public let cloudFormationName: String?
    public let cloudTrailEventSource: String?
    public let endpointPrefix: String?

    public init(
        sdkId: String,
        arnNamespace: String?,
        cloudFormationName: String?,
        cloudTrailEventSource: String?,
        endpointPrefix: String?
    ) {
        self.sdkId = sdkId
        self.arnNamespace = arnNamespace
        self.cloudFormationName = cloudFormationName
        self.cloudTrailEventSource = cloudTrailEventSource
        self.endpointPrefix = endpointPrefix
    }
}

/// Defines an ARN of a Smithy resource shape.
public struct AwsArnTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#arn"
    public var selector: Selector { TypeSelector<ResourceShape>() }
    public let template: String
    public let absolute: Bool?
    public let noAccount: Bool?
    public let noRegion: Bool?

    public init(template: String, absolute: Bool?, noAccount: Bool?, noRegion: Bool?) {
        self.template = template
        self.absolute = absolute
        self.noAccount = noAccount
        self.noRegion = noRegion
    }
}

/// Specifies that a string shape contains a fully formed AWS ARN.
public struct AwsArnReferenceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#arnReference"
    public var selector: Selector { TypeSelector<StringShape>() }
    public let type: String?
    public let service: ShapeId?
    public let resource: ShapeId?

    public init(type: String?, service: ShapeId?, resource: ShapeId?) {
        self.type = type
        self.service = service
        self.resource = resource
    }
}

/// Indicates that the target contains data of the specified classification.
public struct AwsDataTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.api#data"
    public var selector: Selector {
        OrSelector(
            SimpleTypeSelector(),
            TypeSelector<ListShape>(),
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
        OrSelector(
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
        OrSelector(
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
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public let operation: ShapeId
    public let error: ShapeId
}

/// The clientDiscoveredEndpoint trait indicates that the target operation should use the client's endpoint
/// discovery logic.
public struct AwsClientDiscoveredEndpointTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#clientDiscoveredEndpoint"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let required: Bool?
}

/// The clientEndpointDiscoveryId trait indicates which member(s) of the operation input should be used to
/// discover an endpoint for the service.
public struct AwsClientEndpointDiscoveryIdTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#clientEndpointDiscoveryId"
    public var selector: Selector {
        AndSelector(
            TypeSelector<OperationShape>(),
            TraitSelector<AwsClientEndpointDiscoveryTrait>()
        )
    }
}

/// Specifies that a string shape contains a fully formed AWS ARN.
public struct AwsHttpChecksumTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.protocols#httpChecksum"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public enum Algorithm: String, Codable {
        case crc32c = "CRC32C"
        case crc32 = "CRC32"
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case crc64NVME = "CRC64NVME"
    }

    public let requestAlgorithmMember: String?
    public let requestChecksumRequired: Bool?
    public let requestValidationModeMember: String?
    public let responseAlgorithms: Set<Algorithm>?

    public init(
        requestAlgorithmMember: String?,
        requestChecksumRequired: Bool?,
        requestValidationModeMember: String?,
        responseAlgorithms: Set<Algorithm>?
    ) {
        self.requestAlgorithmMember = requestAlgorithmMember
        self.requestChecksumRequired = requestChecksumRequired
        self.requestValidationModeMember = requestValidationModeMember
        self.responseAlgorithms = responseAlgorithms
    }
}

/// Indicates the service supports resource level tagging consistent with AWS services.
public struct AwsTagEnabledTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#tagEnabled"
    public var selector: Selector { TypeSelector<ServiceShape>() }

    public let disableDefaultOperations: Bool?

    public init(disableDefaultOperations: Bool?) {
        self.disableDefaultOperations = disableDefaultOperations
    }
}

/// Indicates the resource supports AWS tag associations and identifies resource specific operations
/// that perform CRUD on the associated tags.
public struct AwsTaggableTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.api#taggable"
    public var selector: Selector { TypeSelector<ResourceShape>() }
    public struct TaggableResourceAPI: Decodable {
        let tagApi: ShapeId
        let untagApi: ShapeId
        let listTagsApi: ShapeId
    }

    public let property: String?
    public let apiConfig: TaggableResourceAPI?

    public init(property: String?, apiConfig: TaggableResourceAPI?) {
        self.property = property
        self.apiConfig = apiConfig
    }
}

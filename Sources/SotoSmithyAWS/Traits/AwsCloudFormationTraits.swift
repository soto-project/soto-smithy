//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SotoSmithy

/// Indicates that a Smithy resource is a CloudFormation resource.
public struct AwsCloudFormationResourceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnResource"
    public var selector: Selector { TypeSelector<ResourceShape>() }
    public let name: String?
    public let additionalSchemas: [ShapeId]?
}

/// Indicates that structure member should not be included as a property in generated CloudFormation
/// resource definitions.
public struct AwsCloudFormationExcludePropertyTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnExcludeProperty"
    public var selector: Selector { TypeSelector<MemberShape>() }
}

/// Indicates an explicit CloudFormation mutability of the structure member when part of a CloudFormation resource.
public struct AwsCloudFormationMutabilityTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnMutability"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public enum MutabilityValue: String, Codable {
        case full
        case create
        case createAndRead = "create-and-read"
        case read
        case write
    }

    public let value: MutabilityValue
    public init(value: MutabilityValue) {
        self.value = value
    }
}

/// Allows a CloudFormation resource property name to differ from a structure member name used in the model.
public struct AwsCloudFormationNameTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnName"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public let value: String
    public init(value: String) {
        self.value = value
    }
}

/// Indicates that the CloudFormation property generated from this member is an additional identifier for the resource.
public struct AwsCloudFormationAdditionalIdentifierTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnAdditionalIdentifier"
    public var selector: Selector { TargetSelector(TypeSelector<StringShape>()) }
}

/// Indicates that the member annotated has a default value for that property of the CloudFormation resource. Thus,
/// when this trait annotates an @output structure member, it indicates that the CloudFormation property generated
/// from that member has a default value in the CloudFormation schema. This trait can be used to indicate that an
/// output field with a value may return a default value assigned by the service.
public struct AwsCloudFormationDefaultValueTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.cloudformation#cfnDefaultValue"
    public var selector: Selector { TypeSelector<MemberShape>() }
}

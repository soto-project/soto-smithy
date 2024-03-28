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

import SotoSmithy

/// Indicates properties of a Smithy operation in AWS IAM.
public struct AwsIAMAction: StaticTrait {
    public struct ActionResource: Codable {
        let conditionKeys: [String]
    }

    public struct ActionResources: Codable {
        let required: [String: ActionResource]
        let optional: [String: ActionResource]
    }

    public static let staticName: ShapeId = "aws.iam#iamAction"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let name: String?
    public let documentation: String?
    public let relativeDocumentation: String?
    public let requiredActions: [String]?
    public let resources: ActionResources?
    public let createsResources: [String]?
}

/// Provides a custom IAM action name.
public struct AwsIAMActionName: SingleValueTrait {
    public static let staticName: ShapeId = "aws.iam#actionName"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let value: String
    public init(value: String) {
        self.value = value
    }
}

/// A brief description of what granting the user permission to invoke an operation would entail.
public struct AwsIAMActionPermissionDescriptionTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.iam#actionPermissionDescription"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let value: String
    public init(value: String) {
        self.value = value
    }
}

/// Applies condition keys, by name, to a resource or operation.
public struct AwsIAMConditionKeysTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.iam#conditionKeys"
    public var selector: Selector { OrSelector(TypeSelector<OperationShape>(), TypeSelector<ResourceShape>()) }
    public let value: [String]
    public init(value: [String]) {
        self.value = value
    }
}

/// Defines the set of condition keys that appear within a service in addition to inferred and global condition keys.
public struct AwsIAMDefineConditionKeysTrait: SingleValueTrait {
    public enum KeyType: String, Codable {
        case arn = "ARN"
        case binary = "Binary"
        case bool = "Bool"
        case date = "Date"
        case ipAddress = "IPAddress"
        case numeric = "Numeric"
        case string = "String"
        case arrayOfArn = "ArrayOfARN"
        case arrayOfBinary = "ArrayOfBinary"
        case arrayOfBool = "ArrayOfBool"
        case arrayOfDate = "ArrayOfDate"
        case arrayOfIpAddress = "ArrayOfIPAddress"
        case arrayOfNumeric = "ArrayOfNumeric"
        case arrayOfString = "ArrayOfString"
    }

    public static let staticName: ShapeId = "aws.iam#defineConditionKeys"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public struct ConditionKey: Codable {
        let type: KeyType
        let documentation: String?
        let externalDocumentation: String?
    }

    public let value: [String: ConditionKey]
    public init(value: [String: ConditionKey]) {
        self.value = value
    }
}

/// Uses the associated member’s value for the specified condition key.
public struct AwsIAMConditionKeyValueTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.iam#conditionKeyValue"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public let value: String
    public init(value: String) {
        self.value = value
    }
}

/// Declares that the condition keys of a resource should not be inferred.
public struct AwsIAMDisableConditionKeyInferenceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.iam#disableConditionKeyInference"
    public var selector: Selector { OrSelector(TypeSelector<ResourceShape>(), TypeSelector<ServiceShape>()) }
}

/// Other actions that the invoker must be authorized to perform when executing the targeted operation.
public struct AwsIAMRequiredActionsTrait: SingleValueTrait {
    public static let staticName: ShapeId = "aws.iam#requiredActions"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let value: [String]
    public init(value: [String]) {
        self.value = value
    }
}

/// The IAM principal types that can use the service or operation.
public struct AwsIAMSupportPrincipalTypesTrait: SingleValueTrait {
    public enum PrincipalType: String, Codable {
        case root = "Root"
        case iamUser = "IAMUser"
        case iamRole = "IAMRole"
        case federatedUser = "FederatedUser"
    }

    public static let staticName: ShapeId = "aws.iam#supportedPrincipalTypes"
    public var selector: Selector { OrSelector(TypeSelector<ServiceShape>(), TypeSelector<OperationShape>()) }
    public let value: [PrincipalType]
    public init(value: [PrincipalType]) {
        self.value = value
    }
}

/// Indicates properties of a Smithy resource in AWS IAM.
public struct AwsIAMResourceTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.iam#iamResource"
    public var selector: Selector { TypeSelector<ResourceShape>() }
    public let name: String
    public init(name: String) {
        self.name = name
    }
}

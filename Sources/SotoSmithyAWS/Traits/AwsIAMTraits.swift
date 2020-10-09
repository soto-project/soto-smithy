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

public struct AwsIAMActionPermissionDescriptionTrait: SingleValueTrait {
    public static let staticName = "aws.iam#actionPermissionDescription"
    public var selector: Selector { return TypeSelector<OperationShape>() }
    public let value: String
    public init(value: String) {
        self.value = value
    }
}

public struct AwsIAMConditionKeysTrait: SingleValueTrait {
    public static let staticName = "aws.iam#conditionKeys"
    public var selector: Selector { return OrSelector(TypeSelector<OperationShape>(), TypeSelector<ResourceShape>()) }
    public let value: [String]
    public init(value: [String]) {
        self.value = value
    }
}

public struct AwsIAMDefineConditionKeysTrait: SingleValueTrait {
    public static let staticName = "aws.iam#defineConditionKeys"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
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

public struct AwsDisableConditionKeyInferenceTrait: StaticTrait {
    public static let staticName = "aws.iam#disableConditionKeyInference"
    public var selector: Selector { return TypeSelector<ResourceShape>() }
}

public struct AwsIAMRequiredActionsTrait: SingleValueTrait {
    public static let staticName = "aws.iam#requiredActions"
    public var selector: Selector { return TypeSelector<OperationShape>() }
    public let value: [String]
    public init(value: [String]) {
        self.value = value
    }
}

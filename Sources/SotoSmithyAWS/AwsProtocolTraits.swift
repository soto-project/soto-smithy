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

public struct AwsProtocolsRestJson1Trait: StaticTrait {
    public static let staticName = "aws.protocols#restJson1"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsAwsJson1_1Trait: StaticTrait {
    public static let staticName = "aws.protocols#awsJson1_1"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsAwsJson1_0Trait: StaticTrait {
    public static let staticName = "aws.protocols#awsJson1_0"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsAwsQueryTrait: StaticTrait {
    public static let staticName = "aws.protocols#awsQuery"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsEc2QueryTrait: StaticTrait {
    public static let staticName = "aws.protocols#ec2Query"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsRestXmlTrait: StaticTrait {
    public static let staticName = "aws.protocols#restXml"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

public struct AwsProtocolsEc2QueryNameTrait: SingleValueTrait {
    public static let staticName = "aws.protocols#ec2QueryName"
    public var selector: Selector { return TypeSelector<MemberShape>() }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

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

/// A protocol definition trait that configures a service to support the aws.protocols#restJson1 protocol.
///
/// This specification defines the aws.protocols#restJson1 protocol. This protocol is used to expose services
/// that serialize payloads as JSON and utilize features of HTTP like configurable HTTP methods, URIs, and
/// status codes.
public struct AwsProtocolsRestJson1Trait: StaticTrait {
    public static let staticName = "aws.protocols#restJson1"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Adds support for an HTTP protocol that sends POST requests and responses with JSON documents.
public struct AwsProtocolsAwsJson1_1Trait: StaticTrait {
    public static let staticName = "aws.protocols#awsJson1_1"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Adds support for an HTTP protocol that sends POST requests and responses with JSON documents.
public struct AwsProtocolsAwsJson1_0Trait: StaticTrait {
    public static let staticName = "aws.protocols#awsJson1_0"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Adds support for an HTTP protocol that sends requests in the query string and responses in XML documents.
public struct AwsProtocolsAwsQueryTrait: StaticTrait {
    public static let staticName = "aws.protocols#awsQuery"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Adds support for an HTTP protocol that sends requests in the query string OR in a x-form-url-encoded body
///  and responses in XML documents. This protocol is an Amazon EC2-specific extension of the awsQuery protocol.
public struct AwsProtocolsEc2QueryTrait: StaticTrait {
    public static let staticName = "aws.protocols#ec2Query"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Adds support for an HTTP-based protocol that sends XML requests and responses.
public struct AwsProtocolsRestXmlTrait: StaticTrait {
    public static let staticName = "aws.protocols#restXml"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}

/// Allows a serialized query key to differ from a structure member name when used in the model.
public struct AwsProtocolsEc2QueryNameTrait: SingleValueTrait {
    public static let staticName = "aws.protocols#ec2QueryName"
    public var selector: Selector { return TypeSelector<MemberShape>() }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

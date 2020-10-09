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

public struct AwsApiGatewayApiKeySourceTrait: SingleValueTrait {
    public static let staticName = "aws.apigateway#apiKeySource"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public enum KeySource: String, Codable {
        case header = "HEADER"
        case authorizer = "AUTHORIZER"
    }
    public let value: KeySource
    public init(value: Value) {
        self.value = value
    }
}

public struct AwsApiGatewayAuthorizersTrait: SingleValueTrait {
    public static let staticName = "aws.apigateway#authorizers"
    // need selector to test for trait inside "aws-protocols" namespace
    public var selector: Selector { return AndSelector(TypeSelector<ServiceShape>()) }
    public struct Authorizer: Codable {
        let scheme: String
        let type: String?
        let customAuthType: String?
        let uri: String?
        let credentials: String?
        let identitySource: String?
        let identityValidationExpression: String?
        let resultTtlInSeconds: Int?
    }
    public let value: [String: Authorizer]
    public init(value: Value) {
        self.value = value
    }
}

public struct AwsApiGatewayAuthorizerTrait: SingleValueTrait {
    public static let staticName = "aws.apigateway#authorizer"
    public var selector: Selector { return OrSelector(TypeSelector<ServiceShape>(), TypeSelector<ResourceShape>(), TypeSelector<OperationShape>()) }
    public let value: String
    public init(value: Value) {
        self.value = value
    }
}

public struct AwsApiGatewayRequestValidatorTrait: SingleValueTrait {
    public static let staticName = "aws.apigateway#requestValidator"
    public var selector: Selector { return OrSelector(TypeSelector<ServiceShape>(), TypeSelector<OperationShape>()) }
    public enum Validator: String, Codable {
        case full
        case paramsOnly = "params-only"
        case bodyOnly = "body-only"
    }
    public let value: Validator
    public init(value: Value) {
        self.value = value
    }
}

public struct AwsApiGatewayIntegrationTrait: StaticTrait {
    public static let staticName = "aws.apigateway#integration"
    public var selector: Selector { return OrSelector(TypeSelector<ServiceShape>(), TypeSelector<ResourceShape>(), TypeSelector<OperationShape>()) }
    public enum IntegrationType: String, Codable {
        case http
        case httpProxy = "http-proxy"
        case aws = "aws"
        case awsProxy = "aws-proxy"
    }
    public enum ContentHandling: String, Codable {
        case convertToText = "CONVERT_TO_TEXT"
        case convertToBinary = "CONVERT_TO_BINARY"
    }
    public enum ConnectionType: String, Codable {
        case internet = "INTERNET"
        case vpcLink = "VPC_LINK"
    }
    public struct Response: Codable {
        public let statusCode: String?
        public let responseTemplates: [String: String]?
        public let responseParameters: [String: String]?
        public let contentHandling: ContentHandling?
    }
    public let type: IntegrationType
    public let uri: String
    public let httpMethod: String
    public let credentials: String?
    public let passThroughBehavior: String?
    public let contentHandling: ContentHandling?
    public let timeoutInMillis: Int?
    public let connectionId: String?
    public let connectionType: ConnectionType?
    public let cacheNamespace: String?
    public let payloadFormatVersion: String?
    public let cacheKeyParameters: [String]?
    public let requestParameters: [String:String]?
    public let requestTemplates: [String:String]?
    public let responses: [String:Response]?
}

public struct AwsApiGatewayMockIntegrationTrait: StaticTrait {
    public static let staticName = "aws.apigateway#mockIntegration"
    public var selector: Selector { return OrSelector(TypeSelector<ServiceShape>(), TypeSelector<ResourceShape>(), TypeSelector<OperationShape>()) }
    public let passThroughBehavior: String?
    public let requestParameters: [String:[String:String]]?
    public let requestTemplates: [String:[String:String]]?
    public let responses: [String:AwsApiGatewayIntegrationTrait.Response]?
}

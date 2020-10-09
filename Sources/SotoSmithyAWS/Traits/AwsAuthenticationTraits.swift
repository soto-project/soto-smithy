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

public struct AwsAuthSigV4Trait: StaticTrait {
    public static let staticName = "aws.auth#sigv4"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
    public let name: String
}

public struct AwsAuthUnsignedPayloadTrait: StaticTrait {
    public static let staticName = "aws.auth#unsignedPayload"
    public var selector: Selector { return TypeSelector<OperationShape>() }
}

public struct AwsAuthCognitoUserPoolsTrait: StaticTrait {
    public static let staticName = "aws.auth#cognitoUserPools"
    public var selector: Selector { return TypeSelector<ServiceShape>() }
}
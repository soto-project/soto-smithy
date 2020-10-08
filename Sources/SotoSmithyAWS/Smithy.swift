//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SotoSmithy

extension Smithy {
    public static func registerAWSTraits() {
        // register AWS traits
        registerTraitTypes(
            // Core traits
            AwsServiceTrait.self,
            AwsArnTrait.self,
            AwsArnReferenceTrait.self,
            AwsDataTrait.self,
            AwsControlPlaneTrait.self,
            AwsDataPlaneTrait.self,
            AwsClientEndpointDiscoveryTrait.self,
            AwsClientDiscoveredEndpointTrait.self,
            AwsClientEndpointDiscoveryIdTrait.self,
            // Authentication Traits
            AwsAuthSigV4Trait.self,
            AwsAuthUnsignedPayloadTrait.self,
            AwsAuthCognitoUserPoolsTrait.self,
            // Protocol traits
            AwsProtocolsRestJson1Trait.self,
            AwsProtocolsAwsJson1_0Trait.self,
            AwsProtocolsAwsJson1_1Trait.self,
            AwsProtocolsAwsQueryTrait.self,
            AwsProtocolsEc2QueryTrait.self,
            AwsProtocolsRestXmlTrait.self,
            AwsProtocolsEc2QueryNameTrait.self
        )
    }


}
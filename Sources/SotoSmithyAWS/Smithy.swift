//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2021 the Soto project authors
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
            AwsHttpChecksumTrait.self,
            AwsTagEnabledTrait.self,
            AwsTaggableTrait.self,
            // Authentication Traits
            AwsAuthSigV4Trait.self,
            AwsAuthUnsignedPayloadTrait.self,
            AwsAuthCognitoUserPoolsTrait.self,
            // Protocol traits
            AwsProtocolsRestJson1Trait.self,
            AwsProtocolsAwsJson1_0Trait.self,
            AwsProtocolsAwsJson1_1Trait.self,
            AwsProtocolsAwsQueryTrait.self,
            AwsProtocolsAwsQueryErrorTrait.self,
            AwsProtocolsAwsQueryCompatibleTrait.self,
            AwsProtocolsEc2QueryTrait.self,
            AwsProtocolsRestXmlTrait.self,
            AwsProtocolsEc2QueryNameTrait.self,
            // IAM traits
            AwsIAMAction.self,
            AwsIAMActionName.self,
            AwsIAMConditionKeysTrait.self,
            AwsIAMRequiredActionsTrait.self,
            AwsIAMDefineConditionKeysTrait.self,
            AwsIAMActionPermissionDescriptionTrait.self,
            AwsIAMConditionKeyValueTrait.self,
            AwsIAMDisableConditionKeyInferenceTrait.self,
            AwsIAMServiceResolvedConditionKeys.self,
            AwsIAMSupportPrincipalTypesTrait.self,
            AwsIAMResourceTrait.self,
            // API Gateway traits
            AwsApiGatewayApiKeySourceTrait.self,
            AwsApiGatewayAuthorizersTrait.self,
            AwsApiGatewayAuthorizerTrait.self,
            AwsApiGatewayRequestValidatorTrait.self,
            AwsApiGatewayIntegrationTrait.self,
            AwsApiGatewayMockIntegrationTrait.self,
            // AWS CloudFormation traits
            AwsCloudFormationResourceTrait.self,
            AwsCloudFormationExcludePropertyTrait.self,
            AwsCloudFormationMutabilityTrait.self,
            AwsCloudFormationNameTrait.self,
            AwsCloudFormationAdditionalIdentifierTrait.self,
            AwsCloudFormationDefaultValueTrait.self,
            // S3 traits
            AwsS3UnwrappedXmlOutputTrait.self
        )
    }
}

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

import Foundation

/// Management for SotoSmithy. Decode Smithy models with this and register new Trait types
public struct Smithy {
    public init() {
        if Self.registeredShapes == false {
            Model.registerShapeTypes([
                // Simple shapes
                BlobShape.self,
                BooleanShape.self,
                StringShape.self,
                ByteShape.self,
                ShortShape.self,
                IntegerShape.self,
                LongShape.self,
                FloatShape.self,
                DoubleShape.self,
                BigIntegerShape.self,
                BigDecimalShape.self,
                TimestampShape.self,
                DocumentShape.self,
                // Aggregate shapes
                ListShape.self,
                SetShape.self,
                MapShape.self,
                StructureShape.self,
                UnionShape.self,
                // Service shapes
                ServiceShape.self,
                OperationShape.self,
                ResourceShape.self,
                // Apply shape
                ApplyShape.self
            ])

            Smithy.registerTraitTypes(
                // constraint traits
                EnumTrait.self,
                IdRefTrait.self,
                LengthTrait.self,
                PatternTrait.self,
                PrivateTrait.self,
                RangeTrait.self,
                RequiredTrait.self,
                UniqueItemsTrait.self,
                // documentation traits
                DeprecatedTrait.self,
                DocumentationTrait.self,
                ExamplesTrait.self,
                ExternalDocumentationTrait.self,
                InternalTrait.self,
                SensitiveTrait.self,
                SinceTrait.self,
                TagsTrait.self,
                TitleTrait.self,
                UnstableTrait.self,
                // type refinement traits
                BoxTrait.self,
                ErrorTrait.self,
                SparseTrait.self,
                // protocol traits
                ProtocolDefinitionTrait.self,
                JsonNameTrait.self,
                MediaTypeTrait.self,
                TimestampFormatTrait.self,
                // authentication traits
                AuthDefinitionTrait.self,
                HttpBasicAuthTrait.self,
                HttpDigestAuthTrait.self,
                HttpBearerAuthTrait.self,
                HttpApiKeyAuthTrait.self,
                OptionalAuthTrait.self,
                AuthTrait.self,
                // behaviour traits
                IdempotencyTokenTrait.self,
                IdempotentTrait.self,
                ReadonlyTrait.self,
                RetryableTrait.self,
                PaginatedTrait.self,
                HttpChecksumRequiredTrait.self,
                HttpChecksumTrait.self,
                // resource traits
                NoReplaceTrait.self,
                ReferencesTrait.self,
                ResourceIdentifierTrait.self,
                // streaming traits
                StreamingTrait.self,
                RequiresLengthTrait.self,
                EventHeaderTrait.self,
                EventPayloadTrait.self,
                // http protocol binding traits
                HttpTrait.self,
                HttpErrorTrait.self,
                HttpHeaderTrait.self,
                HttpLabelTrait.self,
                HttpPayloadTrait.self,
                HttpPrefixHeadersTrait.self,
                HttpQueryTrait.self,
                HttpQueryParamsTrait.self,
                HttpResponseCodeTrait.self,
                HttpCorsTrait.self,
                // xml binding traits
                XmlAttributeTrait.self,
                XmlFlattenedTrait.self,
                XmlNameTrait.self,
                XmlNamespaceTrait.self,
                // endpoint traits
                EndpointTrait.self,
                HostLabelTrait.self,
                // suppress trait
                SuppressTrait.self,
                // trait trait
                TraitTrait.self,
                // http compliance test traits
                HttpRequestTestsTrait.self,
                HttpResponseTestsTrait.self,
                // mqtt binding traits
                MqttPublishTrait.self,
                MqttSubscribeTrait.self,
                MqttTopicLabelTrait.self,
                // waiters traits
                WaitableTrait.self
            )
            Self.registeredShapes = true
        }
    }
    
    /// Decode Smithy JSON AST
    /// - Parameter data: Data holding Smithy model in JSON AST format
    /// - Returns: Smithy model
    public func decodeAST(from data: Data) throws -> Model {
        try JSONDecoder().decode(Model.self, from: data)
    }
    
    /// Register trait types with Smithy. All `StaticTrait` have to be registered if you want to decode them
    /// - Parameter traitTypes: List of traits to register
    public static func registerTraitTypes(_ traitTypes: StaticTrait.Type ...) {
        TraitList.registerTraitTypes(traitTypes)
    }

    static var preludeShapes: [ShapeId: Shape] = [
        "smithy.api#String": StringShape(traits: nil),
        "smithy.api#Blob": BlobShape(traits: nil),
        "smithy.api#BigInteger": BigIntegerShape(traits: nil),
        "smithy.api#BigDecimal": BigDecimalShape(traits: nil),
        "smithy.api#Timestamp": TimestampShape(traits: nil),
        "smithy.api#Document": DocumentShape(traits: nil),
        "smithy.api#Boolean": BooleanShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveBoolean": BooleanShape(traits: nil),
        "smithy.api#Byte": ByteShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveByte": ByteShape(traits: nil),
        "smithy.api#Short": ShortShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveShort": ShortShape(traits: nil),
        "smithy.api#Integer": IntegerShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveInteger": IntegerShape(traits: nil),
        "smithy.api#Long": LongShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveLong": LongShape(traits: nil),
        "smithy.api#Float": FloatShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveFloat": FloatShape(traits: nil),
        "smithy.api#Double": DoubleShape(traits: [BoxTrait()]),
        "smithy.api#PrimitiveDouble": DoubleShape(traits: nil),
    ]

    private static var registeredShapes: Bool = false

}

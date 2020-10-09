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

public struct HttpTrait: StaticTrait {
    public static let staticName = "smithy.api#http"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public let method: String
    public let uri: String
    public let code: Int?
}

public struct HttpErrorTrait: SingleValueTrait {
    public static let staticName = "smithy.api#httpError"
    public var selector: Selector { AndSelector(TypeSelector<StructureShape>(), TraitSelector<ErrorTrait>()) }
    public typealias Value = Int
    public var value: Int
    public init(value: Int) {
        self.value = value
    }
}

public struct HttpHeaderTrait: SingleValueTrait {
    public static let staticName = "smithy.api#httpHeader"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        NumberSelector(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>(),
        // TODO: really need to check member of List/Set
        TypeSelector<ListShape>(),
        TypeSelector<SetShape>()
    )) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct HttpLabelTrait: StaticTrait {
    public static let staticName = "smithy.api#httpLabel"
    public var selector: Selector { AndSelector(
        TargetSelector(OrSelector(
            TypeSelector<BooleanShape>(),
            NumberSelector(),
            TypeSelector<StringShape>(),
            TypeSelector<TimestampShape>()
        )),
        TraitSelector<RequiredTrait>()
    ) }
    public init() {}
}

public struct HttpPayloadTrait: StaticTrait {
    public static let staticName = "smithy.api#httpPayload"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<StringShape>(),
        TypeSelector<BlobShape>(),
        TypeSelector<StructureShape>(),
        TypeSelector<UnionShape>(),
        TypeSelector<DocumentShape>()
    )) }
    public init() {}
}

public struct HttpPrefixHeadersTrait: SingleValueTrait {
    public static let staticName = "smithy.api#httpPrefixHeaders"
    public var selector: Selector { TargetSelector(TypeSelector<MapShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct HttpQueryTrait: SingleValueTrait {
    public static let staticName = "smithy.api#httpQuery"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        NumberSelector(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>(),
        // TODO: really need to check member of List/Set
        TypeSelector<ListShape>(),
        TypeSelector<SetShape>()
    )) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct HttpResponseCodeTrait: StaticTrait {
    public static let staticName = "smithy.api#httpResponseCode"
    public var selector: Selector { TargetSelector(TypeSelector<IntegerShape>()) }
    public init() {}
}

public struct HttpCorsTrait: StaticTrait {
    public static let staticName = "smithy.api#cors"
    public var selector: Selector { TypeSelector<ServiceShape>() }
    public let origin: String?
    public let maxAge: Int?
    public let additionalAllowedHeaders: [String]?
    public let additionalExposedHeaders: [String]?
}
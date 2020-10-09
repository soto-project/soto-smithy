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

public struct StreamingTrait: StaticTrait {
    public static let staticName = "smithy.api#streaming"
    public var selector: Selector { OrSelector(TypeSelector<BlobShape>(), TypeSelector<UnionShape>()) }
    public init() {}
}

public struct RequiresLengthTrait: StaticTrait {
    public static let staticName = "smithy.api#requiresLength"
    public var selector: Selector { TraitSelector<StreamingTrait>() }
    public init() {}
}

public struct EventHeaderTrait: StaticTrait {
    public static let staticName = "smithy.api#eventHeader"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        TypeSelector<ByteShape>(),
        TypeSelector<ShortShape>(),
        TypeSelector<IntegerShape>(),
        TypeSelector<LongShape>(),
        TypeSelector<BlobShape>(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>()
    )) }
    public init() {}
}

public struct EventPayloadTrait: StaticTrait {
    public static let staticName = "smithy.api#eventPayload"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BlobShape>(),
        TypeSelector<StringShape>(),
        TypeSelector<StructureShape>(),
        TypeSelector<UnionShape>()
    )) }
    public init() {}
}

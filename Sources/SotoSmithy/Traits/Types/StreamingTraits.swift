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

/// Indicates that the data represented by the shape needs to be streamed.
///
/// When applied to a blob, this simply means that the data could be very large and thus should not be stored in
/// memory or that the size is unknown at the start of the request.
///
/// When applied to a union, it indicates that shape represents an event stream.
public struct StreamingTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#streaming"
    public var selector: Selector { OrSelector(TypeSelector<BlobShape>(), TypeSelector<UnionShape>()) }
    public init() {}
}

/// Indicates that the streaming blob MUST be finite and has a known size.
///
/// In an HTTP-based protocol, for instance, this trait indicates that the Content-Length header MUST be sent
/// prior to a client or server sending the payload of a message. This can be useful for services that need to
/// determine if a request will be accepted based on its size or where to store data based on the size of the stream.
public struct RequiresLengthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#requiresLength"
    public var selector: Selector { TraitSelector<StreamingTrait>() }
    public init() {}
}

/// Binds a member of a structure to be serialized as an event header when sent through an event stream.
public struct EventHeaderTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#eventHeader"
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

/// Binds a member of a structure to be serialized as the payload of an event sent through an event stream.
public struct EventPayloadTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#eventPayload"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BlobShape>(),
        TypeSelector<StringShape>(),
        TypeSelector<StructureShape>(),
        TypeSelector<UnionShape>()
    )) }
    public init() {}
}

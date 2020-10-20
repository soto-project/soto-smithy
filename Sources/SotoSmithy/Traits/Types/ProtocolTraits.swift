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

/// A meta-trait that marks a trait as a protocol definition trait. Traits that are marked with this trait are applied to
/// service shapes to define the protocols supported by a service. A client MUST understand at least one of the
/// protocols in order to successfully communicate with the service.
public struct ProtocolDefinitionTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#protocolDefinition"
    public init() {}
}

/// Allows a serialized object property name in a JSON document to differ from a structure member name used in
/// the model
public struct JsonNameTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#jsonName"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Describes the contents of a blob or string shape using a design-time media type as defined by RFC 6838 (for
/// example, application/json).
public struct MediaTypeTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#mediaType"
    public var selector: Selector { OrSelector(TypeSelector<BlobShape>(), TypeSelector<StringShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Defines a custom timestamp serialization format.
public struct TimestampFormatTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#timestampFormat"
    public var selector: Selector { OrTargetSelector(TypeSelector<TimestampShape>()) }
    public enum TimestampFormat: String, Codable {
        case datetime = "date-time"
        case httpDate = "http-date"
        case epochSeconds = "epoch-seconds"
    }
    public let value: TimestampFormat
    public init(value: TimestampFormat) {
        self.value = value
    }
}

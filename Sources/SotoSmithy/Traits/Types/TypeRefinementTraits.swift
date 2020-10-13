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

/// Indicates that a shape is boxed. When a member is marked with this trait or the shape targeted by a member is
/// marked with this trait, the member may or may not contain a value, and the member has no default value.
///
/// Boolean, byte, short, integer, long, float, and double shapes are only considered boxed if they are marked with
/// the box trait. All other shapes are always considered boxed.
public struct BoxTrait: StaticTrait {
    public static let staticName = "smithy.api#box"
    public var selector: Selector { OrTargetSelector(
        OrSelector(
            TypeSelector<BooleanShape>(),
            TypeSelector<ByteShape>(),
            TypeSelector<ShortShape>(),
            TypeSelector<IntegerShape>(),
            TypeSelector<LongShape>(),
            TypeSelector<FloatShape>(),
            TypeSelector<DoubleShape>()
        )
    ) }
    public init() {}
}

/// Indicates that a structure shape represents an error. All shapes referenced by the errors list of an operation MUST
/// be targeted with this trait.
public struct ErrorTrait: SingleValueTrait {
    public static let staticName = "smithy.api#error"
    public var selector: Selector { TypeSelector<StructureShape>() }
    public enum ErrorType: String, Codable {
        case client
        case server
    }

    public typealias Value = ErrorType
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

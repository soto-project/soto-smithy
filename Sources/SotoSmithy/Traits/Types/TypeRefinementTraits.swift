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
    public static let staticName: ShapeId = "smithy.api#box"
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
    public static let staticName: ShapeId = "smithy.api#error"
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

/// Specializes a structure for use only as the input of a single operation.
public struct InputTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#input"
    public var selector: Selector { TypeSelector<StructureShape>() }
    public init() {}
}

/// Specializes a structure for use only as the output of a single operation.
public struct OutputTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#output"
    public var selector: Selector { TypeSelector<StructureShape>() }
    public init() {}
}

/// Indicates that lists and maps MAY contain null values. The sparse trait has no effect on map keys; map keys are
/// never allowed to be null.
public struct SparseTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#sparse"
    public var selector: Selector { OrSelector(
        TypeSelector<ListShape>(),
        TypeSelector<MapShape>()
    ) }
    public init() {}
}

public struct DefaultTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#default"
    public enum Value: Decodable {
        case boolean(Bool)
        case number(Double)
        case string(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "DefaultTrait value cannot be decoded")
            }
        }
    }

    public let value: Value
    public init(value: Value) {
        self.value = value
    }

    public func validate(using model: Model, shape: Shape) throws {
        guard let member = shape as? MemberShape else { throw Smithy.ValidationError(reason: "Trait \(traitName) cannot be applied to shape **") }
        guard let target = model.shape(for: member.target) else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(member.target)") }
        switch self.value {
        case .boolean(let b):
            guard target is BooleanShape else { throw Smithy.ValidationError(reason: "Invalid default value \(b) for **") }
        case .number(let n):
            let selector = NumberSelector()
            guard selector.select(using: model, shape: target) else { throw Smithy.ValidationError(reason: "Invalid default value \(n) for **") }
        case .string(let s):
            guard target is StringShape else { throw Smithy.ValidationError(reason: "Invalid default value \(s) for **") }
        }
    }
}

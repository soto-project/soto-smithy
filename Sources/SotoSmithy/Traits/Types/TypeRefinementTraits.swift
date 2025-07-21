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
    public var selector: Selector {
        OrTargetSelector(
            OrSelector(
                TypeSelector<BooleanShape>(),
                TypeSelector<ByteShape>(),
                TypeSelector<ShortShape>(),
                TypeSelector<IntegerShape>(),
                TypeSelector<LongShape>(),
                TypeSelector<FloatShape>(),
                TypeSelector<DoubleShape>()
            )
        )
    }
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
    public var selector: Selector {
        OrSelector(
            TypeSelector<ListShape>(),
            TypeSelector<MapShape>()
        )
    }
    public init() {}
}

/// Provides a structure member with a default value.
public struct DefaultTrait: OptionalSingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#default"
    public enum DefaultValue: Decodable, Equatable {
        case boolean(Bool)
        case number(Double)
        case string(String)
        case empty

        public init(from decoder: Decoder) throws {
            struct DontDecode: Decodable {
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "DefaultTrait value cannot be decoded")
                }
            }
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let _ = try? container.decode([DontDecode].self) {
                self = .empty
            } else if let _ = try? container.decode([String: DontDecode].self) {
                self = .empty
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "DefaultTrait value cannot be decoded")
            }
        }
    }

    public let value: DefaultValue?
    public init(value: DefaultValue?) {
        self.value = value
    }

    public func validate(using model: Model, shape: Shape) throws {
        let targetShape: Shape
        if let member = shape as? MemberShape {
            guard let target = model.shape(for: member.target) else {
                throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(member.target)")
            }
            targetShape = target
        } else {
            targetShape = shape
        }
        switch self.value {
        case .boolean(let b):
            guard targetShape is BooleanShape else {
                throw Smithy.ValidationError(reason: "Invalid default value \(b) for **")
            }
        case .number(let n):
            let selector = NumberSelector()
            guard selector.select(using: model, shape: targetShape) else {
                throw Smithy.ValidationError(reason: "Invalid default value \(n) for **")
            }
        case .string(let s):
            guard targetShape is StringShape || targetShape is EnumShape || targetShape is BlobShape else {
                throw Smithy.ValidationError(reason: "Invalid default value \(s) for **")
            }
        case .empty:
            guard targetShape is ListShape || targetShape is MapShape || targetShape is DocumentShape else {
                throw Smithy.ValidationError(reason: "Invalid default value for **")
            }
        case .none:
            // do nothing
            break
        }
    }
}

/// Indicates that the default trait was added to a structure member after initially publishing the member.
/// This allows tooling to decide whether to ignore the @default trait if it will break backward compatibility
/// in the tool.
/// Specializes a structure for use only as the input of a single operation.
public struct AddedDefaultTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#addedDefault"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public init() {}
}

/// Requires that non-authoritative generators like clients treat a structure member as optional regardless
/// of if the member is also marked with the required trait or default trait.
public struct ClientOptionalTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#clientOptional"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public init() {}
}

public struct EnumValueTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#enumValue"
    public enum EnumValue: Decodable, Equatable {
        case integer(Int)
        case string(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Int.self) {
                self = .integer(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "EnumValueTrait value cannot be decoded")
            }
        }
    }

    public let value: EnumValue
    public init(value: EnumValue) {
        self.value = value
    }
}

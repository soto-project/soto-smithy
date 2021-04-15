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

/// Constrains the acceptable values of a string to a fixed set.
public struct EnumTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#enum"
    public var selector: Selector { TypeSelector<StringShape>() }
    public struct EnumDefinition: Codable {
        public init(value: String, name: String? = nil, documentation: String? = nil, tags: [String]? = nil, deprecated: Bool? = nil) {
            self.value = value
            self.name = name
            self.documentation = documentation
            self.tags = tags
            self.deprecated = deprecated
        }
        
        public let value: String
        public let name: String?
        public let documentation: String?
        public let tags: [String]?
        public let deprecated: Bool?
    }

    public typealias Value = [EnumDefinition]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

/// Indicates that a string value MUST contain a valid absolute shape ID
///
/// The idRef trait is used primarily when declaring trait shapes in a model. A trait shape that targets a string shape
/// with the idRef trait indicates that when the defined trait is applied to a shape, the value of the trait MUST be a valid
///  shape ID. The idRef trait can also be applied at any level of nesting on shapes referenced by trait shapes.
public struct IdRefTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#idRef"
    public var selector: Selector { OrTargetSelector(TypeSelector<StringShape>()) }
    public let failWhenMissing: Bool?
    public let resolvedShapeSelector: String?
    public let errorMessage: String?

    private enum CodingKeys: String, CodingKey {
        case failWhenMissing
        case resolvedShapeSelector = "selector"
        case errorMessage
    }
}

/// Constrains a shape to minimum and maximum number of elements or size.
public struct LengthTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#length"
    public var selector: Selector { OrTargetSelector(
        OrSelector(
            TypeSelector<ListShape>(),
            TypeSelector<SetShape>(),
            TypeSelector<MapShape>(),
            TypeSelector<StringShape>(),
            TypeSelector<BlobShape>()
        )
    ) }
    public let min: Int?
    public let max: Int?

    public init(min: Int?, max: Int?) {
        self.min = min
        self.max = max
    }
}

/// Restricts string shape values to a specified regular expression.
public struct PatternTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.api#pattern"
    public var selector: Selector { OrTargetSelector(TypeSelector<StringShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Prevents models defined in a different namespace from referencing the targeted shape.
public struct PrivateTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#private"
    public init() {}
}

/// Restricts allowed values of byte, short, integer, long, float, double, bigDecimal, and bigInteger shapes within an
/// acceptable lower and upper bound.
public struct RangeTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#range"
    public var selector: Selector { OrTargetSelector(NumberSelector()) }
    public let min: Double?
    public let max: Double?

    public init(min: Double?, max: Double?) {
        self.min = min
        self.max = max
    }
}

/// Marks a structure member as required, meaning a value for the member MUST be present.
public struct RequiredTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#required"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public init() {}
}

/// Indicates that the items in a List MUST be unique.
public struct UniqueItemsTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.api#uniqueItems"
    public init() {}
    //TODO: Validation :test(list > member > simpleType)
}

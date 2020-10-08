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

public struct EnumTrait: SingleValueTrait {
    public static let staticName = "smithy.api#enum"
    public var selector: Selector { TypeSelector<StringShape>() }
    public struct EnumDefinition: Codable {
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

public struct IdRefTrait: StaticTrait {
    public static let staticName = "smithy.api#idRef"
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

public struct LengthTrait: StaticTrait {
    public static let staticName = "smithy.api#length"
    public var selector: Selector { OrTargetSelector(
        OrSelector(
            TypeSelector<ListShape>(),
            TypeSelector<MapShape>(),
            TypeSelector<StringShape>(),
            TypeSelector<BlobShape>()
        )
    ) }
    public let min: Int?
    public let max: Int?
}

public struct PatternTrait: StringTrait {
    public static let staticName = "smithy.api#pattern"
    public var selector: Selector { OrTargetSelector(TypeSelector<StringShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct PrivateTrait: StaticTrait {
    public static let staticName = "smithy.api#private"
    public init() {}
}

public struct RangeTrait: StaticTrait {
    public static let staticName = "smithy.api#range"
    public var selector: Selector { OrTargetSelector(NumberSelector()) }
    public let min: Double?
    public let max: Double?
}

public struct RequiredTrait: StaticTrait {
    public static let staticName = "smithy.api#required"
    public var selector: Selector { TypeSelector<MemberShape>() }
    public init() {}
}

public struct UniqueItemsTrait: StaticTrait {
    public static let staticName = "smithy.api#uniqueItems"
    public init() {}
}

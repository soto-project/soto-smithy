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

/// Serializes an object property as an XML attribute rather than a nested XML element.
public struct XmlAttributeTrait: StaticTrait {
    public static let staticName = "smithy.api#xmlAttribute"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<BooleanShape>(),
        NumberSelector(),
        TypeSelector<StringShape>(),
        TypeSelector<TimestampShape>()
    )) }
    public init() {}
}

/// Unwraps the values of a list or map into the containing structure.
public struct XmlFlattenedTrait: StaticTrait {
    public static let staticName = "smithy.api#xmlFlattened"
    public var selector: Selector { TargetSelector(OrSelector(
        TypeSelector<ListShape>(),
        TypeSelector<SetShape>(),
        TypeSelector<MapShape>()
    )) }
    public init() {}
}

/// Changes the serialized element or attribute name of a structure, union, or member.
public struct XmlNameTrait: SingleValueTrait {
    public static let staticName = "smithy.api#xmlName"
    public var selector: Selector { OrSelector(
        TypeSelector<StructureShape>(),
        TypeSelector<UnionShape>(),
        TypeSelector<MemberShape>()
    ) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Adds an XML namespace to an XML element.
public struct XmlNamespaceTrait: StaticTrait {
    public static let staticName = "smithy.api#xmlNamespace"
    public let uri: String
    public let prefix: String?
}

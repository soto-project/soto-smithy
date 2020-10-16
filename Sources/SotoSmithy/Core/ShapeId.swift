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

/// Identifier for shape in model
public struct ShapeId: Equatable, Hashable, RawRepresentable {
    /// Raw string value
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(namespace: String, shapeName: String) {
        self.rawValue = "\(namespace)#\(shapeName)"
    }

    /// namespace
    public var namespace: String? {
        return self.rawValue.firstIndex(of: "#").map { return String(rawValue[rawValue.startIndex..<$0]) }
    }

    /// shape
    public var shapeName: String {
        let start = self.rawValue.firstIndex(of: "#").map { rawValue.index(after: $0) } ?? self.rawValue.startIndex
        let end = self.rawValue.firstIndex(of: "$") ?? self.rawValue.endIndex
        return String(self.rawValue[start..<end])
    }

    /// member
    public var member: String? {
        return self.rawValue.firstIndex(of: "$").map { return String(rawValue[rawValue.index(after: $0)..<rawValue.endIndex]) }
    }

    /// root shape id
    public var rootShapeId: ShapeId {
        let end = self.rawValue.firstIndex(of: "$") ?? self.rawValue.endIndex
        return ShapeId(rawValue: String(self.rawValue[self.rawValue.startIndex..<end]))
    }
}

extension ShapeId: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension ShapeId: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral: String) {
        self.rawValue = stringLiteral
    }
}

extension ShapeId: CustomStringConvertible {
    public var description: String { return self.rawValue }
}

extension ShapeId: Comparable {
    public static func < (lhs: ShapeId, rhs: ShapeId) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

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

public struct ShapeId: Codable, Equatable, Hashable, RawRepresentable, CustomStringConvertible, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public typealias RawValue = String
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral: String) {
        self.rawValue = stringLiteral
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    /// namespace
    public var namespace: Substring? {
        return rawValue.firstIndex(of: "#").map { return rawValue[rawValue.startIndex..<$0]}
    }
    /// shape
    public var shape: Substring {
        let start = rawValue.firstIndex(of: "#").map { rawValue.index(after: $0) } ?? rawValue.startIndex
        let end = rawValue.firstIndex(of: "$") ?? rawValue.endIndex
        return rawValue[start..<end]
    }
    /// member
    public var member: Substring? {
        return rawValue.firstIndex(of: "$").map { return rawValue[rawValue.index(after: $0)..<rawValue.endIndex]}
    }
    /// root shape id
    public var rootShapeId: Substring {
        let end = rawValue.firstIndex(of: "$") ?? rawValue.endIndex
        return rawValue[rawValue.startIndex..<end]
    }
    
    public var description: String { return rawValue }
}
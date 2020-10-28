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

/// Protocol for all Errors returned by SotoSmithy
public protocol SmithyError: Error {
    var reason: String { get }
    var context: SmithyErrorContext? { get }
}

extension SmithyError {
    public var context: SmithyErrorContext? { return nil }
}

/// Context for error. The line it happened on, the line and column number
public struct SmithyErrorContext {
    public let line: String
    public let lineNumber: Int
    public let columnNumber: Int
    
    init(_ parser: Parser) {
        let context = parser.getContext()

        self.line = context.line
        self.lineNumber = context.lineNumber
        self.columnNumber = context.columnNumber
    }

    init?(_ string: String, position: String.Index) {
        var parser = Parser(string)
        do {
            try parser.setPosition(position)
        } catch {
            return nil
        }
        self.init(parser)
    }
    
}

extension Smithy {
    /// Error thrown when `Model.validate` finds an error
    public struct ValidationError: SmithyError {
        public let reason: String
    }
    
    /// Error thrown when shape being looked for doesnt exist
    public struct ShapeDoesNotExistError: SmithyError {
        public let id: ShapeId
        public var reason: String { "Shape \(id) does not exist" }
    }

    /// Error thrown when shape member being looked for doesnt exist
    public struct MemberDoesNotExistError: SmithyError {
        public let name: String
        public var reason: String { "Shape member \(name) does not exist" }
    }
    
    /// Error thrown when parsing a selector failed
    public struct UnrecognisedSelectorError: SmithyError {
        public let value: String
        public var reason: String { "Unrecoginised selector \"\(value)\"" }
    }
}

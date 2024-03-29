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

// import Foundation

struct Tokenizer {
    struct Token: CustomStringConvertible {
        enum TokenType: Equatable {
            case token(Substring)
            case grammar(Character)
            case string(String)
            case number(Double)
            case documentationComment(Substring)
            case newline
        }

        let type: TokenType
        let position: String.Index

        init(_ type: TokenType, position: String.Index) {
            self.type = type
            self.position = position
        }

        static func == (lhs: Self, rhs: Tokenizer.Token.TokenType) -> Bool {
            return lhs.type == rhs
        }

        static func != (lhs: Self, rhs: Tokenizer.Token.TokenType) -> Bool {
            return lhs.type != rhs
        }

        var description: String {
            switch self.type {
            case .token(let string):
                return ".token(\(string))"
            case .grammar(let char):
                return ".grammar(\(char))"
            case .string(let string):
                return ".string(\"\(string)\")"
            case .number(let number):
                return ".number(\(number))"
            case .documentationComment(let string):
                return ".comment(\(string))"
            case .newline:
                return ".newline"
            }
        }
    }

    static var numberChars = set(from: "0123456789.")
    static var numberStartChars = set(from: "0123456789")

    static var defaultGrammarChars = set(from: "(){}:[],=")
    static var defaultTokenChars = set(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@.#$_-")
    static var defaultTokenStartChars = set(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@$")

    let tokenChars: Set<Character>
    let tokenStartChars: Set<Character>
    let grammarChars: Set<Character>

    init(tokenChars: String? = nil, tokenStartChars: String? = nil, grammarChars: String? = nil) {
        self.tokenChars = tokenChars.map { Self.set(from: $0) } ?? Self.defaultTokenChars
        self.tokenStartChars = tokenStartChars.map { Self.set(from: $0) } ?? Self.defaultTokenStartChars
        self.grammarChars = grammarChars.map { Self.set(from: $0) } ?? Self.defaultGrammarChars
    }

    static func set(from string: String) -> Set<Character> {
        return .init(string.map { $0 })
    }

    func tokenize(_ smithy: String) throws -> [Token] {
        var parser = Parser(smithy)
        var tokens: [Token] = []

        while !parser.reachedEnd() {
            parser.read(while: Self.set(from: " \t"))
            let current = try parser.current()
            let position = parser.position
            if grammarChars.contains(current) {
                tokens.append(.init(.grammar(try parser.character()), position: position))
            } else if current.isNewline {
                try parser.advance()
                tokens.append(.init(.newline, position: position))
            } else if tokenStartChars.contains(current) {
                let token = parser.read(while: tokenChars)
                tokens.append(.init(.token(token), position: position))
            } else if Self.numberStartChars.contains(current) {
                let token = parser.read(while: Self.numberChars)
                tokens.append(.init(.number(Double(token) ?? 0.0), position: position))
            } else if current == "\"" {
                let text = try readQuotedText(from: &parser)
                tokens.append(.init(.string(text), position: position))
            } else if current == "/" {
                if let comment = try readDocumentationComment(from: &parser) {
                    tokens.append(.init(.documentationComment(comment), position: position))
                }
            } else {
                throw Error.unexpectedCharacter(parser)
            }
        }
        return tokens
    }

    func readQuotedText(from parser: inout Parser) throws -> String {
        var stringParser = parser
        defer { parser = stringParser }
        var text = ""
        try stringParser.advance()
        do {
            // check for """
            if try stringParser.current() == "\"" {
                try stringParser.advance()
                if !stringParser.reachedEnd(), try stringParser.current() == "\"" {
                    return try self.readBlockText(from: &stringParser)
                }
                return ""
            }
            repeat {
                text += try stringParser.read(until: Set(Self.set(from: "\\\"\n")))
                let current = try stringParser.current()
                if current == "\\" {
                    try stringParser.advance()
                    let escapeCharacter = try stringParser.character()
                    switch escapeCharacter {
                    case "n":
                        text += "\n"
                    case "t":
                        text += "\t"
                    case "\"":
                        text += "\""
                    default:
                        throw Error.unrecognisedEscapeCharacter(stringParser)
                    }
                } else if current == "\n" {
                    throw Error.unterminatedString(parser)
                }
            } while try stringParser.current() != "\""
            try stringParser.advance()
        } catch Parser.Error.overflow {
            throw Error.unterminatedString(parser)
        }
        return text
    }

    func readBlockText(from parser: inout Parser) throws -> String {
        var stringParser = parser
        defer { parser = stringParser }
        try stringParser.advance()
        var text = ""

        let newlineToken = try stringParser.character()
        guard newlineToken == "\n" else { throw Error.corruptTextBlock(stringParser) }

        do {
            while true {
                text += try stringParser.read(until: Set(Self.set(from: "\\\"")))
                let current = try stringParser.current()
                if current == "\\" {
                    try stringParser.advance()
                    let escapeCharacter = try stringParser.character()
                    switch escapeCharacter {
                    case "n":
                        text += "\n"
                    case "t":
                        text += "\t"
                    case "\"":
                        text += "\""
                    case "\n":
                        text += "\\\n"
                    default:
                        throw Error.unrecognisedEscapeCharacter(stringParser)
                    }
                } else if current == "\"" {
                    let quoteCount = stringParser.read(while: "\"")
                    if quoteCount == 1 {
                        text += "\""
                    } else if quoteCount == 2 {
                        text += "\"\""
                    } else if quoteCount == 3 {
                        break
                    } else {
                        throw Error.unexpectedCharacter(stringParser)
                    }
                }
            }
        } catch Parser.Error.overflow {
            throw Error.unterminatedString(parser)
        }

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let lastLine = lines.last!
        let numSpaces = lastLine.count
        try lastLine.forEach {
            guard $0 == " " else { throw Error.corruptTextBlock(parser) }
        }
        // remove indentation
        let linesNoIndent = try lines.dropLast().map { line -> Substring.SubSequence in
            if line.count == 0 {
                return ""
            }
            guard line.starts(with: lastLine) else { throw Error.corruptTextBlock(parser) }
            return line.dropFirst(numSpaces)
        }
        // construct string (merge any string ending with "\" with the next line
        return String(linesNoIndent.reduce("") {
            if $0.last == "\\" {
                return "\($0.dropLast())\($1)"
            } else {
                return "\($0)\n\($1)"
            }
        }.dropFirst())
    }

    func readDocumentationComment(from parser: inout Parser) throws -> Substring? {
        try parser.advance()
        guard try parser.read("/") else {
            throw Error.unexpectedCharacter(parser)
        }
        let documentationComment = try parser.read("/")
        parser.read(while: Self.set(from: " \t"))
        let text = try parser.read(until: "\n", throwOnOverflow: false)
        // skip newline
        if !parser.reachedEnd(), try parser.current() == "\n" {
            try parser.advance()
        }
        return documentationComment ? text : nil
    }

    struct Error: SmithyError {
        enum ErrorType {
            case unexpectedCharacter
            case unrecognisedEscapeCharacter
            case unterminatedString
            case corruptTextBlock
        }

        let errorType: ErrorType
        let context: SmithyErrorContext?

        static func unexpectedCharacter(_ parser: Parser) -> Self { .init(errorType: .unexpectedCharacter, context: .init(parser)) }
        static func unrecognisedEscapeCharacter(_ parser: Parser) -> Self { .init(errorType: .unrecognisedEscapeCharacter, context: .init(parser)) }
        static func unterminatedString(_ parser: Parser) -> Self { .init(errorType: .unterminatedString, context: .init(parser)) }
        static func corruptTextBlock(_ parser: Parser) -> Self { .init(errorType: .corruptTextBlock, context: .init(parser)) }

        var reason: String {
            switch self.errorType {
            case .unexpectedCharacter:
                return "Unexpected character"
            case .unrecognisedEscapeCharacter:
                return "Unrecognised escape character"
            case .unterminatedString:
                return "Unterminated string"
            case .corruptTextBlock:
                return "Invalid text block"
            }
        }
    }
}

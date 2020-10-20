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

import Foundation

struct Tokenizer {
    enum Token: Equatable {
        case token(Substring)
        case grammar(Character)
        case string(String)
        case number(Double)
        case documentationComment(Substring)
        case newline
        
    }

    static var tokenChars = set(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@.#$_-")
    static var tokenStartChars = set(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@")
    static var numberChars = set(from: "0123456789.")
    static var numberStartChars = set(from: "0123456789")
    static var grammarChars = set(from: "(){}:[],=")

    static func set(from string: String) -> Set<Character> {
        return .init(string.map{ $0 })
    }
    
    func tokenize(_ smithy: String) throws -> [Token] {
        var parser = Parser(smithy)
        var tokens: [Token] = []

        while !parser.reachedEnd() {
            parser.read(while: Self.set(from: " \t"))
            let current = try parser.current()
            if Self.grammarChars.contains(current) {
                tokens.append(.grammar(try parser.character()))
            } else if current.isNewline {
                try parser.advance()
                tokens.append(.newline)
            } else if Self.tokenStartChars.contains(current) {
                let token = parser.read(while: Self.tokenChars)
                tokens.append(.token(token))
            } else if Self.numberStartChars.contains(current) {
                let token = parser.read(while: Self.numberChars)
                tokens.append(.number(Double(token) ?? 0.0 ))
            } else if current == "\"" {
                let text = try readQuotedText(from: &parser)
                tokens.append(.string(text))
            } else if current == "/" {
                if let comment = try readDocumentationComment(from: &parser) {
                    tokens.append(.documentationComment(comment))
                }
            } else {
                throw Error.unrecognisedCharacter(parser)
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
                    return try readBlockText(from: &stringParser)
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
        } catch ParserError.overflow {
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
        guard newlineToken == "\n" else { throw Error.multilineError(stringParser) }
        
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
                        break
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
        } catch ParserError.overflow {
            throw Error.unterminatedString(parser)
        }
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let lastLine = lines.last!
        let numSpaces = lastLine.count
        try lastLine.forEach {
            guard $0 == " " else { throw Error.multilineError(parser) }
        }
        // remove indentation
        let linesNoIndent = try lines.dropLast().map { line -> Substring.SubSequence in
            if line.count == 0 {
                return ""
            }
            guard line.starts(with: lastLine) else { throw Error.multilineError(parser) }
            return line.dropFirst(numSpaces)
        }
        return linesNoIndent.joined(separator: "\n")
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
        if try parser.current() == "\n" {
            try parser.advance()
        }
        return documentationComment ? text : nil
    }
    
    struct Error: Swift.Error {
        enum ErrorType {
            case unrecognisedCharacter
            case unexpectedCharacter
            case unrecognisedEscapeCharacter
            case unterminatedString
            case multilineError
        }
        let errorType: ErrorType
        let context: Parser.Context

        static func unrecognisedCharacter(_ parser: Parser) -> Self { .init(errorType: .unrecognisedCharacter, context: parser.getContext()) }
        static func unexpectedCharacter(_ parser: Parser) -> Self { .init(errorType: .unexpectedCharacter, context: parser.getContext()) }
        static func unrecognisedEscapeCharacter(_ parser: Parser) -> Self { .init(errorType: .unrecognisedEscapeCharacter, context: parser.getContext()) }
        static func unterminatedString(_ parser: Parser) -> Self { .init(errorType: .unterminatedString, context: parser.getContext()) }
        static func multilineError(_ parser: Parser) -> Self { .init(errorType: .multilineError, context: parser.getContext()) }
    }
}

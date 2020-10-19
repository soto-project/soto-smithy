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
    
    enum Error: Swift.Error {
        case unrecognisedCharacter(line: String, lineNumber: Int, column: Int)
        case unexpectedCharacter(line: String, lineNumber: Int, column: Int)
        case unrecognisedEscapeCharacter(line: String, lineNumber: Int, column: Int)
        case unterminatedString(line: String, lineNumber: Int, column: Int)
    }

    static var tokenChars = set(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@.#$")
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
        var lineNumber: Int = 1
        while !parser.reachedEnd() {
            parser.read(while: Self.set(from: " \t"))
            let current = try parser.current()
            if Self.grammarChars.contains(current) {
                tokens.append(.grammar(try parser.character()))
            } else if current.isNewline {
                lineNumber += 1
                try parser.advance()
                tokens.append(.newline)
            } else if Self.tokenStartChars.contains(current) {
                let token = parser.read(while: Self.tokenChars)
                tokens.append(.token(token))
            } else if Self.numberStartChars.contains(current) {
                let token = parser.read(while: Self.numberChars)
                tokens.append(.number(Double(token) ?? 0.0 ))
            } else if current == "\"" {
                let text = try readString(from: &parser, lineNumber: lineNumber)
                tokens.append(.string(text))
            } else if current == "/" {
                if let comment = try readDocumentationComment(from: &parser, lineNumber: lineNumber) {
                    tokens.append(.documentationComment(comment))
                }
            } else {
                let position = try getCurrentLine(from: parser)
                throw Error.unrecognisedCharacter(line: position.line, lineNumber: lineNumber, column: position.column)
            }
        }
        return tokens
    }
    
    func readString(from parser: inout Parser<String>, lineNumber: Int) throws -> String {
        var stringParser = parser
        var text = ""
        try stringParser.advance()
        do {
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
                        let position = try getCurrentLine(from: stringParser)
                        throw Error.unrecognisedEscapeCharacter(line: position.line, lineNumber: lineNumber, column: position.column)
                    }
                } else if current == "\n" {
                    let position = try getCurrentLine(from: parser)
                    throw Error.unterminatedString(line: position.line, lineNumber: lineNumber, column: position.column)
                }
            } while try stringParser.current() != "\""
            try stringParser.advance()
        } catch ParserError.overflow {
            let position = try getCurrentLine(from: parser)
            throw Error.unterminatedString(line: position.line, lineNumber: lineNumber, column: position.column)
        }
        parser = stringParser
        return text
    }
    
    func readDocumentationComment(from parser: inout Parser<String>, lineNumber: Int) throws -> Substring? {
        try parser.advance()
        guard try parser.read("/") else {
            let position = try getCurrentLine(from: parser)
            throw Error.unexpectedCharacter(line: position.line, lineNumber: lineNumber, column: position.column)
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
    
    func getCurrentLine(from parser: Parser<String>) throws -> (line: String, column: Int) {
        var parser = parser
        var column = 0
        while !parser.atStart() {
            try parser.retreat()
            if try parser.current() == "\n" {
                break
            }
            column += 1
        }
        if try parser.current() == "\n" {
            try parser.advance()
        }
        let line = try parser.read(until: Character("\n"), throwOnOverflow: false)
        return (line: String(line), column: column)
    }
}

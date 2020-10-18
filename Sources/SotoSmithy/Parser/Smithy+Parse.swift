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

enum SmithyParserError: Error {
    case shapesDefinedBeforeNamespace
    case namespaceAlreadyDefined
    case missingNamespace
    case missingShapeName
    case unexpectedToken
    case overflow
}

extension Smithy {
    
    func parse(_ string: String) throws -> Model {
        var model: [Substring: Any] = [:]
        var modelShapes: [Substring: Any] = [:]
        let tokens = try Tokenizer().tokenize(string)
        var tokenParser = TokenParser(tokens: tokens)
        var namespace: Substring? = nil

        model["smithy"] = "1.0"
        
        while !tokenParser.reachedEnd() {
            let token = try tokenParser.nextToken()
            if case .token(let string) = token {
                if string == "namespace" {
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingNamespace }
                    guard modelShapes["shapes"] == nil else { throw SmithyParserError.shapesDefinedBeforeNamespace }
                    guard namespace == nil else { throw SmithyParserError.namespaceAlreadyDefined }
                    namespace = name
                } else if string.first == "@" {
                    //let traitName = string.dropFirst()
                } else {
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingShapeName }
                    let shapeName = namespace != nil ? "\(namespace!)#\(name)" : name
                    modelShapes[shapeName] = try parseModel(&tokenParser, type: string)
                }
            }
        }
        model["shapes"] = modelShapes
        let data = try JSONSerialization.data(withJSONObject: model, options: [])
        print(String(data: data, encoding: .utf8)!)
        return try Smithy().decodeAST(from: data)
    }
    
    func parseModel(_ tokenParser: inout TokenParser, type: Substring) throws -> [Substring: Any] {
        var model: [Substring: Any] = ["type": type]
        guard !tokenParser.reachedEnd() else { return model }
        let next = try tokenParser.nextToken()
        guard next != .newline else { return model }
        guard next == .grammar("{") else { throw SmithyParserError.unexpectedToken }
        let shapeTokens = try tokenParser.read(until: .grammar("}"))
        _ = try tokenParser.nextToken()
        return [:]
    }
    
    /// Token parser used internal by Smithy.parse
    struct TokenParser {
        let tokens: [Tokenizer.Token]
        var position: Int = 0
        
        mutating func nextToken() throws -> Tokenizer.Token {
            guard position < tokens.count else { throw SmithyParserError.overflow }
            let token = tokens[position]
            position += 1
            return token
        }
        
        mutating func token(_ token: Tokenizer.Token) throws {
            guard position < tokens.count else { throw SmithyParserError.overflow }
            guard token == tokens[position] else { throw SmithyParserError.unexpectedToken }
            position += 1
        }
        
        @discardableResult mutating func read(until: Tokenizer.Token, throwOnOverflow: Bool = true) throws -> ArraySlice<Tokenizer.Token> {
            let startIndex = position
            while !reachedEnd() {
                let token = try nextToken()
                if token == until {
                    return tokens[startIndex..<position]
                }
            }
            if throwOnOverflow {
                position = startIndex
                throw SmithyParserError.overflow
            }
            return tokens[startIndex..<position]
        }

        func reachedEnd() -> Bool {
            return position == tokens.count
        }
    }
    
}
